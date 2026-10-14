# run_mdd.jl — (re)compute the marginal data density of one finished run from its
# saved posterior draws (posterior_draws/<m_label>_<tag>.jld2); no re-estimation.
# Writes 7_Results/MDD/mdd_<tag>.jld2 (see MDD.jl). Same switches as run_estimation.jl:
#   DD_EXAMPLE=replication_less_af julia -t 16 --project=5_Code/code/julia/env 5_Code/code/julia/run_mdd.jl
# Then collect all rows with run_mdd_table.jl.

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))

const func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)

run_mdd(model_options.tag, model_elements, measures_folder(model_options.measures), param_sizes, priors, meas_ind, Σ_ids, model_options)
