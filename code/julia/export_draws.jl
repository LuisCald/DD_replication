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
#   # optional: DD_N_DRAWS=400 DD_STATE_DRAWS=joint|pointwise|none julia ... code/julia/export_draws.jl
#   # DD_DRAWS_OUT=<dir> writes there instead of data/synthetic (e.g. to compare before replacing)
#   # DD_CONSENSUS_CHECK=1 also logs the inverse-ME-SD consensus weights at the mode
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
    hyperpriors = st_hyperpriors(priors, param_sizes)
end

n_draws     = parse(Int, get(ENV, "DD_N_DRAWS", "200"))
state_draws = Symbol(get(ENV, "DD_STATE_DRAWS", get(ENV, "DD_STATE_UNC", "1") == "0" ? "none" : "joint"))
out_dir     = get(ENV, "DD_DRAWS_OUT", "")
out_dir     = isempty(out_dir) ? nothing : out_dir
@info "Exporting $n_draws posterior factor draws for tag = '$(model_options.tag)' (state_draws = $state_draws)..."
f = export_factor_draws(param_sizes, hyperpriors, Σ_ids, model_elements,
                        model_options, time_params;
                        n_draws=n_draws, state_draws=state_draws, out_dir=out_dir)
summarize_factor_draws(; draws_csv=f, out_dir=out_dir)
@info "Done. See $f and the bands file next to it"

if get(ENV, "DD_CONSENSUS_CHECK", "0") == "1"
    par_mode = get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, model_options.tag)
    n_dfs  = length(model_elements.Gⱼ)
    n_coef = size(model_elements.Gⱼ[1], 1)
    mo_w = deepcopy(model_options); mo_w.consensus_weights = :inv_me_sd
    W = consensus_weight_matrix(par_mode, param_sizes, Σ_ids, mo_w, model_elements.agg_count, n_coef, n_dfs)
    names_ = obs_data.df_vec[2]
    for (j, nm) in enumerate(names_)
        w = W[:, j]; ok = .!isnan.(w)
        @info "  $(rpad(nm, 6)): observed coefs $(count(ok)) of $n_coef; weight median $(round(median(w[ok]); digits=2)), range [$(round(minimum(w[ok]); digits=2)), $(round(maximum(w[ok]); digits=2))]"
    end
end
