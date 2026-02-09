cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")

const func_data, time_params, model_elements = estimation_prep(obs_data, model_options);
# const (param_vector, param_sizes, priors, meas_ind, Σ_ids)     = set_params(model_elements, time_params, model_options)
const smoother_results, dv, all_chains, diagnos, label = SSM_optimize(model_elements, model_options, mcmc_options, diagnostics_options, obs_data, func_data, time_params);

# logV, alarm                                             =  likeli(model_elements, param_vector, param_sizes, priors, meas_ind, Σ_ids, model_options)
# const chains, lprobs, propdist  = SSM_optimize(model_elements, method_options, mcmc_options, diagnostics_options, obs_data, func_data, time_params);


