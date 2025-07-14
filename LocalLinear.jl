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

function local_series(data, weights; order=10, bandwidth=0.1, grid=0.0:0.01:1.0)
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
        # d = vec(sum(Phi_w .^ 2; dims=1))     # column-wise sums
        # β[:, g] = β[:, g] ./ sqrt.(d)          # element-wise
        # G = (Phi_w' * Phi_w) / sum(kvec)   # (m+1)×(m+1)
        # L = cholesky(G).L                  # lower-triangular
        # β[:, g] = L * β[:, g]
    end
    return q_hat, β
end


# for measure_of_choice in [:wealth] #, :income, :consum]
measure_of_choice = :wealth
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
p_values[end] = 0.9999
s_weights = cumsum(weights2) / sum(weights2)

# Plot the results    
O = 10
q_est, coefs = series_estimator_with_coefs(data_trans, weights2, O, p_values)
q_est2, coefs2 = local_series(data_trans, weights2; order=O, bandwidth=0.1, grid=p_values)
coefs2 = coefs2 ./ sum(abs.(coefs2), dims=1)
mean_coefs2 = abs.(mean(coefs2, dims=2))
Plots.plot()
Plots.plot!(axes(q_est), q_est, color=:black, ls=:dash, xlabel="x", ylabel="PCF", label="Series")
Plots.plot!(axes(q_est2), q_est2, color=:red, ls=:dot, label="LL")
Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/$(String(measure_of_choice))_LLseries_est.pdf")

Plots.plot()
Plots.plot!(axes(coefs), coefs, color=:black, ls=:dash, xlabel="x", ylabel="Coefs", label="Series")
Plots.plot!(axes(coefs2), mean_coefs2, color=:red, ls=:dot, label="LL")

Plots.savefig("/Users/lc/Dropbox/Distributional_Dynamics/7_Results/order_analysis/$(String(measure_of_choice))_LLseries_coefs.pdf")

cor(coefs, mean_coefs2)




