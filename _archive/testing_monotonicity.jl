# import csv file
using CSV

data = CSV.read("/home/luisc/Distributional_Dynamics/7_Results/consum_and_income_and_wealth additional factors/from_mcmc/data/PSID_coefficients.csv", DataFrame)
aggregate_data = DataFrame(XLSX.readtable(raw"/home/luisc/Distributional_Dynamics/inflation_corrected_correction_series.xlsx", "data", header=true,))
measures = ["consum", "income", "wealth"]

aggregate_data[!, "date"] = QuarterlyDate.(aggregate_data[!, "time"])
correction_names = [meas * "_per_hh" for meas in measures]
filter!(row -> row.date == QuarterlyDate(2000, 1), aggregate_data)
filter!(row -> QuarterlyDate(row.time) == QuarterlyDate(2000, 1), data)

# For data, keep last 30 columns 
data_pcfs = vec(Matrix(data[:, end-29:end]))
data_cops = vec(Matrix(data[:, 2:end-30]))
data_cops = reshape(data_cops, (10, 10, 10, 1))

# Copula is quick 
cop = generate_copula_densities(data_cops, measures, 10)

select_series = select(aggregate_data, correction_names)
split_pcfs = [data_pcfs[I] for I in Iterators.partition(eachindex(data_pcfs), 10)]  # split by measure 
ints = collect(range(0, 1, length=10000))
new_data_pcf = [zeros(length(ints) - 1, 1) for i in 1:3]

for m in eachindex(split_pcfs)
    for i in eachindex(ints[1:end-1])
        # Using coefs, generate pcf function and then integrate pcf function over diff. intervals 
        # integral, _ = quadgk(u -> reverse_inverse_hyperbolic_sine(eval_quantile_function(split_pcfs[m][:, 1], 9, u))[1] .* select_series[1, correction_names[m]], ints[i], ints[i+1], rtol=1e-8)
        integral, _ = quadgk(u -> eval_quantile_density(split_pcfs[m][:, 1], 9, u)[1], ints[i], ints[i+1], rtol=1e-8)

        # Undo treatment of data => gives us average quantile within the interval 
        new_data_pcf[m][i, 1] = integral / (ints[i+1] - ints[i]) #reverse_inverse_hyperbolic_sine(integral)[1] .* select_series[t, correction_names[m]] #./ (intervals[i+1] - intervals[i])
    end
end

function eval_quantile_density(coefficients, order, u)

    basis = zeros(1, order + 1)

    for j in 0:order
        basis[j+1] = legendre_derivative(j, u)
    end

    quants = basis * coefficients

    return quants
end



function Q_m(m, x)
    L_m = legendre_polynomial(m, 2x - 1)

    return sqrt(2m + 1) * L_m
end

function legendre_derivative(m, x)
    if m == 0
        return 0.0
    elseif m == 1
        return 1.0
    else
        return (m / (x^2 - 1)) * (x * legendre_polynomial(m, x) - legendre_polynomial(m - 1, x))
    end
end

function copula_cdf_estimator(X, integrals, u)
    C_N = 0.0

    # Dimension of copula 
    d = length(size(X))

    # Order of the object 
    N = size(X, 1) - 1

    # Ranges for the object
    ranges = [(0:N) for _ in 1:d]

    # All possible orders of the object
    m_combos = collect(Iterators.product(ranges...))

    # Look over each weight <==> looping over each m_combos 
    # Threads.@threads 
    for ci in CartesianIndices(m_combos)
        m = Tuple(m_combos[ci])
        rho_m = X[ci]
        product = 1.0

        for j in 1:d
            product *= integrals[(m[j], u[j])]
        end

        C_N += rho_m * product
    end

    return C_N
end


function generate_copula_densities(X, measures, grid_size_data_cop)
    # In the case of the reconstructions, if the dataset ONCE had 3 measures observed, then predictions will be made for all 3 

    # 'd' has to be based on the coefficients that are obsered <==> the observed measures 
    T = size(X)[end]
    D = length(size(X)[1:end-1])

    # This has to be of the same dimensionality of the estimation 
    obs_cop_size = tuple([grid_size_data_cop for i in 1:D]...) # doesnt affect SeriesEstimator
    new_dv = fill!(Array{Float64}(undef, obs_cop_size..., T), NaN)  #zeros(cop_size..., T)
    # grid_cop      = size(X, 1)
    # cop_size      = tuple([grid_cop for i in 1:D]...) 
    colons = copula_case(measures, measures)

    # Grid points 
    x = select_grid_points(grid_size_data_cop)

    # Compute the integrals first
    N = size(X, 1) - 1
    integrals = precompute_integrals(N, x)

    # Threads.@threads 
    for t in 1:T
        # At each period, check what is observed 
        obs_meas = check_observed_measures(X[colons..., t], measures)
        cop_ind = copula_case(obs_meas, measures)
        obs_d = length(obs_meas)

        if obs_d <= 1
            nothing
        else
            XX = obs_d == 2 ? [[x[i], x[j]] for i in eachindex(x), j in eachindex(x)] : [[x[i], x[j], x[k]] for i in eachindex(x), j in eachindex(x), k in eachindex(x)]

            cop_w = X[cop_ind..., t]
            cop_cdf = obs_d == 2 ? [copula_cdf_estimator(cop_w, integrals, [XX[i, j][1], XX[i, j][2]]) for i in eachindex(x), j in eachindex(x)] : [copula_cdf_estimator(cop_w, integrals, [XX[i, j, k][1], XX[i, j, k][2], XX[i, j, k][3]]) for i in eachindex(x), j in eachindex(x), k in eachindex(x)]
            new_dv[cop_ind..., t] .= cdf_to_pdf(cop_cdf)
        end
    end

    return new_dv
end

function cdf_to_pdf(cdf_matrix::Array{Float64,2})
    # Initialize the PDF matrix with zeros
    pdf_matrix = zeros(size(cdf_matrix))

    # Compute differences between adjacent cells
    for i in 1:size(cdf_matrix, 1)
        for j in 1:size(cdf_matrix, 2)
            left = j > 1 ? cdf_matrix[i, j-1] : 0
            above = i > 1 ? cdf_matrix[i-1, j] : 0
            left_above = (i > 1 && j > 1) ? cdf_matrix[i-1, j-1] : 0
            pdf_matrix[i, j] = cdf_matrix[i, j] - left - above + left_above
        end
    end

    # correct pdf_matrix 
    pdf_matrix[pdf_matrix.<0] .= 0
    pdf_matrix .= pdf_matrix ./ sum(pdf_matrix)

    return pdf_matrix
end