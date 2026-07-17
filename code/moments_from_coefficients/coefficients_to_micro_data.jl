# ─────────────────────────────────────────────────────────────
# coefficients_to_micro_data.jl — synthetic micro data from the
# published coefficient files.
# ─────────────────────────────────────────────────────────────
#
# WHAT THIS PRODUCES
# One weighted synthetic cross-section per quarter, in the same layout the
# model pipeline writes (see `construct_micro_dataset` in Correlations.jl and
# `create_micro_df`, called from CreateTimeSeries.jl): one row per cell of the
# 10×10×10 decile copula grid,
#
#   cop_share, grid_point, consum, income, wealth,
#   consumgrid, incomegrid, wealthgrid, time
#
#   cop_share  — probability mass of the cell (the household weight share;
#                model-implied, so isolated cells can be slightly negative)
#   grid_point — concatenated cell index, e.g. 372 = (consum decile 3,
#                income decile 7, wealth decile 2); deciles are 1 (bottom)
#                to 10 (top)
#   consum/income/wealth — the AVERAGE of the measure within its decile,
#                RELATIVE TO THE PER-HOUSEHOLD MEAN of that quarter
#   *grid      — the cell indices as separate columns
#
# HOW IT FOLLOWS THE MODEL CODE
# * Weights: `copula_pmf_grid` reproduces the published `ciw_*` probability
#   masses (the copula block of the coefficient files).
# * Values: CreateTimeSeries.jl (≈ line 2376) integrates the quantile function
#   over each decile with quadgk and divides by the interval length. Here the
#   same average is computed as the mean of `quantile_at` on 32 nodes per
#   decile (the quantile function is a degree-11 polynomial in the basis, so
#   this agrees to ~machine precision).
# * Row layout: identical to `construct_micro_dataset` (Correlations.jl),
#   including the concatenated `grid_point` index.
#
# UNITS — SCALING TO LEVELS
# Values are relative to the per-household mean (the same convention as
# `quantile_at`; e.g. 0.73 = 73% of mean consumption that quarter). The model
# pipeline multiplies by a per-household aggregate series, shipped as
# `data/synthetic/aggregate_anchors.csv` (time, consum_per_hh, income_per_hh,
# wealth_per_hh, tot_hhs — the same series the estimation uses). To get
# dollar levels, join on the quarter and compute
#
#   level_it = value_it × <measure>_per_hh_t
#
# To expand into unit-record data (N synthetic households), sample rows with
# probability `cop_share` (clip negatives to 0 and renormalize) and assign
# each household its row's values.
#
# USAGE
#   julia --project=../julia/env coefficients_to_micro_data.jl
#   # options: DATASET=PSID TREND=normal DATE=2008-Q3 (omit DATE for all quarters)
#   # output:  ../../data/synthetic/<DATASET>_synthetic_microdata.csv
#
# Only deps: CSV, DataFrames (wraps the canonical helper code/julia/reconstruct.jl).
# Python twin: coefficients_to_micro_data.py.
# ─────────────────────────────────────────────────────────────

const HERE = @__DIR__
const REPO = abspath(joinpath(HERE, "..", ".."))

include(joinpath(REPO, "code", "julia", "reconstruct.jl"))
using .DistributionalReconstruction
using CSV, DataFrames, Statistics

const MEASURES = [:consum, :income, :wealth]   # alphabetical — model convention
const GRID = 10
const NODES_PER_DECILE = 32

"Decile-average quantiles: mean of the quantile function within each decile."
function decile_averages(r, date, measure)
    avgs = zeros(GRID)
    for d in 1:GRID
        us = (d - 1) / GRID .+ (collect(1:NODES_PER_DECILE) .- 0.5) ./ (GRID * NODES_PER_DECILE)
        avgs[d] = mean(quantile_at(r, date, measure, us))
    end
    return avgs
end

"One quarter's synthetic cross-section (1000 rows) in the model's layout."
function micro_rows(r, date; digits = 6)
    pmf = copula_pmf_grid(r, date)                       # 10×10×10, matches ciw_*
    q = Dict(m => round.(decile_averages(r, date, m); digits) for m in MEASURES)
    df = DataFrame(cop_share = Float64[], grid_point = Int[],
                   consum = Float64[], income = Float64[], wealth = Float64[],
                   consumgrid = Int[], incomegrid = Int[], wealthgrid = Int[])
    for i in 1:GRID, j in 1:GRID, k in 1:GRID            # same order as construct_micro_dataset
        push!(df, (round(pmf[i, j, k]; digits),
                   parse(Int, string(i) * string(j) * string(k)),
                   q[:consum][i], q[:income][j], q[:wealth][k], i, j, k))
    end
    df[!, :time] .= date
    return df
end

function main()
    dataset = get(ENV, "DATASET", "PSID")
    trend   = get(ENV, "TREND", "normal")
    date    = get(ENV, "DATE", "")            # empty → all quarters

    csv = joinpath(REPO, "data", "synthetic", "$(dataset)_coefficients_$(trend).csv")
    isfile(csv) || error("Coefficient file not found: $csv")
    r = Reconstruction(csv)

    dates = isempty(date) ? available_dates(r) : [date]
    out = DataFrame()
    for (n, d) in enumerate(dates)
        append!(out, micro_rows(r, d))
        n % 50 == 0 && println("  $n / $(length(dates)) quarters")
    end

    dest = joinpath(REPO, "data", "synthetic", "$(dataset)_synthetic_microdata.csv")
    CSV.write(dest, out)
    println("Wrote $(nrow(out)) rows ($(length(dates)) quarters × $(GRID^3) cells) → $dest")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
