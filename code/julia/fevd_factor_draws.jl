# fevd_factor_draws.jl — the FACTOR part of the FEVD (aggregate share of each distributional factor's 20-quarter
# forecast-error variance, block Cholesky with the aggregates first: AggregateBlocks.fevd_factor_shares) over posterior
# draws. Matrix algebra only, so thousands of draws take seconds; the observables/copula part is fevd_draws.jl.
# Also reports the aggregate AR coefficients diag(D) per draw (their mean across aggregates), since the share tracks them.
#   DD_EXAMPLE=replication DD_TAG=" scf22" [DD_AGG_MODE=blocks DD_AGG_SPEC=b11] DD_FEVDF_NDRAWS=2000 \
#     julia --project=5_Code/code/julia/env 5_Code/code/julia/fevd_factor_draws.jl      (Marvin: marvin/fevdfactor.sbatch)
# Output: 7_Results/aggregate_blocks/<tag>/fevd_factor_draws.csv, fevd_factor_draws_summary.csv
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using Statistics, LinearAlgebra, Random

const NDRAWS = parse(Int, get(ENV, "DD_FEVDF_NDRAWS", "2000"))
const OUT = joinpath(RESULTS_DIR, "aggregate_blocks", strip(model_options.tag))
mkpath(OUT)
func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)

function factor_shares(par)
    A, B_mat, C, D, Ω_var, Ω_corr, _ = matrisize(st_core_params(par, param_sizes), param_sizes)
    Ω_var[diagind(Ω_var)] = log.(exp.(Ω_var[diagind(Ω_var)]) .+ 1)
    Ω = Ω_var * Matrix(Ω_corr) * Ω_var'
    r, q = size(B_mat)
    Φ = zeros(4r + q, 4r + q)
    Φ[1:r, 1:r] .= A; Φ[1:r, 4r+1:4r+q] .= B_mat
    for k in 1:3; Φ[k*r+1:(k+1)*r, (k-1)*r+1:k*r] .= Matrix(I, r, r); end
    Φ[4r+1:end, 1:r] .= C; Φ[4r+1:end, 4r+1:end] .= D
    ids = vcat(1:r, 4r+1:4r+q)
    return fevd_factor_shares(Φ[ids, ids], Ω; r, q, horizon = 20, shock_order = :agg_first), mean(diag(D))
end

par_mode = get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, model_options.tag)
sh_mode, D_mode = factor_shares(par_mode)
f = jldopen(joinpath(BASE_PATH, "posterior_draws", measures_folder(model_options.measures) * "_" * model_options.tag * ".jld2"))
chains = f["d_chains"]; it = size(chains, 1); lprobs = f["lprobs"][end-it+1:end, :]; close(f)
valid = [(i, c) for c in axes(chains, 2) for i in axes(chains, 1) if isfinite(lprobs[i, c]) && lprobs[i, c] > MDD_INVALID]
Random.seed!(20261022)
sel = length(valid) > NDRAWS ? valid[sort(randperm(length(valid))[1:NDRAWS])] : valid
r = length(sh_mode)
S = fill(NaN, length(sel), r); Dm = fill(NaN, length(sel)); LP = [lprobs[i, c] for (i, c) in sel]
Threads.@threads for k in eachindex(sel)
    i, c = sel[k]
    try
        s, d = factor_shares(chains[i, c, :]); S[k, :] .= s; Dm[k] = d
    catch; end
end
ok = vec(all(isfinite, S; dims = 2))
@info "run $(model_options.tag): $(count(ok)) of $(length(sel)) draws ok ($(length(valid)) valid in $(size(chains, 2)) chains)"
long = DataFrame(draw = repeat(findall(ok), inner = r), factor = repeat(1:r, outer = count(ok)), aggregate = vec(S[ok, :]'))
CSV.write(joinpath(OUT, "fevd_factor_draws.csv"), hcat(long, DataFrame(D_mean = repeat(Dm[ok], inner = r), logpost = repeat(LP[ok], inner = r))))
q(x, p) = quantile(x, p)
summ = DataFrame(factor = ["f$i" for i in 1:r], mode = sh_mode, median = [median(S[ok, i]) for i in 1:r],
    q05 = [q(S[ok, i], 0.05) for i in 1:r], q16 = [q(S[ok, i], 0.16) for i in 1:r],
    q84 = [q(S[ok, i], 0.84) for i in 1:r], q95 = [q(S[ok, i], 0.95) for i in 1:r])
push!(summ, ("mean_over_factors", mean(sh_mode), median(mean(S[ok, :]; dims = 2)), q(vec(mean(S[ok, :]; dims = 2)), 0.05),
    q(vec(mean(S[ok, :]; dims = 2)), 0.16), q(vec(mean(S[ok, :]; dims = 2)), 0.84), q(vec(mean(S[ok, :]; dims = 2)), 0.95)))
push!(summ, ("D_mean", D_mode, median(Dm[ok]), q(Dm[ok], 0.05), q(Dm[ok], 0.16), q(Dm[ok], 0.84), q(Dm[ok], 0.95)))
CSV.write(joinpath(OUT, "fevd_factor_draws_summary.csv"), summ)
println("SUMMARY " * strip(model_options.tag)); show(stdout, summ; allrows = true, allcols = true); println()
