function inverse_transform(rv::AbstractArray, grid_size::Integer, weight=nothing)
    # Estimate cdf and generate percentiles 
    obs    = unique(rv)
    rv_cdf = ecdf(rv, weights=weight)

    # Percentiles 
    cdf_obs = map(x -> rv_cdf(x), sort(obs))  

    # Generate probability mass function for next part 
    pmf = Float64[]
    for i in 1:length(obs)
        if i == 1 
            append!(pmf,cdf_obs[1])
        else
            append!(pmf, cdf_obs[i]-cdf_obs[i-1])
        end
    end
    # Generate, using MLE, the distribution object 
    d = DiscreteNonParametric(sort(obs), pmf)

    # Sampling from the distribution object # out = rand(d,100) # Test it: plot(sort(out))
    # Generate percentile functions 
    grid      = collect(0.1:1/grid_size:1)
    grid[end] = .99
    rv_vals   = zeros(length(grid), 1)

    # Inverse transform 
    for (i, v) in enumerate(grid)
        rv_vals[i] = quantile(d,v)  # Gives you the income value for some percentile from distribution "d" 
    end 
    return rv_vals
end



"""Extract the years that exist in the given dataset.

# Arguments
- `data` : an XLSX object excel file with all sheets contained 
"""
function create_list_of_years(data)
    sheet_names = XLSX.sheetnames(data)
    list_of_years = String[]
    regex_rule = r"^[0-9]+"  # Extract numbers 
    for sheet in sheet_names
        year = [ match.match for match in eachmatch(regex_rule, sheet)]
        append!(list_of_years, year)  # appends the year only
    end
    return sort!(unique(tryparse.(Int, list_of_years)))
end

