# run_dropwave.jl — drop-one-SCF-wave predictions and their score for one finished run
# (fig. recon_missing1 panels g–i; ForecastSSM.perform_iterative_forecast). Parameters
# are fixed at the run's posterior mode; each SCF wave is removed in turn and predicted.
# Writes <results>/from_mcmc/data/SCF_dropwave_scores.csv (+ the iterative panels).
#   DD_EXAMPLE=replication_6_factors julia -t 16 --project=5_Code/code/julia/env 5_Code/code/julia/run_dropwave.jl
# Collect all runs with run_dropwave_table.jl.

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))

@unpack measures, data_cutoffs, tag, case = model_options
label = "3D_$case"
kind_of_plots = :mcmc

const func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)
hyperpriors = st_hyperpriors(priors, param_sizes)
@unpack tmin, tmax = time_params
user_t = (deepcopy(tmin), deepcopy(tmax))

par_final = get_param_vector(measures, kind_of_plots, label, data_cutoffs, tag)
perform_forecast("SCF", par_final, param_sizes, hyperpriors, meas_ind, Σ_ids, 1, obs_data, model_options,
                 model_elements, time_params, user_t, func_data, kind_of_plots, ["iterative"])
