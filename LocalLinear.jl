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

function series_estimator_with_coefs(data, weights, order, p_values)
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
    return quants, coefficients
end

function local_series(data, weights, grid; order=10, bandwidth=0.01)
    n = length(data)
    s_weights = cumsum(weights) / sum(weights)
    Qm = (j, u) -> Q_m(j, u)                    # your Legendre routine
    m = order
    y = data
    q_hat = similar(grid)                         # store fitted values

    # Storing the coefficients for each polynomial order
    β = zeros(m + 1, length(grid))

    # Pre-compute global Phi for speed
    Phi = [Qm(j, s_weights[i]) for i in 1:n, j in 0:m]

    for (g, p) in enumerate(grid)
        # kvec      = @. weights * Kernel((s_weights - p)/bandwidth) / bandwidth
        # Use a Gaussian kernel for local weighting
        kern = @. exp(-0.5 * ((s_weights - p) / bandwidth)^2) / (bandwidth * sqrt(2π))   # Gaussian
        kvec = weights .* kern                 # ⟨survey⟩ × ⟨kernel⟩
        Wp_sqrt = sqrt.(kvec)
        Phi_w = Wp_sqrt .* Phi                  # element-wise multiply
        y_w = Wp_sqrt .* y

        β[:, g] = (Phi_w' * Phi_w) \ (Phi_w' * y_w)       # local coefficients
        q_hat[g] = sum(β[j+1, g] * Qm(j, p) for j in 0:m)
    end

    return q_hat, β
end


