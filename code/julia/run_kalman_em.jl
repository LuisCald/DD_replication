# ─────────────────────────────────────────────────────────────────────────────
# run_kalman_em.jl — loadings-only Kalman EM (doc/em_and_copula_factors.tex).
#
# Holds A, B, Ω, Σ (and the trend block) at an ESTIMATED MODE, and iterates
#   E-step: Kalman-smooth the factors over every quarter from every dataset
#   M-step: pooled regression of each coefficient on the smoothed factor path,
#           over all datasets and all dates at which that coefficient is
#           observed  —  Λ_i = (Σ z zᵀ + Cov)⁻¹ Σ z y  (restricted to the
#           support of the initial row, so structural zeros are preserved)
# until Λ stops changing. This is the dynamically consistent version of the
# static impute-and-refit EM in perform_pca: SCF's nine waves stop being nine
# isolated snapshots and become anchor points on a path the other surveys help
# trace. Only Λ is updated — the dynamics keep their priors and their sampler.
#
# Whitening. Under pre_multiply = true (the default) the model's y and G are
# Σ̂⁻¹²-whitened by a matrix that is DENSE within each dataset block, so the
# regression is run on the RAW coefficients (model_elements.MV) and the raw
# rebuilt G is re-whitened through the same pre_multiply_part! the prep uses.
# The per-row regression on raw data ignores the cross-row noise correlation
# and the per-(dataset,object) Σ — a consistent but not fully efficient
# estimator, i.e. a generalized-EM step: the likelihood need not rise at every
# iteration, and a small dip is not an error.
#
# Frame: with A, Ω fixed, the smoothed factors live in the frame A describes,
# so the re-estimated Λ stays in that frame. No re-rotation is applied; the
# result is therefore directly usable with the source mode (cheap look) and as
# the starting loadings of a re-estimation. A Procrustes diagnostic at the end
# reports how much of the change is rotation versus real movement.
#
# Usage (config via the usual DD_EXAMPLE / HANK_* switches, with
# HANK_PCA=kalman_em so the tag carries " kem"):
#   DD_EXAMPLE=HANK ... HANK_PCA=kalman_em julia -t 16 --project=... run_kalman_em.jl
# Env:
#   DD_KEM_SOURCE_TAG  tag of the run whose mode to hold fixed
#                      (default: this tag with " kem" removed)
#   DD_KEM_ITERS       max EM iterations (default 50)
#   DD_KEM_TOL         relative Frobenius change in Λ to stop (default 1e-5)
#   DD_KEM_PRIOR_OBS   strength of the pull toward the initial loadings, in
#                      pseudo-observations (default 12 = the complete-case
#                      PCA's own evidence). A loadings-only EM with Ω fixed has
#                      a scale indeterminacy: a factor whose smoothed variance
#                      is tiny gets an enormous loading to compensate (first
#                      run: ‖ΔΛ‖/‖Λ‖ = 716 at iteration 1). The M-step is
#                      therefore MAP with a Gaussian prior centred on Λ_init
#                      whose precision equals the row's average information per
#                      observation times DD_KEM_PRIOR_OBS — a row observed 12
#                      times stays half-way to PCA, a row observed 236 times
#                      moves almost freely. 0 disables it. The regression runs
#                      on ROW-STANDARDISED coefficients so the prior is in each
#                      row's own units (standardisation is per object, so one
#                      copula row can have sd 40 and another 0.1).
#   DD_KEM_MIN_OBS     rows observed fewer times than this are HELD at their
#                      initial loadings (default: complete-case count + 1). A
#                      row seen only in the complete-case columns carries no
#                      information beyond what PCA already used; regressing it
#                      on five smoothed factors from twelve points is noise
#                      (R² ≈ 45% under the null) — the first run's 40–56×
#                      "explosion" was exactly these rows.
#   DD_KEM_DAMP        step damping α in Λ_{k+1} = Λ_k + α (Λ_MAP − Λ_k)
#                      (default 0.5). The raw-data M-step and the whitened
#                      E-step optimise slightly different objectives, so the
#                      undamped iteration overshoots: the first full run rose
#                      ~1000 log-points in 3 iterations, then oscillated with
#                      growing swings and blew up at iteration 29.
#   DD_KEM_PATIENCE    stop after this many iterations without a new best
#                      likelihood (default 5). The SAVED loadings are always
#                      the best-likelihood iterate, never the last one.
#   DD_KEM_POST        1 (default) = hand off to run_postestimation.jl after
# Output (under this tag's from_mcmc/parameter_vectors/):
#   kalman_em_loadings.csv   the new Λ (rows = coefficients, cols = factors)
#   kalman_em_trace.csv      iteration, log-likelihood, ‖ΔΛ‖/‖Λ‖
#   solution<label>_<end>.csv  copied from the source run, so
#                            run_postestimation.jl on this tag has a mode
# ─────────────────────────────────────────────────────────────────────────────
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using DelimitedFiles, LinearAlgebra, Statistics

