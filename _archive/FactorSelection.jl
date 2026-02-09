using LinearAlgebra, Statistics

"""
    bninfocrit(x, kmax, gnum; demean=1)

Estimate number of factors by Bai & Ng (2002) information criteria.

# Arguments
- `x::AbstractMatrix{<:Real}`: data matrix of size T×N (rows=time, cols=series)
- `kmax::Int`: maximum number of factors to consider
- `gnum::Int`: which penalty to use
    1=ICp1, 2=ICp2, 3=ICp3,
    4=AIC1, 5=BIC1, 6=AIC2,
    7=BIC2, 8=AIC3, 9=BIC3,
    10=modified CP (JLN)
- `demean::Integer` (keyword, default=1):
    - `0`: raw data  
    - `1`: demean only  
    - `2`: standardize (zero mean, unit std)

# Returns
`numfac, IC, Fhat, Lhat, eigval`
"""
function bninfocrit(x::AbstractMatrix{<:Real}, kmax::Int, gnum::Int; demean::Int=1)
    # 1) sizes & transform
    T, N = size(x)
    xtr = Array{Float64}(undef, T, N)
    if demean == 2
        # standardize each column
        μ = mean(x, dims=1)
        σ = std(x, dims=1, corrected=true)
        @. xtr = (x - μ) / σ
    elseif demean == 1
        μ = mean(x, dims=1)
        @. xtr = x - μ
    else
        xtr .= x
    end

    # 2) economy SVD for initial PCA
    U, S, Vt = svd(xtr; full=false)
    Fhat0 = U * Diagonal(S)    # T × min(T,N)
    Lhat0 = Vt'                # N × min(T,N)
    eigval = S                 # singular values

    # 3) some constants for penalties
    NT = N * T
    NTsum = N + T
    CNT = min(sqrt(N), sqrt(T))

    # 4) build penalty vector kgNT[1:kmax]
    kgNT = zeros(Float64, kmax)
    for ii in 1:kmax
        kgNT[ii] = begin
            if gnum == 1
                ii * NTsum / NT * log(NT / NTsum)                # ICp1
            elseif gnum == 2
                ii * NTsum / NT * log(min(N, T))               # ICp2
            elseif gnum == 3
                ii * log(min(N, T)) / min(N, T)              # ICp3
            elseif gnum == 4
                ii * 2 / T                                      # AIC1
            elseif gnum == 5
                ii * log(T) / T                                # BIC1
            elseif gnum == 6
                ii * 2 / N                                      # AIC2
            elseif gnum == 7
                ii * log(N) / N                                # BIC2
            elseif gnum == 8
                ii * 2 * (NTsum - ii) / NT                      # AIC3
            elseif gnum == 9
                ii * (NTsum - ii) * log(NT) / NT                # BIC3
            elseif gnum == 10
                ii * 2 * (sqrt(N) + sqrt(T))^2 / NT               # modified CP (JLN)
            else
                throw(ArgumentError("gnum must be 1–10"))
            end
        end
    end

    # 5) loop over k to compute IC(k)
    IC = zeros(Float64, kmax)
    for k in 1:kmax
        Fk = Fhat0[:, 1:k]      # T×k
        Lk = Lhat0'[:, 1:k]      # N×k
        Chat = Fk * Lk'           # T×N fitted common part
        ehat = xtr - Chat         # residuals T×N
        VF = mean(ehat .^ 2)      # avg MSE = sum(ehat.^2)/(N*T)
        IC[k] = log(VF) + kgNT[k]
    end

    # 6) pick minimizer
    numfac = argmin(IC)

    # 7) slice the chosen factors/loadings
    Fhat = Fhat0[:, 1:numfac]
    Lhat = Lhat0[:, 1:numfac]

    return numfac #, IC, Fhat, Lhat, eigval
end

