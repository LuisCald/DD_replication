# # Import models which are comparable 
# model_dict = Dict()
# models = [tag] # " less AF", " more AF", " 6 factors", " additional factors",
# # models = [""]
# k = tag

# init_path     = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
# for model in models 
#     model_dict[model] = jldopen(init_path * "/posterior_draws" * "/" * m_label * "_$model.jld2") 
# end

# function laplace_approximation(model, model_elements, m_label, param_sizes, priors, meas_ind, Σ_ids, model_options)
#     """
#     H is the negative hessian at the posterior mode.
#     """
#     init_path = BASE_PATH
#     model_post = jldopen(init_path * "/posterior_draws" * "/" * m_label * "_$model.jld2")
#     θ_mode = find_mode(model_post["d_chains"], model_post["lprobs"])

#     # Implementation of the Laplace approximation
#     SSM(par) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]
#     SSM(par, _) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]

#     n = length(θ_mode)
#     ∂²f∂p∂p = zeros(Float64, n, n)

#     # # new
#     # FiniteDiff.finite_difference_hessian!(∂²f∂p∂p, pp -> SSM(pp), θ_mode)
#     # inv_hessian = inv(∂²f∂p∂p) # inverse of the negative hessian

#     # # Store the hessian 
#     # jldsave(init_path * "/Hessians" * "/$m_label" * "_$model.jld2"; ∂²f∂p∂p)
#     chain_sizes = size(model_post["d_chains"])

#     chain = reshape(model_post["d_chains"], chain_sizes[1] * chain_sizes[2], chain_sizes[end])
#     inv_hess = cov(chain, dims=1) # inverse of the negative hessian

#     log_det_inv_hess = generate_log_det_hessian(inv_hess)

#     lprobs_max = likeli(model_elements, θ_mode, param_sizes, priors, meas_ind, Σ_ids, model_options)[1]

#     mdd = 0.5 * n * log(2 * pi) + 0.5 * log_det_inv_hess + lprobs_max
#     println(mdd)

#     jldsave(init_path * "/MDD" * "/" * "laplace_$model.jld2"; mdd)
# end


# function generate_log_det_hessian(inv_hess)
#     DG = Diagonal(ones(size(inv_hess, 1)))
#     for i in [0.00001, 0.0001, 0.001, 0.01, 0.1, 0.2, 0.5]
#         pert_inv_hess = inv_hess .+ i .* DG
#         D = det(pert_inv_hess)
#         println("Determinant of the hessian: ", D)
#         println("Condition number", cond(pert_inv_hess))
#         if !isapprox(D, 0.0; atol=1e-8)
#             return log(det(pert_inv_hess))
#         end
#     end
# end

# function compute_harmonic_mean_for_all_models!(model_dict, models)
#     model_res = Dict()
#     for model in models
#         chain = model_dict[model]["d_chains"] # iterations by chains by parameters
#         it = size(chain, 1)
#         lprobs = model_dict[model]["lprobs"][end-it+1:end, :] # iterations by chains

#         model_res[model] = mdd_harmonic_mean(chain, lprobs)
#     end

#     # jldsave this dictionary
#     jldsave(init_path * "/MDD" * "/" * "mdd.jld2"; model_res)
#     println(model_res)

#     return model_res
# end

# ─────────────────────────────────────────────────────────────────────────────
# Marginal data density (2026-10-13 rewrite)
#
#   mdd_hm   Geweke modified harmonic mean (truncated-normal weight, α = 0.05)
#   mdd_bs   bridge sampler (Meng & Wong 1996), iterated in LOG space
#   af_corr  log density of the aggregate scores s_{k+1..K} this model does NOT
#            observe (k = its aggregate factor count, K = MDD_AF_MAX), under
#            independent conjugate Bayesian AR(1)s. The aggregate block is observed
#            as PCA scores, so a k-factor model is a density over (ŷ_dist, s_1..s_k):
#            adding af_corr makes every row a density over the same (ŷ_dist, s_1..s_K).
#   *_comparable = raw + af_corr  ← compare these across rows
#
# The old bridge sampler exponentiated (l − l*)/100 (not a valid rescaling: it
# overflowed to Inf or collapsed r to 0 ⇒ log r = −Inf), dropped posterior draws
# by the index of unrelated proposal draws, and used one iteration per chain.
# Caveat (all rows): the stationarity cap truncates the prior without
# renormalising it, so every MDD is p(y)·Pr_prior(stationary).
# ─────────────────────────────────────────────────────────────────────────────

const MDD_AF_MAX = 15
const MDD_INVALID = -1e5          # likelihood sentinel threshold (likeli returns −1e12 outside the support)

