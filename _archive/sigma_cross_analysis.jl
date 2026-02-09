# cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")

# Function to generate a random covariance matrix
function generate_random_covariance(N::Int)
    A = randn(N, N) # Random matrix
    Σ = A * A' # Symmetric positive semi-definite matrix
    return cov(diag(Σ)) .* Σ # Normalize variances to 1
end

# Function to generate time series data with temporal and cross-sectional structure
function generate_time_series(T::Int, N::Int, Σ::Matrix{Float64}, ρ::Float64; missing_rate::Float64 = 0.0)
    L = cholesky(Σ).L # Cholesky decomposition of Σ for cross-sectional structure
    X = zeros(T, N) # Initialize time series data
    X[1, :] = L * randn(N) # Initialize first time step
    
    # Generate AR(1) process for each variable with cross-sectional covariance
    for t in 2:T
        X[t, :] = ρ * X[t - 1, :] + L * randn(N)
    end
    
    # Create incomplete data if missing_rate > 0
    X_incomplete = deepcopy(X)
    if missing_rate > 0.0
        num_missing_cols = Int(round(N * missing_rate)) # Number of columns to set as missing
        missing_cols = sample(1:N, num_missing_cols, replace=false) # Randomly select columns
        X_incomplete[:, missing_cols] .= NaN # Set entire columns to NaN
    end
    
    return X, X_incomplete
end

# Compute the exact variance of Z (using fully observed data)
function compute_exact_variance(X_complete, Σ)
    Σ_inv_sqrt = sqrt(inv(Σ)) # Inverse square root of Σ
    Z = Σ_inv_sqrt * X_complete'
    return cov(Z, dims=2)
end

# Compute the variance of Z using estimated Σ
function compute_estimated_variance(X_incomplete)
    # Remove cols with missing values
    valid_cols = mapslices(col -> all((!isnan).(col)), X_incomplete, dims=1)[:]
    XM = X_incomplete[:, valid_cols]
    Σ_hat = cov(XM, dims=1)
    # Σ_hat     = nancov(X_incomplete, dims=1)
    # zero_inds = find_zero_diagonal_indices(Σ_hat)

    # for (v,w) in zero_inds
    #     Σ_hat[v,w]        = 1 #[v == 0 ? v + .1 : v for v in diag(Σ[k])]
    # end

    Σ_hat_inv_sqrt = sqrt(inv(nearest_spd(Σ_hat)))
    Z = Σ_hat_inv_sqrt[:, :] * XM'
    # Z = Σ_hat_inv_sqrt[valid_cols, valid_cols] * X_incomplete[:, valid_cols]'
    return cov(Z, dims=2)
end

# Simulation study for time series data
function simulation_study(T::Int, N::Int, ρ::Float64, n_trials::Int; missing_rate::Float64 = 0.0)
    Σ = diagm(ones(N)) # generate_random_covariance(N) # Automatically generate covariance matrix
    results_exact = []
    results_estimated = []
    results_X_complete = []
    results_X_incomplete = []

    for _ in 1:n_trials
        # Generate time series data
        X_complete, X_incomplete = generate_time_series(T, N, Σ, ρ, missing_rate=missing_rate)
        
        # Store the datasets 
        push!(results_X_complete, X_complete)
        push!(results_X_incomplete, X_incomplete)

        # Exact variance
        exact_var = compute_exact_variance(X_complete, Σ)
        push!(results_exact, exact_var)

        # Estimated variance
        estimated_var = compute_estimated_variance(X_incomplete)
        push!(results_estimated, estimated_var)

    end

    return results_exact, results_estimated, results_X_complete, results_X_incomplete, Σ
end

function compute_estimated_variance_our_way(results)    
    
    # Create a large matrix, hcatting all the X_complete matrices
    X_complete_rs = reduce(hcat, results)
    stacked       = reshape(X_complete_rs, size(results[1])..., length(results)) # Reshape into 3D

    # Demean across bootstraps 
    stacked .= stacked .- mean(stacked, dims=3)

    # Reshape the 3D array to 2D
    stacked = reshape(stacked, size(stacked)[1] * size(stacked)[3], size(stacked)[2])
    
    # Compute the covariance matrix
    Σ_hat = nancov(stacked, dims=1)
    replace!(Σ_hat, -0.0=>0.0)

    return Σ_hat
