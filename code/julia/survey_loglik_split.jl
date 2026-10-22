# ─────────────────────────────────────────────────────────────────────────────
# survey_loglik_split.jl — split the likelihood of an estimated run into the SURVEY part and the
# AGGREGATE part, draw by draw, and reweight the MDD onto the surveys only (Oct 2026).
#
# Why: the aggregate scores are part of the observation vector, so runs with different aggregate
# blocks are scored on different data and their MDDs are not comparable (MDD.af_correction only
# handles nested PCA panels). For each posterior draw θ:
#   log p(all | θ)     — the usual filter (surveys + aggregate rows)
#   log p(surveys | θ) — the same filter with the aggregate rows of y, G and Σ removed: the aggregate
#                        states stay latent with their own dynamics, i.e. the aggregates are integrated out
#   log p(agg | surveys, θ) = difference
# Survey-only MDD by importance reweighting of the full-data posterior draws:
#   MDD_surveys = MDD_all · E_post[ 1 / p(agg | surveys, θ) ]
# with Kish ESS, the log-weight spread and a Pareto-k check on the largest weights (Vehtari et al.):
# the weights are minus an 11 × 247 conditional log-likelihood, so expect them to be heavy-tailed.
# Also reported: the posterior mean of the survey log-likelihood (a common-data fit comparison that
# needs no reweighting).
#
# Run (Marvin, 5_Code/marvin/surveysplit.sbatch; the DD_* switches must match the estimated run):
#   DD_EXAMPLE=replication DD_TAG=" scf22" DD_AGG_MEAS=tight [DD_AGG_MODE=blocks DD_AGG_SPEC=b5x2 DD_NAF=10] \
#     DD_SPLIT_NDRAWS=2000 julia -t 16 --project=5_Code/code/julia/env 5_Code/code/julia/survey_loglik_split.jl
# Output: 7_Results/aggregate_blocks/<tag>/survey_split_draws.csv, survey_split_summary.csv
# ─────────────────────────────────────────────────────────────────────────────

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using Statistics, LinearAlgebra, Random

const NDRAWS = parse(Int, get(ENV, "DD_SPLIT_NDRAWS", "2000"))
const RUN = measures_folder(model_options.measures) * model_options.tag
const OUT = joinpath(RESULTS_DIR, "aggregate_blocks", strip(model_options.tag))
mkpath(OUT)
@info "═══ survey / aggregate likelihood split ═══" RUN NDRAWS Threads.nthreads()

func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)
const AGG_TIGHT = hasproperty(model_options, :agg_meas_prior) && model_options.agg_meas_prior == :tight
model_options.trend_spec == :stochastic && error("stochastic-trend runs are not handled here (st_likeli)")
model_options.aggregate_rep == :as_states || error("needs aggregate_rep = :as_states")

"""log prior, log p(all | θ), log p(surveys | θ) — Model.likeli's parameter path, then the filter twice."""
function loglik_parts(par)
    @unpack y, G, agg_count = model_elements
    n_hyper = param_sizes[end][1]
    hyper_params = par[end-n_hyper+1:end]
    other_params = par[1:end-n_hyper]
    pri = get_priors(model_elements, model_options, hyper_params)
    push!(pri, hyperpriors...)
    A, B, C, D, Ω_var, Ω_corr, Σ = matrisize(other_params, param_sizes)
    log_P, alarm = prioreval([[A..., B..., C..., diag(D)...], Ω_var, Ω_corr, Matrix(Σ), hyper_params], pri, param_sizes;
                             agg_meas_tight = AGG_TIGHT)
    alarm && return (log_P, NaN, NaN)
    Ω_var[diagind(Ω_var)] = log.(exp.(Ω_var[diagind(Ω_var)]) .+ 1)
    Ω = Ω_var * Matrix(Ω_corr) * Ω_var'
    Σ = apply_measurement_criteria(Σ, Σ_ids, model_options, agg_count)
    cnd = Σ .> 10
    Σ[.!cnd] .= log.(exp.(Σ[.!cnd]) .+ 1)
    apply_copula_error_weights!(Σ, model_options, agg_count)
    r = size(A, 1)
    Ω_f = Ω[1:r, 1:r]; Ω_y = Ω[r+1:end, r+1:end]; Ω_fy = Ω[1:r, r+1:end]
    log_all, al1 = recurse_kalman_filter_forward(A, B, C, D, Ω_f, Ω_y, Σ, G, y; Ω_fy = Ω_fy)
    ns = size(y, 1) - agg_count                       # aggregate rows are the last agg_count rows of y
    Gs = [g[1:ns, :] for g in G]
    Σs = Σ isa AbstractVector ? Σ[1:ns] : Σ[1:ns, 1:ns]
    log_sur, al2 = recurse_kalman_filter_forward(A, B, C, D, Ω_f, Ω_y, Σs, Gs, y[1:ns, :]; Ω_fy = Ω_fy)
    return (log_P, al1 ? NaN : log_all, al2 ? NaN : log_sur)
