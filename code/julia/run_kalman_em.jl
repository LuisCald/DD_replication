# ─────────────────────────────────────────────────────────────────────────────
# run_kalman_em.jl — loadings-only Kalman EM (doc/em_and_copula_factors.tex).
#
# Holds A, B, Ω, Σ (and the trend block) at an ESTIMATED MODE, and iterates
#   E-step: Kalman-smooth the factors over every quarter from every dataset
#   M-step: pooled regression of each coefficient on the smoothed factor path,
#           over all datasets and all dates at which that coefficient is
#           observed  —  Λ_i = (Σ z zᵀ + Cov)⁻¹ Σ z y
# until Λ stops changing. This is the dynamically consistent version of the
# static impute-and-refit EM in perform_pca: SCF's nine waves stop being nine
# isolated snapshots and become anchor points on a path the other surveys help
# trace. Only Λ is updated — the dynamics keep their priors and their sampler.
#
# Frame: with A, Ω fixed, the smoothed factors live in the frame A describes,
# so the re-estimated Λ stays in that frame. No re-rotation is applied; the
# result is therefore directly usable with the source mode (cheap look) and as
# the starting loadings of a re-estimation.
#
# Usage (config via the usual DD_EXAMPLE / HANK_* switches, with
# HANK_PCA=kalman_em so the tag carries " kem"):
#   DD_EXAMPLE=HANK ... HANK_PCA=kalman_em julia -t 16 --project=... run_kalman_em.jl
# Env:
#   DD_KEM_SOURCE_TAG  tag of the run whose mode to hold fixed
#                      (default: this tag with " kem" removed)
#   DD_KEM_ITERS       max EM iterations (default 50)
#   DD_KEM_TOL         relative Frobenius change in Λ to stop (default 1e-5)
# Output (under this tag's from_mcmc/parameter_vectors/):
#   kalman_em_loadings.csv   the new Λ (rows = coefficients, cols = factors)
#   kalman_em_trace.csv      iteration, log-likelihood, ‖ΔΛ‖/‖Λ‖
#   solution<label>_<end>.csv  copied from the source run, so
#                            run_postestimation.jl on this tag has a mode
# Then: run_postestimation.jl (same switches) for the cheap look, or
#       run_estimation.jl for the full re-estimation from the new loadings.
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
@info "this tag   : $(tag)"
@info "source mode: $(src_tag)"

# ── prep at the current loadings (the :em initialisation unless a previous
#    kalman_em_loadings.csv exists for this tag, in which case we warm-start)
const func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)

# ── the mode we hold fixed
par_final = get_param_vector(measures, :mcmc, label, data_cutoffs, src_tag)
report_mode_dynamics(par_final, param_sizes, model_options)
ll0, alarm0 = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
alarm0 && error("the source mode is rejected by the likelihood under the current loadings (alarm) — check tags")
@info "log-likelihood at source mode, current loadings: $(round(ll0; digits = 2))"

# ── geometry
@unpack y, G, Gⱼ, proj, factor_count = model_elements
r       = factor_count
n_coef  = size(proj, 1)
n_dfs   = length(Gⱼ)
N_dist  = n_dfs * n_coef
T       = size(y, 2)
@assert all(size(Gⱼ[j], 1) == n_coef for j in 1:n_dfs) "per-dataset loading blocks must all have $(n_coef) rows"
@assert size(Gⱼ[1], 2) == 4r "expected 4 lag blocks of $(r) factors in Gⱼ, got $(size(Gⱼ[1], 2)) columns"

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

obs_mask = .!isnan.(@view y[1:N_dist, :])
n_obs_per_coef = [sum(@view obs_mask[i:n_coef:N_dist, :]) for i in 1:n_coef]
@info "observations per coefficient row, pooled over datasets: min $(minimum(n_obs_per_coef)), median $(round(Int, median(n_obs_per_coef))), max $(maximum(n_obs_per_coef)) (complete-case PCA used 12)"