end

function compute_mean_estimated_diag(results_estimated)
    diag_sums = zeros(size(results_estimated[1], 1)) # Initialize sum of diagonals
    diag_counts = length(results_estimated) * size(results_estimated[1], 1) 

    for matrix in results_estimated
        diag_sums .+= diag(matrix) # Accumulate sum of diagonals
    end
    ovr_mean = diag_sums ./ length(results_estimated) # Compute the overall mean
    
    return mean(ovr_mean) # Return the mean of the overall mean
    
    return 
end

# Parameters
N = 100 # Number of variables
T = 20 # Number of time steps
ρ = 0.8 # AR(1) coefficient for temporal dependency
n_trials = 500 # Number of trials
missing_rate = 0.8 # 10% missing data

# Run simulation
results_exact, results_estimated, results_X_complete, results_X_incomplete, Σ = simulation_study(T, N, ρ, n_trials, missing_rate=missing_rate)

# Reshape results 
stacked = reduce(hcat, results_exact) # Stack matrices horizontally
stacked = reshape(stacked, size(results_exact[1])..., length(results_exact)) # Reshape into 3D

stacked2 = reduce(hcat, results_estimated) # Stack matrices horizontally
stacked2 = reshape(stacked2, size(results_estimated[1])..., length(results_estimated)) # Reshape into 3D

# Analyze results
mean_exact = mean(stacked, dims=3)
mean_estimated = mean(stacked2, dims=3)
our_way_complete = compute_estimated_variance_our_way(results_X_complete)    

mean(diag(mean_exact[:,:]))
mean(diag(mean_estimated[:,:]))
mean(diag(our_way_complete[:,:]))

# Compare the estimated variance with the true variance, Σ, by hcatting the diagonals 
sig_mat  = hcat(diag(mean_exact[:,:]), diag(our_way_complete[:,:]), diag(Σ))


results_summary = Dict()
N_values = [100, 300, 500]  # Number of variables
T_values = [20, 50]               # Number of time steps
missing_rates = [0.0, 0.2, 0.4, 0.6, 0.8, 0.9] # Missing data rates
n_trials = 100                   # Number of trials


# The simulation results 
# Iterate over all parameter combinations
for N in N_values
    for T in T_values
        for missing_rate in missing_rates
            println("Running for N=$N, T=$T, missing_rate=$missing_rate")
            
            # Run simulation
            results_exact, results_estimated, _, _, _ = simulation_study(T, N, ρ, n_trials, missing_rate=missing_rate)

            mean_estimated_diag = compute_mean_estimated_diag(results_estimated)
            mean_exact_diag     = compute_mean_estimated_diag(results_exact)

            # # Reshape results for analysis
            # stacked = reduce(hcat, results_estimated) # Stack matrices horizontally
            # stacked = reshape(stacked, size(results_estimated[1])..., length(results_estimated)) # Reshape into 3D

            # # Compute mean of diagonal for estimated covariance
            # mean_estimated_diag = mean(diag(mean(stacked, dims=3)[:, :]))

            # Store the result
            results_summary[(N, T, missing_rate)] = [mean_estimated_diag, mean_exact_diag]
        end
    end
end


function plot_results(results_summary, N_values, T_values, missing_rates)
    # Prepare data for plotting
    plot_data = Dict()  # Store data to plot for each combination of N and T

    for N in N_values
        for T in T_values
            # Collect mean_estimated_diag for each missing_rate
            y_values = [results_summary[(N, T, missing_rate)] for missing_rate in collect(sort(missing_rates))]
            plot_data[(N, T)] = Float64.(y_values)
        end
    end

    # Plot settings
    Plots.plot(
         xlabel=L"\textrm{Missing\,\, Rate}",
         ylabel="Mean Estimated Diagonal")

    # Add lines to the plot
    for ((N, T), y_values) in plot_data
        Plots.plot!(missing_rates, y_values, label="N=$N, T=$T", marker=:o)
    end

    Plots.savefig("results_summary.pdf")
end