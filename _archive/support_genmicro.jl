
# # Plot from the truth_df
# using Plots
truth_df.t = QuarterlyDate.(truth_df.year, truth_df.quarter)
# Plots.plot(
#     truth_df.t,
#     log.(truth_df.inc_bin10) .- mean(log.(truth_df.inc_bin10));
#     label = "Truth inc 1",
# )
# Plots.plot!(
#     truth_df.t,
#     log.(truth_df.cons_bin10) .- mean(log.(truth_df.cons_bin10));
#     label = "Truth cons",
# )
# Plots.plot!(
#     truth_df.t,
#     log.(truth_df.wealth_bin10) .- mean(log.(truth_df.wealth_bin10));
#     label = "Truth wealth",
# )

# Plots from the micro_df
micro_df.t = QuarterlyDate.(micro_df.year, micro_df.quarter)
# Compute decile 10 average
decile10 = combine(
    groupby(micro_df, :t),
    :income => x -> mean(x[x .>= quantile(x, 0.9)]) => :inc_bin10,
    :consumption => x -> mean(x[x .>= quantile(x, 0.9)]) => :cons_bin10,
    :wealth_value => x -> mean(x[x .>= quantile(x, 0.9)]) => :wealth_bin10,
)

# Ensure columns are not a vector of pairs
micro_inc = [decile10.income_function[i][1] for i = 1:nrow(decile10)]

# Compare plots
Plots.plot(decile10.t, log.(micro_inc) .- mean(log.(micro_inc)); label = "Micro inc 1")
Plots.plot!(
    truth_df.t,
    log.(truth_df.inc_bin10) .- mean(log.(truth_df.inc_bin10));
    label = "Truth inc 1",
)
cor(
    log.(micro_inc) .- mean(log.(micro_inc)),
    log.(truth_df.inc_bin10) .- mean(log.(truth_df.inc_bin10)),
)

# plot average consumption and income over time
micro_df[!, :t] = QuarterlyDate.(micro_df.year, micro_df.quarter)

avg_consumption = combine(groupby(micro_df, :t), :consumption => mean => :avg_consumption)
avg_income = combine(groupby(micro_df, :t), :income => mean => :avg_income)
avg_wealth = combine(groupby(micro_df, :t), :wealth_value => mean => :avg_wealth)
avg_liquid = combine(groupby(micro_df, :t), :liquid => mean => :avg_liquid)

Plots.plot(
    avg_consumption.t,
    log.(avg_consumption.avg_consumption);
    label = "Avg Consumption",
)

Plots.plot!(avg_income.t, log.(avg_income.avg_income); label = "Avg Income")
Plots.plot!(avg_wealth.t, log.(avg_wealth.avg_wealth); label = "Avg Wealth")
Plots.plot!(avg_liquid.t, log.(avg_liquid.avg_liquid); label = "Avg Liquid Assets")

cor(avg_consumption.avg_consumption, avg_income.avg_income)
cor(avg_wealth.avg_wealth, avg_income.avg_income)
cor(avg_liquid.avg_liquid, avg_income.avg_income)

### SOME ANALYSIS TO COMPARE WITH/WITHOUT SHOCKS
# # plot average consumption and income over time
# micro_df2[!, :t] = QuarterlyDate.(micro_df2.year, micro_df2.quarter)

# avg_consumption2 = combine(groupby(micro_df2, :t), :consumption => mean => :avg_consumption)
# avg_income2 = combine(groupby(micro_df2, :t), :income => mean => :avg_income)
# avg_wealth2 = combine(groupby(micro_df2, :t), :wealth_value => mean => :avg_wealth)
# avg_liquid2 = combine(groupby(micro_df2, :t), :liquid => mean => :avg_liquid)

# # Remove non-linear trend without HP package
# using FFTW
# using LinearAlgebra
# function hp_filter(series::Vector{Float64}; λ::Float64 = 1600.0)
#     n = length(series)
#     D = zeros(n - 2, n)
#     for i in 1:(n - 2)
#         D[i, i] = 1.0
#         D[i, i + 1] = -2.0
#         D[i, i + 2] = 1.0
#     end
#     trend = (I + λ * (D' * D)) \ series
#     return trend
# end
# avg_consumption_hp = hp_filter(log.(avg_consumption.avg_consumption); λ = 1600.0)
# avg_consumption_hp2 = hp_filter(log.(avg_consumption2.avg_consumption); λ = 1600.0)

# # with shocks
# Plots.plot(
#     avg_consumption.t,
#     log.(avg_consumption.avg_consumption) .- avg_consumption_hp;
#     label = "Avg Consumption 1",
# )

# Plots.plot!(
#     avg_consumption2.t,
#     log.(avg_consumption2.avg_consumption) .- avg_consumption_hp2;
#     label = "Avg Consumption 2 (HP Filtered)",
# )
# cor(
#     log.(avg_consumption.avg_consumption) .- avg_consumption_hp,
#     log.(avg_consumption2.avg_consumption) .- avg_consumption_hp2,
# )