@info "═══ Kalman EM for the loadings ═══"
@unpack measures, data_cutoffs, tag, case = model_options
hasproperty(model_options, :pca_method) && model_options.pca_method == :kalman_em ||
    error("run with pca_method = :kalman_em (HANK_PCA=kalman_em) so the tag and the loader match")
label    = "3D_$case"
m_label  = measures_folder(measures)
end_year = data_cutoffs["end"] != "" ? data_cutoffs["end"][1:4] : "all"
src_tag  = get(ENV, "DD_KEM_SOURCE_TAG", replace(tag, " kem" => ""))
maxit    = parse(Int, get(ENV, "DD_KEM_ITERS", "50"))
tol      = parse(Float64, get(ENV, "DD_KEM_TOL", "1e-5"))
n0       = parse(Float64, get(ENV, "DD_KEM_PRIOR_OBS", "12"))
α_damp   = parse(Float64, get(ENV, "DD_KEM_DAMP", "0.5"))
patience = parse(Int, get(ENV, "DD_KEM_PATIENCE", "5"))
min_obs_env = get(ENV, "DD_KEM_MIN_OBS", "")
premult  = hasproperty(model_options, :pre_multiply) ? model_options.pre_multiply : true
@info "this tag   : $(tag)"
@info "source mode: $(src_tag)"

out_dir  = BASE_PATH * "/7_Results/$m_label" * "$tag" * "/from_mcmc/parameter_vectors"
kem_file = joinpath(out_dir, "kalman_em_loadings.csv")
warm     = isfile(kem_file)
warm && @warn "a kalman_em_loadings.csv already exists for this tag (written $(Dates.format(Dates.unix2datetime(mtime(kem_file)), "yyyy-mm-dd HH:MM"))) — " *
              "warm-starting from it. If DD_KEM_SOURCE_TAG changed since, delete the file first: the loadings are frame-specific."

# ── prep at the current loadings (the :em initialisation, or the warm start)
const func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)
of_active() && error("run_kalman_em.jl does not support object_factors yet: the M-step would attribute the specific states' contribution to Λ")

# ── the mode we hold fixed
par_final = get_param_vector(measures, :mcmc, label, data_cutoffs, src_tag)
length(par_final) == length(param_vector) ||
    error("source mode has $(length(par_final)) parameters, this configuration has $(length(param_vector)) — " *
          "the source tag ($(src_tag)) was estimated with a different factor count or spec")
report_mode_dynamics(par_final, param_sizes, model_options)
ll0, alarm0 = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
alarm0 && error("the source mode is rejected by the likelihood under the current loadings (alarm) — check tags")
@info "log-likelihood at source mode, current loadings: $(round(ll0; digits = 2))"