# for measure_of_choice in [:wealth] #, :income, :consum]
for measure_of_choice in [:wealth, :income, :consum]
    some_df = copy(df_3D)

    # Get the data
    sort!(some_df, measure_of_choice)
    data = some_df[!, measure_of_choice][:]
    weights2 = some_df[!, :weight][:]

    # Get the aggregate data
    @unpack gdp_series = obs_data
    gdp_series[!, "date"] = QuarterlyDate.(gdp_series[!, "time"])
    a = filter(x -> x.date == QuarterlyDate(2019, 4), gdp_series)
    correction = a[1, "$(String(measure_of_choice))_per_hh"]
    data_trans = inverse_hyperbolic_sine(data ./ correction)

    # Estimate the CDF
    p_values = collect(0.01:0.01:1.0)
    p_values[end] = 0.995
    s_weights = cumsum(weights2) / sum(weights2)
    Δp = 0.01                      # same for every g
    weights = fill(Δp, length(p_values))

    # the data Transformed
    emp_est_trans = zeros(length(p_values))
    for (pp, p) in enumerate(p_values)
        # est = [meas for (meas, cdf) in zip(b_sample[!, measure_of_choice], s_weights) if cdf >= p][1]
        try
            emp_est_trans[pp] = [meas for (meas, cdf) in zip(data_trans, s_weights) if cdf >= p][1]
        catch e
            println(p)
        end
    end

    # Plot the results    
    O = 11
    # Estimate the coefficients
    q_est, coefs = series_estimator_with_coefs(data_trans, weights2, O, p_values)
    q_est2, coefs2 = local_series(data_trans, weights2, p_values; order=O, bandwidth=0.1)

    # Complete Approximation
    Plots.plot(fontsize=16, legendfontsize=16, titlefontsize=16, labelsize=16, xlabelfontsize=16, ylabelfontsize=16, xtickfontsize=14, ytickfontsize=14, xformatter=:latex, yformatter=:latex)
    Plots.plot!(axes(emp_est_trans), emp_est_trans, lw=2, color=:black, ls=:solid, label=L"\textrm{Observed}")
    Plots.plot!(axes(q_est), q_est, color=:blue, lw=2, ls=:dash, xlabel=L"\textrm{Percentile\,\,Grid}", ylabel=L"\textrm{Percentile\,\, Function}", label=L"\textrm{Global}")
    Plots.plot!(axes(q_est2), q_est2, color=:red, lw=3, ls=:dot, label=L"\textrm{Local}")
    Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/$(String(measure_of_choice))_approx_all.pdf")


    # Scale global coefficients
    coefs = abs.(coefs) ./ sum(abs.(coefs), dims=1)

    # Define regions of interest
    regions = [1:20, 21:40, 41:60, 61:80, 81:100, 91:100, 95:100, 99:100]

    for (i, region) in enumerate(regions)
        # Select the region
        coefs_region = coefs2[:, region] # upper tail 

        # Use coefs_bar to estimate the quantile function
        coefs_region_bar = mean(coefs_region, dims=2)
        # q_hat = [sum(coefs_region[j+1, pp] * Q_m(j, p) for j in 0:O) for (pp, p) in enumerate(collect(region ./ 100))]
        q_hat = [sum(coefs_region_bar[j+1] * Q_m(j, p) for j in 0:O) for (pp, p) in enumerate(collect(region ./ 100))]

        # Scale the region
        coefs_region = abs.(coefs_region) ./ sum(abs.(coefs_region), dims=1) #TODO: correct sum?

        # Mean of the region
        mean_coefs_region = mean(coefs_region, dims=2) #, Weights(fill(Δp, size(coefs_region, 1))), dims=2)

        # Difference in approximation
        Plots.plot(fontsize=16, legendfontsize=16, titlefontsize=16, labelsize=16, xlabelfontsize=16, ylabelfontsize=16, xtickfontsize=14, ytickfontsize=14, xformatter=:latex, yformatter=:latex)
        Plots.plot!(axes(emp_est_trans), emp_est_trans, lw=2, color=:black, ls=:solid, label=L"\textrm{Observed}")
        Plots.plot!(axes(q_est), q_est, color=:blue, lw=2, ls=:dash, xlabel=L"\textrm{Percentile\,\,Grid}", ylabel=L"\textrm{Quantile\,\, Function}", label=L"\textrm{Global}")
        Plots.plot!(region, q_hat, color=:red, lw=3, ls=:dot, label=L"\textrm{Local}")
        Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/$(String(measure_of_choice))_approx$(i).pdf")

        # Difference in coefficients
        Plots.plot(fontsize=16, legendfontsize=16, titlefontsize=16, labelsize=16, xlabelfontsize=16, ylabelfontsize=16, xtickfontsize=14, ytickfontsize=14, xformatter=:latex, yformatter=:latex)
        Plots.plot!(1:length(coefs), coefs, color=:blue, lw=2, ls=:solid, xlabel=L"\textrm{Order}", ylabel=L"\textrm{Normalized\,\, Coefficient}", label=L"\textrm{Global}")
        Plots.plot!(1:length(mean_coefs_region), mean_coefs_region, color=:red, ls=:dot, lw=2, label=L"\textrm{Local}", xticks=0:2:O)
        Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/$(String(measure_of_choice))_coefs$(i).pdf")
    end

    # Compute similarity across grid points
    similarity = zeros(length(p_values))
    coefs2 = abs.(coefs2) ./ sum(abs.(coefs2), dims=1)
    for i in eachindex(p_values)
        similarity[i] = dot(coefs, coefs2[:, i]) / (norm(coefs) * norm(coefs2[:, i]))
    end

    Plots.plot(fontsize=16, legendfontsize=16, titlefontsize=16, labelsize=16, xlabelfontsize=16, ylabelfontsize=16, xtickfontsize=14, ytickfontsize=14, xformatter=:latex, yformatter=:latex)
    Plots.plot!(axes(similarity), similarity;
        xlabel=L"\textrm{Percentile\,\, Grid}",
        ylabel=L"\textrm{Cosine\,\, similarity}",
        label="",
        ls=:dash,
        lc=:blue,
        lw=2)
    Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/$(String(measure_of_choice))_similarity.pdf")
end

