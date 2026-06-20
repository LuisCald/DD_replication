# ─────────────────────────────────────────────────────────────────────────────
# GrowthCorrection.jl — growth step of the survey pipeline.
#
# Purpose: temporally ALIGN measures collected at different dates within a survey.
# SCF collects wealth (and balance-sheet stocks) at the survey date (Q3) but income
# for the prior year; income is grown forward quarter-by-quarter to sit at the
# wealth date. Stock variables (wealth, stocks, ...) are NOT growth-adjusted.
#
# Pipeline position (SCF):
#   data_cleaning.do -> SCF_noForbes_nogrowth.xlsx
#     -> [this file] -> SCF_noForbes.csv
#       -> generateForbes400.py -> SCF.csv  (read by Julia model)
#
# PROVENANCE: recovered from git (_archive/GrowthCorrection.jl, parent of commit
# 4c06537 "Remove _archive/ ahead of public release"). If a newer local copy
# exists, reconcile. CAVEATS to verify on first run: (1) the env below
# (`env_dd_v19/`) predates the repo reorg to `code/julia/env`; (2) this script is
# standalone (not included by DistributionalDynamics.jl) and is not yet wired into
# master.sh between 00_master_data.do and generateForbes400.py.
# ─────────────────────────────────────────────────────────────────────────────
cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")

using Pkg
Pkg.activate(joinpath(@__DIR__, "env"))  # project env (env_dd_v19/ is empty/stale)
using DataFrames
using CSV
using Dates 
using PeriodicalDates
using StatsBase
using LinearAlgebra
using XLSX

PSID =  DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/PSID_nogrowth.xlsx", "data", header=true,))

for c in [:income, :consum, :wealth, :assets, :finast, :illiqd, :liquid, :tdebt, :pdebt, :hdebt, :hhequiv, :weight, :stocks, :real_estate, :business]
    replace!(PSID[!, c], missing => NaN)
    PSID[!, c] = convert.(Float64, PSID[!, c])
end

PSID = dropmissing(PSID, :quarter)

for c in [:id, :year, :quarter, :income_year]
    PSID[!, c] = convert.(Int64, PSID[!, c])
end

# Analyzing
PSID[!, :income_quarter] .= 4 

# Get counts for WEALTH 
grouped_counts = combine(groupby(PSID, [:year, :quarter]), nrow => :count)

# Merge the counts 
sort!(PSID, [:year, :quarter, :id])
PSID = leftjoin(PSID, grouped_counts, on=[:year, :quarter])

# if wealth count < 1500 replace the year_quarter with the previous quarter
less_than                   = sort(filter(x -> x.count < 1500, grouped_counts), [:year, :quarter])
less_than[!, :year_quarter] = QuarterlyDate.(less_than[!, :year], less_than[!, :quarter]) 
PSID[!, :year_quarter]      = QuarterlyDate.(PSID[!, :year], PSID[!, :quarter]) 

# So, this going to highlight observations that belong to a time period with perhaps maybe not many wealth observations 

for row in eachrow(PSID)
    if row.year_quarter ∈ unique(less_than.year_quarter)
        yr = year(row.year_quarter)
        row.year_quarter = QuarterlyDate(yr, 2)
    end
end

# Get counts for WEALTH again as a check 
grouped_counts = combine(groupby(PSID, [:year_quarter]), nrow => :count)

# Correct wealth quarter: Replace 'quarter' with year_quarter's quarter 
PSID[!, :quarter] = quarter.(PSID[!, :year_quarter])

# Import GDP and consum growth rates
gdp_con = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inflation_corrected_correction_series.xlsx",  "data", header=true,))

for c in [:income_per_hh, :consum_per_hh]
    gdp_con[!, c] = convert.(Float64, gdp_con[!, c])
end

# Create date columns 
gdp_con[!, :date] = QuarterlyDate.(gdp_con[!, "time"])

# Compute growth rates from columns :gdp and :tot_consumption
gdp_con[!, :gdp_growth]      .= NaN
gdp_con[!, :con_growth]      .= NaN

# These are shifted up one
gdp_con[2:end, :gdp_growth] = diff(log.(gdp_con[!, :income_per_hh])) 
gdp_con[2:end, :con_growth] = diff(log.(gdp_con[!, :consum_per_hh])) 

# Merge growth rates on inc_con
gdp_con   = gdp_con[:, [:date, :gdp_growth, :con_growth]]
gdp_con[!, :year] = year.(gdp_con[!, :date])
gdp_con[!, :quarter] = quarter.(gdp_con[!, :date])