# ── geometry
@unpack y, G, Gⱼ, MV, proj, factor_count = model_elements
r       = factor_count
n_coef  = size(proj, 1)
n_dfs   = length(Gⱼ)
N_dist  = n_dfs * n_coef
T       = size(y, 2)
@assert all(size(Gⱼ[j], 1) == n_coef for j in 1:n_dfs) "per-dataset loading blocks must all have $(n_coef) rows"
@assert size(Gⱼ[1], 2) == 4r "expected 4 lag blocks of $(r) factors in Gⱼ, got $(size(Gⱼ[1], 2)) columns"

# RAW coefficients for the regression (model_elements.y is Σ̂⁻¹²-whitened when
# pre_multiply is on; MV holds the un-whitened blocks with the same NaN pattern)
y_raw = Matrix{Float64}(vcat(MV...))
@assert size(y_raw) == (N_dist, T) "vcat(MV...) is $(size(y_raw)), expected ($(N_dist), $(T))"
y_full_raw = vcat(y_raw, y[N_dist+1:end, :])          # aggregate rows are never whitened
Σ̂⁻¹² = model_elements.boot_noise_processes
if premult
    size(Σ̂⁻¹², 1) == N_dist || error("pre_multiply is on but Σ̂⁻¹² is $(size(Σ̂⁻¹²)), expected $(N_dist)×$(N_dist)")
    @info "pre_multiply = true: regressing on raw coefficients, re-whitening G through pre_multiply_part! each iteration"
end

# lag weights per stacked row: G_j[i, lag block l] = w[ρ, l] · Λ_i  (contemporaneous
# datasets have w = (1,0,0,0); the annual "tent" has w = (¼,¼,¼,¼) on flows)
W = zeros(N_dist, 4)
for j in 1:n_dfs, i in 1:n_coef
    ρ = (j - 1) * n_coef + i
    k = argmax(abs.(proj[i, :]))
    proj[i, k] == 0 && continue
    for l in 1:4
        W[ρ, l] = Gⱼ[j][i, (l - 1) * r + k] / proj[i, k]
    end
end
patterns = unique(eachrow(round.(W; digits = 6)))
@info "lag-weight patterns found across rows: $(length(patterns)) " * join(["(" * join(round.(p; digits = 3), ",") * ")" for p in patterns], " ")

obs_mask = .!isnan.(y_raw)
n_obs_per_coef = [sum(@view obs_mask[i:n_coef:N_dist, :]) for i in 1:n_coef]
@info "observations per coefficient row, pooled over datasets: min $(minimum(n_obs_per_coef)), median $(round(Int, median(n_obs_per_coef))), max $(maximum(n_obs_per_coef)) (complete-case PCA used 12)"

# rows to UPDATE: those with observations beyond the complete-case columns
n_cc    = minimum(n_obs_per_coef)                      # = the complete-case column count
min_obs = isempty(min_obs_env) ? n_cc + 1 : parse(Int, min_obs_env)
update  = [n_obs_per_coef[i] >= min_obs for i in 1:n_coef]
@info "rows updated by the Kalman EM: $(count(update)) of $(n_coef) (observed ≥ $(min_obs) times); " *
      "$(count(!, update)) rows seen only in the $(n_cc) complete-case columns are held at their initial loadings"
# per-row scale of the raw coefficients (pooled over datasets and dates)
row_sd = zeros(n_coef)
for i in 1:n_coef
    vals = Float64[]
    for j in 1:n_dfs
        ρ = (j - 1) * n_coef + i
        for t in 1:T
            obs_mask[ρ, t] && push!(vals, y_raw[ρ, t])
        end
    end
    row_sd[i] = length(vals) > 1 ? std(vals) : 0.0
end
@info "per-row sd of the raw coefficients: median $(round(median(filter(>(0), row_sd)); sigdigits = 3)), " *
      "90th pct $(round(quantile(filter(>(0), row_sd), 0.9); sigdigits = 3)), max $(round(maximum(row_sd); sigdigits = 3)) " *
      "(standardisation is per object, not per row)"

