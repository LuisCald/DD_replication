# Measuring measurement error 
# (3) Estimation procedure for the measurement error
# -> For each time period, for each bootstrap
# ->-> estimate the percentile functions / copula and save them
# ->-> Result: an array of --- N by T_j by 999
# ->->-> For each bootstrap, perform data transformations on each of the time series generated 
# ->->-> Result: transformed N by T_j by 999 array

# To estimate the noise:
# ->-> Approach (1): estimate standard deviation (since the model says each measure is independent)
# ->-> this is done by row of the N by T_j matrix. We will have 999 averages i.e., a distribution, for each time series.
# ->-> From here, we extract the mean.
# ->-> I now perform what I did perform (same as above, but just with the data and not the 999 bootstraps), but estimate a distribution for each object, so, 4 distributions in our case (copula plus marginals) separate.
# ->-> scale the mean and variance of these objects by the mean derived from the bootstrap step (scaled by its precision).

# ->-> We can alternatively define the mean and variance of the measurement errors directly from the distribution of variances, just again, making it object specific, thus, there will be no need to scale anything. The mean and variance of each distribution define the moments of the priors for the measurement errors. The lower bound would be the lowest variance of each distribution. Upper bound is a large positive number or the greatest variance of each distribution.

# ->->->->-> Approach (2): estimate variance covariance
# ->->->->-> We take the N by T_j matrix and compute directly the variance-covariance matrix, for each object, and keep the variances only.
# ->->->->-> we do this 999 times and get 1 distribution of variances and extract the mean
# ->->->->-> I then compute the 4 distributions, one for each object, separate (from raw data and not bootstrap)
# ->->->->-> we can scale the 4 distributions here by the mean or simply break the bootstrap distribution into 4 and define the priors based on the moments of these 4 distributions.

# Hopefully this is correct,
# Luis

function estimate_noise_processes(obs_data, method_options)
    # Correct for family size 
    if method_options.equivalized
        type = "_eq"
    else
        type = ""
    end

    @unpack grid, measures, lags, freq, agg_freq, number_of_dfs, case, pca_perspective, pca_method, plot_proof = method_options
    @unpack files, agg_data, df_vec, gdp_series = obs_data
    number_of_dfs = length(df_vec.data)
    init_path     = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) * "/2_Data_processing" : pwd()
    dimension     = length(measures)
    
    @info("Taking raw data and placing them in the correct containers, sorted in alphabetical order of datasets' name.")
    dfs, year_vec, time_dict, freq_type = data_constructor(obs_data, method_options)

    # Remove seasonality of the data for CEX 
    id_of_cex = findall(x -> x == "CEX", df_vec.df_names)

    if length(id_of_cex) == 1
        id_of_cex = id_of_cex[1]
        dfs[id_of_cex] = X13_seasonality_adjustment!(dfs, id_of_cex)
    end


    # Using time parameters from data and from aggregates, we find an agreeable time frame for the estimation
    time_p               = define_timeframe(agg_data, year_vec, freq_type, time_dict) # TODO: time_dict needs to be filtered as well  

    align_data_with_aggs!(dfs, year_vec)

    for 
    large_bootstrap_object = generate_bootstrap_distributions(df_vec, method_options, init_path, time_p, obs_data)

    # Perform transformations 
    for b in axes(large_bootstrap_object)
        # STEP 1: Detrending
        for j in eachindex(dfs)
            βs[:,:, j], dfs[j], trend[j] = perform_detrending(dfs[j], time_p, year_vec[j], freq, freq_type[j], time_dict[j])
        end

    # Standardization
    pool, means, stds    = perform_standardization(dfs, grid, dimension) 

    # Dimensionality reduction 
    proj, pcs, _ , n_less_than_one, m_pcs, m_proj = perform_pca(pool, measures, :functional_data) 


end