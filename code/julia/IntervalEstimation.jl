function bootstrap_non_parametric_approach!(sub_boot_dict, DCT_boot, period_data, measures, grid_size, gdp_series, count, cop_rows, quantile_rows, hhs_g, dim, d, yr, actual_period; with_imputation_error=false)
    cut = with_imputation_error ? 5 : 1 
    obs_measures    = []

    for i in 1:cut
        d +=1
        # Get implicate data
        period_dataᵢ   = filter(row -> row.impnum == i, period_data)
        
        for (m, meas) in enumerate(measures)
            # Assign quantile groups
            m_sample, flag = assign_quantile_groups_for_bootstrap(period_dataᵢ, meas, grid_size) 
            avg_aggr       = filter(row -> row.date >= QuarterlyDate(yr, actual_period), gdp_series)[!, meas * "_per_hh"][1]

            if flag # data is missing for this measure  
                sub_boot_dict[meas]["levels"][:, d, count]     .= NaN
                sub_boot_dict[meas]["shares"][:, d, count]     .= NaN
                sub_boot_dict[meas]["quantiles"][:, d, count]  .= NaN
                DCT_boot[quantile_rows[m], count, d]           .= NaN
            else    
                push!(obs_measures, meas)                            
                meas_average                                   = mean(m_sample[:, meas], weights(m_sample[:, :weight]))
                multiplier                                     = abs.(avg_aggr / meas_average)
                
                if multiplier[1] > 20
                    println(multiplier[1])
                    sub_boot_dict[meas]["levels"][:, d, count]     .= NaN
                    sub_boot_dict[meas]["quantiles"][:, d, count]  .= NaN
                    sub_boot_dict[meas]["shares"][:, d, count]     .= NaN
                    DCT_boot[quantile_rows[m], count, d]           .= NaN
                else 
                    # Perform scaling 
                    m_sample[!, meas]              = m_sample[!, meas] .* multiplier
                    tot_scale                      = avg_aggr .- mean(m_sample[:, meas], weights(m_sample[:, :weight])) # should be zero if data is all positive 
                    m_sample[!, meas]             .= m_sample[!, meas] .+ tot_scale # the average is corrected and ranks don't change. 
                    
                    # Generate levels, quantiles and shares  
                    levels                                         = zeros(grid_size)
                    for g in 1:grid_size
                        data_q                                         = filter(x -> x[meas * "_quantile"] == g, m_sample)                            
                        sub_boot_dict[meas]["quantiles"][g, d, count]  = mean(data_q[:, meas], weights(data_q[:, :weight]))
                        levels[i]                                      = sub_boot_dict[meas]["quantiles"][g, d, count] .* hhs_g #sum(data_q[:, :weight] .* data_q[:, meas]) / sum(data_q[:, :weight]), # levels[i]                                      = wsum(data_q[:, meas], data_q[:, :weight])
                    end
                    tot          = sum(levels)
                    shares       = levels ./ tot

                    # DCT the CORRECTED quantile data 
                    DCT_boot[quantile_rows[m], count, d] .= dct(sub_boot_dict[meas]["quantiles"][:, d, count] ./ avg_aggr)

                    # Generate the different objects
                    if grid_size == 10
                        sub_boot_dict[meas]["levels"][:, d, count]    = vcat(sum(levels[1:5]), sum(levels[6:9]), levels[grid_size])
                        sub_boot_dict[meas]["shares"][:, d, count]    = vcat(sum(shares[1:5]), sum(shares[6:9]), shares[grid_size])
                    elseif grid_size == 5
                        # Bottom 40, Next 40, Top 20
                        sub_boot_dict[meas]["levels"][:, d, count]    = vcat(sum(levels[1:2]), sum(levels[3:4]), levels[grid_size])
                        sub_boot_dict[meas]["shares"][:, d, count]    = vcat(sum(shares[1:2]), sum(shares[3:4]), shares[grid_size])
                    elseif grid_size == 20
                        sub_boot_dict[meas]["levels"][:, d, count]    = vcat(sum(levels[1:10]), sum(levels[11:18]), sum(levels[19:20]))
                        sub_boot_dict[meas]["shares"][:, d, count]    = vcat(sum(shares[1:10]), sum(shares[11:19]), sum(shares[19:20]))
                    elseif grid_size == 100
                        sub_boot_dict[meas]["levels"][:, d, count]    = vcat(sum(levels[1:50]), sum(levels[51:90]), sum(levels[91:100]))
                        sub_boot_dict[meas]["shares"][:, d, count]    = vcat(sum(shares[1:50]), sum(shares[51:90]), sum(shares[91:100]))
                    end
                end
            end
        end

        # Generate copulas  
        unique!(obs_measures)
        obs_dims = length(obs_measures)
        local cop_v
        if dim == obs_dims
            DCT_boot[cop_rows, count, d] .= get_copulas(period_dataᵢ, measures, obs_measures, grid_size)
            cop_v                         = idct(get_copulas(period_dataᵢ, measures, obs_measures, grid_size; with_immutable=true))

        elseif obs_dims < dim && obs_dims >= 2 
            correction                    = sqrt(grid_size)^(dim - obs_dims) 
            DCT_boot[cop_rows, count, d] .= get_copulas(period_dataᵢ, measures, obs_measures, grid_size)
            cop_v                         = get_copulas(period_dataᵢ, measures, obs_measures, grid_size; with_immutable=true) .* correction 

            # In this case, the idct will return NaNs, so, we need to perform the idct like so:
            cop_v = idct(idct(cop_v, 1), 2)  #TODO: this only works if the copula has NaNs on the other slices -> otherwise, it would be incorrect 

        elseif obs_dims <= 1
            cop_v = NaN
            DCT_boot[cop_rows, count, d] .= NaN
        end

        cop_size = tuple([grid_size for i in 1:dim]...)
        cop_m    = zeros(cop_size)
        obs_dims = length(obs_measures)
        
        # Compute correlations 
        if any(isfinite, cop_v) 
            cop_m                            .= reshape(cop_v, cop_size)
            pcfs_y                            = vcat([sub_boot_dict[m]["quantiles"][:, d, count] for m in measures]...)
            micro_df                          = construct_micro_dataset(cop_m, pcfs_y, grid_size, hhs_g * grid_size)
            
            if grid_size >=10 #TODO: I don't think this matters 
                # First I need to set some of the correlations to NaN, based on how many measures are actually observed 
                if obs_dims == dim
                    sub_boot_dict["correlations"]["g_ktau"][:, d, count], sub_boot_dict["correlations"]["g_pcorr"][:, d, count] = compute_granular_correlations(micro_df, measures, grid_size)
                    sub_boot_dict["correlations"]["ktau"][:, d, count], sub_boot_dict["correlations"]["pcorr"][:, d, count]     = compute_correlations(micro_df, measures) 

                elseif obs_dims < dim && obs_dims >= 2
                    # scomb      = length(combinations(obs_measures, 2))
                    # comb_bound = scomb * 4
                    
                    # Normal correlations 
                    sub_boot_dict["correlations"]["ktau"][:, d, count], sub_boot_dict["correlations"]["pcorr"][:, d, count]     = compute_correlations(micro_df, measures) 
                    # sub_boot_dict["correlations"]["ktau"][scomb+1:end, s, count]  .= NaN
                    # sub_boot_dict["correlations"]["pcorr"][scomb+1:end, s, count] .= NaN

                    # Granular now 
                    sub_boot_dict["correlations"]["g_ktau"][:, d, count], sub_boot_dict["correlations"]["g_pcorr"][:, d, count] = compute_granular_correlations(micro_df, measures, grid_size) 
                    # sub_boot_dict["correlations"]["g_ktau"][comb_bound+1:end, s, count]  .= NaN
                    # sub_boot_dict["correlations"]["g_pcorr"][comb_bound+1:end, s, count] .= NaN
                end
            end
        
        else
            sub_boot_dict["correlations"]["ktau"][:, d, count]       .= NaN
            sub_boot_dict["correlations"]["pcorr"][:, d, count]      .= NaN
            sub_boot_dict["correlations"]["g_ktau"][:, d, count]     .= NaN
            sub_boot_dict["correlations"]["g_pcorr"][:, d, count]    .= NaN
        end
    end
    return sub_boot_dict, DCT_boot