# support of each row: structural zeros (copula-only factors on marginal rows,
# block layouts) stay zero — the regression runs on the non-zero columns only
Λ_init  = copy(proj)
support = [findall(!iszero, Λ_init[i, :]) for i in 1:n_coef]
n_restricted = count(length(s) < r for s in support)
n_restricted > 0 && @info "$(n_restricted) rows have structural zeros in their loadings — those columns are held at zero"

# ── rebuilding G: raw structure exactly as set_measurements, then the same
#    whitening; a NEW vector so any identity-keyed cache is invalidated too
function rebuild_G!(me, Λ, W, r, n_coef, n_dfs, N_dist, y_full_raw, Σ̂⁻¹², premult)
    for j in 1:n_dfs, i in 1:n_coef
        ρ = (j - 1) * n_coef + i
        for l in 1:4
            @views me.Gⱼ[j][i, (l - 1) * r + 1 : l * r] .= W[ρ, l] .* Λ[i, :]
        end
    end
    proj_dist = vcat(me.Gⱼ...)
    G_raw = [copy(g) for g in me.G]                    # keeps the aggregate identity block
    for t in eachindex(G_raw)
        mask = .!isnan.(@view y_full_raw[1:N_dist, t])
        @views G_raw[t][1:N_dist, 1:4r] .= Diagonal(mask) * proj_dist
    end
    if premult
        _, Ĝ = pre_multiply_part!(y_full_raw, G_raw, Σ̂⁻¹², 4r)
        me.G = Ĝ
    else
        me.G = G_raw
    end
    me.proj = Λ
    _ST_G_CACHE[] = nothing                            # stochastic-trend G̃ cache is keyed on objectid(G)
    return me
end