"""
    nearest_spd(A::AbstractMatrix)

Finds the nearest symmetric positive definite matrix to A.    
"""
function nearest_spd(A::AbstractMatrix)
    """It finds the nearest symmetric positive definite matrix to A.
    This allows for the invertibility in the kalman-filter likelihood calculation.
        https://scicomp.stackexchange.com/questions/30631/how-to-find-the-nearest-a-near-positive-definite-from-a-given-matrix
    """
    identity = Matrix(I, size(A,1), size(A,1))
    shift    = eps() * identity

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
    dg      = Diagonal(FS)
    
    # Construct spd 
    dg[dg .< 0] .= 1e-10
    eig_min      = minimum(diag(dg)) # minimum(abs.(dg)[abs.(dg) .> 0])
    H            = FVt' * dg * FVt
    G            = @. 0.5 * (H + H') + shift

    if isposdef(G)
        return G
    else
        # test that H is in fact PD. if it is not so, then tweak it just a bit.
        p = false
        count = 1
        # small_ϵ(k) = (-eig_min .* k .* k .+ eps(eig_min))
        small_ϵ = eps() .* identity
        ii = 0
        while p == false && count<1000
            G .+= small_ϵ 
            p = isposdef(G)
            ii += 1
            count += 1
        end
    end
    
    return G
end

# function isposdef_approx(M)
#     eigvals = Flux.eigvals(M)
#     min_eigval = minimum(eigvals)
    
#     return sigmoid(min_eigval)

# end

function run_qr_algorithm!(A, FVt_transpose)
    for i in 1:500
        d = qr(A, Val{true}());
        FVt_transpose = FVt_transpose * d.Q;
        A .= d.R * d.Q;
    end 
    return A, FVt_transpose
end

function gen_spd_in_lyapd(A, B)
    n = size(A, 1)
    Q = zeros(eltype(A), n, n)  # Initialize X with random symmetric matrix
    X = (Q + Q') ./ 2

    function objective(x)
        X = reshape(x, (n, n))
        return norm(A * X * A' - X + B, 2)
    end

    result = reshape(optimize(objective, vec(X), LBFGS(), autodiff = :forward).minimum, (n, n))
    return result
end

function gen_spd_in_lyapd2(A, B)
    tm_P  = (I - A * A') \ B
    W     = isposdef(tm_P) ? tm_P : nearest_spd(tm_P)   
    return W
end

# function psd_lyapd(A, B)
#     P_F  = lyapd(A, Ω)
#     if isposdef(P_F)
#         return P_F
#     else
#         return P_F .= gen_spd_in_lyapd2(A, Ω)
#     end
# end


function user_cholesky(A)
lower = zeros(eltype(A), size(A))

for i in axes(A,1)
    for j in 1:i
        sum1 = 0;
        # summation for diagonals
        if (j == i)
            for k in 1:j
                sum1 += (lower[j,k])^2
            end
            lower[j,j] = sqrt(A[j,j] - sum1)
        else
            # Evaluating L(i, j)  using L(j, j)
            for k in 1:j
                sum1 += (lower[i,k] * lower[j,k]);
            end
            if(lower[j,j] > 0)
                lower[i,j] = (A[i,j] - sum1) /lower[j,j]
            end
        end
    end
end
return lower 
end


function drop_rc2(x; r=nothing, c=nothing)
    nr, nc = size(x)
    if !isnothing(r)
        return x[setdiff(1:nr, r...), :]
    elseif !isnothing(c)
        return x[:, setdiff(1:nc, c...)]
    else
        return x
    end
end

function cube_root_correction(x)
    y = sign.(x) .* (abs.(x)).^(1/3)
    return y
end

    # symmetrize A into B
    # B           = @. 0.5 * (A + A')
    # _, FS, FVt = LinearAlgebra.LAPACK.gesvd!('N', 'S', copy(B))  # TODO: change this, check out discourse 
    # # H           = FVt' * Diagonal(FS) * FVt
    # dg = Diagonal(FS)
    # dg[dg .< 0] .= 0 
    # H = FVt' * dg * FVt + .01I
    # H = @. 0.5 * (H + H)
    # return H
# end

#TODO: for large matrices there seems to be a difference 
# A = rand(200,200)
# X = (A .+ A') ./ 2
# _, FS, FVt = LinearAlgebra.LAPACK.gesvd!('N', 'S', copy(X))  # TODO: change this, check out discourse 
# # H           = FVt' * Diagonal(FS) * FVt
# dg = Diagonal(FS)
# dg[dg .< 0] .= 0 
# H = FVt' * dg * FVt 
# H = @. 0.5 * (H + H)





# # initialize algo 
# FVt_transpose = Diagonal(ones(size(X, 1))) 

# # iterate 
# for i in 1:40
#     d = qr(X, Val{true}());
#     FVt_transpose = FVt_transpose * d.Q;
#     X .= d.R * d.Q;
# end 






# ─────────────────────────────────────────────────────────────────────
# data_tag(sources)
#   "CEX_and_CPS_and_..._and_SCF"  — used to name the cached sigma file
#   that ModelPrep.jl loads when reusing an earlier run's noise estimate.
#   Restored from _archive/ in commit 4c06537.
# ─────────────────────────────────────────────────────────────────────
function data_tag(sources)
    new_sources = deepcopy(sources)
    # Alias SCF2016 to SCF so the cached filename matches across vintages.
    for (m, source) in enumerate(new_sources)
        if source == "SCF2016"
            new_sources[m] = "SCF"
        end
    end
    return join(sort(new_sources), "_and_")
end


# ─────────────────────────────────────────────────────────────────────
# measures_folder(measures)
#   "consum_and_income_and_wealth" — folder name under 7_Results/.
#   Same join-with-"_and_" convention as data_tag.
# Restored from _archive/MCMC.jl in commit 4c06537.
# ─────────────────────────────────────────────────────────────────────
function measures_folder(measures)
    return join(sort(measures), "_and_")
end


# ─────────────────────────────────────────────────────────────────────
# draw_from_prior(param_sizes, priors, nchain)
#   Initial parameter draws for each MCMC chain. Used by DIMESampler.jl.
# Restored from _archive/MCMC.jl in commit 4c06537.
# ─────────────────────────────────────────────────────────────────────
function draw_from_prior(param_sizes, priors, nchain)
    nf = param_sizes[1][1]   # number of factors
    ny = param_sizes[2][2]   # number of controls
    nΣ = param_sizes[7][1]

    A_B_C_D = rand(priors[1], nchain)
    Ωf      = hcat([rand(priors[2], nf) for _ in 1:nchain]...)
    Ωy      = hcat([rand(priors[3], ny) for _ in 1:nchain]...)

    # Draw the full Cholesky from the LKJ prior, then map back to the
    # unconstrained u-parameterization via `Lcorr_to_u` (defined in Model.jl).
    L_draws = [rand(priors[4]).L for _ in 1:nchain]
    ΩC      = hcat([Lcorr_to_u(L) for L in L_draws]...)

    Σ = hcat([rand.(priors[5:4+nΣ])    for _ in 1:nchain]...)
    H = hcat([rand.(priors[end-5:end]) for _ in 1:nchain]...)
    return vcat(A_B_C_D, Ωf, Ωy, ΩC, Σ, H)
end


# ─────────────────────────────────────────────────────────────────────
# store_optim_estimate(params, label, m_label, data_cutoffs, tag)
#   Persist the post-optimization parameter vector to a CSV under
#   7_Results/<m_label><tag>/from_mcmc/parameter_vectors/.
# Restored from _archive/MCMC.jl in commit 4c06537.
# ─────────────────────────────────────────────────────────────────────
function store_optim_estimate(params, label, m_label, data_cutoffs, tag)
    end_year = data_cutoffs["end"] != "" ? data_cutoffs["end"][1:4] : "all"
    init_path = BASE_PATH
    out_path  = init_path * "/7_Results/$m_label" * "$tag" *
                "/from_mcmc/parameter_vectors/solution" * "$label" *
                "_$end_year" * ".csv"
    mkpath(dirname(out_path))
    DelimitedFiles.writedlm(out_path, params, ',')
end