end

#TODO: to finish 
function semi_parametric_approach!(sub_boot_dict, DCT_boot, period_data, measures, grid_size, gdp_series, count, quantile_rows, obs_measures, hhs_g, dim, d; with_imputation_error=false)
# The idea here is we estimate all objects 5 times. One for each implicate. 
# then bootstrap without imputation error 

    cut = with_imputation ? 5 : 1 

    for i in 1:cut
        d +=1
        # Get implicate data
        period_dataᵢ   = filter(row -> row.impnum == i, period_data)
        
        for (m, meas) in enumerate(measures)
            # Assign quantile groups
            m_sample, flag = assign_quantile_groups_for_bootstrap(period_dataᵢ, meas, grid_size) 
            avg_aggr     = filter(row -> row.date >= QuarterlyDate(yr, actual_period), gdp_series)[!, meas * "_per_hh"][1]
        
            if flag # data is missing for this measure  
                sub_boot_dict[meas]["levels"][:, d, count]     .= NaN
                sub_boot_dict[meas]["shares"][:, d, count]     .= NaN
                sub_boot_dict[meas]["quantiles"][:, d, count]  .= NaN
                DCT_boot[quantile_rows[m], count, d]           .= NaN
                break
            else    
                push!(obs_measures, meas)                            
                meas_average                                   = mean(m_sample[:, meas], weights(m_sample[:, :weight]))
                multiplier                                     = abs.(avg_aggr / meas_average)
                
                if multiplier[1] > 20
                    sub_boot_dict[meas]["levels"][:, d, count]     .= NaN
                    sub_boot_dict[meas]["quantiles"][:, d, count]  .= NaN
                    sub_boot_dict[meas]["shares"][:, d, count]     .= NaN
                    DCT_boot[quantile_rows[m], count, d]           .= NaN
                    break
                else 
                    # Perform scaling 
                    m_sample[!, meas]              = m_sample[!, meas] .* multiplier
                    tot_scale                      = avg_aggr .- mean(m_sample[:, meas], weights(m_sample[:, :weight])) # should be zero if data is all positive 
                    m_sample[!, meas]             .= m_sample[!, meas] .+ tot_scale # the average is corrected and ranks don't change. 
                    
                    # Generate levels, quantiles and shares  
                    levels                                         = zeros(grid_size)
                    for g in 1:grid_size
                        data_q                                         = filter(x -> x[meas * "_quantile"] == g, m_sample)                            
                        sub_boot_dict[meas]["quantiles"][g, d, count]  = mean(data_q[:, meas], weights(data_q[:, :weight]))
                        levels[i]                                      = sub_boot_dict[meas]["quantiles"][g, d, count] .* hhs_g #sum(data_q[:, :weight] .* data_q[:, meas]) / sum(data_q[:, :weight]), # levels[i]                                      = wsum(data_q[:, meas], data_q[:, :weight])
                    end
                    tot          = sum(levels)
                    shares       = levels ./ tot

                    # DCT the CORRECTED quantile data 
                    DCT_boot[quantile_rows[m], count, d] .= dct(sub_boot_dict[meas]["quantiles"][:, d, count] ./ avg_aggr)

                    # Generate the different objects
                    if grid_size == 10
                        sub_boot_dict[meas]["levels"][:, d, count]    = vcat(sum(levels[1:5]), sum(levels[6:9]), levels[grid_size])
                        sub_boot_dict[meas]["shares"][:, d, count]    = vcat(sum(shares[1:5]), sum(shares[6:9]), shares[grid_size])
                    elseif grid_size == 5
                        # Bottom 40, Next 40, Top 20
                        sub_boot_dict[meas]["levels"][:, d, count]    = vcat(sum(levels[1:2]), sum(levels[3:4]), levels[grid_size])
                        sub_boot_dict[meas]["shares"][:, d, count]    = vcat(sum(shares[1:2]), sum(shares[3:4]), shares[grid_size])
                    elseif grid_size == 20
                        sub_boot_dict[meas]["levels"][:, d, count]    = vcat(sum(levels[1:10]), sum(levels[11:18]), sum(levels[19:20]))
                        sub_boot_dict[meas]["shares"][:, d, count]    = vcat(sum(shares[1:10]), sum(shares[11:19]), sum(shares[19:20]))
                    elseif grid_size == 100
                        sub_boot_dict[meas]["levels"][:, d, count]    = vcat(sum(levels[1:50]), sum(levels[51:90]), sum(levels[91:100]))
                        sub_boot_dict[meas]["shares"][:, d, count]    = vcat(sum(shares[1:50]), sum(shares[51:90]), sum(shares[91:100]))
                    end
                end
            end
        end

        # Generate copulas  
        unique!(obs_measures)
        obs_dims = length(obs_measures)
        local cop_v
        if dim == obs_dims
            DCT_boot[cop_rows, count, d] .= get_copulas(period_dataᵢ, measures, obs_measures, grid_size)
            cop_v                         = idct(get_copulas(period_dataᵢ, measures, obs_measures, grid_size; with_immutable=true))

        elseif obs_dims < dim && obs_dims >= 2 
            correction                    = sqrt(grid_size)^(dim - obs_dims) 
            DCT_boot[cop_rows, count, d] .= get_copulas(period_dataᵢ, measures, obs_measures, grid_size)
            cop_v                         = get_copulas(period_dataᵢ, measures, obs_measures, grid_size; with_immutable=true) .* correction 

            # In this case, the idct will return NaNs, so, we need to perform the idct like so:
            cop_v = idct(idct(cop_v, 1), 2)  #TODO: this only works if the copula has NaNs on the other slices -> otherwise, it would be incorrect 

        elseif obs_dims == 1
            cop_v = NaN
            DCT_boot[cop_rows, count, d] .= NaN
        end

        cop_size = tuple([grid_size for i in 1:dim]...)
        cop_m    = zeros(cop_size)
        obs_dims = length(obs_measures)
        
        # Compute correlations 
        if any(isfinite, cop_v) 
            cop_m                            .= reshape(cop_v, cop_size)
            pcfs_y                            = vcat([sub_boot_dict[m]["quantiles"][:, d, count] for m in measures]...)
            micro_df                          = construct_micro_dataset(cop_m, pcfs_y, grid_size, hhs_g * grid_size)
            
            if grid_size >=10 #TODO: I don't think this matters 
                # First I need to set some of the correlations to NaN, based on how many measures are actually observed 
                if obs_dims == dim
                    sub_boot_dict["correlations"]["g_ktau"][:, d, count], sub_boot_dict["correlations"]["g_pcorr"][:, d, count] = compute_granular_correlations(micro_df, measures, grid_size)
                    sub_boot_dict["correlations"]["ktau"][:, d, count], sub_boot_dict["correlations"]["pcorr"][:, d, count]     = compute_correlations(micro_df, measures) 

                elseif obs_dims < dim && obs_dims >= 2
                    # scomb      = length(combinations(obs_measures, 2))
                    # comb_bound = scomb * 4
                    
                    # Normal correlations 
                    sub_boot_dict["correlations"]["ktau"][:, d, count], sub_boot_dict["correlations"]["pcorr"][:, d, count]     = compute_correlations(micro_df, measures) 
                    # sub_boot_dict["correlations"]["ktau"][scomb+1:end, s, count]  .= NaN
                    # sub_boot_dict["correlations"]["pcorr"][scomb+1:end, s, count] .= NaN

                    # Granular now 
                    sub_boot_dict["correlations"]["g_ktau"][:, d, count], sub_boot_dict["correlations"]["g_pcorr"][:, d, count] = compute_granular_correlations(micro_df, measures, grid_size) 
                    # sub_boot_dict["correlations"]["g_ktau"][comb_bound+1:end, s, count]  .= NaN
                    # sub_boot_dict["correlations"]["g_pcorr"][comb_bound+1:end, s, count] .= NaN
                end
            end
        
        else
            sub_boot_dict["correlations"]["ktau"][:, d, count]       .= NaN
            sub_boot_dict["correlations"]["pcorr"][:, d, count]      .= NaN
            sub_boot_dict["correlations"]["g_ktau"][:, d, count]     .= NaN
            sub_boot_dict["correlations"]["g_pcorr"][:, d, count]    .= NaN
        end
    end

end