Λ_old  = copy(proj)
Λ_hist = Matrix{Float64}[]
trace  = Float64[]
dtrace = Float64[]
blk(l) = (l - 1) * r + 1 : l * r
Λ_best  = copy(proj)          # the iterate with the highest likelihood is what gets saved
ll_best = -Inf
it_best = 0
stall   = 0
procrustes_rem(A, B) = (F = svd(B' * A); norm(A - B * (F.U * F.Vt)) / max(norm(A), eps()))

for it in 1:maxit
    out = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth = true)
    length(out) == 3 || error("likeli returned $(length(out)) values with smooth=true at iteration $(it)")
    sm, ll, alarm = out
    alarm && error("smoother alarm at iteration $(it) — the mode is inconsistent with the updated loadings")
    push!(trace, ll)
    if ll > ll_best + 1e-6
        global ll_best = ll; global it_best = it; global Λ_best = copy(Λ_old); global stall = 0
    else
        global stall += 1
    end
    it == 1 && abs(ll - ll0) > 1e-6 &&
        @info "note: likeli(smooth=true) at the same parameters gives $(round(ll; digits = 2)) vs $(round(ll0; digits = 2)) from the plain filter (Δ = $(round(ll - ll0; digits = 2))) — pre-existing difference between the forward and smoother recursions; the trace uses the smoother's value throughout"
    X = sm.x_smoothed
    P = sm.sigma_smoothed
    if size(X, 2) == T + 1                      # drop the initial state if present
        X = X[:, 2:end]; P = P[2:end]
    end
    @assert size(X, 2) == T
    if it == 1
        fsd  = [std(X[k, :]) for k in 1:r]
        pvar = [mean(P[t][k, k] for t in 1:T) for k in 1:r]
        @info "smoothed factor path (lag-0 block, f+τ): sd per factor $(round.(fsd; sigdigits = 3)); mean posterior var $(round.(pvar; sigdigits = 3)). " *
              "A factor with sd ≪ 1 is the scale-indeterminacy risk the prior guards against."
        @info "rows observed exactly 12 times (PSID only — the 3D copula): $(count(==(12), n_obs_per_coef)) of $(n_coef)"
        # scale check: y ≈ Λ f, so sd(y) should be of the order ‖Λ col‖ × sd(f).
        # If sd(f) ≪ sd(y)/‖Λ‖ the mode is explaining the data as noise/trend
        # rather than through the cycle factors, and the regression will inflate Λ.
        typ_load = mean(norm(Λ_init[:, k]) for k in 1:r) / sqrt(n_coef)      # typical |Λ_ik|
        @info "scale check — column norms of Λ_init: $(round.([norm(Λ_init[:, k]) for k in 1:r]; sigdigits = 3)) (typical |Λ_ik| ≈ $(round(typ_load; sigdigits = 3))); " *
              "sd of observed raw coefficients: $(round(std(y_raw[obs_mask]); sigdigits = 3)); " *
              "with sd(f) ≈ $(round(mean(fsd); sigdigits = 3)) the factors imply sd(y) ≈ $(round(typ_load * mean(fsd) * sqrt(r); sigdigits = 3)) — the rest is noise/trend"
    end

    num = [zeros(r) for _ in 1:n_coef]
    den = [zeros(r, r) for _ in 1:n_coef]
    for t in 1:T
        F  = [X[blk(l), t] for l in 1:4]
        Pt = P[t]
        for ρ in 1:N_dist
            obs_mask[ρ, t] || continue
            i = (ρ - 1) % n_coef + 1
            w = @view W[ρ, :]
            all(iszero, w) && continue          # row carries no loading in this dataset
            z = w[1] .* F[1]
            for l in 2:4
                w[l] == 0 || (z .+= w[l] .* F[l])
            end
            den[i] .+= z * z'
            for l in 1:4, l2 in 1:4
                (w[l] == 0 || w[l2] == 0) && continue
                @views den[i] .+= (w[l] * w[l2]) .* Pt[blk(l), blk(l2)]
            end
            num[i] .+= z .* y_raw[ρ, t]
        end
    end
    Λ_new = copy(Λ_old)
    n_skipped = 0
    for i in 1:n_coef
        s = support[i]
        if !update[i] || isempty(s) || tr(den[i]) < 1e-12 || row_sd[i] <= 0
            n_skipped += 1
            continue
        end
        # MAP in the row's own units: y/sd_i on z, prior N(Λ_init/sd_i, κ⁻¹ I),
        # κ = n0 × (information per observation); back-transform by sd_i
        κ = n0 > 0 ? n0 * tr(den[i]) / (length(s) * max(n_obs_per_coef[i], 1)) : 1e-10 * tr(den[i]) / length(s)
        D = Symmetric(den[i][s, s]) + κ * I
        Λ_new[i, s] = row_sd[i] .* (D \ (num[i][s] ./ row_sd[i] .+ κ .* Λ_init[i, s] ./ row_sd[i]))
    end
    # damped step (the undamped MAP target is what the stale-G self-check compares:
    # with damping, consecutive Λ differ even when the smoother never moved)
    Λ_map = copy(Λ_new)
    Λ_new = Λ_old .+ α_damp .* (Λ_new .- Λ_old)
    rel = norm(Λ_new - Λ_old) / max(norm(Λ_old), eps())
    if n_skipped == n_coef
        @warn "iteration $(it): no row could be updated (the smoother returned a degenerate path) — stopping; keeping the best iterate"
        break
    end
    if rel > 5
        big = sortperm(vec(sum(abs2, Λ_new - Λ_old; dims = 2)); rev = true)[1:min(8, n_coef)]
        @error "loadings exploded at iteration $(it) (‖ΔΛ‖/‖Λ‖ = $(round(rel; sigdigits = 3))). Largest-moving rows (row, n_obs, max|Λ_new|, max|Λ_old|): " *
               join(["($(i), $(n_obs_per_coef[i]), $(round(maximum(abs, Λ_new[i, :]); sigdigits = 3)), $(round(maximum(abs, Λ_old[i, :]); sigdigits = 3)))" for i in big], " ")
        error("stopping — raise DD_KEM_PRIOR_OBS or inspect the smoothed-factor sd line above")
    end
    push!(dtrace, rel)
    push!(Λ_hist, Λ_map)
    @info "iter $(lpad(it, 3)): loglik $(round(ll; digits = 2))$(it == it_best ? " ★" : "")  ‖ΔΛ‖/‖Λ‖ = $(round(rel; sigdigits = 3))  " *
          "drift vs init (after best rotation) $(round(procrustes_rem(Λ_new, Λ_init); sigdigits = 3))" *
          (n_skipped > 0 ? "  ($(n_coef - n_skipped) rows updated)" : "")
    rebuild_G!(model_elements, Λ_new, W, r, n_coef, n_dfs, N_dist, y_full_raw, Σ̂⁻¹², premult)
    global Λ_old = Λ_new
    if rel < tol
        @info "converged at iteration $(it) (Λ change below $(tol))"; break
    end
    if stall >= patience
        @info "no likelihood improvement for $(patience) iterations — stopping; best was iteration $(it_best)"; break
    end
end
# the loop's last E-step evaluated Λ_old before the final M-step; score that one too
let out = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth = false)
    ll_last = out[1]
    if isfinite(ll_last) && ll_last > ll_best + 1e-6
        global ll_best = ll_last; global it_best = length(trace) + 1; global Λ_best = copy(Λ_old)
    end
