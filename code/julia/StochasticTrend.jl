# ── StochasticTrend.jl ───────────────────────────────────────────────────────
# Option (a) stochastic trends — all logic lives HERE; existing functions are
# not modified. Design: doc/stochastic_trend_design.md (S1 spec surface, S2
# data layer, S3 state block). Gated on ModelOptions.trend_spec = :stochastic.
#
# KEY IMPLEMENTATION IDEA (no forked filters): fold the r_τ random-walk trend
# states into the FACTOR block, f̃ = [f; τ], and feed the EXISTING Kalman
# recursions augmented inputs:
#     Ã = blkdiag(A, ρ_τ·I)   B̃ = [B; 0]   C̃ = [C 0]   Ω̃_f = blkdiag(Ω_f, diag(ω_τ²))
# The recursions' internal lag-chain template then carries τ lags alongside f
# lags, so annual observations (which load across the four f-lag blocks) treat
# the trend EXACTLY — no within-year-constancy approximation. Aggregates stay
# driven by the cycle only (C̃ zero on τ). ρ_τ = 0.999 (near-unit root) keeps
# the `lyapd` stationary initialization inside the untouched recursions valid;
# at wave frequency this is indistinguishable from a pure RW.
#
# Measurement: τ loads with the SAME loadings as f — G̃ duplicates, within each
# of the four lag blocks, that block's f-columns (quarterly rows pick up Λ at
# t; annual rows pick up Λ/4 across the four lags, exactly as for f).
#
# STATUS: S2 (st_perform_detrending) and the S3 core (st_augment_system,
# st_augment_G, verified by st_selftest: ω_τ=0 reproduces the baseline
# likelihood to machine precision) are implemented. PENDING (S3b/S4): the
# parameter plumbing — append the ω_τ block to param_sizes in
# define_parameter_space, hierarchical prior in get_priors (global-local scale,
# cf. Chan-style adaptive shrinkage; Stock–Watson 1998 pile-up motivates it),
# an st_likeli wrapper calling matrisize + st_augment_system, and the
# reconstruction consumers adding smoothed τ to f before Λ-multiplication.
# estimation_prep keeps ERRORING on :stochastic until those land.

const ST_RHO_TAU = 0.999   # near-unit-root trend persistence (see header)

"""
    st_augment_system(A, B, C, Ω_f, ω_τ; ρ_τ=ST_RHO_TAU)

Return `(Ã, B̃, C̃, Ω̃_f)` with `r_τ = length(ω_τ)` trend states folded into the
factor block. `D`, `Ω_y`, `Σ` are unchanged by construction and not passed.
"""
function st_augment_system(A, B, C, Ω_f, ω_τ; ρ_τ = ST_RHO_TAU)
    r = size(A, 1)
    rτ = length(ω_τ)
    T = eltype(A)
    Ã = [A zeros(T, r, rτ); zeros(T, rτ, r) ρ_τ*Matrix{T}(I, rτ, rτ)]
    B̃ = [B; zeros(T, rτ, size(B, 2))]
    C̃ = [C zeros(T, size(C, 1), rτ)]
    Ω̃_f = [Ω_f zeros(T, r, rτ); zeros(T, rτ, r) diagm(ω_τ .^ 2)]
    return Ã, B̃, C̃, Ω̃_f
end

"""
    st_augment_G(G, r, rτ)

Augment the per-period measurement matrices for the [f; τ] factor block:
states go [f(4 lags), a] → [f̃(4 lags), a] with f̃ = [f; τ], and within each lag
block τ's columns duplicate the f-columns (`rτ ≤ r`: τ_j shares factor j's
loadings). Returns a new vector of matrices; `G` is untouched.
"""
function st_augment_G(G::AbstractVector, r::Int, rτ::Int)
    r̃ = r + rτ
    map(G) do Gt
        n = size(Gt, 1)
        q = size(Gt, 2) - 4r
        G̃ = zeros(eltype(Gt), n, 4r̃ + q)
        for lag in 0:3
            src = lag*r .+ (1:r)
            G̃[:, lag*r̃ .+ (1:r)] .= @view Gt[:, src]
            G̃[:, lag*r̃ + r .+ (1:rτ)] .= @view Gt[:, src[1:rτ]]
        end
        G̃[:, 4r̃+1:end] .= @view Gt[:, 4r+1:end]
        G̃
    end
end

