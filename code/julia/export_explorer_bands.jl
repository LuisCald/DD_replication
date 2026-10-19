# ─────────────────────────────────────────────────────────────
# export_explorer_bands.jl — posterior bands for the website's Data Explorer (Oct 2026).
# ─────────────────────────────────────────────────────────────
#
# The explorer plots, for consumption, income and wealth in the PSID view, the share of total, the group
# total and the mean per household of the decile groups D1..D10 and of bottom 50 / next 40 / top 10. This
# script draws DD_N_BAND_DRAWS (default 200) parameter vectors from the posterior and, for each, a path of the
# state around the smoothed mean (reconstruct_data(…; state_draw = true), as generate_credible_bounds does),
# so the bands carry parameter AND factor uncertainty. Groups are computed per draw, not by summing decile
# bands. Writes <results>/from_mcmc/data/explorer_bands.csv: stat, var, group, time, p025, p05, p50, p95, p975.
#
#   DD_EXAMPLE=replication julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/export_explorer_bands.jl
# The website turns the CSV into data/explorer_bands.json (tools/build_explorer_bands.py).
# ─────────────────────────────────────────────────────────────

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
using JLD2, Random, Statistics, DataFrames, CSV

@unpack measures, data_cutoffs, tag, case, estimator = model_options
const m_label = measures_folder(measures)
@info "Preparing functional data (cached)..."
const func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)
@unpack data_sources = func_data
@unpack tmin, tmax = time_params

n_draws = parse(Int, get(ENV, "DD_N_BAND_DRAWS", "200"))
seed = 20261018
postd = jldopen(BASE_PATH * "/posterior_draws/" * m_label * "_$tag.jld2", "r")
chains = postd["d_chains"]
lp = postd["lprobs"][end-size(chains, 1)+1:end, :]
close(postd)
valid = [(i, c) for i in axes(chains, 1), c in axes(chains, 2) if isfinite(lp[i, c]) && lp[i, c] > -1e5]
rng = MersenneTwister(seed)
picks = valid[randperm(rng, length(valid))[1:min(n_draws, length(valid))]]
n_draws = length(picks)
@info "Explorer bands: $n_draws posterior draws (parameter + state), PSID view"

# anchors and households on the model's quarter axis (as in get_implicate!)
gs = deepcopy(obs_data.gdp_series)
gs[!, "date"] = QuarterlyDate.(gs[!, "time"])
filter!(r -> QuarterlyDate(tmin["year"], tmin["quarter"]) <= r.date <= QuarterlyDate(tmax["year"], tmax["quarter"]), gs)
meas_s = sort(measures)
anchor = Matrix(gs[:, [m * "_per_hh" for m in meas_s]])     # T × D
tot_hhs = Vector{Float64}(gs[!, "tot_hhs"])
dates = ["$(year(d))-Q$(quarter(d))" for d in gs.date]
T = length(dates)
K = estimator.grid_pcf
D = length(meas_s)
intervals = vcat([0.0] .+ 1e-6, select_grid_points(10))

"Decile-group means per household (10 × T per measure) from one draw's PSID coefficients."
function decile_means(pcfs)
    X = reshape(pcfs, (K * D, size(pcfs)[end]))
    out = [fill(NaN, 10, T) for _ in 1:D]
    for m in 1:D, t in 1:min(T, size(X, 2))
        c = X[(m-1)*K+1:m*K, t]
        any(isnan, c) && continue
        for i in 1:10
            out[m][i, t] = gauss_legendre_integrate(u -> reverse_inverse_hyperbolic_sine(eval_quantile_function(c, K - 1, u))[1] * anchor[t, m],
                                                    intervals[i], intervals[i+1]) / (intervals[i+1] - intervals[i])
        end
    end
    return out
end

M = [fill(NaN, 10, T, n_draws) for _ in 1:D]                # decile means, per draw
for batch in Iterators.partition(collect(enumerate(picks)), max(1, Threads.nthreads()))
    Threads.@threads for j in eachindex(batch)
        p, (i, c) = batch[j]
        dv, _ = reconstruct_data(chains[i, c, :], param_sizes, hyperpriors, meas_ind, Σ_ids, model_elements, obs_data,
                                 model_options, time_params, data_sources; state_draw = true, rng = MersenneTwister(seed + p))
        dm = decile_means(dv["PSID"]["normal"][2])
        for m in 1:D
            M[m][:, :, p] .= dm[m]
        end
    end
    @info "  draws done: $(batch[end][1]) / $n_draws"
end

groups = vcat(["0.$k" for k in 1:9], ["1.0"])              # D1..D10, the explorer's keys
gsets = ("bottom50" => 1:5, "next40" => 6:9, "top10" => 10:10)
rows = DataFrame(stat = String[], var = String[], group = String[], time = String[], p025 = Float64[], p05 = Float64[], p50 = Float64[], p95 = Float64[], p975 = Float64[])
pct(v) = (w = filter(isfinite, v); isempty(w) ? ntuple(_ -> NaN, 5) : Tuple(quantile(w, [0.025, 0.05, 0.5, 0.95, 0.975])))
for (m, v) in enumerate(meas_s)
    mean_d = M[m]                                            # 10 × T × draws
    total = sum(mean_d; dims = 1)                            # sum of decile means (= 10 × overall mean)
    for t in 1:T
        for (g, idx) in vcat([(groups[k], k:k) for k in 1:10], collect(gsets))
            share = [sum(mean_d[idx, t, d]) / total[1, t, d] for d in 1:n_draws]
            level = [sum(mean_d[idx, t, d]) * 0.1 * tot_hhs[t] / 1e12 for d in 1:n_draws]   # trillions
            meanhh = [mean(mean_d[idx, t, d]) for d in 1:n_draws]
            for (stat, vals) in (("shares", share), ("levels", level), ("quantiles", meanhh))
                push!(rows, (stat, v, g, dates[t], pct(vals)...))
            end
        end
    end
end
out = BASE_PATH * "/7_Results/$m_label$tag/from_mcmc/data/explorer_bands.csv"
CSV.write(out, rows)
@info "Explorer bands written: $out ($(nrow(rows)) rows)"
