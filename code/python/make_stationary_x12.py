import numpy as np
import pandas as pd
import os
from fuzzywuzzy import fuzz
from statsmodels.tsa.stattools import adfuller, kpss
import matplotlib.pyplot as plt
import statsmodels.api as sm
from pmdarima.arima import auto_arima
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.graphics.tsaplots import plot_pacf
import time
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from scipy.stats import norm
import seaborn as sns
# Specify the path to your .out file
agg_data  = pd.read_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.xlsx")

# Specify the directory containing the .d11 files
directory = '/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/x12/output'

# Create an empty DataFrame to store the imported data
data = pd.DataFrame()

# Iterate over all files in the directory
for filename in os.listdir(directory):
    print(filename)
    if filename.endswith('.d11'):
        
        # Construct the full file path
        file_path = os.path.join(directory, filename)
        
        # Import the .d11 file using pandas read_csv()
        file_data = pd.read_csv(file_path, skiprows=0, delim_whitespace=True, index_col=0).reset_index()
        file_data.drop(0, inplace=True)

    
        # Extract the desired column (e.g., Adjusted series)
        print(file_data.columns)
        col_name  = filename[:-4]
        file_data.columns = ["date", "series"]
        adjusted_series = file_data['series']
        
        # Append the column to the combined DataFrame
        data[col_name] = adjusted_series
        
data.columns = data.columns.str.upper()
agg_data.columns = agg_data.columns.str.upper()
data.columns = data.columns.str.replace(' ', '_')

bad_cols = []
for c in agg_data.columns:
    if c not in data.columns:
        bad_cols.append(c)
        
        
for column in bad_cols:
    if column not in agg_data.columns:
        # Loop over each column in dataset2
        max_ratio = 0  # Initialize maximum fuzzy match ratio
        matched_column = None  # Initialize variable to store matched column name
        
        for column2 in agg_data.columns:
            # Calculate fuzzy match ratio between column names
            ratio = fuzz.token_sort_ratio(column, column2)
            
            # Check if the ratio is greater than the maximum found so far
            if ratio > max_ratio:
                max_ratio = ratio
                matched_column = column2
        
        # Check if a suitable match is found (minimum match ratio threshold can be adjusted)
        if max_ratio > 80:
            data.rename(columns={column: matched_column}, inplace=True)

# Export deseasoned consumption
consumption = pd.to_numeric(data["DURABLE_CONSUMPTION"]) + 	pd.to_numeric(data["NONDURABLE_CONSUMPTION"]) + pd.to_numeric(data["SERVICES_CONSUMPTION"])
consumption.to_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/consumption.xlsx")          


# Detrending the data
# Step 1: Taking the logs

tricky_cols = [
    # "MMFSABSHNO",
    # "BOGZ1LM153091003Q",
    # "BOGZ1LM153061705Q",
    # "BOGZ1FL153069005Q",
    "UNEMPLOYMENT_RATE",
    "GS1",
    "GS5",
    "CORP_BOND_PREMIA",
	"SP_DIV_YIELD",
    "TB3MS",
    "TIME"
    ]
agg_data.dropna(inplace=True)
agg_data.reset_index(inplace=True, drop=True)
data.reset_index(inplace=True, drop=True)
data["TIME"] = agg_data["TIME"]
cols = data.columns.difference(tricky_cols)


for c in cols:
    print(c)
    data[c] = pd.to_numeric(data[c])
    if c == "BOGZ1FL153069005Q":
        data[c] = np.log(data[c] + 2000)
    else:
        data[c] = np.log(data[c] + 2) #np.sign(data[c]) * np.abs(data[c])**(1/4)

for c in tricky_cols:
    print(c)
    if c == "TIME":
        pass
    else:
        data[c] = pd.to_numeric(data[c])
        data[c] = data[c] / 100

data = data[3:]
data = data.drop('BOGZ1FL153069005Q', axis=1)
cols = data.columns.difference(["TIME"])
data = data.dropna().reset_index(drop=True)

# Performing HP-Filter
for c in cols:
    data[c] = sm.tsa.filters.hpfilter(data[c], 1600)[0]
    results = adfuller(data[c].dropna())    
    if results[1] > .05:
        print(c)
        # if c in ["UNEMPLOYMENT_RATE", "TB3MS", "GS1", "GS5", "CORP_BOND_PREMIA", "SP_DIV_YIELD"]:
        #     pass
        # else:
        #     data[c] = data[c].diff()
        #     results = adfuller(data[c].dropna())
        #     print("new ", results[1])

data = data.dropna().reset_index(drop=True)
data.to_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/test_stationary_series.xlsx")          



# DIAGNOSTICS
# Plot histogram of residuals and compare to normal distribution
output_dir = r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/stationarity_checks"
for c in cols:
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(data[c], kde=True, ax=ax, color='blue', stat='density')
    x = np.linspace(norm.ppf(0.01), norm.ppf(0.99), 100)
    ax.plot(x, norm.pdf(x), 'r-', lw=2, label='Normal PDF')
    ax.legend()
    ax.set_title('Histogram of Residuals')
    
    if output_dir is not None:
        file_path = os.path.join(output_dir, f'{c}_residuals_histogram.png')
        fig.savefig(file_path, bbox_inches='tight')


    # Plot ACF and PACF of residuals
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6))
    plot_acf(data[c], ax=ax1)
    plot_pacf(data[c], ax=ax2)
    ax1.set_title('ACF of Residuals')
    ax2.set_title('PACF of Residuals')
    
    if output_dir is not None:
        file_path = os.path.join(output_dir, f'{c}_residuals_acf_pacf.png')
        fig.savefig(file_path, bbox_inches='tight')
        
# FINAL CHECK
for c in data.columns.difference(["TIME"]):
    if kpss(data[c].dropna())[1] <= .05:
        print(c)
        print(kpss(data[c].dropna())[1])
