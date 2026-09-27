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
    # priors[2] is a Vector{Normal} (one per factor) under persistence_prior = :per_factor
    Ωf      = priors[2] isa AbstractVector ?
              hcat([rand.(priors[2]) for _ in 1:nchain]...) :
              hcat([rand(priors[2], nf) for _ in 1:nchain]...)
    Ωy      = hcat([rand(priors[3], ny) for _ in 1:nchain]...)

    # Draw the full Cholesky from the LKJ prior, then map back to the
    # unconstrained u-parameterization via `Lcorr_to_u` (defined in Model.jl).
    L_draws = [rand(priors[4]).L for _ in 1:nchain]
    ΩC      = hcat([Lcorr_to_u(L) for L in L_draws]...)

    Σ = hcat([rand.(priors[5:4+nΣ])    for _ in 1:nchain]...)
    # NB: the only caller (DIMESampler) passes a REBUILT priors list
    # (get_priors + push hyperpriors) whose tail IS the H-block hyperpriors —
    # the trend priors are never re-appended there, so slicing the last
    # n_hyper_block entries is correct under BOTH trend specs.
    n_h = n_hyper_block(param_sizes)
    H = hcat([rand.(priors[end-n_h+1:end]) for _ in 1:nchain]...)
    if st_is_stochastic(param_sizes)
        # raw softplus coords: tight spread around the st_set_params initials
        r = param_sizes[1][1]
        θ0 = vcat(fill(-3.0, r), fill(0.54, r), [-2.25], of_initials())   # + object-factor block
        θtr = θ0 .+ 0.1 .* randn(length(θ0), nchain)
        return vcat(A_B_C_D, Ωf, Ωy, ΩC, Σ, H, θtr)
    end
    return vcat(A_B_C_D, Ωf, Ωy, ΩC, Σ, H)
end


# ─────────────────────────────────────────────────────────────────────
# report_mode_dynamics(par_final, param_sizes, model_options)
#   Log-only diagnostic (S5): factor-block persistence and innovation
#   scales at the current mode. A white-noise-like cycle shows up as
#   |eig(A)| ≪ the Minnesota ρ_F target with large Ω_f sds — the wealth
#   jitter signature (empirical smoke 2026-08-28; HANK runs 2026-09).
# ─────────────────────────────────────────────────────────────────────
"""
    report_mode_dynamics(par, param_sizes, model_options; label = "Mode dynamics", dead_frac = 0.05)

Prints the dynamics implied by a parameter vector: factor persistence, innovation
sds, trend block, object factors — and the number of LIVE distributional factors
(innovation sd above `dead_frac` × the median dist sd; DD_DEAD_FRAC overrides).
Called at the DIME mode and, with `label = "BBO point"`, at the black-box
optimiser's candidate before sampling starts: if the two live counts agree, the
BBO stage alone can fix the factor count (estimate once at an upper bound, count
the survivors, re-run at that count — see doc/hank_campaign_overview.md).
"""
function report_mode_dynamics(par_final, param_sizes, model_options; label::AbstractString = "Mode dynamics",
                              dead_frac::Float64 = parse(Float64, get(ENV, "DD_DEAD_FRAC", "0.15")))
    try
        core = st_core_params(par_final, param_sizes)
        A, _, _, D, Ω_var, _, _ = matrisize(core, param_sizes)
        spd(x) = x > 35 ? x : log1p(exp(x))
        r = param_sizes[1][1]
        ev = sort(abs.(eigvals(A)); rev = true)
        Ωd = diag(Ω_var)
        ωf = spd.(Ωd[1:r])
        live = ωf .> dead_frac * median(ωf)
        @info "$(label): live distributional factors = $(count(live)) of $(r) " *
              "(innovation sd > $(dead_frac) × median $(round(median(ωf); digits = 3)); dead: $(findall(.!live)))"
        # κ₅/κ₆/σ_ϕ are ESTIMATED (get_priors overwrites the Minnesota struct
        # from the H block each evaluation) — report the mode's values, not
        # the struct's (which holds whatever draw was evaluated last).
        Hraw = st_hyper_params(par_final, param_sizes)
        local ρtxt, iY, iσ
        if length(Hraw) == 6
            ρtxt = "ρ_F = $(round(inv_logit(Hraw[2], -0.99, 0.99); digits = 2))"
            iY, iσ = 3, 4
        else  # persistence_prior = :per_factor: [κ₁, ρ_F(1..r), ρ_Y, σ_ϕ, σ_ϕY, ν]
            rH = length(Hraw) - 5
            ρv = [inv_logit(Hraw[1+j], -0.99, 0.99) for j in 1:rH]
            ρtxt = "per-factor ρ_F = $(round.(ρv; digits = 2))"
            iY, iσ = rH + 2, rH + 3
        end
        ρ_Y = inv_logit(Hraw[iY], -0.99, 0.99)
        σϕ = spd(Hraw[iσ])
        @info "$(label): dist-factor |eig(A)| = $(round.(ev; digits = 3)) " *
              "(estimated persistence target $(ρtxt), σ_ϕ = $(round(σϕ; digits = 2)); agg ρ_Y = $(round(ρ_Y; digits = 2)))"
        @info "$(label): innovation sds — dist $(round.(spd.(Ωd[1:r]); digits = 2)), " *
              "agg $(round.(spd.(Ωd[r+1:end]); digits = 2)); agg AR diag(D) $(round.(D isa AbstractMatrix ? diag(D) : D; digits = 2))"
        if st_is_stochastic(param_sizes)
            θblk = par_final[end-st_ntrend(param_sizes)+1:end]
            n_tr = st_trend_dim(r)
            θtr = θblk[1:n_tr]
            @info "$(label): trend ω_τ = $(round.(spd.(θtr[1:r]); digits = 3)), " *
                  "ψ = $(round.(spd.(θtr[r+1:2r]); digits = 2)), λ = $(round(spd(θtr[n_tr]); digits = 3))"
            if of_active() && length(θblk) > n_tr
                Φg, ωg, _ = of_unpack(θblk[n_tr+1:end])
                O = OBJECT_FACTORS[]
                lab = vcat([fill(string(O.names[k]), O.r[k]) for k in eachindex(O.names)]...)
                @info "$(label): object factors — " *
                      join(["$(lab[i]): φ = $(round(Φg[i]; digits = 3)), ω = $(round(ωg[i]; digits = 3))" for i in eachindex(lab)], "; ")
            end
        end
    catch e
        @warn "report_mode_dynamics failed (diagnostic only): $e"
    end