############################
# Generation
############################

# We need to split both micro_df and shocks_df into 10 chunks of 100 periods and denote each chunk with "_i"
# Create year and quarter columns
micro_df.time = QuarterlyDate.(micro_df.year, micro_df.quarter)
shocks_df.time = QuarterlyDate.(shocks_df.year, shocks_df.quarter)
n_chunks = 10
periods = unique(micro_df.time)
chunk_size = Int(length(periods) / n_chunks)
data_path = "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/"

for i = 1:n_chunks
    # Defining the time periods
    start_period = periods[(i - 1) * chunk_size + 1]
    end_period = periods[i * chunk_size]

    # Defining the different chunks
    micro_chunk =
        filter(row -> row.time >= start_period && row.time <= end_period, micro_df)
    shocks_chunk =
        filter(row -> row.time >= start_period && row.time <= end_period, shocks_df)

    # Create average per household variables
    avg_df = combine(
        groupby(micro_chunk, :time),
        names(micro_chunk, Not([:time, :id, :weight, :year, :quarter])) .=>
            mean .=>
                names(micro_chunk, Not([:time, :id, :weight, :year, :quarter])) .*
                "_per_hh",
    )

    CSV.write(joinpath(data_path, "HANK_correction_series_$(i).csv"), avg_df)

    # Export the chunks to CSV
    # CSV.write(joinpath(data_path, "HANK_full_economy_$(i).csv"), micro_chunk)
    CSV.write(joinpath(data_path, "HANK_shocks_economy_$(i).csv"), shocks_chunk)

    # Now the idea is to create 4 different datasets with different subsamples of households and frequencies.
    # Here we treat them as *independent surveys*: at each survey observation date, we draw a fresh sample
    # of households from that date's cross-section.

    # Helper: sample N ids from a cross-section; use replacement if N > available
    sample_ids(ids, N) = sample(ids, N; replace = (N > length(ids)))

    # Chunk-specific periods (ensure survey frequencies are anchored to this chunk)
    chunk_periods = sort(unique(micro_chunk.time))
    chunk_start = chunk_periods[1]

    # 1) CEX: quarterly, 1k households; (currently exporting consumption/income)
    cex_rows = DataFrame(;)
    for t in chunk_periods
        xs = micro_chunk[micro_chunk.time .== t, :]
        ids_t = unique(xs.id)
        draw = sample_ids(ids_t, 1_000)
        tmp = xs[in.(xs.id, Ref(draw)), :]
        append!(cex_rows, tmp)
    end
    select!(cex_rows, [:time, :id, :weight, :year, :quarter, :consumption, :income])
    CSV.write(joinpath(data_path, "HANK_CEX_$(i).csv"), cex_rows)

    # 2) CPS: annual (every 4th quarter), 25k households, income only
    cps_rows = DataFrame(;)
    for t in chunk_periods
        diffq = (t - chunk_start).value
        if diffq % 4 != 0
            continue
        end
        xs = micro_chunk[micro_chunk.time .== t, :]
        ids_t = unique(xs.id)
        draw = sample_ids(ids_t, 25_000)
        tmp = xs[in.(xs.id, Ref(draw)), :]
        append!(cps_rows, tmp)
    end
    select!(cps_rows, [:time, :id, :weight, :year, :quarter, :income])
    CSV.write(joinpath(data_path, "HANK_CPS_$(i).csv"), cps_rows)

    # 3) SCF: triennial (every 12th quarter), 12k households, income and wealth only
    scf_rows = DataFrame(;)
    for t in chunk_periods
        diffq = (t - chunk_start).value
        if diffq % 12 != 0
            continue
        end
        xs = micro_chunk[micro_chunk.time .== t, :]
        ids_t = unique(xs.id)
        draw = sample_ids(ids_t, 12_000)
        tmp = xs[in.(xs.id, Ref(draw)), :]
        append!(scf_rows, tmp)
    end
    select!(scf_rows, [:time, :id, :weight, :year, :quarter, :income, :wealth])
    CSV.write(joinpath(data_path, "HANK_SCF_$(i).csv"), scf_rows)

    # 4) PSID: biennial (every 8th quarter), 5k households, consumption/income/wealth
    psid_rows = DataFrame(;)
    for t in chunk_periods
        diffq = (t - chunk_start).value
        if diffq % 8 != 0
            continue
        end
        xs = micro_chunk[micro_chunk.time .== t, :]
        ids_t = unique(xs.id)
        draw = sample_ids(ids_t, 5_000)
        tmp = xs[in.(xs.id, Ref(draw)), :]
        append!(psid_rows, tmp)
    end
    select!(
        psid_rows,
        [:time, :id, :weight, :year, :quarter, :consumption, :income, :wealth],
    )
    CSV.write(joinpath(data_path, "HANK_PSID_$(i).csv"), psid_rows)
end
