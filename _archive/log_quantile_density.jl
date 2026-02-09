include("DistributionalDynamics.jl")

# Compute Legendre polynomials using recurrence relation
function legendre_polynomial(m, x)
    if m == 0
        return 1.0
    elseif m == 1
        return x
    else
        P_prev_prev = 1.0
        P_prev = x
        P_current = 0.0

        for n in 2:m
            P_current = ((2n - 1) * x * P_prev - (n - 1) * P_prev_prev) / n
            P_prev_prev, P_prev = P_prev, P_current
        end
        return P_current
    end
end

# Compute the derivative of Legendre polynomials
function legendre_derivative(m, x)
    if m == 0
        return 0.0
    elseif m == 1
        return 1.0
    else
        return (m / (x^2 - 1)) * (x * legendre_polynomial(m, x) - legendre_polynomial(m - 1, x))
    end
end


# Compute quantile function expansion
function estimate_quantile_function(data, weights, order)
    Phi = zeros(length(data), order + 1)
    s_weights = cumsum(weights) / sum(weights)

    for i in eachindex(data)
        for j in 0:order
            Phi[i, j+1] = sqrt(2j + 1) * legendre_polynomial(j, 2s_weights[i] - 1)
        end
    end

    # Solve for coefficients
    coefficients = zeros(order + 1)
    for j in 1:order+1
        for i in 1:length(data)
            coefficients[j] += weights[i] * Phi[i, j] * data[i]
        end
        coefficients[j] /= sum(weights)
    end

    return coefficients
end

# Compute quantile density function q(p)
function estimate_quantile_density(coefficients, order, p_grid)
    q_values = zeros(length(p_grid))
    for i in eachindex(p_grid)
        x = 2p_grid[i] - 1
        q_values[i] = sum(coefficients[m+1] * legendre_derivative(m, x) for m in 1:order) # \sum c_m P_m'(x)
    end
    # q_values .= max.(q_values, 1e-6)  # Ensure positivity

    return q_values
end


# Fit log quantile density function
# function estimate_log_quantile_density(q_values, p_grid, order)
#     log_q_values = inverse_hyperbolic_sine(q_values)
#     Phi = zeros(length(p_grid), order + 1)

#     for i in eachindex(p_grid)
#         for j in 0:order
#             Phi[i, j+1] = sqrt(2j + 1) * legendre_polynomial(j, 2p_grid[i] - 1)
#         end
#     end

#     # Solve for coefficients
#     coefficients = Phi \ log_q_values

#     # # Solve for coefficients
#     # coefficients = zeros(order + 1)
#     # for j in 1:order+1
#     #     for i in 1:length(log_q_values)
#     #         coefficients[j] += Phi[i, j] * log_q_values[i]
#     #     end
#     # end

#     return coefficients
# end

function estimate_log_quantile_density(q_values, p_grid, order, weights)
    log_q_values = inverse_hyperbolic_sine(q_values)
    Phi = legendre_basis(p_grid, order)
    W = Diagonal(sqrt.(weights))  # Weight matrix
    log_q_coefs = (Phi' * W * Phi) \ (Phi' * W * log_q_values)  # Weighted Least Squares
    return log_q_coefs
end


# Integrate back to reconstruct Q(p)
function eval_log_quantile_density(log_q_coefs, order, u)
    basis = zeros(order + 1)
    for j in 0:order
        basis[j+1] = sqrt(2j + 1) * legendre_polynomial(j, 2u - 1)  # Map u from [0,1] to [-1,1]
    end
    return basis' * log_q_coefs
end

# Reconstruct Q(p) using quadgk integration
function reconstruct_quantile_function(log_q_coefs, p_grid, order, Q0)
    integral_q = zeros(length(p_grid))
    integral_q[1] = Q0  # Set initial condition

    for i in 2:length(p_grid)  # Start from 2 to avoid negative index
        # Compute the integral ∫ exp(log q(u)) du over small interval
        integral, _ = quadgk(u -> reverse_inverse_hyperbolic_sine(eval_log_quantile_density(log_q_coefs, order, u)),
            p_grid[i-1], p_grid[i], rtol=1e-8)
        integral_q[i] = integral_q[i-1] + integral  # Accumulate integral over p
    end
    return integral_q
end


# Example Usage
reverse_inverse_hyperbolic_sine(x) = (exp.(2 .* x) .- 1) ./ (2 .* exp.(x))

inverse_hyperbolic_sine(x) = log.(x .+ sqrt.(x .^ 2 .+ 1))
dc = 50000 .* sort(randn(1000)) ./ 40000
data = inverse_hyperbolic_sine(dc)  # Simulated income data

a = rand(length(data))
weights = a / sum(a)
order = 5
p_grid = range(0.01, stop=0.99, length=length(data))

# Step 1: Estimate quantile function coefficients
q_coefs = estimate_quantile_function(data, weights, order)

# Step 2: Compute quantile density q(p)
q_values = estimate_quantile_density(q_coefs, order, p_grid)

# Step 3: Fit log quantile density
# log_q_coefs, oth_coefs = estimate_log_quantile_density(q_values, p_grid, order)
log_q_coefs = estimate_log_quantile_density(q_values, p_grid, order, weights)

# Set initial condition for Q(p) (e.g., minimum quantile value)
Q0 = minimum(data)

# Step 4: Reconstruct quantile function
p_grid2 = range(0.01, stop=0.99, length=10)
reconstructed_Q = reconstruct_quantile_function(log_q_coefs, p_grid2, order, Q0)

Plots.plot(data)
Plots.plot!(reconstructed_Q)
Plots.savefig("log_quantile_density.pdf")

# Plot the legendre polynomials for up to order 10 over some grid within [0,1]
x_grid = range(0, stop=1, length=100)
Plots.plot()
for i in 1:10
    Plots.plot!(x_grid, legendre_polynomial.(i, x_grid), label="P_0 to P_10", legend=:topleft)
end
Plots.savefig("legendre_polynomials.pdf")
