using Parameters, StatsBase, PeriodicalDates, Dates, CSV, DataFrames

function get_data(
    exovars::Vector{Int64},
    shock_syms::Vector{Symbol},
    gx::Matrix{Float64},
    hx::Matrix{Float64},
    XSS::Vector{Float64},
    ids;
    T::Int64=1000,
    burnin::Int64=100,
    init_val::Vector{Float64}=fill(0.01, length(exovars)),
    comp_ids=nothing,
    n_par,
)

    # Compute the number of states and controls from gx and hx
    ncontrols = size(gx, 1)
    nstates = size(hx, 1)

    # Compute IRFs, generate micro data from that
    shocks_df, micro_df = get_micro_data(
        exovars,
        gx,
        hx,
        XSS,
        ids,
        T,
        nstates,
        ncontrols,
        init_val,
        comp_ids,
        burnin,
        n_par,
    )
    return shocks_df, micro_df
end

"""
    compute_irfs_all(
        exovar,
        gx,
        hx,
        XSS,
        ids,
        T,
        nstates,
        ncontrols,
        init_val,
        distribution,
        comp_ids
    )

Computes impulse response functions (IRFs) for a given shock to a single exogenous variable.

See `compute_irfs` for argument and return value descriptions.
"""
function get_micro_data(
    exovars::Vector{Int64},
    gx::Matrix{Float64},
    hx::Matrix{Float64},
    XSS::Vector{Float64},
    ids,
    T::Int64,
    nstates::Int64,
    ncontrols::Int64,
    init_val::Vector{Float64},
    comp_ids,
    burnin,
    n_par,
)
    # Initialize matrices for states and controls
    S_t = zeros(nstates, T)
    C_t = zeros(ncontrols, T)

    @unpack grid_b, grid_k, grid_h = n_par

    # Shocks
    ε_HANK = init_val .* randn(length(exovars), T)

    # Initial conditions: states by assumption, controls as implied by gx and initial state
    S_t[:, 1] .= 0.0                    # deviations from steady state
    C_t[:, 1] .= gx * S_t[:, 1]            # implied controls

    # Simulation: iterate forward
    for t = 2:T
        S_t[exovars, t] .= ε_HANK[:, t]          # ← inject period-t innovations
        S_t[:, t] .= hx * S_t[:, t-1]         # propagate all states
        C_t[:, t] .= gx * S_t[:, t]           # controls
    end

    # Recompute levels for the original IRFs, as defined in macro @generate_equations
    original = [S_t; C_t]

    # Draw from the copula to get household data
    micro_df = get_household_data(
        original,
        ids,
        XSS,
        comp_ids,
        grid_h,
        grid_b,
        grid_k,
        burnin,
        n_par,
    )

    # Save shocks / burn-in correction     
    shocks_to_keep = ε_HANK[:, (burnin+1):end]          # each ε_j as a column

    # Drop the burn-in period
    filter!(row -> row.t > burnin, micro_df)

    # Subtract burn-in from time index
    micro_df.t .-= burnin

    # Change 't' to be some random quarterly time index (2000Q1, 2000Q2, ...)
    time_periods =
        QuarterlyDate(2000, 1):Quarter(1):(QuarterlyDate(
            2000,
            1,
        )+Quarter(1)*(maximum(micro_df.t)-1))
    t_dict = Dict(zip(1:length(time_periods), time_periods))

    micro_df.t = [t_dict[ti] for ti in micro_df.t]

    # 5) Wrap the shocks in a tidy DataFrame and save both objects
    shocks_df = DataFrame(
        :t => unique(micro_df.t),
        [
            Symbol("ε_", s) => vec(shocks_to_keep[i, :]) for (i, s) in enumerate(shock_syms)
        ]...,
    )
    shocks_df.year = year.(shocks_df.t)
    shocks_df.quarter = quarter.(shocks_df.t)
    select!(shocks_df, Not(:t))  # Drop 't' column

    micro_df.year = year.(micro_df.t)
    micro_df.quarter = quarter.(micro_df.t)
    select!(micro_df, Not(:t))  # Drop 't' column

    return shocks_df, micro_df
end

