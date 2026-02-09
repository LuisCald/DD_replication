cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")


using Integrals
@unpack df_vec = obs_data
df = df_vec[1][1]
df = df[df[:, :year].==2019, :]

# Cleaning out NaNs
non_missing = coalesce.(df, NaN)
if df_vec.df_names[1] == "SCF"
    non_missing = filter("income" => !isnan, select(df, ["income", "wealth", "weight", "id"]))
    filter!("weight" => !isnan, non_missing)
    filter!("income" => !isnan, non_missing)
    filter!("wealth" => !isnan, non_missing)
    df_to_analyze = select(non_missing, ["income", "wealth", "weight", "id", "impnum"])
elseif df_vec.df_names[1] == "PSID"
    non_missing = filter("income" => !isnan, select(df, ["income", "wealth", "consum", "weight", "id"]))
    filter!("weight" => !isnan, non_missing)
    filter!("income" => !isnan, non_missing)
    filter!("wealth" => !isnan, non_missing)
    filter!("consum" => !isnan, non_missing)
    df_to_analyze = select(non_missing, ["consum", "income", "wealth", "weight"])
elseif df_vec.df_names[1] == "HANK a"
    non_missing = filter("income" => !isnan, select(df, ["income", "liquid", "illiqd", "weight", "id"]))
    filter!("weight" => !isnan, non_missing)
    filter!("income" => !isnan, non_missing)
    filter!("consum" => !isnan, non_missing)
    filter!("wealth" => !isnan, non_missing)
    df_to_analyze = select(non_missing, ["income", "consum", "wealth", "weight"])
end

function series_estimator(data, weights, order, p_values)
    # Estimate Phi using the legendre polynomials
    Phi = zeros(length(data), order + 1)

    s_weights = cumsum(weights) / sum(weights)

    for i in eachindex(data)
        for j in 0:order
            # Phi[i, j+1]          = Q_m(j, normalize_to_0_1(data[i], min_data, max_data)) # Q_m places [0,1] data internally to [-1, 1]
            Phi[i, j+1] = Q_m(j, s_weights[i]) # Q_m places [0,1] data internally to [-1, 1]
        end
    end
    # Estimate the coefficients, (Phi' * Phi)^(-1) * Phi' * y
    # coefficients = inv(transpose(Phi) * Phi) * transpose(Phi) * data
    # Incorporate weights into the Phi matrix
    W = Diagonal(sqrt.(weights))  # Use square root of weights for correct weighting
    Phi_weighted = W * Phi

    # More stable and efficient way to estimate the coefficients
    # Weighted least squares solution
    # coefficients = (transpose(Phi_weighted) * Phi_weighted) \ (transpose(Phi_weighted) * (W * data))
    # coefficients = (transpose(Phi_weighted) * (W * data))

    coefficients = zeros(order + 1)
    for j in 1:order+1
        for i in 1:length(data)
            coefficients[j] += weights[i] * Phi[i, j] * data[i]
        end
        coefficients[j] /= sum(weights)
    end
    # cdf_est = Phi * coefficients

    basis = zeros(length(p_values), order + 1)
    for (i, p) in enumerate(p_values)
        for j in 0:order
            basis[i, j+1] = Q_m(j, p)
        end
    end

    quants = basis * coefficients

    # return cdf_est
    return quants
end

# The different p_values of interest 
p_values = collect(0.01:0.01:0.99)
n_p = length(p_values)
tail_values = [0.995, 0.999, 0.9995, 0.9999]

all_p_values = vcat(collect(0.01:0.01:0.99), tail_values)

# Boot strap procedure
init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
# rep_w = CSV.read(init_path * "/1_Data/SCF+/replicate_weights/replicate_weights_2019.csv", DataFrame)

@unpack measures = model_options