function adjust_to_wealth_date!(df, growth_rates)
    df.year_quarter .= QuarterlyDate(1900, 2)  # Initialize a column to hold QuarterlyDate objects

    for row in eachrow(df)
        income = row[:income]
        wealth = row[:wealth]
        consum = row[:consum]
        income_year = row[:income_year]
        wealth_year = row[:year]
        wealth_quarter = row[:quarter]
        income_quarter = 4
        
        if !isnan(wealth) && wealth_year > income_year
            # Find difference between income dates and wealth dates 
            diff = QuarterlyDate(income_year, income_quarter) : Quarter(1) : QuarterlyDate(wealth_year, wealth_quarter)
            growth_rows = filter(r -> r.date ∈ diff, growth_rates)

            # Apply growth rates quarter-by-quarter
            if !isempty(growth_rows)
                for r in eachrow(growth_rows)
                    gdp_rate = r[:gdp_growth]
                    consum_rate = r[:con_growth]
                    income *= 1 + gdp_rate
                    consum *= 1 + consum_rate
                end
            end
            row[:income] = income
            row[:consum] = consum
            row[:year_quarter] = QuarterlyDate(row[:year], row[:quarter])
        else
            row[:year_quarter] = QuarterlyDate(row[:income_year], income_quarter)
        end
    end
end


# If income and wealth are observed, it's then scaled and the :year_quarter should reflect that ...
adjust_to_wealth_date!(PSID, gdp_con)
grouped_counts = combine(groupby(PSID, [:year_quarter]), nrow => :count)

# Find how many observations there are for wealth 
select!(PSID, Not([:income_year, :year, :quarter, :count]))

# Create a date column, but first drop income_year, year, quarter 
PSID[!, :year] = year.(PSID[!, :year_quarter])
PSID[!, :quarter] = quarter.(PSID[!, :year_quarter])

# Remove rows pertaining to dates with less than 500 observations
grouped_counts = combine(groupby(PSID, [:year_quarter]), nrow => :count)

# Merge grouped_counts with PSID based on year_quarter
PSID = leftjoin(PSID, grouped_counts, on=:year_quarter)

sort!(grouped_counts, [:year_quarter])

# Remove rows where count < 2000
filter!(row -> row.count >= 1000, PSID)

