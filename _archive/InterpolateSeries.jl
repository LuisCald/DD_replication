include("DistributionalDynamics.jl")

# Generate quarterly rental eq 
rental_eq = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/rental_eq.XLSX", "Sheet1", header=true,))

# Generate quarterly indicies
l_df     = length(rental_eq[!, :rental_eq])
indices  = collect(1:l_df*4) 
indices_int  = indices[1:end-3] # because, the first observation is Q4 1951, so, minus 3 
indices_ext  = indices[1:end-2] # but we want to extrapolate to 2024 Q1, so minus 2

interp_linear    =  linear_interpolation(indices_int[1:4:end], rental_eq[!, :rental_eq], extrapolation_bc=Line())
LI_df            =  interp_linear.(indices_ext)
LI_df            =  convert.(Float64, LI_df)

Plots.plot(axes(LI_df), LI_df)
Plots.plot!([1:4:length(indices)], rental_eq[!, :rental_eq])
Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/rent_data.pdf")

# Generate dataframe for LI_df
LI_df = DataFrame(reshape(LI_df, (length(LI_df), 1)), [:rental_eq])

# Generate quarterly date column 
LI_df[!, "date"] = QuarterlyDate(1951, 4):Quarter(1):QuarterlyDate(2024, 1)

# Divide data by 4
LI_df[!, "rental_eq"] = LI_df[!, "rental_eq"] ./ 4

# This is annual rental equivalance ... must divide by 4 for quarterly (in billions)
CSV.write("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/rental_data.csv", LI_df)

# Interpolate the total number of households, thousands
data    = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/total_HHs_annual.xlsx", "Sheet1", header=true,))

# Subset to greater than or equal to 1951
data = data[12:end, :TTLHH] # 1951 to 2023

# Generate quarterly indicies
l_df     = length(data)
indices  = collect(1:l_df*4)
indices_int  = indices[1:end-3] # because, the first observation is Q4 1951, so, minus 3
indices_ext  = indices[1:end-2] # but we want to extrapolate to 2024 Q1, so minus 2

interp_linear    =  linear_interpolation(indices_int[1:4:end], data, extrapolation_bc=Line())
LI_df            =  interp_linear.(indices_ext)
LI_df            =  convert.(Float64, LI_df)

Plots.plot(axes(LI_df), LI_df)
Plots.plot!([1:4:length(indices)], data)
Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/tot_hhs_data.pdf")

# Generate dataframe for LI_df
LI_df = DataFrame(reshape(LI_df, (length(LI_df), 1)), [:tot_hhs])

# Generate quarterly date column
LI_df[!, "date"] = QuarterlyDate(1951, 4):Quarter(1):QuarterlyDate(2024, 1)

CSV.write("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/tot_hhs_data.csv", LI_df)

# Interpolate inflation 
# generate quarterly indicies 
data    = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/aggregates_HHs_NPs.xlsx", "CPI adjustment", header=true,))
data[!, "date"]    = QuarterlyDate.(data[!, "time"])


inf_data = data[:, "CPI factor "]

# Time index by dataset
t                = collect(1:1:length(inf_data)*4)

# Interpolate this dataset for all rows 
interp_linear    =  linear_interpolation(t[1:4:end], inf_data, extrapolation_bc=Line())
LI_df            =  interp_linear.(t)
LI_df            =  convert.(Float64, LI_df)

Plots.plot(axes(LI_df), LI_df)
Plots.savefig("inf_data.png")

CSV.write("inf_data.csv", DataFrame(reshape(LI_df, (length(LI_df), 1)), [:inf]))


# Importing DFAs, subtracting pensions and correcting for inflation 
# wealth_shares    = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/DFA/DFA.xlsx", "wealth_shares", header=true,))
wealth_levels    = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/DFA/DFA.xlsx", "wealth_levels", header=true,))
wealth_pensions  = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/DFA/DFA.xlsx", "pensions", header=true,))

# Subset data 

