# """Aggregate monthly series to quarterly"""
# import pandas as pd
# import numpy as np
# import os

# os.chdir(r'C:\Dropbox\Master_Thesis\2_Analysis\intermediate_files')
# deficit_monthly_series = pd.read_excel(r"gov_deficit_monthly.xls")
# deficit_monthly_series["observation_date"] = pd.to_datetime(deficit_monthly_series["observation_date"])
# deficit_monthly_series.set_index('observation_date', inplace=True)

# deficit_q_series= deficit_monthly_series.resample('QS').sum()
# deficit_q_series.to_excel('gov_deficit_quarterly.xls')

"""Delete months to get only quarter end months"""
import pandas as pd
import numpy as np
import os

# federal_funds_rate_m = pd.read_excel(r'/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/FEDFUNDS.xls')
# federal_funds_rate_m["observation_date"] = federal_funds_rate_m["observation_date"].astype(str)

# # Based on the release dates of the FRED
# federal_funds_rate_m["months_end_ind"] = federal_funds_rate_m["observation_date"].str.contains('-01-01|-04-01|-07-01|-11-01', regex=True)
# final_df = federal_funds_rate_m[federal_funds_rate_m.months_end_ind]
# final_df = final_df[["observation_date", "FEDFUNDS"]]
# final_df.to_excel("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/fed_funds_quarterly.xls")

def convert_to_quarterly(file, var, export_name):
    df = pd.read_excel(file)
    df["observation_date"] = df["observation_date"].astype(str)

    # Based on the release dates of the FRED
    df["months_end_ind"] = df["observation_date"].str.contains('-01-01|-04-01|-07-01|-10-01', regex=True)
    final_df = df[df.months_end_ind]
    final_df = final_df[["observation_date", var]]
    final_df.to_excel("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/{}".format(export_name))

convert_to_quarterly(r'/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/FEDFUNDS.xls', "FEDFUNDS", "fed_funds_quarterly.xls")
convert_to_quarterly(r'/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/shiller_index.xlsx', "HP_ind", "HP_quarterly.xls")
convert_to_quarterly(r'/Users/lc/Dropbox/Distributional_Dynamics/1_Data/TB3MS.xls', "TB3MS", "stir_quarterly.xls")
convert_to_quarterly(r'/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/UNRATENSA.xls', "UNRATENSA", "unemp_q.xls")
