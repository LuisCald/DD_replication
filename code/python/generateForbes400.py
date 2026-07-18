import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

url = 'http://www.forbes.com/ajax/list/data?year={}&uri=forbes-400&type=person'

# Cache-first: the live forbes.com endpoint is fragile and makes the data
# stage non-reproducible offline. On the first successful scrape the raw
# 2021-2024 records are saved next to the Fernholz-Haslberger data; later
# runs read the cache. Delete the cache file to force a re-scrape.
CACHE = "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/Forbes 400 Data Set/Forbes 400 scrape 2021-2024.csv"
import os
if os.path.exists(CACHE):
	df = pd.read_csv(CACHE)
else:
	big_df = []
	for x in range(2021,2024+1):
		# get json as dataframe
		df = pd.read_json(u:= url.format(str(x)))
		# add year and source url to dataframe
		df['year'] = x
		df['source_url'] = u

		big_df.append(df)

	df = pd.concat(big_df)
	cols_to_keep = ["year", "lastName", "worth"]
	df = df[cols_to_keep]
	df.to_csv(CACHE, index=False)
df = df.rename(columns={"worth": "wealth"})
df["wealth"] = pd.to_numeric(df["wealth"])

# Multiply wealth by 1e6
df["wealth"] = df["wealth"] * 1e6 

# Indeed, 400 ppl for each year
df_counts = df.groupby("year").size().reset_index(name='count')
not_nan_rows = df[~df["wealth"].isna()]
not_nan_rows.groupby("year").size().reset_index(name='count')

df = df[~df["wealth"].isna()]

#############################################################################
# Read other Forbes source
df_all = pd.read_csv("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/Forbes 400 Data Set/Forbes 400 per Capita.csv")  # or pd.read_excel("your_file.xlsx")
df_all["Dynasty"]= df_all["Dynasty"].astype(str)

# Convert wide to long format
long_df = df_all.melt(id_vars="Dynasty", var_name="Year", value_name="Wealth")

# Convert year to integer (optional, if needed)
long_df["Year"] = long_df["Year"].astype(int)

# Rename columns for consistency
long_df = long_df.rename(columns={"Year": "year"})
long_df = long_df.rename(columns={"Wealth": "wealth"})
long_df = long_df.rename(columns={"Dynasty": "lastName"})

# Replace empty strings with NaN
long_df["wealth"] = long_df["wealth"].replace('', np.nan)
long_df["wealth"] = long_df["wealth"].replace(" ", np.nan)

# Convert to numeric (will turn non-numeric to NaN too)
long_df["wealth"] = pd.to_numeric(long_df["wealth"])
long_df["wealth"] = long_df["wealth"].astype("float64")

# Append 
final_df = pd.concat([df, long_df])
final_df["quarter"] = 3

# Generate date column for year and quarter
final_df["time"] = pd.PeriodIndex(year=final_df["year"], quarter=final_df["quarter"], freq="Q")

# Import inflation factor data 
infl_data = pd.read_csv("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/quarterly_inflation_ratio.csv", encoding="latin")

infl_data = infl_data[infl_data["quarter"] == 3]
infl_data = infl_data[infl_data["year"] > 1980]
cols_to_keep = ["year", "quarter", "inflation_ratio"]
infl_data = infl_data[cols_to_keep]

merged_df = pd.merge(final_df, infl_data, on=["year", "quarter"], how="left")  # or 'left', 'right', 'outer'
merged_df = merged_df[merged_df["wealth"].notna()]

merged_df["wealth"] = merged_df["wealth"] * merged_df["inflation_ratio"]

cols_to_keep = ["year", "quarter", "lastName", "wealth"]
merged_df = merged_df[cols_to_keep]

# Describe by year the mean of realTimeWorth
yearly_stats = merged_df.groupby('year').agg({
    'wealth': ['count','mean','std','min','max'],
})

yearly_stats[('wealth', 'mean')].plot(marker='o')
plt.title("Mean Wealth by Year")
plt.xlabel("Year")
plt.ylabel("Wealth (2019 dollars)")
plt.grid(True)
plt.tight_layout()
plt.show()

# Import SCF no forbes
# scf = pd.read_csv("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF_noForbes.csv", encoding="latin")
scf = pd.read_csv("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF_noForbes_new.csv", encoding="latin")
scf["source"] = "SCF"

# scf["weight"] = scf["weight"] * 5000

# Find years where they intersect
scf_years = scf["year"].unique()
int_years = list(set(scf_years) & set(merged_df["year"]))

# Subset to these years and take out years we dont care about (until later)
scf_notmerged = scf[~scf["year"].isin(int_years)]
scf = scf[scf["year"].isin(int_years)]

# Add 5 imputations of each top 400
merged_df = merged_df[merged_df['year'].isin(int_years)]

