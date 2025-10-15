# ------------------------------------------------------------------------------------------
# Example: simulate shocks + generate household micro data and save to CSV
# ------------------------------------------------------------------------------------------

using Random, DataFrames, CSV, StatsBase, Parameters, PeriodicalDates, Dates

# Reproducibility (optional)
Random.seed!(1234)

# 1) Choose which exogenous states get i.i.d. shocks each period.
#    Here I mirror your IRF order:
shock_syms = [:Z, :ZI, :μ, :μw, :A, :Rshock, :Gshock, :Tprogshock, :Sshock]

# Map those symbols to their state indices (these must be state positions in S_t)
exovars = [getfield(sr_full.indexes, s) for s in shock_syms]  # Vector{Int}

# 2) Build the vector of standard deviations for the shocks (same order as shock_syms)
#    This matches the naming convention in your m_par (σ_A, σ_Z, σ_Rshock, …).
stds = [getfield(m_par, Symbol("σ_", s)) for s in shock_syms]  # Vector{Float64}

# 3) Simulation settings
T = 1000   # total length
burnin = 900    # dropped from outputs
initval = stds   # innovation scale (you can override, e.g. 0.01 .* ones(length(exovars)))

# 4) Run the simulation using your linear solution and steady state
#    Required arguments:
#      - exovars: indices of exogenous state positions (Vector{Int})
#      - gx:      lr_full.State2Control
#      - hx:      lr_full.LOMstate
#      - XSS:     sr_full.XSS
#      - ids:     sr_full.indexes
#    Keywords:
#      - T, burnin, init_val, comp_ids, n_par
shocks_df, micro_df = generate_microdata(
    exovars,
    shock_syms,
    lr_full.State2Control,
    lr_full.LOMstate,
    sr_full.XSS,
    sr_full.indexes;
    T=T,
    burnin=burnin,
    init_val=initval,
    comp_ids=sr_full.compressionIndexes,
    n_par=sr_full.n_par,
)

# Plot averages for each variable over time (optional)
# using Plots
# micro_df.date = QuarterlyDate.(micro_df.year, micro_df.quarter)
# avg_df = combine(groupby(micro_df, :date), names(micro_df, Not([:date, :id, :weight, :year, :quarter])) .=> mean .=> names(micro_df, Not([:date, :id, :weight, :year, :quarter])))
# Plots.plot(avg_df.date, avg_df.liquid, label="C")
# Plots.plot(avg_df.date, avg_df.illiqd, label="Y")
# Plots.plot(avg_df.date, avg_df.income, label="K")

# Paths for outputs
data_path = "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing"
CSV.write(joinpath(data_path, "HANK_full.csv"), micro_df)
CSV.write(joinpath(data_path, "HANK_shocks.csv"), shocks_df)

# Import the HANK.csv
hank_df = CSV.read(joinpath(data_path, "HANK_full.csv"), DataFrame)
hank_df.time = QuarterlyDate.(hank_df.year, hank_df.quarter)
avg_df = combine(groupby(hank_df, :time), names(hank_df, Not([:time, :id, :weight, :year, :quarter])) .=> mean .=> names(hank_df, Not([:time, :id, :weight, :year, :quarter])) .* "_per_hh")
CSV.write(joinpath(data_path, "HANK_correction_series.csv"), avg_df)

# Integrate out income, aggregating weight
hank_df_agg = combine(groupby(hank_df, :time), :weight => sum => :weight, :income => sum => :income)

# Drop 75% of the time periods 
using StatsBase: sample, Weights
n_periods = length(unique(hank_df.time))
n_keep = Int(round(0.25 * n_periods))
keep_periods = sample(1:n_periods, Weights(fill(1.0, n_periods)), n_keep; replace=false)
actual_periods = sort(collect(unique(hank_df.time)))[keep_periods]
filter!(row -> row.time in actual_periods, hank_df)
sort!(hank_df, [:time, :id])


# For each quarter, either set to missing 1 measure (10%), 2 measure (10%) or none (80%).
for period in unique(hank_df.time)
    n_missing = rand() < 0.1 ? 1 : rand() < 0.2 ? 2 : 0
    missing_measures = sample([:income, :liquid, :illiqd], n_missing; replace=false)
    for col in missing_measures
        hank_df[!, col][hank_df.time.==period] .= NaN
    end
end

# Now, for 5 random periods, set 1 measure entirely to NaN
# Random.seed!(42)  # For reproducibility
# random_periods = sample(collect(unique(hank_df.time)), 5; replace=false)
# measures = [:income, :liquid, :illiqd, :income, :liquid]
# for (period, measure) in zip(random_periods, measures)
#     filter!(row -> !(row.time == period && !isnan(row[measure])), hank_df)
# end

# Count how many observations have all 3 measures observed based on NaNs
complete_cases = ((!isnan).(hank_df.income)) .& ((!isnan).(hank_df.liquid)) .& ((!isnan).(hank_df.illiqd))
sum(complete_cases)
CSV.write(joinpath(data_path, "HANK.csv"), hank_df)

# Return observation count per quarter, per measure
obs_count_df = combine(groupby(hank_df, :time),
    :income => x -> sum((!isnan).(x)) => :income_obs,
    :liquid => x -> sum((!isnan).(x)) => :liquid_obs,
    :illiqd => x -> sum((!isnan).(x)) => :illiqd_obs,
)
CSV.write(joinpath(data_path, "HANK_obs_count.csv"), obs_count_df)