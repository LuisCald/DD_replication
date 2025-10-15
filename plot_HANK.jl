
function generate_quantiles_shares_levels_HANK(data_dict, ty, func_data, data_name, smin, smax, tmin, tmax, estimator, label, type, measures, time_params, select_series, gdp_series, posterior_bounds, compare_to_other_est, tag, freq)

    @unpack func_dict, year_vec, data_sources, confidence_intervals = func_data
    if typeof(estimator) <: SeriesEstimator
        @unpack integral_pcf_grid, integral_cop_grid = estimator
    else
        @unpack grid_pcf, grid_cop = estimator
    end

    grid_choice_pcf = typeof(estimator) <: SeriesEstimator ? integral_pcf_grid : grid_pcf
    grid_choice_cop = typeof(estimator) <: SeriesEstimator ? integral_cop_grid : grid_cop

    # Subset data for the reconstruction
    base_jump, end_jump = find_subset_frame(smin, smax, tmin, tmax)
    m_label = measures_folder(measures)
    folder = type == :optimization ? "from_optimization" : "from_mcmc"
    init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
    path = init_path * "/7_Results/$m_label" * "$tag" * "/$folder/plots/"

    # Estimation dates
    dts = QuarterlyDate(smin["year"], smin["quarter"]):Quarter(1):QuarterlyDate(smax["year"], smax["quarter"])
    println("dates of user: ", dts)

    # Import the confidence intervals from the full HANK model 
    file_name = init_path * "/2_Data_processing/confidence_intervals/ci_draws_illiqd_and_income_and_liquid_quintiles_series_HANK full_all.jld2"
    raw_ci = jldopen(file_name, "r")["ci"]

    file_name_raw_data = "/home/luisc/Distributional_Dynamics/7_Results/illiqd_and_income_and_liquid HANK full/other_results/func_dict_HANK_full.jld2"
    func_dict_full_hank = jldopen(file_name_raw_data, "r")["data_obs"]

    # Find the bounds of each 
    hank_year_vec = repeat([i for i in collect(2001:2024)], inner=4)
    confidence_intervals = Dict("HANK" => Dict())
    confidence_intervals["HANK"]["ci_u"], confidence_intervals["HANK"]["ci_l"] = construct_confidence_intervals(raw_ci, 0.025, 0.975, measures, hank_year_vec, estimator)

    # Correct the confidence intervals to be in the same time frame as the estimation
    hank_full_dts = QuarterlyDate(2001, 1):Quarter(1):QuarterlyDate(2024, 4)

    # Find the indices of the estimation time frame in the HANK full time frame
    hank_indices = findall(x -> x in dts, hank_full_dts)
    println("HANK indices: ", hank_indices)
    for meas in measures
        for o in ["quantiles"]
            println("HANK ci_u size: ", size(confidence_intervals["HANK"]["ci_u"][meas][o]))
            println("HANK full size: ", size(func_dict_full_hank["HANK full"][meas][o]["data"]))
            confidence_intervals["HANK"]["ci_u"][meas][o] = confidence_intervals["HANK"]["ci_u"][meas][o][:, hank_indices]
            confidence_intervals["HANK"]["ci_l"][meas][o] = confidence_intervals["HANK"]["ci_l"][meas][o][:, hank_indices]
            func_dict_full_hank["HANK full"][meas][o]["data"] = func_dict_full_hank["HANK full"][meas][o]["data"][:, hank_indices]
        end
    end


    local bot, mid, top
    if grid_choice_pcf == 10 || grid_choice_pcf == 100 || grid_choice_pcf == 20
        bot, mid, top = "bottom50", "next40", "top10"
    elseif grid_choice_pcf == 5
        bot, mid, top = "bottom40", "next40", "top20"
    end

    # Get the observed measures
    obs_meas = get_obs_meas(func_dict, data_name, measures; top=top)

    within_stat_dict = Dict()
    plot_name = data_name

    # Generate the within statistic for the copulas 
    dimension = length(measures)

    # if data_name != "consensus" && ty == "normal" # ty == "average" doesn't work because it has no comparison to the data
    #     within_stat_dict["copula"] = compute_copula_within_stat(data_dict, confidence_intervals, base_jump, end_jump, data_name, dimension, grid_choice_cop)
    # end

    println("select_series size: ", size(select_series))
    println("select_series content: ", select_series[base_jump:end-end_jump, :])
    println("base_jump: ", base_jump, " end_jump: ", end_jump)

    for meas in obs_meas # TODO: this issue here is that not all measures are observed ... ofc, we can use the reconstructed data but not the confidence intervals

        # All quantiles 
        qu = data_dict[meas]["quantiles"]["data"][:, base_jump:end-end_jump] ./ select_series[base_jump:end-end_jump, meas*"_per_hh"]'

        # For the (o)bservations 
        qu_o = Vector{Any}(undef, 4)

        # All quantiles 
        qu_o[1] = func_dict[data_name][meas]["quantiles"]["data"][:, base_jump:end-end_jump] ./ select_series[base_jump:end-end_jump, meas*"_per_hh"]'
        qu_o[2] = confidence_intervals[data_name]["ci_l"][meas]["quantiles"][:, base_jump:end-end_jump] ./ select_series[base_jump:end-end_jump, meas*"_per_hh"]'
        qu_o[3] = confidence_intervals[data_name]["ci_u"][meas]["quantiles"][:, base_jump:end-end_jump] ./ select_series[base_jump:end-end_jump, meas*"_per_hh"]'

        # Quantiles from full HANK model
        # smin_full = Dict("year" => 2001, "quarter" => 1)
        # smax_full = Dict("year" => 2024, "quarter" => 4)
        # base_jump_full, end_jump_full = find_subset_frame(smin, smax, smin_full, smax_full)
        # println("HANK full jumps: ", base_jump_full, " ", end_jump_full)
        qu_o[4] = func_dict_full_hank["HANK full"][meas]["quantiles"]["data"] ./ select_series[base_jump:end-end_jump, meas*"_per_hh"]'

        # Plots 
        markers = [:diamond, :utriangle, :circle, :star5, :cross, :diamond, :utriangle, :circle, :star5, :cross, :diamond, :utriangle, :circle, :star5, :cross, :diamond, :utriangle, :circle, :star5, :cross] #collect(range(0.3, 1, length=length(data_sources)))

        # x-axis
        xaxis = collect(1:length(dts))
        M = uppercasefirst(meas)

        # Important tag 
        detrended_or_not = ty == "average" ? "detrended_" : ""

        # All possible line-styles
        line_styles = [:solid :dash :dot :dashdot :dashdotdot :solid :dash :dot :dashdot :dashdotdot] # has to be a matrix

        within_stat_dict[meas] = Dict()

        # Doing quantiles now 
        label_quantiles = label_qs(grid_choice_pcf) # e.g., L"\textrm{%$(i)th}"
        sequences = define_sequences(grid_choice_pcf) # gets indices of each group
        dist_dict = Dict("bottom" => [sequences[1]], "middle" => [sequences[2]], "top" => [sequences[3]])
        log_qu = log_transformation(deepcopy(qu))


        for (obj, dist) in dist_dict
            within_stat_dict[meas][obj] = Dict()

            cond = data_name != "consensus" ? findall(!isnan, qu_o[1][dist[1][1], :]) : [1] # .!isnan.(all_lv_o[1][:, j])

            est_ids = cond[1]:cond[end]
            s_axis = xaxis[est_ids] # start at the first observation
            s_data = qu[:, est_ids]
            s_dts = dts[est_ids]
            intd = 40

            # Plotting model estimates
            for (lsⱼ, j) in enumerate(dist[1])
                Plots.plot()
                Plots.plot!(s_axis,
                    s_data[j, :],
                    ylabel=L"\textrm{%$(M)\, \, rel.\,  to\,\,  average}",
                    lc=:red,
                    xformatter=:latex,
                    yformatter=:latex,
                    xtickfontsize=14,
                    ytickfontsize=14,
                    legendfontsize=10,
                    guidefontsize=14,
                    xticks=(s_axis[1:intd:end], [L"%$(date)"[1:5] * "\$" for (_, date) in enumerate(s_dts[1:intd:end])]),
                    legend=:best,
                    label="",
                    lw=4, dpi=500, ls=:solid,
                )

                Plots.plot!(s_axis,
                    qu_o[2][j, :][est_ids],
                    fillrange=qu_o[3][j, :][est_ids],
                    fillalpha=0.1,
                    fillcolor=:red,
                    la=0.0,
                    lc=:white,
                    lw=4, dpi=500,
                    label="",
                )

                Plots.plot!(s_axis,
                    qu_o[4][j, :][est_ids],
                    lc=:blue,
                    lw=4,
                    la=0.5,
                    xtickfontsize=14,
                    ytickfontsize=14,
                    legendfontsize=10,
                    guidefontsize=14,
                    dpi=500, ls=:dot,
                    label=""
                )

                # Compute correlation between model 
                corr_n = round(cor(s_data[j, :], qu_o[4][j, :][est_ids]), digits=2)

                c_data = Vector{Any}(undef, 3)
                c_data[1] = qu_o[1][j, :][cond]
                c_data[2] = qu_o[2][j, est_ids]
                c_data[3] = qu_o[3][j, est_ids]

                # See how many points fall within the confidence intervals
                r_data = qu[j, est_ids] # estimates that correspond to the indices of the data points 
                num = count(c_data[2] .<= r_data .<= c_data[3])
                den = length(r_data)
                within_stat = floor(Int, (num ./ den) * 100)

                within_stat_dict[meas][obj][label_quantiles[:, j][1]] = "$num" * "/" * "$den"

                Plots.scatter!(xaxis[cond],
                    c_data[1],
                    marker=:utriangle, #markers[j],
                    markercolor=:black,
                    ms=5,
                    la=0.5,
                    lw=2, dpi=500,
                    label=""
                    # label=L"\textrm{HANK \,\,Data\,\, Used}",
                )
                Plots.plot!([], [], ls=:dash, lc=:black, la=0.0, label=L"\textrm{Within\, \,  bounds: %$(within_stat)\%}",)
                Plots.plot!([], [], ls=:dash, lc=:black, la=0.0, label=L"\textrm{Corr.: %$(corr_n)\%}",)
                Plots.savefig(path * "$meas/" * "quantiles_levels/" * plot_name * "_$meas" * "_$obj" * "_quantiles_$(j)" * detrended_or_not * label * ".pdf")
            end
        end
    end

    return within_stat_dict
end