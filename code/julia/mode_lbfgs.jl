# mode_lbfgs.jl — climb the log-posterior from an existing chain mode with L-BFGS (threaded central finite differences,
# no AD), as an INITIALIZER for DIME: the DIME ensemble of the baseline was still climbing a narrow ridge at 6,000
# iterations (−53,540 @1600 → −52,615 @6000) and BBO, the stage that seeds it, stops ~12,500 log points lower. The optimum
# found here is not a result; it seeds a re-run (make_init_checkpoint.jl) whose posterior is what gets reported.
#   DD_EXAMPLE=replication DD_TAG=" it6000 scf22" DD_AGG_MEAS=tight DD_INC_SHIFT=1 \
#   DD_MODEOPT_START=" seed2 scf22" DD_MODEOPT_NAME=from_seed2_1600 DD_MODEOPT_HOURS=2 [DD_MODEOPT_HESS=1] \
#     julia --project=5_Code/code/julia/env --threads=80 5_Code/code/julia/mode_lbfgs.jl       (Marvin: marvin/modeopt.sbatch)
# DD_TAG fixes data, priors and the output run folder; DD_MODEOPT_START is the tag whose from_mcmc mode is the start
# (same spec, only the start vector differs). Output: 7_Results/<m_label><DD_TAG>/mode_search/<DD_MODEOPT_NAME>/
#   trace.csv (iteration, log-post, ‖g‖∞, max |eig[A B; C D]|, seconds), x_checkpoint.csv (every 25 iterations),
#   x_opt.csv (one value per row, like store_optim_estimate), summary.csv / summary.txt (log-post split, block summaries,
#   factor FEVD at start and optimum, mode dynamics), hessian.jld2 + hessian_eigs.csv (DD_MODEOPT_HESS=1).
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using Statistics, LinearAlgebra, Printf, DelimitedFiles, Random

# DD_MODEOPT_START is a DD_TAG-style suffix (" seed2 scf22"); the full tag keeps the spec part of model_options.tag
const START_SUFFIX = get(ENV, "DD_MODEOPT_START", get(ENV, "DD_TAG", ""))
const START_TAG = model_options.tag[1:end-length(get(ENV, "DD_TAG", ""))] * START_SUFFIX
const NAME = get(ENV, "DD_MODEOPT_NAME", "from_" * replace(strip(START_SUFFIX), " " => "_"))
const MAXIT = parse(Int, get(ENV, "DD_MODEOPT_MAXIT", "100000"))
const HOURS = parse(Float64, get(ENV, "DD_MODEOPT_HOURS", "2"))
const DO_HESS = get(ENV, "DD_MODEOPT_HESS", "0") == "1"
const OUT = joinpath(RESULTS_DIR, measures_folder(model_options.measures) * model_options.tag, "mode_search", NAME)
mkpath(OUT)
@info "mode_lbfgs: start = mode of $(repr(START_TAG)), budget $(HOURS) h / $(MAXIT) iterations, $(Threads.nthreads()) threads → $OUT"

func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)
x0 = Vector{Float64}(get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, START_TAG))
const n = length(x0)

# ── objective ───────────────────────────────────────────────────────────────────────────────────────────────────────────
logpost(x) = likeli(model_elements, x, param_sizes, hyperpriors, Σ_ids, model_options)[1]
const CLIFF = -1e11            # likeli returns −1e12 off the stationarity cap / on Cholesky failures: a wall, not a value
f(x) = (v = logpost(x); (isfinite(v) && v > CLIFF) ? -v : Inf)
logpost(x0)                    # serial warm-up: fills the lazy G caches before the first threaded batch (as DIMESampler does)
t0 = time()
lp0 = logpost(x0)
@info @sprintf("log-posterior at the start: %.3f (%.2f s per evaluation)", lp0, time() - t0)

# central differences, one coordinate per thread; a coordinate whose stencil hits the wall falls back to a one-sided step
hstep(x) = 1e-4 .* max.(1.0, abs.(x))
function fd_gradient!(g, x, f0; h = hstep(x))
    Threads.@threads for i in 1:n
        xp = copy(x); xm = copy(x)
        xp[i] += h[i]; xm[i] -= h[i]
        fp = f(xp); fm = f(xm)
        g[i] = if isfinite(fp) && isfinite(fm)
            (fp - fm) / (2h[i])
        elseif isfinite(fp)
            (fp - f0) / h[i]
        elseif isfinite(fm)
            (f0 - fm) / h[i]
        else
            0.0
        end
    end
    return g
end

