# ─────────────────────────────────────────────────────────────
# coefficients_to_moments.jl — turn the published coefficient files into moments.
#
# Point estimate only (no posterior uncertainty). For posterior bands see
# `posterior_bands.jl` in this folder.
#
# Usage:
#   julia --project=code/julia/env code/moments_from_coefficients/coefficients_to_moments.jl
#   # optional: DATASET=SCF DATE=2020-Q3 TREND=normal julia ... coefficients_to_moments.jl
#
# Wraps the canonical helper code/julia/reconstruct.jl (single source of truth).
# Only deps: CSV, DataFrames (same as the helper).
# ─────────────────────────────────────────────────────────────

const HERE = @__DIR__
const REPO = abspath(joinpath(HERE, "..", ".."))

include(joinpath(REPO, "code", "julia", "reconstruct.jl"))
using .DistributionalReconstruction
using DataFrames, CSV

const MEASURES = [:consum, :income, :wealth]
const DECILES  = collect(0.1:0.1:0.9)

has_measure(r, date, m) = try
    quantile_at(r, date, m, [0.5]); true
catch
    false
end

function main()
    dataset = get(ENV, "DATASET", "PSID")
    trend   = get(ENV, "TREND", "normal")
    date    = get(ENV, "DATE", "2008-Q3")

    csv = joinpath(REPO, "data", "synthetic", "$(dataset)_coefficients_$(trend).csv")
    isfile(csv) || error("Coefficient file not found: $csv")

    r = Reconstruction(csv)
    measures = filter(m -> has_measure(r, date, m), MEASURES)

    println("Dataset $dataset ($trend trend), date $date")
    println("Margins available: ", join(string.(measures), ", "), "\n")

    rows = DataFrame(date = String[], measure = String[], quantile = Float64[], value = Float64[])
    for m in measures
        q = quantile_at(r, date, m, DECILES)
        println(rpad(string(m), 8), "deciles:  ", join([string(round(v, digits=3)) for v in q], "  "))
        for (u, v) in zip(DECILES, q)
            push!(rows, (date, string(m), u, v))
        end
    end

    if length(measures) == 3
        cmed = copula_density_at(r, date, 0.5, 0.5, 0.5)
        println("\ncopula density at joint median (0.5,0.5,0.5): ", round(cmed, digits=4))
        push!(rows, (date, "copula_median", NaN, cmed))
    end

    out = joinpath(HERE, "coefficients_to_moments_output.csv")
    CSV.write(out, rows)
    println("\nWrote $out")
end

main()
