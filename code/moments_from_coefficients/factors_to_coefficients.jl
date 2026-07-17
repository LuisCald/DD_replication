# ─────────────────────────────────────────────────────────────
# factors_to_coefficients.jl — reconstruct coefficient rows from the
# smoothed factors (the FactorMap bridge).
#
# Fits the linear map factors → coefficients from the published point-estimate
# files (`FactorMap` in code/julia/reconstruct.jl; on the `_average` trend
# files the fit is exact, median R² = 1.0), then writes the reconstructed
# coefficient row for every date. This is the middle stage of the pipeline
#
#     factors  →  coefficients  →  moments / micro data
#
# and the hook for counterfactuals: perturb a factor before predicting, e.g.
#
#     include("factors_to_coefficients.jl")          # in a session
#     F = factors_at(fm, "2008-Q3"); F[1] += 1.0     # shock factor 1
#     row = predict(fm, F)                           # counterfactual coefficients
#     quantile_from_row(row, :wealth, [0.1, 0.5, 0.9])
#
# Usage:
#   julia --project=../julia/env factors_to_coefficients.jl
#   # options: DATASET=PSID (fit target; also SCF, CEX)
#   # output:  <DATASET>_coefficients_reconstructed.csv (next to this script)
#
# Only deps: CSV, DataFrames.  Python twin: factors_to_coefficients.py.
# ─────────────────────────────────────────────────────────────

const HERE = @__DIR__
const REPO = abspath(joinpath(HERE, "..", ".."))

include(joinpath(REPO, "code", "julia", "reconstruct.jl"))
using .DistributionalReconstruction
using CSV, DataFrames

dataset = get(ENV, "DATASET", "PSID")
fm = FactorMap(joinpath(REPO, "data", "synthetic", "$(dataset)_coefficients_average.csv"),
               joinpath(REPO, "data", "synthetic", "smoothed_factors.csv"))
println(DistributionalReconstruction.summary(fm))

if abspath(PROGRAM_FILE) == @__FILE__
    rows = [predict(fm, fm.factors_4q[i, :]) for i in eachindex(fm.dates_used)]
    out = DataFrame(reduce(vcat, permutedims.(rows)), ["x$i" for i in 1:fm.n_coefs])
    out[!, "time"] = fm.dates_used
    dest = joinpath(HERE, "$(dataset)_coefficients_reconstructed.csv")
    CSV.write(dest, select(out, "time", :))
    println("Wrote $(nrow(out)) reconstructed coefficient rows → $dest")
end