"""
    st_perform_detrending(df, time_p, year_vec, freq, freq_type, time_dict)

S2 data layer: per-dataset LINEAR alignment drift only (no HP). Fits an OLS
line per coefficient row on its observed dates, subtracts at observed dates,
and stores the line over all periods in the same `trend` container the
reconstruction re-adds — so `Reconstruction.jl`'s add-back works unchanged and
all remaining low-frequency movement is left for the τ states to absorb.
Return signature matches `perform_detrending` (βs carry slope/intercept).
"""
function st_perform_detrending(df, time_p, year_vec, freq, freq_type, time_dict; return_only_data=false)
    @unpack tot_periods = time_p
    t = collect(1:tot_periods)
    trend = fill(NaN, size(df, 1), tot_periods)
    βs = fill(NaN, size(df, 1), 3)      # baseline contract: n×3 (ModelPrep container is (n,3,J))
    correct_indices = generate_correct_indices(year_vec, freq_type, freq,
                                               time_p.tmin, time_dict)
    for i in axes(df, 1)
        mask = findall(!isnan, @view df[i, :])
        isempty(mask) && continue
        obs_t = Float64.(correct_indices[mask])
        # 1 obs → constant drift (level); 2 obs → exact line; ≥3 → OLS line.
        # Rows must never be left un-detrended: an all-NaN trend row would NaN
        # the reconstruction add-back at every period (review finding 5).
        β = if length(mask) == 1
            [Float64(df[i, mask[1]]), 0.0]
        else
            X = hcat(ones(length(obs_t)), obs_t)
            X \ Vector{Float64}(@view df[i, mask])
        end
        βs[i, 1:2] .= β
        line = β[1] .+ β[2] .* t
        first_obs = minimum(obs_t)
        trend[i, Int(first_obs):end] .= line[Int(first_obs):end]
        df[i, mask] .= df[i, mask] .- (β[1] .+ β[2] .* obs_t)
    end
    return return_only_data ? df : (βs, df, trend)
end

# ── S3b: parameter plumbing ─────────────────────────────────────────────────
# Layout under :stochastic — the baseline 8-block vector gets a TREND block
# appended at the very end: θ_tr = [ω_raw(r); ψ_raw(r); λ_raw], transformed to
# positives by softplus inside st_likeli. Global–local hierarchy:
#   ω_τ,j ~ N⁺(0, (λ·ψ_j)²),  ψ_j ~ C⁺(0,1),  λ ~ C⁺(0, trend_lambda_scale)
#   (ModelOptions.trend_lambda_scale, default 0.1).
# The core blocks are priored/evaluated by the UNTOUCHED baseline machinery
# (get_priors/prioreval on core_sizes); the hierarchy's log-prior is added
# explicitly here. Note: like the baseline (which evaluates priors on raw
# coordinates and softplus-transforms afterwards), no transform Jacobian is
# added — documented choice, consistent with the existing blocks.

# ── review-fix helpers (F1/F2/F4): trend-block-aware slicing ─────────────────
st_is_stochastic(param_sizes) = length(param_sizes) == 9
st_ntrend(param_sizes) = st_trend_dim(param_sizes[1][1])

"H-block length from param_sizes: 6 (:common) or r+5 (persistence_prior = :per_factor)."
n_hyper_block(param_sizes) = st_is_stochastic(param_sizes) ? param_sizes[end-1][1] : param_sizes[end][1]

"Hyperprior slice of `priors` (the H-block hyperpriors precede any appended trend block)."
st_hyperpriors(priors, param_sizes) = (n_h = n_hyper_block(param_sizes); st_is_stochastic(param_sizes) ?
    priors[end-st_ntrend(param_sizes)-n_h+1:end-st_ntrend(param_sizes)] : priors[end-n_h+1:end])

"Hyperparameter slice of a full parameter vector (F2: DIMESampler init path)."
st_hyper_params(par, param_sizes) = (n_h = n_hyper_block(param_sizes); st_is_stochastic(param_sizes) ?
    par[end-st_ntrend(param_sizes)-n_h+1:end-st_ntrend(param_sizes)] : par[end-n_h+1:end])

"Strip hypers (+trend block) for matrisize (F4: run_postestimation call sites)."
st_core_params(par, param_sizes) = (n_h = n_hyper_block(param_sizes); st_is_stochastic(param_sizes) ?
    par[1:end-n_h-st_ntrend(param_sizes)] : par[1:end-n_h])

st_trend_dim(r::Int) = 2r + 1
const _ST_G_CACHE = Ref{Any}(nothing)   # (objectid(G), r, rτ) => G̃, single entry