n_imp = 5
merged_df = merged_df.loc[np.repeat(merged_df.index, n_imp)].reset_index(drop=True)
merged_df["impnum"] = np.tile(np.arange(1, 6), len(merged_df) // 5)
merged_df["source"] = "Forbes"

# Create id where the impnum is last and year is first
merged_df["id"] = merged_df["year"].astype(str) + (merged_df.index + 100000).astype(str) + (merged_df["impnum"]).astype(str)

# Generate weight column
merged_df["weight"] = scf['weight'].min()
merged_df = merged_df.drop(columns=["lastName"])

# append scf to this
# 3) Concatenate the two datasets
df = pd.concat([scf, merged_df], ignore_index=True)

# ------------------------------------------------------------
# 1) Year-specific Forbes minimum Fmin_y  (ignore non-positive)
# ------------------------------------------------------------
scfmax_by_year = (
    df.loc[(df.source == "SCF") & (df.wealth > 0)]
      .groupby(["year", "impnum"])["wealth"]
      .max()
)

fmin_by_year = (
    df.loc[(df.source == "Forbes") & (df.wealth > 0)]
      .groupby(["year", "impnum"])["wealth"]
      .min()
      .rename("Fmin")
)
df = df.merge(fmin_by_year, on=["year", "impnum"], how="left")  # broadcast Fmin_y to all rows

# ------------------------------------------------------------
# 2) Year-specific bin edges (vectorised via np.select)
#    Bin definitions:
#       [Fmin, 1.5*Fmin) -> 1
#       [1.5*Fmin, 2.5*Fmin) -> 2
#       [2.5*Fmin, 5.0*Fmin) -> 3
#       [5.0*Fmin, inf)      -> 4
#    wealth < Fmin or missing Fmin -> NaN
# ------------------------------------------------------------
w  = df["wealth"]
f  = df["Fmin"]

conditions = [
    (w >= f)            & (w < 1.5 * f),
    (w >= 1.5 * f)      & (w < 2.5 * f),
    (w >= 2.5 * f)      & (w < 5.0 * f),
    (w >= 5.0 * f)
]
choices = [1, 2, 3, 4]

df["bin"] = np.select(conditions, choices, default=np.nan)

# ------------------------------------------------------------
# 3) Aggregate by year, source, bin
# ------------------------------------------------------------
agg = (
    df.dropna(subset=["bin"])
      .groupby(["year", "source", "bin", "impnum"], observed=True)
      .agg(
          n_obs = ("wealth", "size"),
          N_wgt = ("weight", "sum")
      )
      .reset_index()
)


# ------------------------------------------------------------
# 5) Relative frequency RF_{b,d,y}
#     Guard against divide-by-zero (set RF=NaN if any denom 0)
# ------------------------------------------------------------
agg["ratio"] = agg["n_obs"] / agg["N_wgt"]
agg["denom"] = agg.groupby(["year", "bin", "impnum"])["ratio"].transform("sum")
agg["RF"] = np.where(
    (agg["N_wgt"] > 0) & (agg["denom"] > 0),
    agg["ratio"] / agg["denom"],
    np.nan
)

# ------------------------------------------------------------
# 6) Merge back to full data
# ------------------------------------------------------------
df = df.merge(
    agg[["year", "source", "bin", "impnum", "RF"]],
    on=["year", "source", "bin", "impnum"],
    how="left"
)

# 10) Construct the final adjusted weight
# fill RF NaNs with 1 so outside-bin obs (below the Forbes minimum) keep their weight unchanged
df["RF"] = df["RF"].fillna(1)

# replace all +inf and -inf in the entire DataFrame with NaN
df.replace([np.inf, -np.inf], np.nan, inplace=True)


# then recompute weight_adj
df["weight_adj"] = df["RF"] * df["weight"]

scf_notmerged["weight_adj"] = scf_notmerged["weight"]
fin_df = pd.concat([df, scf_notmerged])
fin_df = fin_df.drop(columns="weight")
fin_df  = fin_df.rename(columns={"weight_adj": "weight"})

fin_df = fin_df.drop(columns=["bin", "RF", "Fmin", "source"])
# fin_df.to_csv("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF.csv", index=False)
fin_df.to_csv("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF_new.csv", index=False)


# # Plotting the top 1% wealth
# for_plotting = df[df["impnum"] ==1]

# # assume df has columns "year", "wealth", "weight_adj"
# results = []

# for year, g in for_plotting.groupby("year"):
#     sub = g.dropna(subset=["weight_adj"]).copy()

#     # sort ascending so tail is cum >= 0.99
#     sub = sub.sort_values("wealth")

#     w = sub["weight_adj"].to_numpy(dtype=float)
#     W = w.sum()
#     if W <= 0:
#         results.append({"year": year, "top1_share": np.nan})
#         continue

#     wealth = sub["wealth"].to_numpy(dtype=float)

#     # cumulative population share
#     cum_pop = np.cumsum(w) / W
#     print(cum_pop)

#     # mask: richest 1% of population
#     mask = cum_pop > 0.99

#     # total weighted wealth
#     total_wealth = np.dot(wealth, w)

#     # top1 weighted wealth
#     top1_wealth = np.dot(wealth[mask], w[mask])

#     share_top1 = top1_wealth / total_wealth if total_wealth != 0 else np.nan
#     results.append({"year": year, "top1_share": share_top1})

# top1_share_df = pd.DataFrame(results).sort_values("year")
# print(top1_share_df)

# top1_share_df["top1_share"].plot(marker='o')
# plt.title("Mean Wealth by Year")
# plt.xlabel("Year")
# plt.ylabel("Wealth (2019 dollars)")
# plt.grid(True)
# plt.tight_layout()
# plt.show()