_logsumexp(v) = (m = maximum(v); isfinite(m) ? m + log(sum(exp.(v .- m))) : m)
_logmeanexp(v) = _logsumexp(v) - log(length(v))
function _logaddexp(a, b)
    a == -Inf && return b
    b == -Inf && return a
    return max(a, b) + log1p(exp(-abs(a - b)))
end

function run_mdd(tag, model_elements, m_label, param_sizes, priors, meas_ind, Σ_ids, model_options)
    init_path = BASE_PATH
    model_mcmc = jldopen(init_path * "/posterior_draws" * "/" * m_label * "_$tag.jld2")
    chains = model_mcmc["d_chains"]                          # iterations × chains × parameters
    it = size(chains, 1)
    lprobs = model_mcmc["lprobs"][end-it+1:end, :]           # iterations × chains
    close(model_mcmc)

    mdd_hm = mdd_harmonic_mean(chains, lprobs)
    bs = bridge_sampler(chains, lprobs, model_elements, param_sizes, priors, Σ_ids, model_options)
    bs2 = bridge_sampler(chains, lprobs, model_elements, param_sizes, priors, Σ_ids, model_options; seed = 2)

    af_corr, k_af = NaN, 0
    try
        af_corr, k_af = af_correction(model_elements, model_options)
    catch e
        @warn "MDD: aggregate-score correction failed: $e"
    end

    @info "MDD $(repr(tag)): harmonic mean $(round(mdd_hm; digits=2)), bridge $(round(bs["logml"]; digits=2)) " *
          "(second split $(round(bs2["logml"]; digits=2))), AF correction for k = $k_af of $MDD_AF_MAX: $(round(af_corr; digits=2))"
    mkpath(init_path * "/7_Results/MDD")
    jldsave(init_path * "/7_Results/MDD" * "/" * "mdd_$tag.jld2";
        mdd_hm = mdd_hm, mdd_bs = bs, mdd_bs_split2 = bs2["logml"],
        af_corr = af_corr, k_af = k_af, af_max = MDD_AF_MAX,
        mdd_hm_comparable = mdd_hm + af_corr, mdd_bs_comparable = bs["logml"] + af_corr,
        n_params = size(chains, 3))
end

"Valid (finite, inside the support) draws as an N × P matrix with their log posteriors."
function _valid_draws(chains, lprobs, chain_ids)
    θ = Vector{Vector{Float64}}(); lp = Float64[]
    for c in chain_ids, i in axes(chains, 1)
        l = lprobs[i, c]
        (isfinite(l) && l > MDD_INVALID) || continue
        push!(θ, chains[i, c, :]); push!(lp, l)
    end
    return isempty(θ) ? zeros(0, size(chains, 3)) : permutedims(reduce(hcat, θ)), lp
end

"Gaussian fitted to draws, with a ridge large enough for a Cholesky factorisation."
function _fit_gaussian(X)
    m = vec(mean(X, dims = 1))
    V = Symmetric(cov(X, dims = 1))
    τ = 1e-10 * max(mean(diag(V)), 1e-12)
    for _ in 1:12
        F = cholesky(V + τ * I; check = false)
        issuccess(F) && return MvNormal(m, PDMat(Matrix(V + τ * I), F))
        τ *= 10
    end
    error("MDD: covariance of the posterior draws is not positive definite even with a ridge")
end

function mdd_harmonic_mean(chains, lprobs; α = 0.05)
    X, lp = _valid_draws(chains, lprobs, axes(chains, 2))
    size(X, 1) <= size(X, 2) && (@warn "MDD (harmonic mean): $(size(X, 1)) valid draws for $(size(X, 2)) parameters"; return NaN)
    g = _fit_gaussian(X)
    thr = quantile(Chisq(size(X, 2)), 1 - α)
    Σi = inv(cov(g))
    mls = Float64[]
    for i in axes(X, 1)
        d = X[i, :] .- mean(g)
        dot(d, Σi * d) < thr || continue
        push!(mls, logpdf(g, X[i, :]) - log(1 - α) - lp[i])   # log f(θ) − log p(y|θ)p(θ), f truncated normal
    end
    isempty(mls) && (@warn "MDD (harmonic mean): no draw inside the truncation region"; return NaN)
    return -_logmeanexp(mls)
end

