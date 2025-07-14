cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")

using Integrals
@unpack df_vec = obs_data
df = df_vec[1][1]
df = df[df[:, :year].==2019, :]

# Cleaning out NaNs
non_missing = coalesce.(df, NaN)
non_missing = filter("income" => !isnan, select(df, ["income", "wealth", "consum", "weight", "id"]))
filter!("weight" => !isnan, non_missing)
filter!("income" => !isnan, non_missing)
filter!("wealth" => !isnan, non_missing)
filter!("consum" => !isnan, non_missing)

df_3D = select(non_missing, ["consum", "income", "wealth", "weight"])

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

for measure_of_choice in [:wealth] #, :income, :consum]
    some_df = copy(df_3D)

    # # Drop all observations that are equal to zero
    # if measure_of_choice == :wealth
    #     filter!(x -> x.wealth > 1, some_df)
    # end

    sort!(some_df, measure_of_choice)
    data = some_df[!, measure_of_choice][:]
    weights2 = some_df[!, :weight][:]

    # Plot the shares of the measure of choice across different bins 

    # Assume `data` is already sorted and you have weights
    total = sum(weights2 .* data)

    # Define breakpoints — here 10 equal-sized bins (deciles)
    percentiles = collect(0:0.1:1.0)
    bin_edges = quantile(data, weights(weights2), percentiles)

    # Initialize storage for wealth shares
    bin_shares = Float64[]

    for i in 1:(length(bin_edges)-1)
        # Find data in the current bin
        in_bin = (data .>= bin_edges[i]) .& (data .< bin_edges[i+1])
        bin_sum = sum(data[in_bin] .* weights2[in_bin])
        push!(bin_shares, bin_sum / total)
    end

    # Plot the shares
    Plots.bar(1:10, bin_shares, xlabel="Decile", ylabel="$(String(measure_of_choice)) of Total Wealth", title="$(String(measure_of_choice)) Shares by Decile")
    Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/$(String(measure_of_choice))_shares.pdf")


    @unpack gdp_series = obs_data
    gdp_series[!, "date"] = QuarterlyDate.(gdp_series[!, "time"])
    a = filter(x -> x.date == QuarterlyDate(2019, 4), gdp_series)
    correction = a[1, "$(String(measure_of_choice))_per_hh"]
    data_trans = inverse_hyperbolic_sine(data ./ correction)

    # Estimate the CDF
    p_values = collect(0.01:0.01:1.0)
    p_values[end] = 0.9999

    # Generate the quantile function
    emp_est_trans = []
    emp_est = []
    s_weights = cumsum(weights2) / sum(weights2)

    # Transformed
    for p in p_values
        # est = [meas for (meas, cdf) in zip(some_df[!, measure_of_choice], s_weights) if cdf >= p][1]
        est = [meas for (meas, cdf) in zip(data_trans, s_weights) if cdf >= p][1]
        push!(emp_est_trans, est)
    end

    # Original
    for p in p_values
        # est = [meas for (meas, cdf) in zip(some_df[!, measure_of_choice], s_weights) if cdf >= p][1]
        est = [meas for (meas, cdf) in zip(data, s_weights) if cdf >= p][1]
        push!(emp_est, est)
    end

    # emp_est_trans = inverse_hyperbolic_sine(emp_est_trans)
    orders_to_estimate = collect(3:100)

    mse = zeros(length(orders_to_estimate))
    mse_bot = zeros(length(orders_to_estimate))
    mse_mid = zeros(length(orders_to_estimate))
    mse_top = zeros(length(orders_to_estimate))

    Rmse = zeros(length(orders_to_estimate))
    Rmse_bot = zeros(length(orders_to_estimate))
    Rmse_mid = zeros(length(orders_to_estimate))
    Rmse_top = zeros(length(orders_to_estimate))

    # Plot the results
    for (mse_i, i) in enumerate(orders_to_estimate)
        Plots.plot()
        q_est = series_estimator(data_trans, weights2, i, p_values)

        Plots.plot!(axes(q_est), q_est, color=:black, ls=:dash, xlabel="x", ylabel="CDF", title="CDF Estimation using Polynomial Basis")
        Plots.plot!(axes(q_est), emp_est_trans, color=:red, ls=:dot, label="Empirical CDF")

        Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/$(String(measure_of_choice))_cdf_est$i.pdf")

        # Compute the MSE between empirical and estimated quantiles
        q_est_orig = reverse_inverse_hyperbolic_sine(q_est) .* correction

        # Compute the MSE for the bottom, middle, and top quantiles
        mse[mse_i] = mean((emp_est_trans .- q_est) .^ 2)
        mse_bot[mse_i] = mean((emp_est_trans[1:50] .- q_est[1:50]) .^ 2)
        mse_mid[mse_i] = mean((emp_est_trans[51:90] .- q_est[51:90]) .^ 2)
        mse_top[mse_i] = mean((emp_est_trans[91:end] .- q_est[91:end]) .^ 2)

        # Compute the RMSE for the bottom, middle, and top quantiles
        Rmse[mse_i] = sqrt(mean((emp_est .- q_est_orig) .^ 2))
        Rmse_bot[mse_i] = sqrt(mean((emp_est[1:50] .- q_est_orig[1:50]) .^ 2))
        Rmse_mid[mse_i] = sqrt(mean((emp_est[51:90] .- q_est_orig[51:90]) .^ 2))
        Rmse_top[mse_i] = sqrt(mean((emp_est[91:end] .- q_est_orig[91:end]) .^ 2))
    end

    # Concatenate the MSE results
    mse_results = hcat(mse, mse_bot, mse_mid, mse_top)
    Rmse_results = log.(hcat(Rmse, Rmse_bot, Rmse_mid, Rmse_top) .+ 0.1)

    # Plot the MSE
    Plots.plot(orders_to_estimate, mse_results, xlabel=L"\textrm{Order}", ylabel=L"\textrm{MSE}",
        xformatter=:latex, yformatter=:latex,
        color=:auto, marker=:circle, markersize=4, label=[L"\textrm{All}" L"\textrm{Bottom}" L"\textrm{Middle}" L"\textrm{Top}"],
        legend=:topright,
        grid=true,
        size=(600, 400))
    Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/mse_qf_$(String(measure_of_choice)).pdf")

    # Plot the RMSE
    Plots.plot(orders_to_estimate, Rmse_results, xlabel=L"\textrm{Order}", ylabel=L"\textrm{RMSE}",
        xformatter=:latex, yformatter=:latex,
        color=:auto, marker=:circle, markersize=4,
        label=[L"\textrm{All}" L"\textrm{Bottom}" L"\textrm{Middle}" L"\textrm{Top}"],
        legend=:topright,
        grid=true,
        size=(600, 400))
    Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/rmse_qf_$(String(measure_of_choice)).pdf")
end

