# make_init_checkpoint.jl — seed a DIME run from an L-BFGS optimum (mode_lbfgs.jl): writes the checkpoint file that
# DIMESampler.jl loads under DD_RESUME=1 (keys x = ndim × nchain, lprob, it = 0, niter), under a NEW tag so no existing
# run is touched. The ensemble is the final ensemble of a finished run recentred on the optimum (DIME's DE steps and
# AIMH proposal scale with the ensemble spread, so a tight cloud would crawl), with every 10th chain set exactly to the
# optimum (as the BBO mode is injected on a fresh start); chains beyond the joint stationarity cap are shrunk as
# DIMESampler does. Alternative DD_INIT_CLOUD=laplace: x_opt + chol(H⁻¹) z from hessian.jld2 (needs all eigenvalues > 0).
#   DD_EXAMPLE=replication DD_TAG=" init scf22" DD_AGG_MEAS=tight DD_INC_SHIFT=1 DD_NITER=1600 \
#   DD_INIT_XOPT="7_Results/… it6000 scf22/mode_search/from_it6000/x_opt.csv" DD_INIT_ENSEMBLE=" it6000 scf22" \
#     julia --project=5_Code/code/julia/env --threads=80 5_Code/code/julia/make_init_checkpoint.jl
# then: DD_RESUME=1 DD_NITER=1600 DD_TAG=" init scf22" … sbatch 5_Code/marvin/estimation.sbatch
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using Statistics, LinearAlgebra, DelimitedFiles, Random, Printf

const XOPT = ENV["DD_INIT_XOPT"]
# DD_INIT_ENSEMBLE is a DD_TAG-style suffix; the full tag keeps the spec part of model_options.tag
const ENS_TAG = model_options.tag[1:end-length(get(ENV, "DD_TAG", ""))] * get(ENV, "DD_INIT_ENSEMBLE", " it6000 scf22")
const CLOUD = get(ENV, "DD_INIT_CLOUD", "ensemble")      # ensemble | laplace
const NITER = parse(Int, get(ENV, "DD_NITER", "1600"))
const INJECT_EVERY = parse(Int, get(ENV, "DD_INIT_INJECT", CLOUD == "laplace" ? "0" : "10"))

func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)
m_label = measures_folder(model_options.measures)
x_opt = vec(readdlm(isabspath(XOPT) ? XOPT : joinpath(BASE_PATH, XOPT), ','))
length(x_opt) == length(param_vector) || error("x_opt has $(length(x_opt)) entries, the spec has $(length(param_vector))")

ckpt_out = joinpath(BASE_PATH, "posterior_draws", m_label * "_$(model_options.tag)" * "_checkpoint.jld2")
isfile(ckpt_out) && error("refusing to overwrite an existing checkpoint: $ckpt_out (pick another DD_TAG)")

logpost(x) = likeli(model_elements, x, param_sizes, hyperpriors, Σ_ids, model_options)[1]
lp_opt = logpost(x_opt)                       # also the serial warm-up of the lazy caches
@info @sprintf("optimum from %s: log-post %.2f", XOPT, lp_opt)

# joint stationarity cap, as DIMESampler.jl (joint_radius / shrink_to_cap!)
capv = hasproperty(model_options, :stationarity_cap) && isfinite(model_options.stationarity_cap) ? model_options.stationarity_cap : Inf
r = param_sizes[1][1]; q = param_sizes[2][2]
lA = r * r; lB = r * q; lC = q * r
function joint_radius(col)
    all(isfinite, @view col[1:lA+lB+lC+q]) || return NaN
    Φj = [reshape(col[1:lA], r, r) reshape(col[lA+1:lA+lB], r, q);
          reshape(col[lA+lB+1:lA+lB+lC], q, r) diagm(col[lA+lB+lC+1:lA+lB+lC+q])]
    return maximum(abs, eigvals(Φj))
end
function shrink_to_cap!(col)
    isfinite(capv) || return col
    ρ = joint_radius(col)
    (isfinite(ρ) && ρ > capv) || return col
    @views col[1:lA+lB+lC+q] .*= 0.98 * capv / ρ
    return col
end

