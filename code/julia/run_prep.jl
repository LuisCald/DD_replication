# ─────────────────────────────────────────────────────────────
# run_prep.jl — data preparation ONLY (no sampler)
# ─────────────────────────────────────────────────────────────
#
# Usage (from the project root, same switches as run_estimation.jl):
#   DD_EXAMPLE=transfer julia -t 16 --project=5_Code/code/julia/env 5_Code/code/julia/run_prep.jl
#
# What it does: runs estimation_prep and stops. That
#   1. (re)builds the coefficient data from the microdata with the CURRENT
#      estimator (weighted copula ranks), and the bootstrap caches
#      confidence_intervals/ci_draws_*.jld2, noise_distributions/noise_draws_*.jld2,
#      noise_distributions/sigma_*.jld2 for every survey whose cache is absent —
#      the slow part of a fresh run, done once here instead of at the head of a
#      multi-day estimation;
#   2. prints, per survey, `whitening <survey>: … cond(Σ̂) = …`, which is the
#      number that decides whether the whitening ridge is needed (≳ 1e12 ⇒ yes);
#   3. prints the loadings diagnostics (EM completion size, factor-score
#      rescaling, retained-factor criteria) and the parameter dimension.
#
# NB the caches are keyed on (measures, grid, survey, end year, ridge) — NOT on
# the rank method. Under weighted ranks every existing cache built before
# 2026-09-19 is stale for every survey with non-uniform weights (all real ones).
# Move the old cache folders aside before running this:
#   mv noise_distributions noise_distributions_oldranks
#   mv confidence_intervals confidence_intervals_oldranks
# ─────────────────────────────────────────────────────────────

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))

@info "═══ Prep only ═══"
@info "BASE_PATH = $BASE_PATH"

const func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)

@info "Prep complete. Parameter dimension: $(length(param_vector)); tag: $(repr(model_options.tag))"
@info "Next: read the `whitening <survey>: cond(Σ̂)` lines above; if any is ≳ 1e12, relaunch with DD_WRIDGE=0.05 " *
      "(the ridge gets its own sigma cache, so nothing built here is lost), then run run_estimation.jl."
@info "═══ Prep finished ═══"