for measure_of_choice in measures #, :income, :consum]
    @unpack gdp_series = obs_data
    gdp_series[!, "date"] = QuarterlyDate.(gdp_series[!, "time"])
    a = filter(x -> x.date == QuarterlyDate(2019, 4), gdp_series)
    correction = a[1, "$(String(measure_of_choice))_per_hh"]

    # Create containers for the bootstrap
    n_draws = 10
    emp_est = zeros(length(all_p_values), n_draws)
    pol_est = zeros(length(all_p_values), n_draws)
    emp_est_trans = zeros(length(all_p_values), n_draws)
    pol_est_trans = zeros(length(all_p_values), n_draws)

    # Generate boot_indices
    boot_indices = rand(1:nrow(df_to_analyze), n_draws, nrow(df_to_analyze))
    lb_crit = 0.01
    ub_crit = 0.99

    for s in 1:n_draws
        b_sample = df_to_analyze[boot_indices[s, :], :]
        # b_sample = deepcopy(df_to_analyze)
        # b_sample[!, "newid"] = [parse(Int, string(row[:id])[1:end-1]) for row in eachrow(b_sample)]
        # rep_draw = select(filter(row -> !ismissing(row["wgtI95W95_imp1_$s"]), rep_w), ["id", "wgtI95W95_imp1_$s"])
        # b_sample = leftjoin(b_sample, rep_draw, on=:newid => :id, indicator=:source) # fully non-parametric bootstrap

        # filter!(row -> row.impnum == 1, b_sample)
        # select!(b_sample, Not([:weight, :source]))
        # rename!(b_sample, Symbol("wgtI95W95_imp1_$s") => :weight)

        # Drop missings from b_sample
        b_sample = dropmissing(b_sample, :weight)

        # Drop NaNs from data and weights
        b_sample = coalesce.(b_sample, NaN)
        not_NaN_cond = .!isnan.(b_sample[!, measure_of_choice][:]) .& .!isnan.(b_sample[!, :weight][:])
        b_sample = b_sample[not_NaN_cond, :]

        sort!(b_sample, measure_of_choice)
        data = b_sample[!, measure_of_choice][:]
        weights2 = b_sample[!, :weight][:]

        # Normalize the data
        data_trans = inverse_hyperbolic_sine(data ./ correction)

        # Generate the quantile function
        s_weights = cumsum(weights2) / sum(weights2)

        # Transformed
        for (pp, p) in enumerate(all_p_values)
            # est = [meas for (meas, cdf) in zip(b_sample[!, measure_of_choice], s_weights) if cdf >= p][1]
            try
                emp_est_trans[pp, s] = [meas for (meas, cdf) in zip(data_trans, s_weights) if cdf >= p][1]
            catch e
                println(p)
            end
        end

        # Original
        for (pp, p) in enumerate(all_p_values)
            # est = [meas for (meas, cdf) in zip(b_sample[!, measure_of_choice], s_weights) if cdf >= p][1]
            emp_est[pp, s] = [meas for (meas, cdf) in zip(data, s_weights) if cdf >= p][1]
        end

        orders_to_estimate = [5] #collect(3:50)

        # Plot the results
        pol_est_trans[:, s] = series_estimator(data_trans, weights2, orders_to_estimate[1], all_p_values)
        pol_est[:, s] = reverse_inverse_hyperbolic_sine(pol_est_trans[:, s]) .* correction
    end

    # Plots the results, with intervals
    lb_est_trans = [quantile(emp_est_trans[jj, :], lb_crit) for jj in eachindex(all_p_values)]
    ub_est_trans = [quantile(emp_est_trans[jj, :], ub_crit) for jj in eachindex(all_p_values)]
    med_est_trans = [quantile(emp_est_trans[jj, :], 0.5) for jj in eachindex(all_p_values)]

    lb_pol_trans = [quantile(pol_est_trans[jj, :], lb_crit) for jj in eachindex(all_p_values)]
    ub_pol_trans = [quantile(pol_est_trans[jj, :], ub_crit) for jj in eachindex(all_p_values)]
    med_pol_trans = [quantile(pol_est_trans[jj, :], 0.5) for jj in eachindex(all_p_values)]

    lb_est = [quantile(emp_est[jj, :], lb_crit) for jj in eachindex(all_p_values)]
    ub_est = [quantile(emp_est[jj, :], ub_crit) for jj in eachindex(all_p_values)]
    med_est = [quantile(emp_est[jj, :], 0.5) for jj in eachindex(all_p_values)]

    lb_pol = [quantile(pol_est[jj, :], lb_crit) for jj in eachindex(all_p_values)]
    ub_pol = [quantile(pol_est[jj, :], ub_crit) for jj in eachindex(all_p_values)]
    med_pol = [quantile(pol_est[jj, :], 0.5) for jj in eachindex(all_p_values)]



    for rr in eachindex(tail_values)
        # Find the .025 and .975 quantiles for the empirical estimates
        emp_est_new_tail = vcat(med_est_trans[1:n_p], med_est_trans[n_p+rr])
        emp_est_new_tail_lb = vcat(lb_est_trans[1:n_p], lb_est_trans[n_p+rr])
        emp_est_new_tail_ub = vcat(ub_est_trans[1:n_p], ub_est_trans[n_p+rr])

        pol_est_trans_new_tail = vcat(med_pol_trans[1:n_p], med_pol_trans[n_p+rr])
        pol_est_trans_new_tail_lb = vcat(lb_pol_trans[1:n_p], lb_pol_trans[n_p+rr])
        pol_est_trans_new_tail_ub = vcat(ub_pol_trans[1:n_p], ub_pol_trans[n_p+rr])


        p = Plots.plot(fontsize=16, legendfontsize=16, titlefontsize=16, labelsize=16, xlabelfontsize=16, ylabelfontsize=16, xtickfontsize=14, ytickfontsize=14)
        Plots.plot!(p, axes(pol_est_trans_new_tail), pol_est_trans_new_tail, color=:black, ls=:dash, lw=3, xlabel=L"\textrm{Percentile\,\,Grid}", ylabel=L"\textrm{Quantile\,\, Function}", xformatter=:latex, yformatter=:latex, label=L"\textrm{Legendre\,\, Approximation\,,\, Order: 11}")
        Plots.plot!(p, axes(emp_est_new_tail), emp_est_new_tail, color=:red, ls=:dot, lw=3, label=L"\textrm{Empirical\,\,Estimate\,,\, Tail: %$(tail_values[rr])}", xformatter=:latex, yformatter=:latex)

        # Plot The confidence intervals, using fill_range
        Plots.plot!(p, axes(emp_est_new_tail), emp_est_new_tail_lb, fillrange=emp_est_new_tail_ub, color=:red, alpha=0.2, xformatter=:latex, yformatter=:latex, label="")
        Plots.plot!(p, axes(pol_est_trans_new_tail), pol_est_trans_new_tail_lb, fillrange=pol_est_trans_new_tail_ub, color=:black, alpha=0.2, xformatter=:latex, yformatter=:latex, label="")

        p = Plots.plot(p; inset_subplots=[(1, bbox(0.65, 0.3, 0.2, 0.2))])

        # ──────────────────────────
        # 3. draw just the last 5 grid points inside subplot 2
        # ──────────────────────────
        n = length(pol_est_trans_new_tail)
        idxs = n-4:n                          # last 5 indices
        x_tail = axes(pol_est_trans_new_tail, 1)[idxs]

        # main curves
        Plots.plot!(p, x_tail, pol_est_trans_new_tail[idxs];
            color=:black, ls=:dash, lw=2,
            subplot=2, label="", yticks=false, xformatter=:latex, yformatter=:latex)

        Plots.plot!(p, x_tail, emp_est_new_tail[idxs];
            color=:red, ls=:dot, lw=2,
            subplot=2, label="")

        # confidence ribbons
        Plots.plot!(p, x_tail, emp_est_new_tail_lb[idxs];
            fillrange=emp_est_new_tail_ub[idxs],
            color=:red, alpha=0.20,
            subplot=2, label="")

        Plots.plot!(p, x_tail, pol_est_trans_new_tail_lb[idxs];
            fillrange=pol_est_trans_new_tail_ub[idxs],
            color=:black, alpha=0.20,
            subplot=2, label="")

        # optional: tighten axes of the inset so it hugs the data nicely
        xlims!(p[2], x_tail[1], x_tail[end])
        ylims!(p[2],
            min(minimum(emp_est_new_tail_lb[idxs]),
                minimum(pol_est_trans_new_tail_lb[idxs])),
            max(maximum(emp_est_new_tail_ub[idxs]),
                maximum(pol_est_trans_new_tail_ub[idxs])))

        Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/HANK_$(String(measure_of_choice))_11_$(tail_values[rr]).pdf")

        # Now for the raw data
        emp_est_new_tail = vcat(med_est[1:n_p], med_est[n_p+rr])
        emp_est_new_tail_lb = vcat(lb_est[1:n_p], lb_est[n_p+rr])
        emp_est_new_tail_ub = vcat(ub_est[1:n_p], ub_est[n_p+rr])

        pol_est_trans_new_tail = vcat(med_pol[1:n_p], med_pol[n_p+rr])
        pol_est_trans_new_tail_lb = vcat(lb_pol[1:n_p], lb_pol[n_p+rr])
        pol_est_trans_new_tail_ub = vcat(ub_pol[1:n_p], ub_pol[n_p+rr])


        p = Plots.plot(fontsize=16, legendfontsize=16, titlefontsize=16, labelsize=16, xlabelfontsize=16, ylabelfontsize=16, xtickfontsize=14, ytickfontsize=14)
        Plots.plot!(p, axes(pol_est_trans_new_tail), pol_est_trans_new_tail, color=:black, ls=:dash, lw=3, xlabel=L"\textrm{Percentile\,\,Grid}", ylabel=L"\textrm{Quantile\,\, Function}", xformatter=:latex, yformatter=:latex, label=L"\textrm{Legendre\,\, Approximation\,,\, Order: 11}")
        Plots.plot!(p, axes(emp_est_new_tail), emp_est_new_tail, color=:red, ls=:dot, lw=3, label=L"\textrm{Empirical\,\,Estimate\,,\, Tail: %$(tail_values[rr])}", xformatter=:latex, yformatter=:latex)

        # Plot The confidence intervals, using fill_range
        Plots.plot!(p, axes(emp_est_new_tail), emp_est_new_tail_lb, fillrange=emp_est_new_tail_ub, color=:red, alpha=0.2, xformatter=:latex, yformatter=:latex, label="")
        Plots.plot!(p, axes(pol_est_trans_new_tail), pol_est_trans_new_tail_lb, fillrange=pol_est_trans_new_tail_ub, color=:black, alpha=0.2, xformatter=:latex, yformatter=:latex, label="")

        p = Plots.plot(p; inset_subplots=[(1, bbox(0.65, 0.3, 0.2, 0.2))])

        # ──────────────────────────
        # 3. draw just the last 5 grid points inside subplot 2
        # ──────────────────────────
        n = length(pol_est_trans_new_tail)
        idxs = n-4:n                          # last 5 indices
        x_tail = axes(pol_est_trans_new_tail, 1)[idxs]

        # main curves
        Plots.plot!(p, x_tail, pol_est_trans_new_tail[idxs];
            color=:black, ls=:dash, lw=2,
            subplot=2, label="", yticks=false, xformatter=:latex, yformatter=:latex)

        Plots.plot!(p, x_tail, emp_est_new_tail[idxs];
            color=:red, ls=:dot, lw=2,
            subplot=2, label="")

        # confidence ribbons
        Plots.plot!(p, x_tail, emp_est_new_tail_lb[idxs];
            fillrange=emp_est_new_tail_ub[idxs],
            color=:red, alpha=0.20,
            subplot=2, label="")

        Plots.plot!(p, x_tail, pol_est_trans_new_tail_lb[idxs];
            fillrange=pol_est_trans_new_tail_ub[idxs],
            color=:black, alpha=0.20,
            subplot=2, label="")

        # optional: tighten axes of the inset so it hugs the data nicely
        xlims!(p[2], x_tail[1], x_tail[end])
        ylims!(p[2],
            min(minimum(emp_est_new_tail_lb[idxs]),
                minimum(pol_est_trans_new_tail_lb[idxs])),
            max(maximum(emp_est_new_tail_ub[idxs]),
                maximum(pol_est_trans_new_tail_ub[idxs])))

        Plots.savefig(p, "/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/HANK_$(String(measure_of_choice))_11_$(tail_values[rr])_raw.pdf")
    end