end
@info "best iterate: $(it_best) with log-likelihood $(round(ll_best; digits = 2)) — saving that one" *
      (it_best == 0 ? "  ⚠ no iterate beat the start; the initial loadings are kept" : "")
it_best == 0 && (global Λ_best = copy(Λ_init))
rebuild_G!(model_elements, Λ_best, W, r, n_coef, n_dfs, N_dist, y_full_raw, Σ̂⁻¹², premult)
global Λ_old = Λ_best

# self-check: the second E-step must have seen the first M-step (a stale G in
# the smoother reproduces the first update exactly and 'converges' at once)
if length(Λ_hist) >= 2 && Λ_hist[2] == Λ_hist[1]
    error("the M-step target at iteration 2 reproduced iteration 1 exactly — the smoother did not see the updated loadings (stale G)")
end
ll_end, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
@info "log-likelihood: $(round(ll0; digits = 2)) → $(round(ll_end; digits = 2))  (Δ = $(round(ll_end - ll0; digits = 2)), Λ only, dynamics fixed)"
ll_end == ll0 && @warn "the likelihood did not change at all — check that the loadings actually entered the model"

# ── fitted-value scale check per object: sd(Λ_new · f̂) vs sd(y_raw) on the
#    observed cells. A ratio far from 1 for some object means its rows' new
#    loadings are off-scale and the reconstruction will blow up through sinh.
let
    sm_f, _, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth = true)
    Xf = sm_f.x_smoothed[1:r, :]
    fit_raw = Λ_old * Xf                                       # n_coef × T, dataset-invariant part
    cp_s, imm_s = retrieve_cop_and_imm_part(model_options.estimator, length(measures))
    gp_s = cp_s - imm_s
    n_q = (n_coef - gp_s) ÷ length(measures)
    fit_init = Λ_init * Xf
    objs = Tuple{String,UnitRange{Int}}[("copula", 1:gp_s)]
    for (k, m) in enumerate(measures)                # pcf blocks follow the copula in `measures` order (id_dict in set_measurements)
        push!(objs, (m, gp_s + (k - 1) * n_q + 1 : gp_s + k * n_q))
    end
    for (nm, rows) in objs
        sd_new = Float64[]; sd_old = Float64[]; sd_dat = Float64[]
        for j in 1:n_dfs
            ρs = (j - 1) * n_coef .+ rows
            m = obs_mask[ρs, :]
            count(m) > 1 || continue
            push!(sd_new, std(fit_raw[rows, :][m])); push!(sd_old, std(fit_init[rows, :][m])); push!(sd_dat, std(y_raw[ρs, :][m]))
        end
        isempty(sd_dat) && continue
        ratio_new = mean(sd_new) / max(mean(sd_dat), eps())
        ratio_old = mean(sd_old) / max(mean(sd_dat), eps())
        msg = "fitted-value scale — $(nm): sd(Λ·f̂)/sd(y) = $(round(ratio_new; sigdigits = 3)) with the new loadings, $(round(ratio_old; sigdigits = 3)) with the initial ones"
        (ratio_new > 3 || ratio_new < 0.1) ? (@warn msg * "   ⚠ off-scale — the reconstruction of this object will be wrong") : (@info msg)
    end
