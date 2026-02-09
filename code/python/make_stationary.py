import pandas as pd 
import numpy as np  
from statsmodels.tsa.stattools import adfuller
from tsfracdiff import FractionalDifferentiator
import statsmodels.api as sm

data      = pd.read_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.xlsx")
tricky_cols = [
    # "MMFSABSHNO",
    # "BOGZ1LM153091003Q",
    # "BOGZ1LM153061705Q",
    # "BOGZ1FL153069005Q",
    "TB3MS",
    "time"
    ]

for c in data.columns.difference(tricky_cols):
    data[c] = np.sign(data[c]) * np.abs(data[c])**(1/4) #np.log(data[c])
    results = adfuller(data[c])
    print(results[1])
    if results[1] > .05:
        data[c] = data[c].diff()
        results = adfuller(data[c].dropna())
        print("new ", results[1])
        if results[1] > .05:
            print(c)
            data[c] = data[c].diff()
            results = adfuller(data[c].dropna())
            print("new ", results[1])

data.to_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/stationary_series.xlsx")          


# fracDiff = FractionalDifferentiator(maxOrderBound=1, unitRootTest='ADF')
# test_cols = data.columns.difference(['time'])
# for c in test_cols:
#     print(c)
#     data[c] = fracDiff.FitTransform(data[c], parallel=False)
    
data = data[test_cols]
data.to_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/stationary_series.xlsx")          

# data      = data.loc[:, data.columns != 'time']

data.insert(0, 't', range(1, 1 + len(data)))
data["t2"] = data["t"]*data["t"]
cols = data.columns.difference(['t', 't2', "time"])

# Remove any kind of trend variation 
# for c in cols:
#     X = data[["t", "t2"]]
#     y = data[c]

#     # fit the model
#     model = sm.OLS(y, sm.add_constant(X, prepend=False)).fit()
#     pred  = model.predict()
#     data[c] = y - pred


for c in cols:
    results = adfuller(data[c])
    print(results[1])
    if results[1] > .05:
        data[c] = data[c].diff()
        results = adfuller(data[c].dropna())
        print("new ", results[1])
        if results[1] > .05:
            data[c] = data[c].diff()
            results = adfuller(data[c].dropna())
            print("new ", results[1])
            
data = data[cols]
data.to_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/stationary_series.xlsx")          


# Only first differencing the data
import pandas as pd 
import numpy as np  
import matplotlib.pyplot as plt
from statsmodels.tsa.stattools import adfuller
import statsmodels.api as sm

# Trying this new method https://econweb.ucsd.edu/~jhamilto/HX.pdf
# df.plot(subplots=True, layout=(4,5))
data      = pd.read_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.xlsx")

# Retain cyclical variation 
tricky_cols = [
    # "MMFSABSHNO",
    # "BOGZ1LM153091003Q",
    # "BOGZ1LM153061705Q",
    # "BOGZ1FL153069005Q",
    "unemployment_rate",
    "gs1",
    "gs5",
    "corp_bond_premia",
	"sp_div_yield",
    "TB3MS",
    "time"
    ]
cols = data.columns.difference(tricky_cols)

for c in cols:
    if c == "BOGZ1FL153069005Q":
        data[c] = np.log(data[c] + 2000)
    else:
        data[c] = np.log(data[c] + 2) #np.sign(data[c]) * np.abs(data[c])**(1/4)

for c in tricky_cols:
    if c == "time":
        pass
    else:
        data[c] = data[c] / 100

data = data.dropna()

# Remove seasonality
data.insert(0, 't', range(1, 1 + len(data)))
data["t2"] = data["t"]*data["t"]

# redefine cols here to remove seasonality and difference out 
cols = data.columns.difference(['t', 't2', "time"])

# Remove any kind of trend variation 
for c in cols:
    X = data[["t", "t2"]]
    y = data[c]

    # fit the model
    model = sm.OLS(y, sm.add_constant(X, prepend=False)).fit()
    pred  = model.predict()
    data[c] = y - pred

# Difference the data
for c in cols:
    print(c)
    results = adfuller(data[c])
    print(results[1])
    if results[1] > .05:
        data[c] = data[c].diff()
        results = adfuller(data[c].dropna())
        print("new ", results[1])
        if results[1] > .05:
            if c in ["unemployment_rate", "TB3MS", "gs1", "gs5", "corp_bond_premia", "sp_div_yield"]:
                pass
            else:
                data[c] = data[c].diff()
                results = adfuller(data[c].dropna())
                print("new ", results[1])

# for c in ["TB3MS", "unemployment_rate"]:
#     data[c] = data[c] / 100
    

