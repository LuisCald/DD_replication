cd("/Users/lc/Dropbox/SigmaTimeAnalysis")
Pkg.activate(".")
using Plots
using Random
using LinearAlgebra
using Statistics
using StatsBase
using DataFrames
using CSV
using NaNStatistics
using Distributions
using LaTeXStrings
# include("DistributionalDynamics.jl")


# Function to generate a random covariance matrix
function generate_random_covariance(N::Int)
    A = randn(N, N) # Random matrix
    Σ = A * A' # Symmetric positive semi-definite matrix
    Σ = Σ ./ sqrt.(diag(Σ) * diag(Σ)')
    return Σ # Normalize variances to 1
end

# Function to generate time series data with temporal and cross-sectional structure
function generate_time_series(T::Int, N::Int, Σ::Matrix{Float64}, A, missing_rate_cross, missing_rate_time)
    # Initialize time series matrix
    X = randn(T, N)
    X[1, :] = rand(MvNormal(zeros(N), Σ))  # Initial observation

    # Cholesky decomposition for correlated noise
    L = cholesky(Σ).L

    # Simulate VAR(1) process
    for t in 2:T
        noise = L * randn(N)
        X[t, :] = A * X[t-1, :] + noise
    end

    # Create incomplete data if missing_rate > 0
    X_incomplete = deepcopy(X)

    num_missing_cols = Int(round(N * missing_rate_cross)) # Number of columns to set as missing
    num_missing_rows = Int(round(T * missing_rate_time)) # Number of columns to set as missing

    missing_cols = sample(1:N, num_missing_cols, replace=false) # Randomly select columns
    missing_rows = sample(1:T, num_missing_rows, replace=false) # Randomly select rows
    X_incomplete[missing_rows, missing_cols] .= NaN

    return X, X_incomplete
end

# Compute the exact variance of Z (using fully observed data)
function compute_exact_variance(X)
    # Compute variance-cov
    Σ = cov(X, dims=1)

    # Compute the inverse square root of Σ as we do in paper
    Σ_inv_sqrt = sqrt(inv(nearest_spd(Σ)))

    # Premultiply with data
    Z = Σ_inv_sqrt * X'

    # Compute the covariance of Z
    Σ_Z = cov(Z, dims=2)

    return Σ_Z
end

# Compute the variance of Z using estimated Σ
function compute_estimated_variance(X_incomplete)
    # Remove cols with missing values
    valid_cols = mapslices(col -> all((!isnan).(col)), X_incomplete, dims=1)[:]
    valid_rows = mapslices(row -> all((!isnan).(row)), X_incomplete, dims=2)[:]

    # Reduced matrix
    XM = X_incomplete[valid_rows, valid_cols]

    # Variance-covariance mat of reduced matrix
    Σ_hat = cov(XM, dims=1)
    Σ_hat_inv_sqrt = sqrt(inv(nearest_spd(Σ_hat)))
    Z = Σ_hat_inv_sqrt[:, :] * XM'
    Σ_Z = cov(Z, dims=2)

    return Σ_Z
    # Σ_hat     = nancov(X_incomplete, dims=1)
    # zero_inds = find_zero_diagonal_indices(Σ_hat)

    # for (v,w) in zero_inds
    #     Σ_hat[v,w]        = 1 #[v == 0 ? v + .1 : v for v in diag(Σ[k])]
    # end

    # Z = Σ_hat_inv_sqrt[valid_cols, valid_cols] * X_incomplete[:, valid_cols]'
end

# Simulation study for time series data
function simulation_study(T::Int, N::Int, ρ::Float64, n_trials::Int, missing_rate_cross, missing_rate_time)

    # Define correlation and persistence
    Σ = generate_random_covariance(N)
    A = randn(N, N)
    spectral_radius = maximum(abs.(eigvals(A)))
    if spectral_radius >= 1
        A .= A ./ (1.1 * spectral_radius)  # Scale slightly below 1 for stability
    end

    # Define containers
    results_exact = []
    results_estimated = []
    results_X_complete = []
    results_X_incomplete = []

    for _ in 1:n_trials
        # Generate time series data
        X_complete, X_incomplete = generate_time_series(T, N, Σ, A, missing_rate_cross, missing_rate_time)

        # Store the datasets 
        push!(results_X_complete, X_complete)
        push!(results_X_incomplete, X_incomplete)

        # Exact variance
        exact_var = compute_exact_variance(X_complete)
        estimated_var = compute_estimated_variance(X_incomplete)

        # Estimated variance
        push!(results_exact, exact_var)
        push!(results_estimated, estimated_var)

    end

    # if keep
    #     return results_exact, results_estimated, results_X_complete, results_X_incomplete
    # else
    return results_exact, results_estimated
    # end
end

function compute_estimated_variance_our_way(results)

    # Create a large matrix, hcatting all the X_complete matrices
    X_complete_rs = reduce(hcat, results)
    stacked = reshape(X_complete_rs, size(results[1])..., length(results)) # Reshape into 3D

    # Demean across bootstraps 
    stacked .= stacked .- mean(stacked, dims=3)

    # Reshape the 3D array to 2D
    stacked = reshape(stacked, size(stacked)[1] * size(stacked)[3], size(stacked)[2])

    # Compute the covariance matrix
    Σ_hat = nancov(stacked, dims=1)
    replace!(Σ_hat, -0.0 => 0.0)

    return Σ_hat
end

function compute_mean_estimated_diag(results_estimated)
    diag_sums = zeros(size(results_estimated[1], 1)) # Initialize sum of diagonals

    for matrix in results_estimated
        diag_sums .+= diag(matrix) # Accumulate sum of diagonals
    end
    ovr_mean = diag_sums ./ length(results_estimated) # Compute the overall mean

    return mean(ovr_mean) # Return the mean of the overall mean

    return
end

function nearest_spd(A::AbstractMatrix)
    """It finds the nearest symmetric positive definite matrix to A.
    This allows for the invertibility in the kalman-filter likelihood calculation.
        https://scicomp.stackexchange.com/questions/30631/how-to-find-the-nearest-a-near-positive-definite-from-a-given-matrix
    """
    identity = Matrix(I, size(A, 1), size(A, 1))
    shift = eps() * identity

    # First, adding a small constant 
    if isposdef(A + shift)
        return A + shift
    end
    # if isposdef_approx(A + shift) > 0.5 return A + shift end

    # Nearest spd without LAPACK and ForwardDiff friendly
    B = (A + A') / 2

    # initialize algo 
    _, FS, FVt = LinearAlgebra.LAPACK.gesvd!('N', 'S', copy(B))  # TODO: change this, check out discourse 

    # iterate 
    # FVt_transpose = Diagonal(ones(size(B, 1))) 
    # C, FVt_transpose = run_qr_algorithm!(copy(B), FVt_transpose)
    # dg     = Diagonal(C)
    # H = FVt_transpose * dg * FVt_transpose' 


    # dg[dg .< 0] .= 0 
    # H = FVt' * dg * FVt + .01I

    # Diagonal 
    dg = Diagonal(FS)

    # Construct spd 
    dg[dg.<0] .= 1e-10
    eig_min = minimum(diag(dg)) # minimum(abs.(dg)[abs.(dg) .> 0])
    H = FVt' * dg * FVt
    G = @. 0.5 * (H + H') + shift

    if isposdef(G)
        return G
    else
        # test that H is in fact PD. if it is not so, then tweak it just a bit.
        p = false
        count = 1
        # small_ϵ(k) = (-eig_min .* k .* k .+ eps(eig_min))
        small_ϵ = eps() .* identity
        ii = 0
        while p == false && count < 1000
            G .+= small_ϵ
            p = isposdef(G)
            ii += 1
            count += 1
        end
    end

    return G
end

# Parameters
N = 300 # Number of variables
T = 250 # Number of time steps
ρ = 0.8 # AR(1) coefficient for temporal dependency
n_trials = 2 # Number of trials
missing_rate_cross = 0.4
missing_rate_time = 0.4

# Run simulation
results_exact, results_estimated, results_X_complete, results_X_incomplete = simulation_study(T, N, ρ, n_trials, missing_rate_cross, missing_rate_time)

# Analyze results
mean_exact = compute_mean_estimated_diag(results_exact)
mean_estimated = compute_mean_estimated_diag(results_estimated)
our_way_complete = compute_estimated_variance_our_way(results_X_complete)

# mean(diag(mean_exact[:,:]))
# mean(diag(mean_estimated[:,:]))

# # Compare the estimated variance with the true variance, Σ, by hcatting the diagonals 
# sig_mat  = hcat(diag(mean_exact[:,:]), diag(our_way_complete[:,:]), diag(Σ))


results_summary = Dict()
N_values = [100, 200, 500]  # Number of variables
T_values = [100, 250]               # Number of time steps
missing_rates_cross = [0.05, 0.1, 0.15, 0.2, 0.3] # Missing data rates
missing_rates_time = [0.05, 0.1, 0.15, 0.2, 0.3]  # Missing data rates
n_trials = 100                   # Number of trials
ρ = 0.8 # AR(1) coefficient for temporal dependency

# The simulation results 
# Iterate over all parameter combinations

for N in N_values
    for T in T_values
        for missing_rate_cross in missing_rates_cross
            for missing_rate_time in missing_rates_time
                println("Running for N=$N, T=$T, missing_rate=$missing_rate_cross, $missing_rate_time")

                # Run simulation
                results_exact, results_estimated = simulation_study(T, N, ρ, n_trials, missing_rate_cross, missing_rate_time)

                mean_estimated_diag = compute_mean_estimated_diag(results_estimated)
                mean_exact_diag = compute_mean_estimated_diag(results_exact)

                # # Reshape results for analysis
                # stacked = reduce(hcat, results_estimated) # Stack matrices horizontally
                # stacked = reshape(stacked, size(results_estimated[1])..., length(results_estimated)) # Reshape into 3D

                # # Compute mean of diagonal for estimated covariance
                # mean_estimated_diag = mean(diag(mean(stacked, dims=3)[:, :]))

                # Store the result
                results_summary[(N, T, missing_rate_cross, missing_rate_time)] = [mean_estimated_diag, mean_exact_diag]
            end
        end
    end
end

plot_results(results_summary, N_values, T_values, missing_rates_cross, missing_rates_time)

function plot_results(results_summary, N_values, T_values, missing_rates_cross, missing_rates_time)
    # Determine the subplot layout
    n_rows = length(N_values)
    n_cols = length(T_values)

    # Prepare data for each subplot
    missing_rate_cross_sorted = sort(missing_rates_cross)
    missing_rate_time_sorted = sort(missing_rates_time)

    # Create a surface plot
    surface_mat = zeros(length(missing_rate_cross_sorted), length(missing_rate_time_sorted))

    # Iterate over N and T combinations
    for (i, N) in enumerate(N_values)
        for (j, T) in enumerate(T_values)

            for (k, missing_rate_cross) in enumerate(missing_rate_cross_sorted)
                for (l, missing_rate_time) in enumerate(missing_rate_time_sorted)
                    surface_mat[k, l] = results_summary[(N, T, missing_rate_cross, missing_rate_time)][1]
                end
            end

            # Create the subplot
            Plots.surface(missing_rate_cross_sorted, missing_rate_time_sorted, surface_mat, title=L"N=%$(N), T=%$(T)", xlabel=L"\textrm{Missing\,\, rate\,\, cross}", ylabel=L"\textrm{Missing\,\, rate\,\, time}", zlabel=L"\textrm{Mean\,\, estimated\,\, diag}", xformatter=:latex,
                yformatter=:latex,
                zformatter=:latex,
                legend=false,
                camera=(50, 10),
                size=(600, 500),
                color=:winter,
                display_option=Plots.GR.OPTION_SHADED_MESH,
            )
            Plots.savefig("results_surface_$N" * "_" * "$T.png")
        end
    end
end