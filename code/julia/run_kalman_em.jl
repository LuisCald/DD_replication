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

for it in 1:maxit
    out = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth = true)
    length(out) == 3 || error("likeli returned $(length(out)) values with smooth=true at iteration $(it)")
    sm, ll, alarm = out
    alarm && error("smoother alarm at iteration $(it) — the mode is inconsistent with the updated loadings")
    push!(trace, ll)
    X = sm.x_smoothed
    P = sm.sigma_smoothed
    if size(X, 2) == T + 1                      # drop the initial state if present
        X = X[:, 2:end]; P = P[2:end]
    end
    @assert size(X, 2) == T

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
        if isempty(s) || tr(den[i]) < 1e-12   # never observed with a non-zero loading: keep the row
            n_skipped += 1
            continue
        end
        D = Symmetric(den[i][s, s]) + (1e-10 * tr(den[i]) / length(s)) * I
        Λ_new[i, s] = D \ num[i][s]
    end
    rel = norm(Λ_new - Λ_old) / max(norm(Λ_old), eps())
    push!(dtrace, rel)
    push!(Λ_hist, Λ_new)
    @info "iter $(lpad(it, 3)): loglik $(round(ll; digits = 2))  ‖ΔΛ‖/‖Λ‖ = $(round(rel; sigdigits = 3))" *
          (n_skipped > 0 ? "  ($(n_skipped) rows held)" : "") *
          (it > 1 && ll < trace[end-1] - 1e-6 ? "   (likelihood dipped — allowed for this generalized-EM step, watch that it does not trend down)" : "")
    rebuild_G!(model_elements, Λ_new, W, r, n_coef, n_dfs, N_dist, y_full_raw, Σ̂⁻¹², premult)
    global Λ_old = Λ_new
    rel < tol && (@info "converged at iteration $(it)"; break)
end

# self-check: the second E-step must have seen the first M-step (a stale G in
# the smoother reproduces the first update exactly and 'converges' at once)
if length(Λ_hist) >= 2 && Λ_hist[2] == Λ_hist[1]
    error("iteration 2 reproduced iteration 1 exactly — the smoother did not see the updated loadings (stale G)")
end
ll_end, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
@info "log-likelihood: $(round(ll0; digits = 2)) → $(round(ll_end; digits = 2))  (Δ = $(round(ll_end - ll0; digits = 2)), Λ only, dynamics fixed)"
ll_end == ll0 && @warn "the likelihood did not change at all — check that the loadings actually entered the model"

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
writedlm(joinpath(out_dir, "kalman_em_trace.csv"), hcat(1:length(trace), trace, dtrace), ',')
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