# ── gradient check at the start (step size and a directional derivative) ───────────────────────────────────────────────
f0 = f(x0)
g1 = zeros(n); g2 = zeros(n)
tg = time(); fd_gradient!(g1, x0, f0); tg = time() - tg
fd_gradient!(g2, x0, f0; h = hstep(x0) ./ 10)
Random.seed!(1)
d = randn(n); d ./= norm(d); ε = 1e-4
dd_fd = (f(x0 .+ ε .* d) - f(x0 .- ε .* d)) / (2ε)
@info @sprintf("gradient check: %.1f s per gradient; ‖g‖∞ = %.3f; h vs h/10: max |Δ| = %.4f, corr = %.6f; directional derivative g·d = %.5f vs FD %.5f",
               tg, maximum(abs, g1), maximum(abs, g1 .- g2), cor(g1, g2), dot(g1, d), dd_fd)

# ── block helpers (same layout as matrisize; hyperparameters last) ──────────────────────────────────────────────────────
n_h = param_sizes[end][1]
softplus(x) = log(exp(x) + 1)
function joint_maxeig(x)
    A, B, C, D, _, _, _ = matrisize(x[1:end-n_h], param_sizes)
    return maximum(abs, eigvals([A B; C D]))
end
function split_lp(x)
    hp = x[end-n_h+1:end]
    pri = get_priors(model_elements, model_options, copy(hp)); push!(pri, hyperpriors...)
    A, B, C, D, Ωv, Ωc, Σ = matrisize(x[1:end-n_h], param_sizes)
    logP, _ = prioreval([[A..., B..., C..., diag(D)...], Ωv, Ωc, Matrix(Σ), hp], pri, param_sizes;
                        agg_meas_tight = hasproperty(model_options, :agg_meas_prior) && model_options.agg_meas_prior == :tight)
    tot = logpost(x)
    return tot, logP, tot - logP
end
function factor_fevd(x)        # the mode row of fevd_factor_draws.jl
    A, B_mat, C, D, Ω_var, Ω_corr, _ = matrisize(x[1:end-n_h], param_sizes)
    Ω_var[diagind(Ω_var)] = softplus.(Ω_var[diagind(Ω_var)])
    Ω = Ω_var * Matrix(Ω_corr) * Ω_var'
    r, q = size(B_mat)
    Φ = zeros(4r + q, 4r + q)
    Φ[1:r, 1:r] .= A; Φ[1:r, 4r+1:4r+q] .= B_mat
    for k in 1:3; Φ[k*r+1:(k+1)*r, (k-1)*r+1:k*r] .= Matrix(I, r, r); end
    Φ[4r+1:end, 1:r] .= C; Φ[4r+1:end, 4r+1:end] .= D
    ids = vcat(1:r, 4r+1:4r+q)
    return fevd_factor_shares(Φ[ids, ids], Ω; r, q, horizon = 20, shock_order = :agg_first)
end
function block_summary(x)
    A, B, C, D, Ωv, Ωc, Σ = matrisize(x[1:end-n_h], param_sizes)
    r, q = size(B); R = Matrix(Ωc)
    sd = softplus.(diag(Ωv)); s = map(v -> v > 10 ? v : softplus(v), diag(Matrix(Σ)))
    off(M) = [M[i, j] for i in axes(M, 1), j in axes(M, 2) if i > j]
    return (eigA = maximum(abs, eigvals(A)), eigPhi = maximum(abs, eigvals([A B; C D])), diagA = mean(diag(A)), diagD = mean(diag(D)),
            normB = norm(B), normC = norm(C), sd_f = mean(sd[1:r]), sd_a = mean(sd[r+1:end]),
            corr_ff = mean(abs, off(R[1:r, 1:r])), corr_aa = mean(abs, off(R[r+1:end, r+1:end])), corr_fa = mean(abs, R[r+1:end, 1:r]),
            sigma_med = median(s), diagA_vec = diag(A), sd_f_vec = sd[1:r])
end

# ── L-BFGS ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
best = Ref((f0, copy(x0)))
function fg!(F, G, x)
    v = f(x)
    v < best[][1] && (best[] = (v, copy(x)))
    G === nothing || fd_gradient!(G, x, v)
    return v
end
trace_path = joinpath(OUT, "trace.csv")
open(trace_path, "w") do io; println(io, "iteration,logpost,gnorm_inf,maxeig,seconds"); end
t_start = time()
function cb(st)
    xb = best[][2]
    open(trace_path, "a") do io
        @printf(io, "%d,%.4f,%.5f,%.4f,%.1f\n", st.iteration, -st.value, st.g_norm, joint_maxeig(xb), time() - t_start)
    end
    st.iteration % 25 == 0 && writedlm(joinpath(OUT, "x_checkpoint.csv"), xb, ',')
    return false
end
res = Optim.optimize(Optim.only_fg!(fg!), x0,
                     Optim.LBFGS(m = 20, linesearch = LineSearches.BackTracking(order = 3)),
                     Optim.Options(iterations = MAXIT, g_abstol = 1e-2, time_limit = HOURS * 3600, callback = cb,
                                   show_trace = false, show_every = 1))   # Optim calls the callback only every show_every