# Save file to XLSX 
select!(PSID, Not([:count, :year_quarter, :income_quarter]))
CSV.write(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/PSID.csv", PSID)



# # Extract income and consum out of PSID
# inc_con = PSID[:, [:income_year, :income, :consum, :weight, :id, :hhequiv]]
# wealth  = PSID[:, [:id, :year, :quarter, :weight, :wealth, :assets, :finast, :illiqd, :liquid, :tdebt, :pdebt, :hdebt, :hhequiv]]

# # Generate quarter for wealth 
# inc_con.year    .= inc_con.income_year 
# inc_con.quarter .= 4


# dfs = [DataFrame()]
# b   = DataFrame()

# for q in 1:4
#     local a 
#     if q == 1
#         # Income dataset is for e.g, 2000Q4, but wealth will be all over 2001
#         a = copy(inc_con)
#     else
#         a = copy(dfs[1])
#     end

#     # Shift year by 1
#     if q == 1
#         # Push income year up 1 
#         a.year .= a.year .+ 1
#     end

#     # Shift to correct quarter
#     a.quarter .= q # from 4 to 1 in the first iteration 

#     # Create date col 
#     a[!, :date] = QuarterlyDate.(a[!, "year"], a[!, "quarter"]) 

#     # Merge on growth rates 
#     dfs[1] = leftjoin(a, gdp_con, on=:date)

#     # Multiply income with growth rate of GDP in that quarter 
#     dfs[1].income .= dfs[1].income .* (1 .+ dfs[1].gdp_growth)

#     # Multiply consum with growth rate of consum in that quarter
#     dfs[1].consum .= dfs[1].consum .* (1 .+ dfs[1].con_growth)

#     # Drop columns
#     select!(dfs[1], Not([:date, :gdp_growth, :con_growth]))

#     # Add to vector of dataframes
#     append!(b, dfs[1])
# end


# # Merge wealth onto inc_con
# final_df = outerjoin(b, select(wealth, Not([:hhequiv, :weight])), on=[:id, :year, :quarter])

# for c in [:income, :consum, :wealth, :assets, :finast, :illiqd, :liquid, :tdebt, :pdebt, :hdebt, :hhequiv, :weight]
#     replace!(final_df[!, c], missing => NaN)
# end

# # Remove income_year column 
# select!(final_df, Not(:income_year))

# # Replace 'income' with NaN for quarters != 4 if year is from 1968 - 1983 
# final_df[!, :income] .= ifelse.((final_df.year .< 1984) .& (final_df.quarter .!= 4), NaN, final_df.income)

# # Drop if income equals NaN
# filter!(row -> !isnan(row.income), final_df)


##########################################################################################################################################
SCF =  DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF_noForbes_nogrowth.xlsx", "data", header=true,))

for c in [:income, :wealth, :assets, :finast, :illiqd, :liquid, :tdebt, :pdebt, :hdebt, :hhequiv, :weight, :stocks, :real_estate, :business, :pension, :vehicles]
    # coalesce
    SCF[!, c] = coalesce.(SCF[!, c], NaN)
    SCF[!, c] = convert.(Float64, SCF[!, c])
end

for c in [:year]
    SCF[!, c] = convert.(Int64, SCF[!, c])
end

for c in [:id]
    SCF[!, c] = parse.(Int64, SCF[!, c])
end


# concatenate these columns with the income cols. 
main_cols = ["year", "income", "id", "weight", "hhequiv", "impnum"] 
# inc_cols  = vcat(main_cols, wgt_cols)

# Extract income and consum out of PSID
inc_con = SCF[:, main_cols]
wealth  = SCF[:, [:id, :year, :weight, :wealth, :assets, :finast, :illiqd, :liquid, :tdebt, :pdebt, :hdebt, :hhequiv, :stocks, :real_estate, :business, :pension, :vehicles]]

# Generate year, quarter for vars  
inc_con.quarter .= 4
wealth.quarter  .= 3
inc_con.year    .= inc_con.year .- 1 # income data is from the previous year 

# Import GDP and consum growth rates
gdp_con = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/inflation_corrected_correction_series.xlsx",  "data", header=true,))

for c in [:income_per_hh, :consum_per_hh]
    gdp_con[!, c] = convert.(Float64, gdp_con[!, c])
end

# Create date columns 
gdp_con[!, :date] = QuarterlyDate.(gdp_con[!, "time"])  # import_aggregates exports `time` (was stale `daten`)

# Compute growth rates from columns :gdp and :tot_consumption
gdp_con[!, :income_growth] .= NaN

# These are shifted up one
gdp_con[2:end, :income_growth] = diff(log.(gdp_con[!, :income_per_hh]))

# Merge growth rates on inc_con
gdp_con   = gdp_con[:, [:date, :income_growth]]

# For 1950Q1, it's a NaN, but for this work, it cannot be, so, I give it the same growth as the next quarter.
gdp_con[1, :income_growth] = gdp_con[2, :income_growth]


dfs = [DataFrame()]
for q in 1:3

    local a 
    if q == 1
        a = copy(inc_con)
    else
        a = copy(dfs[1])
    end

    # Shift year by 1
    if q == 1
        a.year .= a.year .+ 1
    end

    # Shift to correct quarter
    a.quarter .= q

    # Create date col 
    a[!, :date] = QuarterlyDate.(a[!, "year"], a[!, "quarter"]) 

    # Merge on growth rates 
    dfs[1] = leftjoin(a, gdp_con, on=:date)

    # Multiply income with growth rate of GDP in that quarter 
    dfs[1].income .= dfs[1].income .* (1 .+ dfs[1].income_growth)

    # Drop columns
    select!(dfs[1], Not([:date, :income_growth]))

    # # Add to vector of dataframes
    # push!(dfs, b)
end

# Concatenate dfs 
# inc_con = vcat(dfs[1], inc_con)

# Merge wealth onto inc_con
final_df = leftjoin(dfs[1], select!(wealth, Not([:hhequiv, :weight])), on=[:id, :year, :quarter])

for c in [:income, :wealth, :assets, :finast, :illiqd, :liquid, :tdebt, :pdebt, :hdebt, :hhequiv, :weight, :stocks, :real_estate, :business, :pension, :vehicles]
    replace!(final_df[!, c], missing => NaN)
end

# Save (no-Forbes, growth-applied). Forbes augmentation -> SCF.csv happens in generateForbes400.py.
CSV.write(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF_noForbes.csv", final_df)

# Read in the same file using CSV
b = CSV.read(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF_noForbes.csv", DataFrame)
a = filter(row -> row.year == 2022, b)
sort!(a, [:id, :year, :quarter])

# Replace impnum with the last integer of id 
a.impnum .= [parse(Int, "$i"[end]) for i in a.id]

filter!(row -> row.year != 2022, b)

# Append a to b
append!(b, a)

# Save file to csv (impnum fixed for 2022 before Forbes augmentation reads it)
CSV.write(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF_noForbes.csv", b)


# CEX =  DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX.xlsx", "data", header=true,))
# CSV.write(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/CEX.csv", CEX)