"""
    compute_irfs_inner_distribution(original, ids, XSS, comp_ids)

Compute impulse response functions (IRFs) for the distribution and marginal value functions
for a given shock to a single exogenous variable.

This function reconstructs the impulse responses of wealth distributions and marginal value
functions from the compressed IRFs. It first extracts steady-state values and applies the
discrete cosine transform (DCT) to uncompress the shocks. It then perturbs the steady-state
distributions with the IRFs and computes the updated marginal value functions and joint
distribution of liquid and illiquid assets.

The function uses a precomputed shuffle matrix to adjust distributions appropriately before
summing over dimensions to extract relevant marginal values.

# Arguments

  - `original::Array{Float64,2}`: The original IRF data matrix containing the compressed
    IRFs for the given exogenous variable.
  - `ids`: Indexes of the model variables.
  - `XSS::Vector{Float64}`: Steady state values of the model variables.
  - `comp_ids`: Compression indices for the distribution.

# Returns

  - `WbIRF::Matrix{Float64}`: The impulse responses for the marginal value function of
    liquid assets over time, size `nb x T`.
  - `WkIRFs::Matrix{Float64}`: The impulse responses for the marginal value function of
    illiquid assets over time, size `nk x T`.
  - `distr_bIRF::Matrix{Float64}`: The impulse responses for the distribution of liquid
    assets over time, size `nb x T`.
  - `distr_kIRF::Matrix{Float64}`: The impulse responses for the distribution of illiquid
    assets over time, size `nk x T`.
  - `distrIRF::Matrix{Float64}`: The impulse responses for the joint distribution of liquid
    and illiquid assets, size `nb x nk x T`.
"""
function get_household_data(
    original::Array{Float64,2},
    ids,
    XSS::Vector{Float64},
    comp_ids,
    grid_h,
    grid_b,
    grid_k,
    burnin,
    n_par,
)

    # Grid sizes
    nb = length(ids.distr_bSS)
    nk = length(ids.distr_kSS)
    nh = length(ids.distr_hSS)
    nb_copula = n_par.nb_copula
    nk_copula = n_par.nk_copula
    nh_copula = n_par.nh_copula
    copula_marginal_b = n_par.copula_marginal_b
    copula_marginal_k = n_par.copula_marginal_k
    copula_marginal_h = n_par.copula_marginal_h
    T = size(original, 2)

    # Get steady-state objects
    # WbSS = XSS[ids.WbSS]
    # WkSS = XSS[ids.WkSS]
    distr_bSS = XSS[ids.distr_bSS]
    distr_kSS = XSS[ids.distr_kSS]
    distr_hSS = XSS[ids.distr_hSS]
    CDF_bSS = cumsum(distr_bSS[:])
    CDF_kSS = cumsum(distr_kSS[:])
    CDF_hSS = cumsum(distr_hSS[:])
    distr_SS = reshape(XSS[ids.COPSS], (nb, nk, nh))

    # DCT containers
    DC = Array{Array{Float64,2},1}(undef, 3)
    DC[1] = mydctmx(nb)
    DC[2] = mydctmx(nk)
    DC[3] = mydctmx(nh)
    # IDC = [DC[1]', DC[2]', DC[3]']

    # DCT containers copula
    DCD = Array{Array{Float64,2},1}(undef, 3)
    DCD[1] = mydctmx(nb_copula)
    DCD[2] = mydctmx(nk_copula)
    DCD[3] = mydctmx(nh_copula)
    IDCD = [DCD[1]', DCD[2]', DCD[3]']

    # Shuffle matrix
    Γ = shuffleMatrix(distr_SS, nb, nk, nh)

    # Define IRF containers
    # WbIRF = zeros(nb, T)
    # WkIRFs = zeros(nk, T)
    distr_bIRF = zeros(nb, T)
    distr_kIRF = zeros(nk, T)
    distr_hIRF = zeros(nh, T)
    # distr_bkIRF = zeros(nb, nk, T)
    # distr_bhIRF = zeros(nb, nh, T)
    # distr_khIRF = zeros(nk, nh, T)

    # Compute IRFs
    for t = 1:T

        # Uncompress IRFs + perturb steady-state values with IRFs
        # Wb_full = exp.(WbSS .+ uncompress(comp_ids[1], original[ids.Wb, t], DC, IDC))
        # Wk_full = exp.(WkSS .+ uncompress(comp_ids[2], original[ids.Wk, t], DC, IDC))

        # Masses of liquid and illiquid assets
        distr_bIRF[:, t] = distr_bSS .+ Γ[1] * original[ids.distr_b, t]
        distr_kIRF[:, t] = distr_kSS .+ Γ[2] * original[ids.distr_k, t]
        distr_hIRF[:, t] = distr_hSS .+ Γ[3] * original[ids.distr_h, t]

        # Dealing with the copula. Step 1: Uncompress deviations from steady state
        θD = uncompress(comp_ids[3], original[ids.COP, t], DCD, IDCD)[:]

        # Step 2: Turn into CDF, defined over the copula grid
        COP_Dev = reshape(θD, (nb_copula, nk_copula, nh_copula))
        COP_Dev = pdf_to_cdf(COP_Dev)

        # Step 3: Interpolate deviation onto full grid, defined by the cdfs of each marginal (as in FSYS)
        CP_full =
            myinterpolate3(
                copula_marginal_b,
                copula_marginal_k,
                copula_marginal_h,
                COP_Dev,
                mod_params.model,
                cumsum(distr_bIRF[:, t])[:],
                cumsum(distr_kIRF[:, t])[:],
                cumsum(distr_hIRF[:, t])[:],
            ) .+ myinterpolate3(
                CDF_bSS,
                CDF_kSS,
                CDF_hSS,
                pdf_to_cdf(distr_SS),
                mod_params.model,
                cumsum(distr_bIRF[:, t])[:],
                cumsum(distr_kIRF[:, t])[:],
                cumsum(distr_hIRF[:, t])[:],
            )
        # Step 4: Perturbed full copula
        CP_full = cdf_to_pdf(CP_full)

        # Get micro data
        write_micro_deterministic!(micro_df, CP_full, grid_b, grid_k, grid_h, t)

        # # Get the marginal value function of liquid assets
        # WbIRF[:, t] = sum(reshape(Wb_full, (nb, nk, nh)); dims = (2, 3))[:]

        # # Get the marginal value function of illiquid assets
        # WkIRFs[:, t] = sum(reshape(Wk_full, (nb, nk, nh)); dims = (1, 3))[:]

        # # Get the joint distribution of liquid and illiquid assets
        # distr_bkIRF[:, :, t] = dropdims(sum(CP_full; dims = 3), ; dims = 3)

        # # Get the joint distribution of liquid assets and income
        # distr_bhIRF[:, :, t] = dropdims(sum(CP_full; dims = 2), ; dims = 2)

        # # Get the joint distribution of illiquid assets and income
        # distr_khIRF[:, :, t] = dropdims(sum(CP_full; dims = 1), ; dims = 1)
    end


    return micro_df
end

function draw_micro_from_copula!(micro_df, CP_full, grid_h, grid_b, grid_k, t; N=5_000)
    prob = vec(CP_full) ./ sum(CP_full)            # 1. normalise to pmf (length nb*nk*nh)
    flat_ix = sample(1:length(prob), Weights(prob), N; replace=true)

    nb = length(grid_b)
    nk = length(grid_k)

    # 2. map flat index → (ib, ik, ih) grid co-ordinates
    ih = ((flat_ix .- 1) .÷ (nb * nk)) .+ 1
    rem1 = (flat_ix .- 1) .% (nb * nk)
    ik = (rem1 .÷ nb) .+ 1
    ib = (rem1 .% nb) .+ 1

    # 3. write to the growing micro DataFrame
    append!(
        micro_df,
        DataFrame(;
            t=fill(t, N)[:],
            id=collect(1:N),                    # IDs
            weight=ones(N),
            liquid=grid_b[ib],            # liquid assets
            illiqd=grid_k[ik],            # illiquid assets
            income=grid_h[ih],            # income
        ),
    )
end

function write_micro_deterministic!(micro_df, CP_full, grid_b, grid_k, grid_h, t)
    nb = length(grid_b)
    nk = length(grid_k)
    nh = length(grid_h)
    P = CP_full ./ max(sum(CP_full), eps())
    rows = nb * nk * nh
    t_vec = fill(t, rows)
    id_vec = collect(1:rows)
    w_vec = vec(P)
    b_vec = similar(w_vec)
    k_vec = similar(w_vec)
    h_vec = similar(w_vec)

    idx = 1
    for ik = 1:nk, ib = 1:nb, ih = 1:nh
        b_vec[idx] = grid_b[ib]
        k_vec[idx] = grid_k[ik]
        h_vec[idx] = grid_h[ih]
        idx += 1
    end
    append!(
        micro_df,
        DataFrame(;
            t=t_vec,
            id=id_vec,
            weight=w_vec,
            liquid=b_vec,
            illiqd=k_vec,
            income=h_vec,
        ),
    )
end

function mydctmx(n::Int)
    DC::Array{Float64,2} = zeros(n, n)
    for j = 0:(n-1)
        DC[1, j+1] = float(1 / sqrt(n))
        for i = 1:(n-1)
            DC[i+1, j+1] = (pi * float((j + 1 / 2) * i / n))
            DC[i+1, j+1] = sqrt(2 / n) .* cos.(DC[i+1, j+1])
        end
    end
    return DC
end

function uncompress(compressionIndexes, XC, DC, IDC)
    nb = size(DC[1], 1)
    nk = size(DC[2], 1)
    nh = size(DC[3], 1)
    θ1 = zeros(eltype(XC), nb, nk, nh)
    for j in eachindex(XC)
        θ1[compressionIndexes[j]] = copy(XC[j])
    end
    @views for hh = 1:nh
        θ1[:, :, hh] = IDC[1] * θ1[:, :, hh] * DC[2]
    end
    @views for bb = 1:nb
        θ1[bb, :, :] = θ1[bb, :, :] * DC[3]
    end
    θ = reshape(θ1, (nb) * (nk) * (nh))
    return θ
end