end


# # Compute the MSE between empirical and estimated quantiles
# pol_est_trans_orig = reverse_inverse_hyperbolic_sine(pol_est_trans) .* correction

# # Compute the MSE for the bottom, middle, and top quantiles
# mse[mse_i] = mean((emp_est_trans .- pol_est_trans) .^ 2)
# mse_bot[mse_i] = mean((emp_est_trans[1:50] .- pol_est_trans[1:50]) .^ 2)
# mse_mid[mse_i] = mean((emp_est_trans[51:90] .- pol_est_trans[51:90]) .^ 2)
# mse_top[mse_i] = mean((emp_est_trans[91:end] .- pol_est_trans[91:end]) .^ 2)

# # Compute the RMSE for the bottom, middle, and top quantiles
# Rmse[mse_i] = sqrt(mean((emp_est .- pol_est_trans_orig) .^ 2))
# Rmse_bot[mse_i] = sqrt(mean((emp_est[1:50] .- pol_est_trans_orig[1:50]) .^ 2))
# Rmse_mid[mse_i] = sqrt(mean((emp_est[51:90] .- pol_est_trans_orig[51:90]) .^ 2))
# Rmse_top[mse_i] = sqrt(mean((emp_est[91:end] .- pol_est_trans_orig[91:end]) .^ 2))