# ── the loop
function rebuild_G!(me, Λ, W, r, n_coef, n_dfs, N_dist)
    for j in 1:n_dfs, i in 1:n_coef
        ρ = (j - 1) * n_coef + i
        for l in 1:4
            @views me.Gⱼ[j][i, (l - 1) * r + 1 : l * r] .= W[ρ, l] .* Λ[i, :]
        end
    end
    proj_dist = vcat(me.Gⱼ...)
    for t in 1:size(me.y, 2)
        mask = .!isnan.(@view me.y[1:N_dist, t])
        @views me.G[t][1:N_dist, 1:4r] .= Diagonal(mask) * proj_dist
    end
    me.proj = Λ
    return me
end

Λ_init = copy(proj)
Λ_old  = copy(proj)
trace  = Float64[]
dtrace = Float64[]
blk(l) = (l - 1) * r + 1 : l * r

for it in 1:maxit
    sm, ll, alarm = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth = true)
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
            z = w[1] .* F[1]
            for l in 2:4
                w[l] == 0 || (z .+= w[l] .* F[l])
            end
            den[i] .+= z * z'
            for l in 1:4, l2 in 1:4
                (w[l] == 0 || w[l2] == 0) && continue
                @views den[i] .+= (w[l] * w[l2]) .* Pt[blk(l), blk(l2)]
            end
            num[i] .+= z .* y[ρ, t]
        end
    end
    Λ_new = copy(Λ_old)
    for i in 1:n_coef
        n_obs_per_coef[i] == 0 && continue     # never observed anywhere: keep the initial row
        Λ_new[i, :] = (den[i] + 1e-8I) \ num[i]
    end
    rel = norm(Λ_new - Λ_old) / max(norm(Λ_old), eps())
    push!(dtrace, rel)
    @info "iter $(lpad(it, 3)): loglik $(round(ll; digits = 2))  ‖ΔΛ‖/‖Λ‖ = $(round(rel; sigdigits = 3))" *
          (it > 1 && ll < trace[end-1] - 1e-6 ? "   ⚠ likelihood fell (should be non-decreasing in Λ)" : "")
    rebuild_G!(model_elements, Λ_new, W, r, n_coef, n_dfs, N_dist)
    global Λ_old = Λ_new
    rel < tol && (@info "converged at iteration $(it)"; break)
end
ll_end, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
@info "log-likelihood: $(round(ll0; digits = 2)) → $(round(ll_end; digits = 2))  (Δ = $(round(ll_end - ll0; digits = 2)), Λ only, dynamics fixed)"

# ── what moved
cp_k, imm_k = retrieve_cop_and_imm_part(model_options.estimator, length(measures))
gp = cp_k - imm_k
rowchg(A, B, rows) = norm(A[rows, :] - B[rows, :]) / max(norm(B[rows, :]), eps())
@info "relative change in Λ — copula rows: $(round(rowchg(Λ_old, Λ_init, 1:gp); sigdigits = 3)), marginal rows: $(round(rowchg(Λ_old, Λ_init, gp+1:n_coef); sigdigits = 3))"
rowcor = [cor(Λ_old[i, :], Λ_init[i, :]) for i in 1:n_coef if norm(Λ_init[i, :]) > 0 && norm(Λ_old[i, :]) > 0]
@info "row-wise correlation new vs initial loadings: median $(round(median(rowcor); digits = 3)), 10th pct $(round(quantile(rowcor, 0.1); digits = 3))"

# ── save under THIS tag; copy the source mode next to it for run_postestimation
out_dir = BASE_PATH * "/7_Results/$m_label" * "$tag" * "/from_mcmc/parameter_vectors"
mkpath(out_dir)
writedlm(joinpath(out_dir, "kalman_em_loadings.csv"), Λ_old, ',')
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
@info "Kalman-EM loadings written: $(joinpath(out_dir, "kalman_em_loadings.csv"))"
@info "next: run_postestimation.jl with the same switches for the cheap look; run_estimation.jl for the full re-estimation"
