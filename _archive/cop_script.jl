# Solving copula Business
include("DistributionalDynamics.jl")


    # Unpack data + necessary options 
    @unpack files, agg_data, df_vec, gdp_series = obs_data
    @unpack estimator, number_of_dfs, measures, lags, freq, agg_freq, case, plot_proof, pca_perspective, rm_seasonality, equivalized, data_cutoffs, data_to_mute = model_options

    # Preliminairies
    init_path     = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) * "/2_Data_processing" : pwd()
    dimension     = length(measures)
    
    @info("Extracting observations Tⱼ of the joint distributions, in alphabetical order of datasets' name.")

    # Collects data for all available years 
    dfs, year_vec, time_dict, freq_type = data_constructor(obs_data, model_options) # TODO: correct freq_type s.t. it makes sense 
    
    # Using time parameters from data and from aggregates, we find an agreeable time frame for the estimation
    time_p               = define_timeframe(agg_data, year_vec, freq_type, time_dict, data_cutoffs) # TODO: time_dict needs to be filtered as well  

    cutoff_bounds        = align_data_with_timeframe!(dfs, year_vec, time_p, data_cutoffs)

    # Pick the key from confidence intervals corresponding to this id 
    if plot_proof 
        id, OD       = df_selector(dfs, df_vec, measures)
        source_of_id = df_vec.df_names[id]

        perform_proof_of_concept_reconstruction(OD, source_of_id, year_vec[id], gdp_series, time_p, freq_type[id], time_dict[id], model_options)  
    end