x_opt = best[][2]
writedlm(joinpath(OUT, "x_opt.csv"), x_opt, ',')
@info "L-BFGS: $(Optim.iterations(res)) iterations in $(round((time() - t_start) / 60, digits = 1)) min; " *
      "converged = $(Optim.converged(res)); log-post $(round(lp0, digits = 2)) → $(round(-best[][1], digits = 2))"

# ── summary: start vs optimum ───────────────────────────────────────────────────────────────────────────────────────────
rows = NamedTuple[]
for (lab, x) in (("start", x0), ("optimum", x_opt))
    tot, lp, ll = split_lp(x); b = block_summary(x); sh = factor_fevd(x)
    push!(rows, (; label = lab, logpost = tot, logprior = lp, loglik = ll, fevd_mean = mean(sh),
                 fevd = join(round.(sh, digits = 1), " "), b.eigA, b.eigPhi, b.diagA, b.diagD, b.normB, b.normC, b.sd_f, b.sd_a,
                 b.corr_ff, b.corr_aa, b.corr_fa, b.sigma_med, diagA_vec = join(round.(b.diagA_vec, digits = 2), " "),
                 sd_f_vec = join(round.(b.sd_f_vec, digits = 3), " ")))
end
summ = DataFrame(identity.(rows))
summ.start_tag .= strip(START_TAG); summ.name .= NAME; summ.iterations .= Optim.iterations(res)
summ.minutes .= round((time() - t_start) / 60, digits = 1); summ.gnorm_final .= Optim.g_residual(res)
summ.dist_from_start .= [0.0, norm(x_opt - x0)]
CSV.write(joinpath(OUT, "summary.csv"), summ)
open(joinpath(OUT, "summary.txt"), "w") do io
    for r in eachrow(summ)
        @printf(io, "%-8s log-post %.2f = prior %.2f + lik %.2f | FEVD agg share mean %.1f [%s] | max|eig| A %.3f Φ %.3f | diag A %.3f diag D %.3f | ‖B‖ %.3f ‖C‖ %.3f | sd_f %.3f sd_a %.3f | |corr| ff %.3f aa %.3f fa %.3f | Σ med %.4f\n",
                r.label, r.logpost, r.logprior, r.loglik, r.fevd_mean, r.fevd, r.eigA, r.eigPhi, r.diagA, r.diagD, r.normB, r.normC,
                r.sd_f, r.sd_a, r.corr_ff, r.corr_aa, r.corr_fa, r.sigma_med)
        println(io, "         diag A by factor: ", r.diagA_vec, " | factor shock sd: ", r.sd_f_vec)
    end
end
println(read(joinpath(OUT, "summary.txt"), String))
report_mode_dynamics(x0, param_sizes, model_options; label = "Mode dynamics at the START")
report_mode_dynamics(x_opt, param_sizes, model_options; label = "Mode dynamics at the OPTIMUM")

# ── optional: finite-difference Hessian at the optimum (4-point stencil, threaded over pairs) ───────────────────────────
if DO_HESS
    th = time()
    hh = 1e-3 .* max.(1.0, abs.(x_opt))
    pairs = [(i, j) for i in 1:n for j in i:n]
    Hv = zeros(length(pairs))
    Threads.@threads for k in eachindex(pairs)
        i, j = pairs[k]
        xpp = copy(x_opt); xpm = copy(x_opt); xmp = copy(x_opt); xmm = copy(x_opt)
        xpp[i] += hh[i]; xpp[j] += hh[j]; xpm[i] += hh[i]; xpm[j] -= hh[j]
        xmp[i] -= hh[i]; xmp[j] += hh[j]; xmm[i] -= hh[i]; xmm[j] -= hh[j]
        Hv[k] = (f(xpp) - f(xpm) - f(xmp) + f(xmm)) / (4 * hh[i] * hh[j])
    end
    H = zeros(n, n)
    for (k, (i, j)) in enumerate(pairs); H[i, j] = Hv[k]; H[j, i] = Hv[k]; end
    H = Symmetric(H)      # Hessian of −log-post: positive definite at a proper maximum
    ev = eigvals(H)
    JLD2.jldsave(joinpath(OUT, "hessian.jld2"); H = Matrix(H), x_opt = x_opt, h = hh)
    writedlm(joinpath(OUT, "hessian_eigs.csv"), ev, ',')
    @info @sprintf("Hessian (%.1f min): eigenvalues min %.3g, median %.3g, max %.3g; %d negative, %d below 1e-3·max (flat directions)",
                   (time() - th) / 60, minimum(ev), median(ev), maximum(ev), count(<(0), ev), count(<(1e-3 * maximum(ev)), ev))
end
@info "mode_lbfgs done → $OUT"