if CLOUD == "laplace"
    # Laplace cloud: x_opt + chol(H⁻¹) z, H the finite-difference Hessian of −log-post at the optimum (mode_lbfgs.jl,
    # DD_MODEOPT_HESS=1; DD_INIT_HESS = its path, default hessian.jld2 next to x_opt). FD noise and flat ridge directions
    # give small or negative eigenvalues: they are floored at DD_INIT_EIGFLOOR × λ_max (default 1e-4) before inverting, so
    # the cloud is widest along the flat directions without running off. Chains land ~ndim/2 ≈ 243 log points below the
    # optimum, i.e. in the typical set, which is what the DE and AIMH proposals need (an ensemble recentred on the optimum
    # put the median chain 2 million log points down and 1,594 of 1,944 beyond the stationarity cap, 2026-10-24).
    hpath = get(ENV, "DD_INIT_HESS", joinpath(dirname(isabspath(XOPT) ? XOPT : joinpath(BASE_PATH, XOPT)), "hessian.jld2"))
    hz = JLD2.load(isabspath(hpath) ? hpath : joinpath(BASE_PATH, hpath))
    H = Symmetric(hz["H"]); F = eigen(H)
    floor_rel = parse(Float64, get(ENV, "DD_INIT_EIGFLOOR", "1e-4"))
    λ = max.(F.values, floor_rel * maximum(F.values))
    @info @sprintf("Hessian: %d eigenvalues, %d negative, %d floored at %.3g (max %.3g, median %.3g)", length(λ), count(<(0), F.values),
                   count(F.values .< floor_rel * maximum(F.values)), floor_rel * maximum(F.values), maximum(F.values), median(F.values))
    Lc = F.vectors * Diagonal(1 ./ sqrt.(λ))          # Lc Lcᵀ = (V Λ Vᵀ)⁻¹
    nchain = parse(Int, get(ENV, "DD_INIT_NCHAIN", string(4 * length(x_opt))))
    Random.seed!(20261024)
    x_init = x_opt .+ Lc * randn(length(x_opt), nchain)
    sds = sqrt.(vec(sum(Lc .^ 2, dims = 2)))
    @info @sprintf("Laplace cloud: %d chains; parameter sd min %.4f, median %.4f, max %.4f", nchain, minimum(sds), median(sds), maximum(sds))
else
    ens_path = joinpath(BASE_PATH, "posterior_draws", m_label * "_$(ENS_TAG)" * "_checkpoint.jld2")
    ck = JLD2.load(ens_path)
    x_ens = ck["x"]; size(x_ens, 1) == length(x_opt) || error("ensemble has $(size(x_ens, 1)) parameters")
    x_init = x_opt .+ (x_ens .- mean(x_ens, dims = 2))
    @info @sprintf("ensemble cloud from %s (iteration %d, %d chains): mean |shift| %.3f, ensemble sd median %.3f",
                   ens_path, ck["it"], size(x_ens, 2), mean(abs, x_opt .- mean(x_ens, dims = 2)), median(std(x_ens, dims = 2)))
end
# chain 1 is always the optimum (the resume path's donor = best chain); DD_INIT_INJECT=k > 0 also sets every k-th chain to it
# (as the BBO mode on a fresh start). Default 0 for the Laplace cloud: a block of identical top chains dominates the
# lprob-weighted AIMH covariance and degenerates the proposal.
x_init[:, 1] .= x_opt
INJECT_EVERY > 0 && (x_init[:, 1:INJECT_EVERY:end] .= x_opt)
nshrunk = 0
for j in axes(x_init, 2)
    col = x_init[:, j]
    ρ = joint_radius(col)
    if isfinite(ρ) && ρ > capv
        shrink_to_cap!(col); x_init[:, j] .= col; global nshrunk += 1
    end
end
@info "stationarity cap $capv: $nshrunk of $(size(x_init, 2)) chains shrunk"

lprob = Vector{Float64}(undef, size(x_init, 2))
Threads.@threads for j in axes(x_init, 2)
    lprob[j] = logpost(@view x_init[:, j])
end
ok = isfinite.(lprob) .& (lprob .> -1e11)
@info @sprintf("initial ensemble log-post: %d of %d valid; best %.2f (optimum %.2f), median %.2f, worst valid %.2f",
               count(ok), length(ok), maximum(lprob[ok]), lp_opt, median(lprob[ok]), minimum(lprob[ok]))
JLD2.jldsave(ckpt_out; x = x_init, lprob = lprob, it = 0, niter = NITER)
writedlm(joinpath(BASE_PATH, "posterior_draws", m_label * "_$(model_options.tag)" * "_init_lprob.csv"), lprob, ',')
@info "checkpoint written → $ckpt_out (now run estimation.sbatch with DD_RESUME=1 DD_NITER=$NITER DD_TAG=$(repr(model_options.tag)))"
