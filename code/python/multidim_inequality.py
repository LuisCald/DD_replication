""" Generating multidimensional lorenz and gini-coefficients"""
import MEILC_MEGC as megcmeilc
import pandas as pd

# Import data 
data = pd.read_csv(r"/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_mcmc/data/SCF_micro_data_A non-diag_.csv")
# data = data.dropna(subset=["cop_share"])
# data = data[data["cop_share"] >= 0]
# data = data[data["time"] >= "1999-Q2"]
# datamult = data[["income", "wealth"]]



# calculate MEGC
# mult_gini = megcmeilc.mult_gini(X_star)

# # plot MEILC (works only for 2 dimensional data)
# megcmeilc.mult_lorenz(datamult, w=data["cop_share"])

# # Gini of one slice 
# megcmeilc.gini(datamult["income"], w=data["cop_share"])


# Define combinations
combinations = [
    ('incomegrid', 'consumgrid', 'income', 'consum'),
    ('incomegrid', 'wealthgrid', 'income', 'wealth'),
    ('wealthgrid', 'consumgrid', 'wealth', 'consum')
]


# Loop through each combination
def generate_and_export_mv_gini(data, combinations):
    # Initialize a list to store the Gini results
    gini_results = []

    for combo in combinations:
        grid1, grid2, var1, var2 = combo
        
        if var1 == 'income' and var2 == 'consum':
            data = pd.read_csv(r"/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_mcmc/data/CEX_all_micro_data_A non-diag_.csv")
        elif var1 == 'wealth' and var2 == 'consum':
            data = pd.read_csv(r"/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_mcmc/data/PSID_micro_data_A non-diag_.csv")
        else:
            data = pd.read_csv(r"/Users/lc/Dropbox/Distributional_Dynamics/7_Results/consum_and_income_and_wealth/from_mcmc/data/SCF_micro_data_A non-diag_.csv")
        
        data = data.dropna(subset=["cop_share"])
        data = data[data["cop_share"] >= 0]
        
        # Perform grouping and aggregation
        summary = data.groupby([grid1, grid2, 'time']).agg(
            cop_share_sum=('cop_share', 'sum'),
            var1_first=(var1, 'first'),
            var2_first=(var2, 'first')
        ).reset_index()
        
        # Filter by time
        # summary_filtered = summary[summary["time"] >= "1999-Q2"]
        summary_filtered = summary.dropna(subset=["cop_share_sum"])
            
        # Calculate Gini for each time period within the combination
        for time_period in summary_filtered['time'].unique():
            period_data = summary_filtered[summary_filtered['time'] == time_period]

            # Assuming your megcmeilc.x_star and megcmeilc.mult_gini functions can handle the data format
            # You might need to adjust how you call x_star based on your actual data structure

            X_star = megcmeilc.weighted_x_star(period_data[["var1_first", "var2_first"]], period_data["cop_share_sum"])
            mv_gini = megcmeilc.mult_gini(X_star)
            # Store the Gini result with labels
            gini_results.append({
                'combination': f'{var1}-{var2}',
                'time_period': str(time_period),
                'mult_gini': mv_gini
            })
            
    # Convert the results to a DataFrame for easy export
    gini_results_df = pd.DataFrame(gini_results)
    
    # Export to CSV
    gini_results_df.to_csv('/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/multivariate_gini_results.csv', index=False)

generate_and_export_mv_gini(data, combinations)

