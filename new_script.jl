include("DistributionalDynamics.jl")
datasets = sort(["PSID", "SCF", "CEX_all", "CPS2", "CPS"])

# Unpack data + necessary options 
@unpack files, agg_data, df_vec, gdp_series = obs_data
@unpack estimator, number_of_dfs, measures, lags, freq, agg_freq, case, plot_proof, pca_perspective, rm_seasonality, equivalized, data_cutoffs, data_to_mute = model_options

@unpack grid_cop, integral_cop_grid, grid_pcf = estimator


# Preliminairies
init_path     = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) * "/2_Data_processing" : pwd()
dim           = length(measures)

@info("Extracting observations Tⱼ of the joint distributions, in alphabetical order of datasets' name.")

# Collects data for all available years 
dfs, year_vec, time_dict, freq_type = data_constructor(obs_data, model_options) # TODO: correct freq_type s.t. it makes sense 
time_p               = define_timeframe(agg_data, year_vec, freq_type, time_dict, data_cutoffs) # TODO: time_dict needs to be filtered as well  

@unpack time_dict, freq_type, year_vec, tmin, tmax, tot_periods = time_p
@unpack gdp_series = obs_data

gdp_series[!, "date"]    = QuarterlyDate.(gdp_series[!, "time"])
filter!(row -> row.date >= QuarterlyDate(tmin["year"], tmin["quarter"]), gdp_series)
filter!(row -> row.date <= QuarterlyDate(tmax["year"], tmax["quarter"]), gdp_series)



for (df, j) in enumerate(datasets)
    println(j)
    # import the intervals  
    cis      = jldopen("/home/luisc/Distributional_Dynamics/confidence_intervals/ci_draws_consum_and_income_and_wealth_deciles_series_$(j)_all.jld2", "r")["ci"]
    DCT_boot = jldopen("/home/luisc/Distributional_Dynamics/noise_distributions/noise_draws_consum_and_income_and_wealth_deciles_series_$(j)_all.jld2", "r")["noise"]
    
    new_sub_boot_dict = Dict()
    draws                   = size(cis["copula"], 2)
    u_years                 = unique(year_vec[df])

    # Sizes of different topologies + immutable
    cop_part           = grid_cop^dim  # for the series estimator, this size here does NOT correspond to the order of the polynomial, but the initial granularity of the object that was approximated
    imm_part           = grid_cop + (dim - 1) * (grid_cop - 1)
    pcf_part           = grid_pcf * dim        
    
    # Container for the objects to estimate the measurement and process noise
    n                  = cop_part + pcf_part - imm_part
    
    cop_rows      = 1:(cop_part - imm_part) 
    cop_size      = tuple([grid_cop for _ in 1:dim]...)
    cop_ci        = CartesianIndices(cop_size)
    pcf_rows      = [I for I in Iterators.partition(length(cop_rows)+1:length(cop_rows) + pcf_part, grid_pcf)]

    objects = sort(["consum", "income", "wealth"])

    new_sub_boot_dict["copula"] = deepcopy(cis["copula"])

    
    for (m, meas) in enumerate(objects)
        new_sub_boot_dict[meas] = deepcopy(cis[meas])
        
        count = 1
        for (y, yr) in enumerate(u_years)
            for actual_period in time_dict[df][yr]
                # Get the aggregate 
                avg_aggr     = filter(row -> row.date >= QuarterlyDate(yr, actual_period), gdp_series)[!, meas * "_per_hh"][1]
                
                Threads.@threads for s in 1:draws 
            
                    pcf_weights = DCT_boot[pcf_rows[m], count, s]
                
                    if all(isnan, pcf_weights)
                        nothing
                    else
                        # Integrate
                        integral, _  = quadgk(u -> reverse_inverse_hyperbolic_sine(eval_quantile_function(pcf_weights, grid_pcf-1, u)) .* avg_aggr, .9, 1.0, rtol=1e-8)
                        
                        new_sub_boot_dict[meas]["quantiles"][end, s, count] = integral[1] / .1
                    end
                end
                count += 1
            end
        end
    end

    save_path = "/home/luisc/Distributional_Dynamics/confidence_intervals/ci_draws_consum_and_income_and_wealth_deciles_series_$(j)_all_test.jld2"
    jldopen(save_path, "w") do file
        file["ci"] = new_sub_boot_dict
    end
end
            # # Create density and then store it 
            # p = Progress(draws, desc = "Generating copula densities for $(j) $(obj)")
            # for i in 1:draws
            #     X        = cis[obj][:, i, :]

            #     # Reshape 'X' into a 3D array
                
            #     if any(isfinite, X)
            #         X        = reshape(X, (11, 11, 11, T))
            #         cop_dens[:, i, :] = generate_copula_densities(X, measures, grid_size_data_cop)[:]
            #         next!(p)
            #     else
            #         break
            #     end
            # end
            # finish!(p)
            # new_sub_boot_dict[obj] = cop_dens