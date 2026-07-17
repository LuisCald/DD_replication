# ─────────────────────────────────────────────────────────────
# export_draws.jl — export posterior factor draws (run on the server).
# ─────────────────────────────────────────────────────────────
#
# Reconstructs the smoothed factors at a sample of posterior θ-draws and
# writes data/synthetic/smoothed_factor_draws.csv (+ bands). Reads the DIME
# output that Stage 2 already wrote to
# <BASE_PATH>/posterior_draws/<measures>_<tag>.jld2 — so the active
# model_options (tag, factor count, …) must match the estimated model.
#
# Usage (from repo root):
#   julia --project=code/julia/env code/julia/export_draws.jl
#   # optional: DD_N_DRAWS=400 DD_STATE_UNC=0 julia ... code/julia/export_draws.jl
#
# Also `include`-able from a session that already ran estimation_prep /
# set_params — existing objects are reused, the expensive prep is skipped.
#
# Cost: one Kalman-smoother pass per draw (fast — the expensive part is the
# one-time estimation_prep). Runtime ≈ minutes for a few hundred draws.
# ─────────────────────────────────────────────────────────────

if !@isdefined(model_options)
    include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
end

# Reuse session objects when present; run the one-time prep otherwise.
if !@isdefined(model_elements)
    @info "Preparing functional data (one-time)..."
    func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
end
if !@isdefined(param_sizes)
    _, param_sizes, priors, _, Σ_ids = set_params(model_elements, time_params, model_options)
end
if !@isdefined(hyperpriors)
    hyperpriors = priors[end-5:end]
end

n_draws   = parse(Int, get(ENV, "DD_N_DRAWS", "200"))
state_unc = get(ENV, "DD_STATE_UNC", "1") != "0"   # θ+state by default; 0 = mean paths only
@info "Exporting $n_draws posterior factor draws for tag = '$(model_options.tag)' (state_uncertainty=$state_unc)..."
export_factor_draws(param_sizes, hyperpriors, Σ_ids, model_elements,
                    model_options, time_params;
                    n_draws=n_draws, state_uncertainty=state_unc)
summarize_factor_draws()
@info "Done. See data/synthetic/smoothed_factor_draws.csv and smoothed_factors_bands.csv"