"""
    bridge_sampler(chains, lprobs, model_elements, param_sizes, priors, Σ_ids, model_options; seed, n_prop)

Meng–Wong bridge sampler in log space. Chains are split at random: half fit the
Gaussian proposal, the other half are the posterior sample. Proposal draws
outside the support (likeli = −1e12) get posterior density 0 (l = −Inf) and are
KEPT — dropping them would bias the estimate upward.
"""
function bridge_sampler(chains, lprobs, model_elements, param_sizes, priors, Σ_ids, model_options;
                        seed = 1, n_prop = 4000, tol = 1e-10, maxiter = 1000)
    rng = MersenneTwister(seed)
    perm = randperm(rng, size(chains, 2))
    half = length(perm) ÷ 2
    Xf, _ = _valid_draws(chains, lprobs, perm[1:half])
    Xp, lp = _valid_draws(chains, lprobs, perm[half+1:end])
    out = Dict{String,Any}("logml" => NaN, "n_post" => size(Xp, 1), "n_prop" => 0, "n_prop_outside" => 0, "iterations" => 0)
    (size(Xf, 1) > size(Xf, 2) && size(Xp, 1) > 0) ||
        (@warn "MDD (bridge): too few valid draws ($(size(Xf, 1)) fit, $(size(Xp, 1)) posterior)"; return out)

    q = _fit_gaussian(Xf)
    N1 = size(Xp, 1)
    N2 = n_prop
    gen = rand(rng, q, N2)                                    # P × N2
    q12 = [logpdf(q, Xp[i, :]) for i in 1:N1]
    q22 = [logpdf(q, gen[:, j]) for j in 1:N2]
    hyperpriors = st_hyperpriors(priors, param_sizes)
    q21 = Vector{Float64}(undef, N2)
    Threads.@threads for j in 1:N2
        q21[j] = likeli(model_elements, gen[:, j], param_sizes, hyperpriors, Σ_ids, model_options)[1]
    end
    outside = .!(isfinite.(q21) .& (q21 .> MDD_INVALID))
    q21[outside] .= -Inf

    l1 = lp .- q12
    l2 = q21 .- q22
    ls1, ls2 = log(N1 / (N1 + N2)), log(N2 / (N1 + N2))
    logr = median(l1)
    iters = 0
    for k in 1:maxiter
        iters = k
        num = _logmeanexp([l - _logaddexp(ls1 + l, ls2 + logr) for l in l2])
        den = _logmeanexp([-_logaddexp(ls1 + l, ls2 + logr) for l in l1])
        new = num - den
        done = abs(new - logr) < tol
        logr = new
        (done || !isfinite(logr)) && break
    end
    isfinite(logr) || @warn "MDD (bridge): non-finite estimate (proposal far from the posterior: $(count(outside))/$N2 proposal draws outside the support)"
    out["logml"] = isfinite(logr) ? logr : NaN
    out["n_prop"] = N2; out["n_prop_outside"] = count(outside); out["iterations"] = iters
    return out
end

"""
    ar1_log_marginal(s; κ0 = 1, a0 = 2, b0 = 1)

log p(s) for s_1 ~ N(0, 1) and s_t = ρ s_{t−1} + σ ε_t with the conjugate prior
ρ | σ² ~ N(0, σ²/κ0), σ² ~ IG(a0, b0). Closed form (Bayesian linear regression).
"""
function ar1_log_marginal(s::AbstractVector; κ0 = 1.0, a0 = 2.0, b0 = 1.0)
    x, y = s[1:end-1], s[2:end]
    n = length(y)
    κn = κ0 + dot(x, x)
    ρn = dot(x, y) / κn
    an = a0 + n / 2
    bn = b0 + 0.5 * (dot(y, y) - κn * ρn^2)
    return logpdf(Normal(0, 1), s[1]) - n / 2 * log(2π) + 0.5 * log(κ0 / κn) +
           a0 * log(b0) - an * log(bn) + Distributions.SpecialFunctions.loggamma(an) - Distributions.SpecialFunctions.loggamma(a0)
end

"""
    af_correction(model_elements, model_options) -> (log density, k)

Σ_{j=k+1}^{K} log p(s_j) for the aggregate scores this model leaves out, with the
scores from the SAME aggregate PCA (only the slice differs across specs).
"""
function af_correction(model_elements, model_options)
    k = model_elements.agg_count
    k >= MDD_AF_MAX && return 0.0, k
    tp = Main.time_params
    n0 = model_options.n_agg_factors
    local s
    try
        model_options.n_agg_factors = MDD_AF_MAX
        _, s, _ = select_aggregates(copy(obs_data.agg_data), model_options.measures, tp.tot_periods, tp.tmin, tp.tmax,
                                    model_options.agg_lags, model_options.tag, model_options.best_aggs)
    finally
        model_options.n_agg_factors = n0
    end
    # sanity: the observed rows must be the first k of the K-score panel
    maximum(abs.(s[1:k, :] .- model_elements.u)) < 1e-8 ||
        @warn "MDD: the model's aggregate scores are not the first $k of the $MDD_AF_MAX-score panel; correction may be off"
    return sum(ar1_log_marginal(s[j, :]) for j in (k+1):MDD_AF_MAX), k
end
