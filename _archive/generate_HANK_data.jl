# ------------------------------------------------------------------------------------------
# Example: simulate shocks + generate household micro data and save to CSV
# ------------------------------------------------------------------------------------------

using Random, DataFrames, CSV, StatsBase, Parameters, PeriodicalDates, Dates
using StatsBase: sample, Weights

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
T = 1900   # total length
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

# We need to split both micro_df and shocks_df into 10 chunks of 100 periods and denote each chunk with "_i"
n_chunks = 10
periods = unique(micro_df.t)

chunk_size = Int(length(periods) / n_chunks)

for i in 1:n_chunks
    # Defining the time periods
    start_period = periods[(i-1)*chunk_size+1]
    end_period = periods[i*chunk_size]

    # Defining the different chunks
    micro_chunk = filter(row -> row.t >= start_period && row.t <= end_period, micro_df)
    shocks_chunk = filter(row -> row.t >= start_period && row.t <= end_period, shocks_df)

    # Create year and quarter columns
    micro_chunk.time = QuarterlyDate.(micro_chunk.year, micro_chunk.quarter)

    # Create average per household variables
    avg_df = combine(groupby(micro_chunk, :time), names(micro_chunk, Not([:time, :id, :weight, :year, :quarter])) .=> mean .=> names(micro_chunk, Not([:time, :id, :weight, :year, :quarter])) .* "_per_hh")
    CSV.write(joinpath(data_path, "HANK_correction_series_$(i).csv"), avg_df)

    # Export the chunks to CSV
    CSV.write(joinpath(data_path, "HANK_full_economy_$(i).csv"), micro_chunk)
    CSV.write(joinpath(data_path, "HANK_shocks_economy_$(i).csv"), shocks_chunk)

end

# Now the idea is to create 4 different datasets with different subsamples of households and frequencys:
# 1) Quarterly data with only income and liquid assets for 1000 households
# 2) Annual data with only income, 60k households
# 3) Triennial data with only liquid and illiquid assets, 20k households
# 4) Biennial data with income and liquid for half the time and all variables for the remaining time, 5k households

for i in 1:n_chunks
    # Create the first dataset