end

# ── what moved, and how much of it is rotation
cp_k, imm_k = retrieve_cop_and_imm_part(model_options.estimator, length(measures))
gp = cp_k - imm_k
rowchg(A, B, rows) = norm(A[rows, :] - B[rows, :]) / max(norm(B[rows, :]), eps())
@info "relative change in Λ — copula rows: $(round(rowchg(Λ_old, Λ_init, 1:gp); sigdigits = 3)), marginal rows: $(round(rowchg(Λ_old, Λ_init, gp+1:n_coef); sigdigits = 3))"
if r > 1
    Fsv = svd(Λ_init' * Λ_old)                          # Procrustes: closest rotation of Λ_init onto Λ_old
    Q = Fsv.U * Fsv.Vt
    @info "Procrustes: after the best rotation of the initial loadings the remaining change is " *
          "$(round(norm(Λ_old - Λ_init * Q) / max(norm(Λ_old), eps()); sigdigits = 3)) (raw change $(round(norm(Λ_old - Λ_init) / max(norm(Λ_init), eps()); sigdigits = 3))); " *
          "a large gap between the two means the frame drifted, which A and Ω should have pinned"
    rowcor = [cor(Λ_old[i, :], Λ_init[i, :]) for i in 1:n_coef if norm(Λ_init[i, :]) > 0 && norm(Λ_old[i, :]) > 0]
    isempty(rowcor) || @info "row-wise correlation new vs initial loadings: median $(round(median(rowcor); digits = 3)), 10th pct $(round(quantile(rowcor, 0.1); digits = 3))"
end

# ── save under THIS tag; copy the source mode next to it for run_postestimation
mkpath(out_dir)
writedlm(kem_file, Λ_old, ',')
writedlm(joinpath(out_dir, "kalman_em_trace.csv"), vcat(["iter" "loglik" "rel_change" "is_best"],
         hcat(1:length(trace), trace, vcat(dtrace, fill(NaN, length(trace) - length(dtrace))), (1:length(trace)) .== it_best)), ',')
fname   = "solution$label" * "_$end_year" * ".csv"
src_sol = BASE_PATH * "/7_Results/$m_label" * "$src_tag" * "/from_mcmc/parameter_vectors/" * fname
if isfile(src_sol)
    cp(src_sol, joinpath(out_dir, fname); force = true)
    @info "source mode copied to $(joinpath(out_dir, fname))"
else
    writedlm(joinpath(out_dir, fname), par_final, ',')
    @info "source mode written to $(joinpath(out_dir, fname))"
end
@info "Kalman-EM loadings written: $(kem_file)"

# ── chain straight into post-estimation (the cheap look) unless told not to.
# A fresh process, not include(): run_postestimation.jl declares consts that
# would clash with this script's. The ENV (all HANK_* / DD_* switches) is
# inherited, and estimation_prep in that process picks up the loadings file.
if get(ENV, "DD_KEM_POST", "1") == "1"
    post = joinpath(@__DIR__, "run_postestimation.jl")
    cmd  = `$(Base.julia_cmd()) --project=$(Base.active_project()) --threads=$(Threads.nthreads()) $(post)`
    @info "═══ handing off to post-estimation with the new loadings (DD_KEM_POST=0 to skip) ═══"
    run(cmd)
else
    @info "next: run_postestimation.jl with the same switches for the cheap look; run_estimation.jl for the full re-estimation"
end