# Subtract the pensions from the levels for each group
wealth_levels[!, "bottom50"] = wealth_levels[:, "bottom50"] - wealth_pensions[:, "pensions_bottom50_levels"]
wealth_levels[!, "next40"]   = wealth_levels[:, "next40"]   - wealth_pensions[:, "pensions_next40_levels"]
wealth_levels[!, "top10"]    = wealth_levels[:, "top10"]    - wealth_pensions[:, "pensions_top10_levels"]

# read CSV file of inflation data
inf_data = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inf_data.csv", DataFrame, header=true)

# inflation data to keep 
inf_data = inf_data[!, :inf][155:end-8]

wealth_levels[!, "bottom50"] = wealth_levels[:, "bottom50"] .* inf_data
wealth_levels[!, "next40"]   = wealth_levels[:, "next40"]   .* inf_data
wealth_levels[!, "top10"]    = wealth_levels[:, "top10"]    .* inf_data

# Generate column which is the sum of all columns 
transform!(wealth_levels, [:bottom50, :next40, :top10] => (+) => :tot_wealth)

# Generate column which is the share of each wealth level
for c in ["bottom50", "next40", "top10"]
    wealth_levels[!, "share" * c] = (wealth_levels[:, c] ./ wealth_levels[:, "tot_wealth"]) .*100
end

# Export the shares 
CSV.write("wealth_dfa.csv", wealth_levels)


# Creating the quantiles
wealth_levels    = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/DFA/DFA.xlsx", "wealth_levels", header=true,))
wealth_tot_hhs   = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/tot_hhs_by_group.xlsx", "data", header=true,))

# Generate column which is the sum of all columns 
transform!(wealth_levels, [:bottom50, :next40, :top10] => (+) => :tot_wealth)

# Generate column which is the share of each wealth level
for c in ["bottom50", "next40", "top10"]
    wealth_levels[!, "quantile_" * c] = (wealth_levels[:, c] .* 1000000 ./ wealth_tot_hhs[:, "tot_hhs_" * c]) 
end

# Export the shares 
CSV.write("wealth_dfa_quantiles.csv", wealth_levels)







### Importing the DFA data for the copulas
wealth_by_income  = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/validation/DFA/DFA.xlsx", "wealth_by_income_levels", header=true,))
series            = ["bottom40", "next40", "top20"]

# read CSV file of inflation data and housing 
inf_data         = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inf_data.csv", DataFrame, header=true)

# inflation data to keep 
inf_data = inf_data[!, :inf][155:end-8]

for c in series 
    wealth_by_income[!, "wealthlevels_" * c] = wealth_by_income[:, "wealthlevels_" * c] .* inf_data
end

transform!(wealth_by_income, [:wealthlevels_bottom40, :wealthlevels_next40, :wealthlevels_top20] => (+) => :tot_wealth)

# Generate the shares, quantiles for each of these categories 
for c in ["bottom40", "next40", "top20"]
    wealth_by_income[!, "share" * c]     = (wealth_by_income[:,  "wealthlevels_" * c] ./ wealth_by_income[:, "tot_wealth"]) .* 100
    wealth_by_income[!, "quantile_" * c] = (wealth_by_income[:,  "wealthlevels_" * c] .* 1000000 ./ wealth_by_income[:, "tot_hhs_" * c]) 
end

CSV.write("wealth_dfa_by_income.csv", wealth_by_income)

# Import non-durable consumption trends and correcting it for inflation 
gdp_con = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inflation_corrected_correction_series.xlsx",  "data", header=true,))
gdp_con[!, "date"] = QuarterlyDate.(gdp_con[!, "time"])
inf_data = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inf_data.csv", DataFrame, header=true)

# Repeat the first observation 4 times and concatenate it to the beginning of the series
inf_data = vcat([inf_data[1, :inf] for _ in 1:4], inf_data[!, :inf])

# Divide tot_nondurable by the inflation data
gdp_con[!, :tot_nondurable] = gdp_con[:, :tot_nondurable] .* inf_data

# Save gdp_con to the same file as before
CSV.write("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inflation_corrected_correction_series.csv", gdp_con)