end

# check against Model.likeli at the mode
par_final = get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, model_options.tag)
lp0, la0, ls0 = loglik_parts(par_final)
lv0, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
@info "mode: prior $(round(lp0; digits = 2)), log p(all) $(round(la0; digits = 2)), log p(surveys) $(round(ls0; digits = 2)), log p(agg | surveys) $(round(la0 - ls0; digits = 2)); likeli = $(round(lv0; digits = 2)) vs prior + all = $(round(lp0 + la0; digits = 2))"
abs(lv0 - (lp0 + la0)) < 1e-6 || @warn "split does not reproduce Model.likeli at the mode (diff $(lv0 - lp0 - la0))"

# posterior draws (as MDD.run_mdd reads them)
f = jldopen(joinpath(BASE_PATH, "posterior_draws", measures_folder(model_options.measures) * "_" * model_options.tag * ".jld2"))
chains = f["d_chains"]; it = size(chains, 1); lprobs = f["lprobs"][end-it+1:end, :]; close(f)
valid = [(i, c) for c in axes(chains, 2) for i in axes(chains, 1) if isfinite(lprobs[i, c]) && lprobs[i, c] > MDD_INVALID]
@info "draws: $(size(chains, 1)) iterations × $(size(chains, 2)) chains, $(length(valid)) valid"
Random.seed!(20261022)
sel = length(valid) > NDRAWS ? valid[sort(randperm(length(valid))[1:NDRAWS])] : valid
N = length(sel)
res = fill(NaN, N, 4)
Threads.@threads for k in 1:N
    i, c = sel[k]
    θ = chains[i, c, :]
    lp, la, ls = loglik_parts(θ)
    res[k, :] .= (lprobs[i, c], lp, la, ls)
end
ok = vec(all(isfinite, res; dims = 2))
@info "evaluated $N draws, $(count(ok)) finite"
R = res[ok, :]
lpost, lP, lall, lsur = R[:, 1], R[:, 2], R[:, 3], R[:, 4]
lagg = lall .- lsur
CSV.write(joinpath(OUT, "survey_split_draws.csv"), DataFrame(logpost = lpost, logprior = lP, loglik_all = lall, loglik_surveys = lsur, loglik_agg_given_surveys = lagg))

# importance weights w = 1 / p(agg | surveys, θ)
lw = -lagg
lwmax = maximum(lw)
w = exp.(lw .- lwmax)
ess = sum(w)^2 / sum(w .^ 2)
logmeanw = lwmax + log(mean(w))
# Pareto-k on the largest 20% of weights (Zhang & Stephens 2009 profile estimator, as in PSIS)
function pareto_k(x)
    x = sort(x); n = length(x); n < 10 && return NaN
    prior = 3; m = 30 + floor(Int, sqrt(n))
    θs = [1 / x[n] + (1 - sqrt(m / (j - 0.5))) / prior / x[div(n, 4) + 1] for j in 1:m]
    lθ(θ) = n * (log(-θ / mean(log1p.(-θ .* x))) - mean(log1p.(-θ .* x)) - 1)
    l = lθ.(θs); wθ = exp.(l .- maximum(l)); wθ ./= sum(wθ)
    θhat = sum(θs .* wθ)
    return mean(log1p.(-θhat .* x))
end
ntail = max(10, ceil(Int, 0.2 * length(w)))
tail = sort(w)[end-ntail+1:end]
k̂ = pareto_k(tail .- minimum(tail) .+ 1e-12)
# MDD of the run (bridge) → survey-only MDD by reweighting
mdd_file = joinpath(RESULTS_DIR, "MDD", "mdd_" * model_options.tag * ".jld2")
mdd_all = isfile(mdd_file) ? (m = load(mdd_file); m["mdd_bs"] isa AbstractDict ? m["mdd_bs"]["logml"] : NaN) : NaN
summary = DataFrame(run = RUN, n_draws = length(lsur), n_survey_rows = size(model_elements.y, 1) - model_elements.agg_count, n_agg_rows = model_elements.agg_count,
    loglik_surveys_mean = mean(lsur), loglik_surveys_sd = std(lsur), loglik_surveys_mode = ls0,
    loglik_all_mean = mean(lall), loglik_all_mode = la0,
    loglik_agg_cond_mean = mean(lagg), loglik_agg_cond_sd = std(lagg),
    mdd_bs_all = mdd_all, log_mean_weight = logmeanw, mdd_bs_surveys = mdd_all + logmeanw,
    ess_kish = ess, ess_share = ess / length(w), logw_sd = std(lw), logw_max_minus_p99 = lwmax - quantile(lw, 0.99), pareto_k = k̂)
CSV.write(joinpath(OUT, "survey_split_summary.csv"), summary)
println(); show(stdout, permutedims(summary, 1); allrows = true, allcols = true); println()
@info "═══ done → $OUT ═══"
