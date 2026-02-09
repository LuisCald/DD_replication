# Function to calculate ranks for each dimension in a multidimensional dataset
function calculate_ranks(data)
    return [sortperm(data[:, j]) for j in 1:size(data, 2)]
end


# Function to compute the Beta CDF for given ranks and dimension values
function compute_beta_cdf(data, ranks, a, b)
    n = size(data, 1)
    beta_cdf = Array{Float64}(undef, n, size(data, 2))
    for j in 1:size(data, 2)
        for i in 1:n
            rank = ranks[j][i]
            beta_distribution = Beta(a + (rank), b + (n - rank))
            beta_cdf[i, j] = cdf(beta_distribution, data[i, j])
        end
    end
    return beta_cdf
end

# Function to compute the Beta empirical copula
function beta_empirical_copula(data, weights, u, a, b)
    ranks = calculate_ranks(data)
    beta_cdf_values = compute_beta_cdf(data, ranks, a, b)
    n = size(data, 1)
    
    # Evaluating copula value at u
    weighted_products = [prod(beta_cdf_values[i, :] .<= u) for i in 1:n]
    copula_value = sum(weighted_products)
    
    return copula_value
end

# Example data generation (2D for simplicity)
n = 100
data = rand(n, 2)
u = [0.5, 0.5]  # Point at which to evaluate the copula
a = 0           # Beta distribution parameter
b = 1           # Beta distribution parameter

# Calculate the Beta empirical copula
copula_value = beta_empirical_copula(data, u, a, b)

function evaluate_copula_on_grid(data, grid_points, a, b)
    ranks           = calculate_ranks(data)
    beta_cdf_values = compute_beta_cdf(data, ranks, a, b)
    copula_grid     = zeros(size(grid_points, 1), size(grid_points, 1))
    n = size(data, 1)
    
    for i in axes(grid_points, 1)
        for j in axes(grid_points, 1)
            u = grid_points[i]
            v = grid_points[j]

            weighted_products = [(prod(beta_cdf_values[k, :] .<= [u, v])) for k in 1:n]
            copula_grid[i, j] = sum(weighted_products)
        end
    end
    return copula_grid
end

# Example data and parameters
n = 1000
for m in ["income", "wealth"]
    df[:, m * "_rank"] = competerank(df[:, m]) ./ (length(df[:, m]) + 1)
  end
data = Matrix(df[:, ["income_rank", "wealth_rank"]])
grid_size = 10
grid_points = collect(.1:.1:1)
grid_points[end] = .99
a = 0
b = 1

copula_value = beta_empirical_copula(data, [.99, .99], a, b)

# Evaluate the copula on the grid
copula_values = evaluate_copula_on_grid(data, grid_points, a, b)
copula_values = (copula_values .- minimum(copula_values)) ./ (maximum(copula_values) - minimum(copula_values))

cop_pdf = cdf_to_pdf2(copula_values)


# Plot the copula
Plots.plot(grid_points, grid_points, cop_pdf, st=:surface, xlabel="u", ylabel="v", zlabel="PDF", title="Weighted Beta Empirical Copula PDF")
Plots.savefig("NonParametricAnalysis/weighted_copula.pdf")
