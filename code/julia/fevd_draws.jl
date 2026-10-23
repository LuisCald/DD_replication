# ─────────────────────────────────────────────────────────────────────────────
# fevd_draws.jl — the post-estimation FEVD (run_postestimation.jl Step 6: block Cholesky, aggregates first, h = 20,
# observables mapped through the PSID loadings) evaluated on posterior draws instead of the mode only (Oct 2026).
#
# The DIME chains start at the run's mode and stay near it, so the bands describe the uncertainty AROUND that mode;
# they do not bridge different local modes (compare seeds for that).
#
# Run (Marvin, 5_Code/marvin/fevddraws.sbatch; the DD_* switches must match the estimated run):
#   DD_EXAMPLE=replication DD_TAG=" scf22" [DD_AGG_MODE=blocks DD_AGG_SPEC=b11] DD_FEVD_NDRAWS=300 \
#     julia -t 16 --project=5_Code/code/julia/env 5_Code/code/julia/fevd_draws.jl
# Output: 7_Results/aggregate_blocks/<tag>/fevd_draws.csv (one row per draw × item: aggregate share in %)
#         7_Results/aggregate_blocks/<tag>/fevd_draws_summary.csv (mode, median, 5/16/84/95% quantiles)
# ─────────────────────────────────────────────────────────────────────────────

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using Statistics, LinearAlgebra, Random

const NDRAWS = parse(Int, get(ENV, "DD_FEVD_NDRAWS", "300"))
const OUT = joinpath(RESULTS_DIR, "aggregate_blocks", strip(model_options.tag))
mkpath(OUT)
@info "═══ FEVD over posterior draws ═══" model_options.tag NDRAWS Threads.nthreads()

func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)

"""Φ_sub and Ω exactly as run_postestimation.jl Step 6 builds them from a parameter vector."""
function fevd_inputs(par)
    A, B_mat, C, D, Ω_var, Ω_corr, _ = matrisize(st_core_params(par, param_sizes), param_sizes)
    Ω_var[diagind(Ω_var)] = log.(exp.(Ω_var[diagind(Ω_var)]) .+ 1)
    Ω = Ω_var * Matrix(Ω_corr) * Ω_var'
    r, q = size(B_mat)
    Φ = zeros(eltype(A), 4r + q, 4r + q)
    @views begin
        Φ[1:r, 1:r] .= A
        Φ[1:r, 4r+1:4r+q] .= B_mat
        for k in 1:3
            Φ[k*r+1:(k+1)*r, (k-1)*r+1:k*r] .= Matrix(I, r, r)
        end
        Φ[4r+1:end, 1:r] .= C
        Φ[4r+1:end, 4r+1:end] .= D
    end
    ids = vcat(1:r, 4r+1:4r+q)
    return Φ[ids, ids], Ω, r, q
end

"""Aggregate shares (%) of one parameter vector: factors, then measure × group and copula entries."""
function fevd_shares(par)
    Φ_sub, Ω, r, q = fevd_inputs(par)
    tbl, stats = fevd_dist_vs_agg(model_elements, model_options, obs_data, Φ_sub, Ω;
        r, q, horizon = 20, shock_order = :agg_first, data_tag = "PSID", quiet = true)
    rows = [("factor", "f$i", tbl.Variation_from_Aggregates[i]) for i in 1:r]
    for (k, v) in stats
        v isa AbstractDict || continue
        for (g, x) in v
            (x isa AbstractVector && length(x) == 2) && push!(rows, (String(k), String(g), 100 * x[2]))
        end
    end
    return rows
end

# mode (as in post-estimation) and the posterior draws (as survey_loglik_split.jl / MDD.run_mdd read them)
par_mode = get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, model_options.tag)
t_mode = time()
mode_rows = fevd_shares(par_mode)
println(stderr, "FEVD at the mode: $(round(time() - t_mode; digits = 1)) s"); flush(stderr)
f = jldopen(joinpath(BASE_PATH, "posterior_draws", measures_folder(model_options.measures) * "_" * model_options.tag * ".jld2"))
chains = f["d_chains"]; it = size(chains, 1); lprobs = f["lprobs"][end-it+1:end, :]; close(f)
valid = [(i, c) for c in axes(chains, 2) for i in axes(chains, 1) if isfinite(lprobs[i, c]) && lprobs[i, c] > MDD_INVALID]
Random.seed!(20261022)
sel = length(valid) > NDRAWS ? valid[sort(randperm(length(valid))[1:NDRAWS])] : valid
@info "draws: $(size(chains, 1)) iterations × $(size(chains, 2)) chains, $(length(valid)) valid, using $(length(sel))"

# Draws in threaded batches (the FEVD path is thread-safe: its only shared cache, Reconstruction._RQ_CACHE, is
# locked); after each batch the partial results are written and the progress line is flushed, so a time-out keeps
# what was done (Marvin's log files otherwise show buffered output late).
long = DataFrame(draw = Int[], measure = String[], group = String[], aggregate = Float64[])
modedf = DataFrame(measure = first.(mode_rows), group = getindex.(mode_rows, 2), mode = last.(mode_rows))
function write_results(long)
    CSV.write(joinpath(OUT, "fevd_draws.csv"), long)
    summ = combine(groupby(long, [:measure, :group]), :aggregate => median => :median,
        :aggregate => (x -> quantile(x, 0.05)) => :q05, :aggregate => (x -> quantile(x, 0.16)) => :q16,
        :aggregate => (x -> quantile(x, 0.84)) => :q84, :aggregate => (x -> quantile(x, 0.95)) => :q95, nrow => :n)
    summ = leftjoin(summ, modedf, on = [:measure, :group])
    sort!(summ, [:measure, :group])
    CSV.write(joinpath(OUT, "fevd_draws_summary.csv"), summ)
    return summ
end
t0 = time()
res = Vector{Any}(nothing, length(sel))
nfail = Threads.Atomic{Int}(0)
batch = 2 * Threads.nthreads()
for b0 in 1:batch:length(sel)
    ks = b0:min(b0 + batch - 1, length(sel))
    Threads.@threads :dynamic for k in ks
        i, c = sel[k]
        res[k] = try
            fevd_shares(chains[i, c, :])
        catch e
            Threads.atomic_add!(nfail, 1); nothing
        end
    end
    for k in ks, row in something(res[k], [])
        push!(long, (k, row...))
    end
    nrow(long) > 0 && write_results(long)
    println(stderr, "fevd draws: $(last(ks)) / $(length(sel)) done, $(nfail[]) failed, $(round((time() - t0) / 60; digits = 1)) min")
    flush(stderr)
end
@info "evaluated $(length(sel)) draws, $(length(sel) - nfail[]) ok, $(round((time() - t0) / 60; digits = 1)) min"
summ = write_results(long)
show(stdout, filter(r -> r.measure == "factor" || (r.measure in ("consum", "income", "wealth") && r.group in ("bottom50", "next40", "top10")) || (r.measure == "copula"), summ); allrows = true)
println()
@info "═══ done → $OUT ═══"
