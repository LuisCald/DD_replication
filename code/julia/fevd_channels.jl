# fevd_channels.jl — how do the aggregates reach the distributional factors? (Oct 2026)
# (1) Channel shut-downs of the factor FEVD (block Cholesky, aggregates first, h = 20; AggregateBlocks.fevd_factor_shares):
#     the aggregate share with the full transition, with C = 0 (lagged factors no longer move the aggregates: what is
#     left is the DIRECT aggregate-shock channel; the difference is the factor → aggregate → factor loop), with B = 0
#     (only the contemporaneous shock correlation Ω_fy is left) and with Ω_fy = 0 (only lagged feedback through B).
#     At the mode and over DD_CH_NDRAWS posterior draws (median, 5/95%).
# (2) One-step variance decomposition of the factor equation on the smoothed states at the mode,
#     f_t = A f_{t-1} + B a_{t-1} + e_t: Var(f) split into own lags, lagged aggregates, their covariance and the residual.
#   DD_EXAMPLE=replication DD_TAG=" scf22" [DD_AGG_MODE=blocks DD_AGG_SPEC=b11] julia --project=... fevd_channels.jl
# Output: 7_Results/aggregate_blocks/<tag>/fevd_channels.csv, fevd_onestep.csv
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using Statistics, LinearAlgebra, Random

const NDRAWS = parse(Int, get(ENV, "DD_CH_NDRAWS", "500"))
const OUT = joinpath(RESULTS_DIR, "aggregate_blocks", strip(model_options.tag))
mkpath(OUT)
func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)

function system(par)
    A, B_mat, C, D, Ω_var, Ω_corr, _ = matrisize(st_core_params(par, param_sizes), param_sizes)
    Ω_var[diagind(Ω_var)] = log.(exp.(Ω_var[diagind(Ω_var)]) .+ 1)
    Ω = Ω_var * Matrix(Ω_corr) * Ω_var'
    return A, B_mat, C, D, Ω
end
function phi_sub(A, B_mat, C, D)
    r, q = size(B_mat)
    Φ = zeros(r + q, r + q)
    Φ[1:r, 1:r] .= A; Φ[1:r, r+1:end] .= B_mat; Φ[r+1:end, 1:r] .= C; Φ[r+1:end, r+1:end] .= D
    return Φ
end
"""aggregate shares (%) of the r factors: full, C = 0, B = 0, Ω_fy = 0."""
function channel_shares(par)
    A, B_mat, C, D, Ω = system(par)
    r, q = size(B_mat)
    Ω0 = copy(Ω); Ω0[1:r, r+1:end] .= 0; Ω0[r+1:end, 1:r] .= 0
    f(Φ, W) = fevd_factor_shares(Φ, W; r, q, horizon = 20, shock_order = :agg_first)
    return (full = f(phi_sub(A, B_mat, C, D), Ω), noC = f(phi_sub(A, B_mat, zero(C), D), Ω),
            noB = f(phi_sub(A, zero(B_mat), C, D), Ω), noOfy = f(phi_sub(A, B_mat, C, D), Ω0))
end

par_mode = get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, model_options.tag)
cm = channel_shares(par_mode)
r = length(cm.full)

# posterior draws
f = jldopen(joinpath(BASE_PATH, "posterior_draws", measures_folder(model_options.measures) * "_" * model_options.tag * ".jld2"))
chains = f["d_chains"]; it = size(chains, 1); lprobs = f["lprobs"][end-it+1:end, :]; close(f)
valid = [(i, c) for c in axes(chains, 2) for i in axes(chains, 1) if isfinite(lprobs[i, c]) && lprobs[i, c] > MDD_INVALID]
Random.seed!(20261023)
sel = length(valid) > NDRAWS ? valid[sort(randperm(length(valid))[1:NDRAWS])] : valid
res = Vector{Any}(nothing, length(sel))
Threads.@threads for k in eachindex(sel)
    i, c = sel[k]
    try; res[k] = channel_shares(chains[i, c, :]); catch; end
end
ok = findall(!isnothing, res)
rows = DataFrame(channel = String[], factor = String[], mode = Float64[], median = Float64[], q05 = Float64[], q95 = Float64[])
for ch in (:full, :noC, :noB, :noOfy)
    M = reduce(hcat, [getfield(res[k], ch) for k in ok])'          # draws × r
    for j in 1:r
        push!(rows, (String(ch), "f$j", getfield(cm, ch)[j], median(M[:, j]), quantile(M[:, j], 0.05), quantile(M[:, j], 0.95)))
    end
    m = vec(mean(M; dims = 2))
    push!(rows, (String(ch), "mean_over_factors", mean(getfield(cm, ch)), median(m), quantile(m, 0.05), quantile(m, 0.95)))
end
CSV.write(joinpath(OUT, "fevd_channels.csv"), rows)
println("CHANNELS " * strip(model_options.tag) * "  ($(length(ok)) draws)")
show(stdout, filter(x -> x.factor == "mean_over_factors", rows); allrows = true, allcols = true); println()

# (2) one-step decomposition on the smoothed states at the mode
sm, _ = likeli(model_elements, par_mode, param_sizes, hyperpriors, Σ_ids, model_options; smooth = true)
X = sm.x_smoothed                      # (4r + q) × T: [f_t, f_{t-1}, f_{t-2}, f_{t-3}, a_t]
A, B_mat, C, D, Ω = system(par_mode)
q = size(B_mat, 2)
F = X[1:r, 2:end]; Fl = X[1:r, 1:end-1]; Al = X[4r+1:4r+q, 1:end-1]
own = A * Fl; agg = B_mat * Al; e = F .- own .- agg
os = DataFrame(factor = String[], var_f = Float64[], own_lags_pct = Float64[], lagged_aggs_pct = Float64[], cov_own_agg_pct = Float64[], residual_pct = Float64[], cov_resid_pct = Float64[])
for j in 1:r
    v = var(F[j, :]); vo = var(own[j, :]); va = var(agg[j, :]); ve = var(e[j, :])
    c1 = 2 * cov(own[j, :], agg[j, :]); c2 = 2 * (cov(own[j, :], e[j, :]) + cov(agg[j, :], e[j, :]))
    push!(os, ("f$j", v, 100vo / v, 100va / v, 100c1 / v, 100ve / v, 100c2 / v))
end
CSV.write(joinpath(OUT, "fevd_onestep.csv"), os)
println("ONESTEP " * strip(model_options.tag)); show(stdout, os; allrows = true, allcols = true); println()
