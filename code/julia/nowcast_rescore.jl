# nowcast_rescore.jl — re-run only the SCF forecast exercises (ForecastSSM.perform_iterative_forecast) for the run
# selected by the DD_* switches, at its stored mode, without the rest of post-estimation: DD_RESCORE=dropwave,nowcast
# (default both). Scores now include the same-trend benchmarks (rmse_trend, skill_trend, corr_cycle, rmse_lastwave,
# skill_lastwave). DD_NOWCAST_TREND=realtime gives the real-time-trend nowcast (*_nowcast_rt*). The run's earlier
# forecast outputs are copied first to 7_Results/<run>/from_mcmc/archive_forecasts_<date>/ and then overwritten.
#   DD_EXAMPLE=replication DD_TAG=" scf22" [DD_AGG_MODE=blocks DD_AGG_SPEC=b5x2 DD_NAF=10] \
#     julia --project=5_Code/code/julia/env 5_Code/code/julia/nowcast_rescore.jl      (Marvin: marvin/nowcast.sbatch)
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
param_vector, param_sizes, priors, meas_ind, Σ_ids = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)
@unpack tmin, tmax = time_params
user_t = (deepcopy(tmin), deepcopy(tmax))
par_final = get_param_vector(model_options.measures, :mcmc, "3D_$(model_options.case)", model_options.data_cutoffs, model_options.tag)
length(par_final) == length(param_vector) || error("mode/spec mismatch")

rd = joinpath(RESULTS_DIR, measures_folder(model_options.measures) * model_options.tag, "from_mcmc")
arch = joinpath(rd, "archive_forecasts_20261022")
mkpath(arch)
for (root, _, files) in walkdir(rd)
    startswith(root, arch) && continue
    for f in files
        (occursin("nowcast", f) || occursin("dropwave", f) || occursin(joinpath("forecasts", "iterative"), root)) || continue
        dst = joinpath(arch, relpath(joinpath(root, f), rd))
        mkpath(dirname(dst)); isfile(dst) || cp(joinpath(root, f), dst)
    end
end
@info "earlier forecast outputs copied to $arch"

const RESCORE = strip.(split(get(ENV, "DD_RESCORE", "dropwave,nowcast"), ","; keepempty = false))
for kind in RESCORE
    perform_forecast("SCF", par_final, param_sizes, hyperpriors, meas_ind, Σ_ids, 1, obs_data, model_options, model_elements,
        time_params, user_t, func_data, :mcmc, ["iterative"]; nowcast = kind == "nowcast")
end
@info "═══ re-scored ($(join(RESCORE, ", "))) → $(joinpath(rd, "data")) ═══"