function st_G_cached(G, r::Int, rτ::Int)
    key = (objectid(G), r, rτ)
    c = _ST_G_CACHE[]
    (c !== nothing && c[1] == key) && return c[2]
    G̃ = st_augment_G(G, r, rτ)
    _ST_G_CACHE[] = (key, G̃)
    return G̃
end

"""
    st_set_params(model_elements, time_p, model_options)

`set_params` + the appended trend block (initials + placeholder priors for the
sampler's init/step machinery; the hierarchy itself is evaluated in
`st_likeli`). Dispatch guard lives in `set_params`.
"""
function st_set_params(model_elements, time_p, model_options)
    (hasproperty(model_options, :aggregate_rep) && model_options.aggregate_rep == :as_inputs) &&
        error("trend_spec = :stochastic is not implemented for aggregate_rep = :as_inputs")
    prior_objects, meas_ind = estimate_prior(model_elements, model_options)
    param_vector, param_sizes, Σ_ids, priors =
        define_parameter_space(model_elements, model_options, prior_objects)
    r = param_sizes[1][1]
    λs = model_options.trend_lambda_scale
    # initials in RAW (softplus) coordinates: sp(-3)≈0.05, sp(0.54)≈1.0; λ starts at its prior scale
    θ0 = [fill(-3.0, r); fill(0.54, r); log(exp(λs) - 1)]
    push!(param_sizes, (st_trend_dim(r),))
    append!(priors, vcat(fill(truncated(Normal(0.0, 0.1), 0.0, Inf), r),
                         fill(truncated(Cauchy(0.0, 1.0), 0.0, Inf), r),
                         [truncated(Cauchy(0.0, λs), 0.0, Inf)]))
    return [param_vector; θ0], param_sizes, priors, meas_ind, Σ_ids
end

"""
    st_define_step_ranges(param_sizes, priors, param_vector)

Baseline `define_step_ranges` leaves the appended trend block UNDEFINED (it
fills through the H block only). This wrapper runs it on the core and appends
ranges in RAW softplus coordinates (sp(-6)≈0.0025 keeps the lower ends
effectively at zero). Dispatch guard at the top of `define_step_ranges`.
"""
function st_define_step_ranges(param_sizes, priors, param_vector)
    r = param_sizes[1][1]
    n_tr = st_trend_dim(r)
    core = define_step_ranges(param_sizes[1:end-1], priors[1:end-n_tr],
                              param_vector[1:end-n_tr])
    return vcat(core, fill((-6.0, 0.5), r), fill((-2.0, 2.0), r), [(-6.0, 0.5)])
end