data = data[cols]
data.to_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/stationary_series.xlsx")          



# the 8 lag short df
import pandas as pd 
import numpy as np  
import matplotlib.pyplot as plt
from statsmodels.tsa.stattools import adfuller
import statsmodels.api as sm

# Trying this new method https://econweb.ucsd.edu/~jhamilto/HX.pdf
# df.plot(subplots=True, layout=(4,5))
data      = pd.read_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.xlsx")
data      = data.dropna().reset_index(drop=True)

df = pd.DataFrame(np.random.randint(0,100, size=(len(data["time"]) - 11, 1)))

tricky_cols = [
    # "MMFSABSHNO",
    # "BOGZ1LM153091003Q",
    # "BOGZ1LM153061705Q",
    # "BOGZ1FL153069005Q",
    "unemployment_rate",
    "gs1",
    "gs5",
    "corp_bond_premia",
	"sp_div_yield",
    "TB3MS",
    "time"
    ]
cols = data.columns.difference(tricky_cols)

# Step 1: Taking the logs
for c in cols:
    if c == "BOGZ1FL153069005Q":
        data[c] = np.log(data[c] + 2000)
    else:
        data[c] = np.log(data[c] + 2) #np.sign(data[c]) * np.abs(data[c])**(1/4)

for c in tricky_cols:
    if c == "time":
        pass
    else:
        data[c] = data[c] / 100

data      = data.dropna().reset_index(drop=True)
cols = data.columns.difference(["time"])

for c in cols:
    y = pd.DataFrame(data[c])
    for i in range(1,5):
        y['{}_lag{}'.format(c, i+7)] = y[c].shift(i+7)
        
    list_of_lags = ["{}_lag{}".format(c,i+7) for i in range(1,5)]
    y = y.dropna().reset_index()
    X = y[list_of_lags]
    dv = y[c]
    
    # fit the model
    model = sm.OLS(dv, sm.add_constant(X, prepend=False)).fit()
    pred  = model.predict()
    df[c] = dv - pred
    
   for c in df.columns.difference(["time", 0]):
       print(c)
       print(adfuller(data[c].diff().dropna())[1])

df.to_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/cyclical_series.xlsx")          


## New approach:
import pandas as pd 
import numpy as np  
import matplotlib.pyplot as plt
from statsmodels.tsa.stattools import adfuller, kpss
import statsmodels.api as sm
from pmdarima.arima import auto_arima
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.graphics.tsaplots import plot_pacf
import time
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from scipy.stats import norm
import seaborn as sns
import os

def induce_stationarity(series, c, output_dir):
    # Step 2: Use the ADF and KPSS tests to estimate the order of differencing required
    # adf_result  = adfuller(series.diff().dropna())
    
    # Step 2: finding our 'd' parameter
    d_values = range(0, 3)
    best_aic, best_d, best_model = float("inf"), None, None
    for d in d_values:
        try:
            model = ARIMA(series, order=(0, d, 0))
            model_fit = model.fit()
            aic = model_fit.aic
            if aic < best_aic:
                best_aic, best_d, best_model = aic, d, model_fit
        except:
            continue
    
    d = best_d
    # while adf_result[1] > 0.05:
    #     d +=1
    #     adf_result  = adfuller(series.diff(d).dropna().reset_index(drop=True))
    
    # print(d)
    
    # if adf_result[1] >= 0.05:
    #     d += 1
    #     adf_result  = adfuller(series.diff(d).dropna())
    #     if adf_result[1] >= 0.05:
    #         d += 1
    #         adf_result  = adfuller(series.diff(d).dropna())
    #         if adf_result[1] >= 0.05:
    #             d += 1
    #             adf_result  = adfuller(series.diff(d).dropna())

    
    # Step 3A: finding our 'p' parameter
    p_values = range(0, 9)
    best_aic, best_p, best_model = float("inf"), None, None
    for p in p_values:
        try:
            model = ARIMA(series, order=(p, d, 2))
            model_fit = model.fit()
            aic = model_fit.aic
            if aic < best_aic:
                best_aic, best_p, best_model = aic, p, model_fit
        except:
            continue

        
    model       = auto_arima(series, start_p=0, start_d=0, start_q=0, max_p=best_p, max_d=d, max_q=4, start_P=0, start_Q=0, start_D=0, max_P=4, max_D=2, max_Q=4, stepwise=True, suppress_warnings=True, seasonal=True, m=4)
    best_p      = model.order[0]
    d           = model.order[1]
    q           = model.order[2]
    P           = model.seasonal_order[0]
    D           = model.seasonal_order[1]
    Q           = model.seasonal_order[1]
    print("The model is the following:")
    print(best_p, d, q)
    print(P, D, Q, 4)
        
    # Step 4: Fit an ARIMA model to the differenced GDP data to remove trend
    print("removing seasonality and trend")
    model = ARIMA(series, order=(best_p, d, q), seasonal_order=(P,D,Q,4))  
    results = model.fit()

    # Step 5: Generate the predicted values and remove trend from original GDP data
    predictions      = results.predict(start=d, end=len(series), typ='levels')
    series_detrended = series - predictions

    # Step 6: Residual Analysis
    residuals = results.resid
    
    # Plot histogram of residuals and compare to normal distribution
    fig, ax = plt.subplots(figsize=(8, 4))
    sns.histplot(residuals, kde=True, ax=ax, color='blue', stat='density')
    x = np.linspace(norm.ppf(0.01), norm.ppf(0.99), 100)
    ax.plot(x, norm.pdf(x), 'r-', lw=2, label='Normal PDF')
    ax.legend()
    ax.set_title('Histogram of Residuals')
    
    if output_dir is not None:
        file_path = os.path.join(output_dir, f'{c}_residuals_histogram.png')
        fig.savefig(file_path, bbox_inches='tight')


    # Plot ACF and PACF of residuals
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6))
    plot_acf(residuals, ax=ax1)
    plot_pacf(residuals, ax=ax2)
    ax1.set_title('ACF of Residuals')
    ax2.set_title('PACF of Residuals')
    
    if output_dir is not None:
        file_path = os.path.join(output_dir, f'{c}_residuals_acf_pacf.png')
        fig.savefig(file_path, bbox_inches='tight')
    
    adf_result  = adfuller(series_detrended.dropna())

    print(f"ADF Test p-value: {adf_result[1]}")
    
    return series_detrended
        