# mse = zeros(length(orders_to_estimate))
# mse_bot = zeros(length(orders_to_estimate))
# mse_mid = zeros(length(orders_to_estimate))
# mse_top = zeros(length(orders_to_estimate))

# Rmse = zeros(length(orders_to_estimate))
# Rmse_bot = zeros(length(orders_to_estimate))
# Rmse_mid = zeros(length(orders_to_estimate))
# Rmse_top = zeros(length(orders_to_estimate))

# # Concatenate the MSE results
# mse_results = hcat(mse, mse_bot, mse_mid, mse_top)
# Rmse_results = log.(hcat(Rmse, Rmse_bot, Rmse_mid, Rmse_top) .+ 0.1)

# # Plot the MSE
# Plots.plot(orders_to_estimate, mse_results, xlabel=L"\textrm{Order}", ylabel=L"\textrm{MSE}",
#     xformatter=:latex, yformatter=:latex,
#     color=:auto, marker=:circle, markersize=4, label=[L"\textrm{All}" L"\textrm{Bottom}" L"\textrm{Middle}" L"\textrm{Top}"],
#     legend=:topright,
#     grid=true,
#     size=(600, 400))
# Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/mse_qf_$(String(measure_of_choice)).pdf")

# # Plot the RMSE
# Plots.plot(orders_to_estimate, Rmse_results, xlabel=L"\textrm{Order}", ylabel=L"\textrm{RMSE}",
#     xformatter=:latex, yformatter=:latex,
#     color=:auto, marker=:circle, markersize=4,
#     label=[L"\textrm{All}" L"\textrm{Bottom}" L"\textrm{Middle}" L"\textrm{Top}"],
#     legend=:topright,
#     grid=true,
#     size=(600, 400))
# Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/rmse_qf_$(String(measure_of_choice)).pdf")