"""
    st_likeli(model_elements, param_vector, param_sizes, hyperpriors, Σ_ids, model_options; smooth=false)

Fork of `likeli`'s :as_states flow (kept line-compatible on purpose — update
alongside Model.jl) with: trend block stripped from the end, hierarchy
log-prior added, system/G augmented via `st_augment_system`/`st_G_cached`,
and the UNTOUCHED recursions called on the augmented inputs. Smoother output
uses the augmented factor block f̃=[f;τ] — S4 consumers must split it.
"""
function st_likeli(model_elements, param_vector, param_sizes, hyperpriors, Σ_ids, model_options; smooth=false)
    @unpack y, G, u, agg_count = model_elements

    aggregate_rep = hasproperty(model_options, :aggregate_rep) ? model_options.aggregate_rep : :as_states
    aggregate_rep == :as_inputs &&
        error("trend_spec = :stochastic is not implemented for aggregate_rep = :as_inputs")

    r = param_sizes[1][1]
    n_tr = st_trend_dim(r)
    sp(x) = x > 35 ? x : log1p(exp(x))   # overflow-safe softplus (log1p(exp(x)) is Inf beyond x≈709)
    θtr = @view param_vector[end-n_tr+1:end]
    # A wandering DIME proposal can put a raw coordinate far outside the
    # softplus range: λ·ψ then becomes 0·Inf = NaN and Normal() throws, killing
    # the whole run (HANK 1, 2026-08-28, iteration 351/400). Reject such points
    # like the baseline rejects out-of-support draws instead of erroring.
    any(!isfinite, θtr) && return smooth ? (nothing, -1.e12, true) : (-1.e12, true)
    ω_τ = sp.(θtr[1:r])
    ψ = sp.(θtr[r+1:2r])
    λ = sp(θtr[end])
    if !(isfinite(λ) && λ > 0) || any(x -> !(isfinite(x) && x > 0), ψ) || any(!isfinite, ω_τ)
        return smooth ? (nothing, -1.e12, true) : (-1.e12, true)
    end

    core = param_vector[1:end-n_tr]
    core_sizes = param_sizes[1:end-1]

    n_hyper = core_sizes[end][1]
    hyper_params = core[end-n_hyper+1:end]
    other_params = core[1:end-n_hyper]

    local priors
    try
        priors = get_priors(model_elements, model_options, hyper_params)
    catch e
        return smooth ? (nothing, -1.e12, true) : (-1.e12, true)
    end
    push!(priors, hyperpriors...)

    A, B, C, D, Ω_var, Ω_corr, Σ = matrisize(other_params, core_sizes; aggregate_rep=aggregate_rep)

    log_P, alarm = prioreval([[A..., B..., C..., diag(D)...], Ω_var, Ω_corr, Matrix(Σ), hyper_params], priors, core_sizes)

    # global–local hierarchy (evaluated on the positive scale, cf. header note)
    log_P += sum(logpdf.(Normal.(0.0, λ .* ψ), ω_τ)) + r * log(2)
    log_P += sum(logpdf.(Cauchy(0.0, 1.0), ψ)) + r * log(2)
    log_P += logpdf(Cauchy(0.0, model_options.trend_lambda_scale), λ) + log(2)

    # Stationarity guard (stationarity_cap; Inf = off, baseline behavior):
    # explosive A invalidates lyapd initialization, forecasts, FEVD and HD
    # even when the in-sample smoothed fit looks fine (5f pf HANK, 2026-09-10)
    if hasproperty(model_options, :stationarity_cap) && isfinite(model_options.stationarity_cap) &&
       maximum(abs, eigvals(A)) > model_options.stationarity_cap
        return smooth ? (nothing, -1.e12, true) : (-1.e12, true)
    end

    Ω_var[diagind(Ω_var)] = log.(exp.(Ω_var[diagind(Ω_var)]) .+ 1)

    mat_Ω_corr = Matrix(Ω_corr)
    if !all(isapprox(diag(mat_Ω_corr), ones(size(mat_Ω_corr, 1))))
        return smooth ? (nothing, -1.e12, true) : (-1.e12, true)
    end
    Ω = Ω_var * mat_Ω_corr * Ω_var'

    if alarm
        return smooth ? (nothing, log_P - 1.e12, true) : (log_P - 1.e12, alarm)
    end

    Σ = apply_measurement_criteria(Σ, Σ_ids, model_options, agg_count)
    cond = Σ .> 10
    Σ[.!cond] .= log.(exp.(Σ[.!cond]) .+ 1)

    Ω_f = Ω[1:size(A, 1), 1:size(A, 1)]
    Ω_y = Ω[size(A, 1)+1:end, size(A, 1)+1:end]

    Ã, B̃, C̃, Ω̃_f = st_augment_system(A, B, C, Ω_f, ω_τ)
    G̃ = st_G_cached(G, size(A, 1), r)

    if smooth
        smoother_output, log_D, alarm = recurse_kalman_filter_smoother(Ã, B̃, C̃, D, Ω̃_f, Ω_y, Σ, G̃, y)
        return st_collapse_smoother(smoother_output, size(A, 1), r), log_P + log_D, alarm
    else
        local log_D, alarm2
        try
            log_D, alarm2 = recurse_kalman_filter_forward(Ã, B̃, C̃, D, Ω̃_f, Ω_y, Σ, G̃, y)
        catch e
            log_D = -1.e12
            alarm2 = true
        end
        return log_P + log_D, alarm2
    end
end


# ── S4: state collapse at the smoother boundary ─────────────────────────────
# Under :stochastic the states are [f̃(4 lags), a] with f̃ = [f; τ]. Since the
# measurement loads Λ on (f + τ), collapsing f_lag ← f_lag + τ_lag (variances:
# var(f)+var(τ)+2cov; cross-covs likewise) returns baseline-shaped
# SmootherResults — EVERY downstream consumer (reconstruction, anatomy,
# draws, forecasts) works unchanged. Raw τ levels are stashed in ST_LAST_TAU
# ("f̃-block τ at lag 0", r × T) for S5 diagnostics.
const ST_LAST_TAU = Ref{Any}(nothing)