"""
    eigenvalue_ratio(X::AbstractMatrix{<:Real}, kmax::Int) -> Int

Compute number of factors by eigenvalue-ratio criterion (Ahn & Horenstein 2013).
"""
function eigenvalue_ratio(X::AbstractMatrix{<:Real}, kmax::Int)
    T, N = size(X)
    # Compute normalized covariance
    Z = (X' * X) / (T * N)
    # Eigenvalues of Z
    eigs = eigen(Z).values
    # Sort in descending order
    eigs_sorted = sort(abs.(eigs), rev=true)

    m = min(kmax, length(eigs_sorted))
    # Compute ratios of successive eigenvalues
    ratios = eigs_sorted[1:m-1] ./ eigs_sorted[2:m]
    # Select argmax + 0 index adjustment
    return argmax(ratios) + 1
end

"""
    growth_ratio(X::AbstractMatrix{<:Real}, kmax::Int) -> Int

Compute number of factors by growth-ratio criterion (Ahn & Horenstein 2013).
"""
function growth_ratio(X::AbstractMatrix{<:Real}, kmax::Int)
    T, N = size(X)
    Z = (X' * X) / (T * N)
    eigs = eigen(Z).values
    eigs_sorted = sort(abs.(eigs), rev=true)
    m = min(kmax, length(eigs_sorted))
    # Compute mu_star_j = lambda_j / sum_{i=j+1}^end lambda_i
    mu_star = zeros(Float64, m)
    for j in 1:m
        if j < m
            mu_star[j] = eigs_sorted[j] / sum(eigs_sorted[j+1:end])
        else
            mu_star[j] = Inf  # avoid division by zero on last
        end
    end
    # Growth ratios: log(1+mu_j) / log(1+mu_{j+1}) for j=1..m-1
    ratios = log1p.(mu_star[1:end-1]) ./ log1p.(mu_star[2:end])
    return argmax(ratios) + 1
end

"""
    select_factors(X::AbstractMatrix{<:Real}, kmax::Int) -> (Int, Int)

Compute both eigenvalue-ratio and growth-ratio selected number of factors.
Returns a tuple `(er, gr)`.
"""
function AO_estimator_ratio(X::AbstractMatrix{<:Real}, kmax::Int)
    er = eigenvalue_ratio(X, kmax)
    return er
end

function AO_estimator_growth(X::AbstractMatrix{<:Real}, kmax::Int)
    gr = growth_ratio(X, kmax)
    return gr
end

function n_factors(X, r_max; τ::Float64=0.5)
    # Estimates the number of relevant factors for dataset X following Freyaldenhoven (2021)
    #
    # INPUT
    # X: (Txn) matrix of data
    # r_max: upper bound on number of factors
    # include_plot(optional): If set to 1 includes illustrative figures)
    # τ(optional): default is 0.5
    #
    # OUTPUT
    # FR: Estimate for the number of factors

    T, n = size(X)
    z = round(Int, min(0.7 * n^τ * sqrt(log(log(n))), n))

    # SVD decomposition
    _, d, V = svd(X ./ sqrt(T); full=false)

    # Factor Loadings i.e., Projection matrix
    Lambda = V[:, 1:r_max] * Diagonal(d[1:r_max])

    # Sorting
    sorted = sort(abs.(Lambda), dims=1, rev=true)
    largest_z = sorted[1:z, :]

    error_part = d[r_max+1:end]
    estimate_variance = sum(error_part .^ 2) / n

    Shat = zeros(r_max)
    T2 = zeros(r_max)

    for k in 1:r_max
        Shat[k] = ((largest_z[:, k]' * largest_z[:, k] / z) / sqrt(Lambda[:, k]' * Lambda[:, k] / n))
        T2[k] = (Lambda[:, k]' * Lambda[:, k]) * Shat[k]^2
    end

    incl_mock_T2 = [estimate_variance * n; T2]
    T2_ratio = incl_mock_T2[1:r_max] ./ T2[1:r_max]
    FR = findall(x -> x == maximum(T2_ratio), T2_ratio)[1]
    FR -= 1

    # Determine 'maxoutdim'
    eig_X = d[1:min(n, T)] .^ 2
    MOdim = sum(incl_mock_T2[1:r_max] .> eig_X[1:r_max])
    println("Max dimension outputed:", MOdim)
    println("FR", FR)

    return FR
end


function log_ml_glp(Y, X, ν0, Ψ0, νT, ΨT, ΩT, p)
    T, n = size(Y)
    # 1) extract prior/posterior residual covariances
    V_prior = Ψ0 / (ν0 - n - 1)      # prior E[Σ]
    V_post = ΨT / (νT - n - 1)      # posterior E[Σ]

    # 2) term A = ((T-p+d)/2)*logdet(V_post^-1 * V_prior)
    d = ν0
    ldVpr = logdet(V_prior)
    ldVpo = logdet(V_post)
    A = (T - p + d) / 2 * (ldVpr - ldVpo)

    # 3) get posterior Var(vec(β)) = Σ_post ⊗ ΩT  →  for forecasts use Vβ = ΩT
    #    since X_t cov(B) X_t' = X_t * ΩT * X_t'  (and Σ_post enters as additive)
    Vβ = ΩT

    # 4) accumulate -½ ∑ logdet V(t|t-1)
    S = 0.0
    for t in (p+1):T
        xt = X[t, :][:, :]              # 1×m
        Vt = (xt' * Vβ * xt) .* Matrix(I, n, n) .+ V_post
        ld = logdet(Vt)
        S += ld
    end
    return A - 0.5 * S
end

function n_factor_per_estimator(agg_mat)
    nᶠ_dict = Dict()
    r_max = 30

    nᶠ_dict["5"] = 5
    # nᶠ_dict["10"] = 10
    nᶠ_dict["15"] = 15
    # nᶠ_dict["20"] = 20
    nᶠ_dict["25"] = 25
    nᶠ_dict["35"] = 35

    # # Run Bai and Ng
    # nᶠ_dict["BN"] = bninfocrit(agg_mat, r_max, 2; demean=0)

    # # Run AO 
    # nᶠ_dict["AO_growth"] = AO_estimator_growth(agg_mat, r_max)
    # nᶠ_dict["AO_ratio"] = AO_estimator_ratio(agg_mat, r_max)

    # # Run Local Factors estimator
    # nᶠ_dict["FC"] = n_factors(agg_mat, r_max; τ=0.2) # T x N

    # Set my own 
    # nᶠ_dict["M"] = 20


    return nᶠ_dict
end


# for i in 1:10
#     numfac, _, _, _, _ = bninfocrit(agg_mat, 30, i; demean=0)
#     println(numfac)
# end