def auto_induce_stationarity(series):
    # Step 6: remove seasonality
    print("removing seasonality")
    model       = auto_arima(series, start_p=0, start_d=0, start_q=0, max_p=0, max_d=0, max_q=0, start_P=0, start_Q=0, start_D=0, max_P=4, max_D=2, max_Q=4, stepwise=True, suppress_warnings=True, seasonal=True, m=4)
    d           = model.order[1]
    predictions = model.predict_in_sample(start=d, end=len(series))
    series_detrended_seasonal = series- predictions
    
    # Step 7: Check for stationarity
    adf_result  = adfuller(series_detrended_seasonal.dropna())
    print(f"ADF Test p-value: {adf_result[1]}")
    
    i = 0
    while adf_result[1] > 0.05:
        i +=1
        adf_result  = adfuller(series_detrended_seasonal.diff(i).dropna())
    
    print(i)
    return series_detrended_seasonal.diff(i).dropna().reset_index(drop=True)
        
    # else:
    #     adf_result  = adfuller(series_detrended_seasonal.diff().dropna())
    #     if adf_result[1] < 0.5:
    #         return series_detrended_seasonal.diff().dropna()
    #     else:
    #         adf_result  = adfuller(series_detrended_seasonal.diff().dropna()
    #         if adf_result[1] < 0.5:
    #             return series_detrended_seasonal.diff().dropna()


data      = pd.read_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.xlsx")
data      = data.dropna().reset_index(drop=True)
# Retain cyclical variation 
tricky_cols = [
    # "MMFSABSHNO",
    # "BOGZ1LM153091003Q",
    # "BOGZ1LM153061705Q",
    # "BOGZ1FL153069005Q",
    "unemployment_rate",
    "gs1",
    "gs5",
    "corp_bond_premia",
	"sp_div_yield",
    "TB3MS",
    "time"
    ]
cols = data.columns.difference(tricky_cols)

# Step 1: Taking the logs
for c in cols:
    if c == "BOGZ1FL153069005Q":
        data[c] = np.log(data[c] + 2000)
    else:
        data[c] = np.log(data[c] + 2) #np.sign(data[c]) * np.abs(data[c])**(1/4)

for c in tricky_cols:
    if c == "time":
        pass
    else:
        data[c] = data[c] / 100

data      = data.dropna().reset_index(drop=True)
output_dir = r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/stationarity_checks"
for c in data.columns.difference(["time"]):
    print(c)
    data[c] = induce_stationarity(data[c], c, output_dir)
    # data[c] = auto_induce_stationarity(data[c])
    
data.to_excel(r"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/test_stationary_series.xlsx")          


    
    
   for c in data.columns.difference(["time"]):
       print(c)
       print(adfuller(data[c].dropna())[1])
       print(kpss(data[c].dropna())[1])
    

    
    