function st_collapse_index(r::Int, rτ::Int, q::Int)
    r̃ = r + rτ
    fidx = vcat([lag*r̃ .+ (1:r) for lag in 0:3]...)
    τidx = vcat([lag*r̃ + r .+ (1:rτ) for lag in 0:3]...)
    aidx = 4r̃ .+ (1:q)
    return fidx, τidx, aidx
end

function st_collapse_smoother(sm, r::Int, rτ::Int)
    n_aug = size(sm.x_smoothed, 1)
    q = n_aug - 4 * (r + rτ)
    fidx, τidx, aidx = st_collapse_index(r, rτ, q)
    keep = vcat(fidx, aidx)                       # baseline layout order
    Tn = size(sm.x_smoothed, 2)
    ST_LAST_TAU[] = sm.x_smoothed[τidx[1:rτ], :]  # τ_t at lag 0
    coll_x(X) = begin
        Xc = X[keep, :]
        Xc[1:4r, :] .+= X[τidx, :]
        Xc
    end
    coll_P(P) = begin
        M = zeros(eltype(P), 4r + q, n_aug)       # linear map: collapsed = M * states
        for (i, j) in enumerate(fidx); M[i, j] = 1.0; end
        for (i, j) in enumerate(τidx); M[i, j] = 1.0; end
        for (i, j) in enumerate(aidx); M[4r + i, j] = 1.0; end
        M * P * M'
    end
    SmootherResults(coll_x(sm.x_filtered), map(coll_P, sm.sigma_filtered),
                    coll_x(sm.x_updated), map(coll_P, sm.sigma_updated),
                    coll_x(sm.x_smoothed), map(coll_P, sm.sigma_smoothed),
                    map(coll_P, sm.cross_covariances), coll_x(sm.dε_smoothed))
end

"""
    st_selftest(; r=3, rτ=3, q=2, T=40, n=12, seed=42)

Correctness check for the augmentation: with `ω_τ = 0` (and τ₀ pinned by its
stationary prior at 0), the augmented system must reproduce the baseline
`recurse_kalman_filter_forward` likelihood to machine precision, and with
`ω_τ > 0` it must differ. Runs on synthetic matrices; requires Model.jl in
scope. Returns `true` on success.
"""
function st_selftest(; r = 3, rτ = 3, q = 2, T = 40, n = 12, seed = 42)
    rng = Random.MersenneTwister(seed)
    A = 0.6 .* Matrix(Diagonal(rand(rng, r))) .+ 0.05 .* randn(rng, r, r)
    while maximum(abs.(eigvals(A))) >= 0.95
        A .*= 0.9
    end
    B = 0.1 .* randn(rng, r, q)
    C = 0.1 .* randn(rng, q, r)
    D = 0.5 .* Matrix(Diagonal(rand(rng, q)))
    Ω_f = let M = randn(rng, r, r); Matrix(Symmetric(M * M' ./ r + I)) end
    Ω_y = let M = randn(rng, q, q); Matrix(Symmetric(M * M' ./ q + I)) end
    Σ = 0.5 .* ones(n)
    y = randn(rng, n, T)
    G = [begin
             Gt = zeros(n, 4r + q)
             Gt[:, 1:r] .= randn(rng, n, r)          # quarterly rows on f_t
             Gt[:, 4r+1:end] .= 0.1 .* randn(rng, n, q)
             Gt
         end for _ in 1:T]

    base, _ = recurse_kalman_filter_forward(A, B, C, D, Ω_f, Ω_y, Σ, G, y)

    G̃ = st_augment_G(G, r, rτ)
    Ã0, B̃0, C̃0, Ω̃0 = st_augment_system(A, B, C, Ω_f, zeros(rτ))
    aug0, _ = recurse_kalman_filter_forward(Ã0, B̃0, C̃0, D, Ω̃0, Ω_y, Σ, G̃, y)

    Ã1, B̃1, C̃1, Ω̃1 = st_augment_system(A, B, C, Ω_f, 0.3 .* ones(rτ))
    aug1, _ = recurse_kalman_filter_forward(Ã1, B̃1, C̃1, D, Ω̃1, Ω_y, Σ, G̃, y)

    ok_equal = isapprox(base, aug0; rtol = 1e-9)
    ok_moves = !isapprox(base, aug1; rtol = 1e-6)
    ok_equal || @warn "st_selftest: ω_τ=0 does NOT reproduce baseline ($base vs $aug0)"
    ok_moves || @warn "st_selftest: ω_τ>0 does not change the likelihood"
    return ok_equal && ok_moves
end
