# Old plot code for the paper, from CreateTimeSeries.jl

### LEVELS
        # # Levels - Reconstruction
        # agg_labels = generate_agg_labels(grid_choice_pcf) 
        # sequences  = define_sequences(grid_choice_pcf)

        # # dist_dict = Dict(
        # #     "levels" => [all_lv, all_lv_o], 
        # #     "shares" => [all_sh, all_sh_o]
        # #     )

        # for (obj, dist) in dist_dict
        #     cond     = data_name != "consensus" ? findall(!isnan, dist[2][1][:, 1]) : [1] # .!isnan.(all_lv_o[1][:, j])
        #     s_axis   = xaxis[cond[1]:cond[end]] # start at the first observation 
        #     s_data   = dist[1][cond[1]:cond[end], :]
        #     s_dts    = dts[cond[1]:cond[end]]
        
        #     Plots.plot(s_axis, 
        #     s_data, 
        #     # xlabel = L"\textrm{Year}",
        #     ylabel = obj == "levels" ? L"\textrm{%$(M)}\, \, \textrm{level} \,\, \textrm{(2019\,\, base\,\, year)}" : L"\textrm{%$(M)}\, \, \textrm{share}",
        #     xformatter=:latex, 
        #     yformatter=:latex, 
        #     lc=select_color(plot_name),
        #     xticks=(s_axis[1:20:end], [L"%$(date)"[1:5] * "\$" for (_,date) in enumerate(s_dts[1:20:end])]),
        #     legend=:outertopright,
        #     label=agg_labels,
        #     lw=4, dpi=500, ls=line_styles[:,1:size(s_data, 2)],
        #     )
        
        #     if data_name != "consensus"
        #         within_stat_dict[meas][obj] = Dict() 

        #         for j in 1:3
        #             c_data = Vector{Any}(undef, 3)
        #             for i in 1:3
        #                 c_data[i]  = dist[2][i][:, j][cond]
        #             end
        
        #             # See how many points fall within the confidence intervals
        #             r_data      = dist[1][:, j][cond]
        #             num         = count(c_data[2] .<= r_data .<= c_data[3])
        #             den         = length(r_data)
        #             within_stat = floor(Int, (num ./ den) * 100)
        #             xa          = xaxis[cond] 

        #             # Store within stat for this measure, for this object  
        #             within_stat_dict[meas][obj][agg_labels[j]] = "$num" * "/" * "$den"
        
        #             Plots.scatter!(xa,
        #                 c_data[1],
        #                 markersize=5,
        #                 marker=markers[j],
        #                 markercolor=:black,
        #                 lc=:black,
        #                 la=0.5,
        #                 lw=4, dpi=500,
        #                 label=L"\textrm{Within\, \, bounds: %$(within_stat)\%}",
        #                 yerror=(c_data[1] - c_data[2], c_data[3] - c_data[1]),
        #                 )
        #         end
        #     end
        #     Plots.savefig(path * "$meas/" * "quantiles_levels/" * plot_name * "_$meas" * "_$obj" * "_" * label * ".pdf")
        # end


        ## For this plot: Plots.savefig(path * "$meas/" * "quantiles_levels/" * plot_name * "_$(meas)_" * "$(k)_" * "$(esttag)_loghp_" * label * ".pdf")
                                # Plots.plot!([], [], ls=:dash, lc=:blue, lw=2, label=L"\textrm{Less \,\, Data}", dpi=500)

                                
                                # # Perform the within stat thing, once for the data and once for the cycle
                                # # log_r_data_all     = log_transformation(sum(qu[g..., cond_cex], dims=1)' ./ n_lines) .- HP_mat(log_transformation(sum(qu[g..., cond_cex], dims=1)' ./ n_lines), 1600)
                                # log_c_int_ub    = log_transformation(sum(qu_o[3][g..., cond_cex], dims=1)' ./ n_lines) .- HP(vec(log_transformation(sum(qu_o[3][g..., cond_cex], dims=1)' ./ n_lines)), 1600)
                                # log_c_int_lb    = log_transformation(sum(qu_o[2][g..., cond_cex], dims=1)' ./ n_lines) .- HP(vec(log_transformation(sum(qu_o[2][g..., cond_cex], dims=1)' ./ n_lines)), 1600)
                                # log_c_data      = log_transformation(sum(qu_o[1][g..., cond_cex], dims=1)' ./ n_lines) .- HP(vec(log_transformation(sum(qu_o[1][g..., cond_cex], dims=1)' ./ n_lines)), 1600)
                                # log_r_data      = log_transformation(sum(qu_outside_est[esttag][g..., cond_cex], dims=1)' ./ n_lines) .- HP(vec(log_transformation(sum(qu_outside_est[esttag][g..., cond_cex], dims=1)' ./ n_lines)), 1600)


                                # # println(size(r_data_all)) # 38 by 1
                                # # println(size(r_data)) # 38 by 1
                                # # println(size(r_data_all_nocond)) # 149 by 1
                                # # println(size(r_data_noncond)) # 149 by 1

                                # # Statistics
                                # within_stat     = floor(Int, (count(log_c_int_lb .<= log_r_data .<= log_c_int_ub) ./ length(log_r_data)) * 100)

                                # # ρ           = non_overlap_ids != [] ? round(cor(vec(log_c_data(non_overlap_ids)), vec(log_r_data(non_overlap_ids))), digits=2) : NaN # correlate data with estimates (A)
                                # # ρ3          = round(cor(cex_all_est, outside_est), digits=2) # correlate estimates with estimates of full CEX model
                                # # ρ2          = round(cor(vec(c_data[non_overlap_ids]), vec(r_data_all[non_overlap_ids])), digits=2) # correlate data with estimates of full CEX model 
                                
                                # # Plot!
                                # # Plots.plot!(xaxis[cond_cex],
                                # # c_data(cond_cex),
                                # # # marker=markers[g],
                                # # # lc=group_labels[g] != "top" ? palette(:glasbey_bw_n256)[g] : select_color(data_name),
                                # # lc= :black,
                                # # la=0.2,
                                # # ls=:dash,
                                # # lw=4, dpi=500,
                                # # label= g == 1 ? L"\textrm{Data}" : "", 
                                # # )

                                # # Plots.plot!(xaxis[cond_cex],
                                # #     c_int_lb,
                                # #     fillrange = c_int_ub,
                                # #     fillalpha = 0.1,
                                # #     fillcolor = group_labels[g] != "top" ? palette(:glasbey_bw_n256)[g] : select_color(data_name),
                                # #     la=0.0,
                                # #     lc=:white,
                                # #     lw=4, dpi=500,
                                # #     label="",
                                # #     # label=L"\textrm{Within\, \,  bounds: %$(within_stat)\%}"
                                # #     )
                                
                                # # Only for plotting the additional label 
                                # #     Plots.plot!(xaxis[cond_cex],
                                # #         c_data(cond_cex),
                                # #         la=0.0,
                                # #         label=L"\textrm{Corr. \,\, of\,\, (A)\,\,with\,\,(C): %$(ρ)}",
                                # #     )

                                # #     Plots.plot!(xaxis[cond_cex],
                                # #     c_data(cond_cex),
                                # #     la=0.0,
                                # #     label=L"\textrm{Corr. \,\, between \,\, (A)\,\,and \,\, (B): %$(ρ3)}",
                                # # )

                                # # First plot everything as is 
                                # Plots.scatter!(xaxis[cond_cex],
                                #     log_c_data,
                                #     marker=:dot,
                                #     markercolor=:black,
                                #     markersize=5,
                                #     la=0.5,
                                #     lw=4, dpi=500,
                                #     label= g == 1 ? L"\textrm{Data}" : "",
                                #     yerror=(log_c_int_ub - log_c_data, log_c_data - log_c_int_lb),
                                # )

                                # # Replot the data, marking the observations used in the estimates 
                                # # Plots.scatter!(xaxis[overlap_ids],
                                # #     c_data(overlap_ids),
                                # #     marker=:dot,
                                # #     markercolor=:black,
                                # #     markersize=5,
                                # #     la=0.5,
                                # #     lw=4, dpi=500,
                                # #     label= g == 1 ? L"\textrm{Data}" : "",
                                # #     yerror=(c_int_ub(overlap_ids) - c_data(overlap_ids), c_data(overlap_ids) - c_int_lb(overlap_ids)),
                                # # )

                                # if non_overlap_ids != []
                                #     ids = findall(x -> x ∈ cond_cex, non_overlap_ids)
                                #     Plots.scatter!(xaxis[non_overlap_ids],
                                #     log_c_data[ids],
                                #     mc=:white, msc=:black, msw=3, #(5, :white, stroke(1, :black)),
                                #     la=0.5,
                                #     lw=4, dpi=500,
                                #     label= g == 1 ? L"\textrm{Missing\,\, data}" : "",
                                #     )
                                # end

                                                            #     Plots.scatter!(xaxis[non_overlap_ids],
                            #     c_data(non_overlap_ids),
                            #     mc=:white, msc=:black, msw=3, #(5, :white, stroke(1, :black)),
                            #     # marker=:dot,
                            #     # markercolor=:goldenrod1,
                            #     # markersize=3,
                            #     la=0.5,
                            #     lw=4, dpi=500,
                            #     label= g == 1 ? L"\textrm{Missing\,\, data}" : "",
                            #     yerror=(c_int_ub(non_overlap_ids) - c_data(non_overlap_ids), c_data(non_overlap_ids) - c_int_lb(non_overlap_ids)),
                            # )

                                
                                # # Random plot, to plot the label
                                # Plots.plot!([], [], ls=:dash, lc=:black, label=L"\textrm{Imputation}")


                                ## LOG AND HP FILER
                                # Plots.plot()

                                # for (lsⱼ, j) in enumerate(dist[1])
                                #     if length(s_axis) > 1
                                #         Plots.plot!(s_axis, 
                                #             s_log_data[j, :],
                                #             # xlabel = L"\textrm{Year}",
                                #             ylabel = L"\textrm{%$(M)\, \, (rel.\,  to\,\,  HH\,\,  average)\, \,  %$(obj)\, quantiles}",
                                #             lc = obj != "top" ? palette(:glasbey_bw_n256)[j] : select_color(plot_name),
                                #             xformatter=:latex, 
                                #             yformatter=:latex, 
                                #             xticks=(s_axis[1:20:end], [L"%$(date)"[1:5] * "\$" for (_,date) in enumerate(s_dts[1:20:end])]),
                                #             legend=:outertopright,
                                #             label=label_quantiles[:, j][1],
                                #             lw=4, dpi=500, ls=line_styles[:,lsⱼ][1],
                                #             )
                                #     end
                                # end
                            
                                # for i in dist[1]
                                #     if length(s_axis) > 1
                                #         Plots.plot!(s_axis, 
                                #             HP(s_log_data[i, :], 1600), 
                                #             label="",
                                #             lw=4, dpi=500
                                #         ) 
                                #     end
                                # end
                            
                                # if data_name != "consensus"
                                #     for j in dist[1]
                                #         log_c_data = Vector{Any}(undef, 3)
                                #         for i in 1:3
                                #             log_c_data[i]  = log_transformation(qu_o[i][j, :][cond])
                                #         end
                            
                                #         # See how many points fall within the confidence intervals
                                #         r_data      = log_qu[j, :][cond]
                                #         within_stat = floor(Int, (count(log_c_data[2] .<= r_data .<= log_c_data[3]) ./ length(r_data)) * 100)
                                        
                                #         Plots.scatter!(xaxis[cond],
                                #             log_c_data[1],
                                #             markersize=5,
                                #             marker=markers[j],
                                #             markercolor=:black,
                                #             la=0.5,
                                #             lw=4, dpi=500,
                                #             label=L"\textrm{Within\, \,  bounds: %$(within_stat)\%}",
                                #             yerror=(log_c_data[1] - log_c_data[2], log_c_data[3] - log_c_data[1]),
                                #             )
                            
                                #         Plots.plot!(xaxis[cond],
                                #             HP(log_c_data[1], 1600),
                                #             ls=:dash,
                                #             lc=:black,
                                #             la=0.5,
                                #             lw=4, dpi=500,
                                #             label="",
                                #             )
                                #     end
                                # end
                                # Plots.savefig(path * "$meas/" * "quantiles_levels/" * plot_name * "_$meas" * "_$obj" * "_quantiles_" * "log_HP_" * label * ".pdf")