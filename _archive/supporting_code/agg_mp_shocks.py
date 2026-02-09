import pandas as pd 
import numpy as np 

# Aggregate monetary shocks 
MP_shocks = pd.read_csv("/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/unconventional_MP_shocks_sd.csv")
MP_shocks = MP_shocks.loc[:, MP_shocks.columns != "day"]
MP_shocks = MP_shocks.groupby(['year','month']).sum().reset_index()

# Assign month to quarter then groupby 
MP_shocks["quarter"] = ((MP_shocks["month"] -1)//3) + 1
MP_shocks = MP_shocks.loc[:, MP_shocks.columns != "month"]
MP_shocks = MP_shocks.groupby(['year','quarter']).sum().reset_index()

MP_shocks.to_csv("/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/unconventional_MP_quarterly.csv")