end

# ─────────────────────────────────────────────────────────────────────
# hank_economy(tag) — the economy number ("1", "2", …) from a HANK tag.
# Tags used to end in the number (" HANK 1"), and call sites took the last
# token; suffixed tags (" HANK 1 stochastic trend 5 factors") broke that
# (economy "factors" → CSV.read of HANK_truth_factors.csv, 2026-09-09).
# ─────────────────────────────────────────────────────────────────────
function hank_economy(tag::AbstractString)
    m = match(r"HANK(?:\s+[A-Za-z]+)*?\s+(\d+)", tag)   # first number after "HANK" ("HANK 1 …", "HANK full 3")
    m === nothing && error("could not extract a HANK economy number from tag $(repr(tag))")
    return String(m.captures[1])
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


# ─────────────────────────────────────────────────────────────────────
# Fixed-order Gauss–Legendre quadrature (replaces adaptive quadgk for the
# smooth sinh(polynomial) decile integrals in CreateTimeSeries.jl /
# Reconstruction.jl / SeriesEstimator.jl). The integrands are analytic, so a
# fixed 20-node rule converges geometrically — agreement with quadgk at
# rtol=1e-8 is ~1e-14, with no adaptivity overhead. Nodes/weights are
# computed once at load time by Newton iteration on the Legendre recursion
# (no external dependency).
# ─────────────────────────────────────────────────────────────────────
function gauss_legendre_nodes(n::Int)
    xs = zeros(n); ws = zeros(n)
    for i in 1:n
        x  = cos(pi * (i - 0.25) / (n + 0.5))   # Chebyshev initial guess
        dP = 0.0
        for _ in 1:100
            Pm2, Pm1 = 1.0, x
            for k in 2:n
                Pm2, Pm1 = Pm1, ((2k - 1) * x * Pm1 - (k - 1) * Pm2) / k
            end
            dP = n * (x * Pm1 - Pm2) / (x^2 - 1)
            dx = Pm1 / dP
            x -= dx
            abs(dx) < 1e-15 && break
        end
        xs[i] = x
        ws[i] = 2 / ((1 - x^2) * dP^2)
    end
    return xs, ws
end

const GL20_X, GL20_W = gauss_legendre_nodes(20)

"∫ₐᵇ f(u) du by the fixed 20-node Gauss–Legendre rule (exact to machine
precision for the smooth/analytic integrands used in this package)."
function gauss_legendre_integrate(f, a, b)
    h = (b - a) / 2
    c = (a + b) / 2
    s = 0.0
    @inbounds for i in eachindex(GL20_X)
        s += GL20_W[i] * f(c + h * GL20_X[i])
    end
    return s * h
end
