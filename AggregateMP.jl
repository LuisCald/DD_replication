cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")

# Load data from csv 
data = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/unconventional_MP_shocks_bp.csv", DataFrame)

# create a column called "quarter" that is the quarter of the observation based on the month column 
data[!, :date]  = Date.(data[!, :year], data[!, :month], 1)
data[!, :quarter] = quarterofyear.(data[!, :date])

# Collapse columns u1, u2, u3, u4 by year and quarter, taking the sum 
data = combine(groupby(data, [:year, :quarter]), :u1 => sum, :u2 => sum, :u3 => sum, :u4 => sum)

# create a year quarter column 
data[!, :time] = QuarterlyDate.(data[!, :year], data[!, :quarter])

# Export this data to CSV
CSV.write("/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/unconventional_MP_shocks_bp_quarterly.csv", data)


# Load data from csv
data = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/Aruoba_Drechsel/Aruoba_Drechsel_Data.csv", DataFrame)
data[!, :date]  = Date.(data[!, :date], dateformat"m/d/y")
data[!, :quarter] = quarterofyear.(data[!, :date])
data[!, :year] = year.(data[!, :date])
for i in eachindex(data[!, :year])
    if data[i, :year] < 10
        data[i, :year] = data[i, :year] + 2000
    else
        data[i, :year] = data[i, :year] + 1900
    end
end


# Collapse data to year quarter 
data = combine(groupby(data, [:year, :quarter]), :Shock => sum)
data[!, :time] = QuarterlyDate.(data[!, :year], data[!, :quarter])
select!(data, Not([:year, :quarter]))
rename!(data, :Shock_sum => :Aruoba_MP)

# Export this data to CSV
CSV.write("/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks/Aruoba_Drechsel/Aruoba_Drechsel_Data_quarterly.csv", data)
