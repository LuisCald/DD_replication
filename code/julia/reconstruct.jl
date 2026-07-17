"""
Standalone reconstruction of marginal quantile functions and the trivariate
copula density from `*_coefficients_{normal,average}.csv`.

Mirrors `code/python/reconstruct.py`. Self-contained: no dependency on the
model code in this repo. Only CSV.jl + DataFrames.jl + the stdlib.

Usage:

    include("reconstruct.jl")
    using .DistributionalReconstruction

    r = Reconstruction("PSID_coefficients_normal.csv")
    quantile_at(r, "2008-Q3", :consum, [0.1, 0.5, 0.9])
    copula_density_at(r, "2008-Q3", 0.5, 0.5, 0.5)
    copula_density_grid(r, "2008-Q3"; n = 30)

    # Match the published `ciw_*` cell probability masses on a 10x10x10 grid:
    copula_pmf_grid(r, "2008-Q3")   # 10x10x10 array summing to 1

Legendre basis on [0, 1]: Q_o(u) = sqrt(2o + 1) * P_o(2u - 1).
"""

module DistributionalReconstruction

using CSV
using DataFrames
using LinearAlgebra
using Statistics

export Reconstruction,
    FactorMap,
    factors_at,
    predict,
    quantile_at,
    copula_density_at,
    copula_density_grid,
    copula_pmf_grid,
    quantile_from_row,
    copula_density_from_row,
    Q_m,
    I_m,
    available_dates,
    GRID_COP,
    GRID_PCF,
    MEASURES


# Model constants — match Reconstruction.jl / ModelPrep.jl
const GRID_COP = 12            # 12^3 - 34 = 1694 mutable copula coefs
const GRID_PCF = 12            # 12 marginal coefs per measure
const D = 3
const N_MUTABLE_COP = 1694
const N_QUANTILE = D * GRID_PCF      # 36
const MEASURES = (:consum, :income, :wealth)


# -----------------------------------------------------------------------------
# Orthonormal Legendre basis on [0, 1]
# -----------------------------------------------------------------------------
"""
    legendre_P(n, x)

Standard Legendre polynomial P_n on [-1, 1]. Vectorized.
"""
function legendre_P(n::Int, x)
    n == 0 && return one.(x)
    n == 1 && return float.(x)
    pm2 = one.(x)
    pm1 = float.(x)
    p = similar(pm1)
    for k in 2:n
        @. p = ((2k - 1) * x * pm1 - (k - 1) * pm2) / k
        pm2 = pm1
        pm1 = p
        p = similar(pm1)
    end
    return pm1
end

"""
    Q_m(m, u)

Orthonormal Legendre basis on [0, 1]: Q_m(u) = sqrt(2m+1) * P_m(2u - 1).
"""
Q_m(m::Int, u) = sqrt(2m + 1) .* legendre_P(m, 2 .* u .- 1)

"""
    I_m(m, u)

I_m(u) = integral of Q_m(s) on [0, u]. Closed form from Bonnet's recursion:

    I_0(u) = u
    I_m(u) = (P_{m+1}(2u-1) - P_{m-1}(2u-1)) / (2 * sqrt(2m+1)),  m ≥ 1

The boundary terms at s = 0 cancel because P_n(-1) = (-1)^n.
"""
function I_m(m::Int, u)
    m == 0 && return float.(u)
    x = 2 .* u .- 1
    return (legendre_P(m + 1, x) .- legendre_P(m - 1, x)) ./ (2 * sqrt(2m + 1))
end


# -----------------------------------------------------------------------------
# Index mapping: x1..x1694 -> mutable CartesianIndices in (12, 12, 12)
# -----------------------------------------------------------------------------
"""Iteration order matches Julia's CartesianIndices((12,12,12)): i fastest, then j, then k.
An entry is *immutable* if at least D - 1 = 2 of its 1-indexed components equal 1."""
function build_mutable_indices()
    out = NTuple{3, Int}[]
    for k in 1:GRID_COP, j in 1:GRID_COP, i in 1:GRID_COP
        n_ones = (i == 1) + (j == 1) + (k == 1)
        if n_ones < D - 1
            push!(out, (i, j, k))
        end
    end
    @assert length(out) == N_MUTABLE_COP
    return out
end

const MUTABLE_INDICES = build_mutable_indices()


"""
    unflatten_to_kappa(row)

Take the first 1694 entries of a coefficient row (mutable copula κ) and
build the full (12, 12, 12) tensor. The immutable leading entry
κ[1,1,1] = 1 (uniform marginals); all other immutable entries are 0.

(Indices in the returned tensor are 1-based; polynomial order = index - 1.)
"""
function unflatten_to_kappa(row::AbstractVector{<:Real})
    κ = zeros(GRID_COP, GRID_COP, GRID_COP)
    @inbounds for (n, (i, j, k)) in enumerate(MUTABLE_INDICES)
        κ[i, j, k] = row[n]
    end
    κ[1, 1, 1] = 1.0
    return κ
end


# -----------------------------------------------------------------------------
# Public type
# -----------------------------------------------------------------------------
"""
    Reconstruction(csv_path)

Lazy reader for a `*_coefficients_*.csv` file.
"""
struct Reconstruction
    df::DataFrame
    dates::Vector{String}
    csv_path::String
end

function Reconstruction(csv_path::AbstractString)
    df = CSV.read(csv_path, DataFrame)
    if !("time" in names(df))
        error("Expected a `time` column in $csv_path.")
    end
    n_data = ncol(df) - 1
    expected = N_MUTABLE_COP + N_QUANTILE
    if n_data != expected
        error("$csv_path has $n_data data columns; expected $expected (is this a *_coefficients_*.csv file?).")
    end
    dates = string.(df.time)
    return Reconstruction(df, dates, String(csv_path))
end


available_dates(r::Reconstruction) = copy(r.dates)


function _row_for_date(r::Reconstruction, date::AbstractString)
    idx = findfirst(==(date), r.dates)
    isnothing(idx) && throw(KeyError("Date $date not in file. " *
        "First/last available: $(r.dates[1]) .. $(r.dates[end])"))
    # The first column is `time`; data starts at column 2.
    return Vector{Float64}(r.df[idx, 2:end])
end


function _xi(r::Reconstruction, date::AbstractString, measure::Symbol)
    measure in MEASURES || error("measure must be one of $MEASURES, got $measure")
    m_idx = findfirst(==(measure), MEASURES) - 1   # 0-based
    row = _row_for_date(r, date)
    start = N_MUTABLE_COP + m_idx * GRID_PCF + 1
    return row[start : start + GRID_PCF - 1]
end


_kappa(r::Reconstruction, date::AbstractString) = unflatten_to_kappa(_row_for_date(r, date))


# -----------------------------------------------------------------------------
# Public evaluation methods
# -----------------------------------------------------------------------------
"""
    quantile_at(r, date, measure, u)

Marginal quantile function Ξ⁻¹_{m,t}(u) at quantile points `u ∈ [0, 1]`.
Returns a scalar if `u` is a scalar, otherwise a vector.
"""
function quantile_at(r::Reconstruction, date::AbstractString, measure::Symbol, u)
    ξ = _xi(r, date, measure)
    u_vec = u isa Real ? [Float64(u)] : Vector{Float64}(u)
    basis = hcat([Q_m(o, u_vec) for o in 0:GRID_PCF-1]...)   # (n_u, GRID_PCF)
    # The stored ξ are coefficients of asinh(q / per-HH mean) — see
    # DataConstructor.jl (`inverse_hyperbolic_sine` at fitting) and
    # CreateTimeSeries.jl (`reverse_inverse_hyperbolic_sine` at evaluation).
    out = sinh.(basis * ξ)
    return u isa Real ? out[1] : out
end


"""
    copula_density_at(r, date, u_c, u_y, u_w)

Trivariate copula density dC_t(u_c, u_y, u_w) at one or many points.
Scalar inputs return a scalar; equal-length vectors return a vector
(element-wise).
"""
function copula_density_at(r::Reconstruction, date::AbstractString, u_c, u_y, u_w)
    κ = _kappa(r, date)
    uc = u_c isa Real ? [Float64(u_c)] : Vector{Float64}(u_c)
    uy = u_y isa Real ? [Float64(u_y)] : Vector{Float64}(u_y)
    uw = u_w isa Real ? [Float64(u_w)] : Vector{Float64}(u_w)
    @assert length(uc) == length(uy) == length(uw)
    B_c = reduce(vcat, [reshape(Q_m(o, uc), 1, :) for o in 0:GRID_COP-1])  # (GRID_COP, n)
    B_y = reduce(vcat, [reshape(Q_m(o, uy), 1, :) for o in 0:GRID_COP-1])
    B_w = reduce(vcat, [reshape(Q_m(o, uw), 1, :) for o in 0:GRID_COP-1])
    n = length(uc)
    out = zeros(n)
    @inbounds for a in 1:GRID_COP, b in 1:GRID_COP, c in 1:GRID_COP
        κabc = κ[a, b, c]
        κabc == 0 && continue
        for k in 1:n
            out[k] += κabc * B_c[a, k] * B_y[b, k] * B_w[c, k]
        end
    end
    return u_c isa Real ? out[1] : out
end


"""
    copula_density_grid(r, date; n = 30)

Evaluate dC_t on a regular n×n×n grid of (u_c, u_y, u_w) ∈ (0, 1).
"""
function copula_density_grid(r::Reconstruction, date::AbstractString; n::Int = 30)
    κ = _kappa(r, date)
    u = collect(range(1e-6, 1 - 1e-6; length = n))
    B = reduce(vcat, [reshape(Q_m(o, u), 1, :) for o in 0:GRID_COP-1])   # (GRID_COP, n)
    grid = zeros(n, n, n)
    @inbounds for a in 1:GRID_COP, b in 1:GRID_COP, c in 1:GRID_COP
        κabc = κ[a, b, c]
        κabc == 0 && continue
        @views grid .+= κabc .* (B[a, :] .* reshape(B[b, :], 1, :, 1) .* reshape(B[c, :], 1, 1, :))
    end
    return grid
end


"""
    copula_pmf_grid(r, date; grid = DEFAULT_GRID)

Discrete probability mass on a 10x10x10 grid of (u_c, u_y, u_w) cells with
edges `[1e-6, 0.1, 0.2, ..., 0.9, 0.999999]`. Matches the published
`ciw_<i><j><k>` columns exactly.

Steps (same as `Reconstruction.jl: generate_copula_densities` + `cdf_to_pdf`):
  1) Evaluate the copula CDF at the 10 grid edge points via
        C(x_i, x_j, x_k) = sum_m κ[m] * I_{m1}(x_i) * I_{m2}(x_j) * I_{m3}(x_k)
  2) 3D inclusion-exclusion finite difference → cell probability mass.
  3) Clip negative cells to 0 and renormalize to sum to 1.
"""
const DEFAULT_GRID = collect(0.1:0.1:1.0)
DEFAULT_GRID[end] -= 1e-6

function copula_pmf_grid(r::Reconstruction, date::AbstractString;
        grid::AbstractVector{<:Real} = DEFAULT_GRID)
    κ = _kappa(r, date)
    n = length(grid)
    # I[m+1, ui] = I_m(grid[ui])
    Imat = reduce(vcat, [reshape(I_m(m, grid), 1, :) for m in 0:GRID_COP-1])   # (GRID_COP, n)
    cdf = zeros(n, n, n)
    @inbounds for a in 1:GRID_COP, b in 1:GRID_COP, c in 1:GRID_COP
        κabc = κ[a, b, c]
        κabc == 0 && continue
        @views cdf .+= κabc .* (Imat[a, :] .* reshape(Imat[b, :], 1, :, 1) .* reshape(Imat[c, :], 1, 1, :))
    end
    pmf = zeros(n, n, n)
    @inbounds for i in 1:n, j in 1:n, k in 1:n
        c   = cdf[i, j, k]
        a   = i > 1 ? cdf[i-1, j, k] : 0.0
        b2  = j > 1 ? cdf[i, j-1, k] : 0.0
        d2  = k > 1 ? cdf[i, j, k-1] : 0.0
        ab  = (i > 1 && j > 1) ? cdf[i-1, j-1, k] : 0.0
        ad  = (i > 1 && k > 1) ? cdf[i-1, j, k-1] : 0.0
        bd  = (j > 1 && k > 1) ? cdf[i, j-1, k-1] : 0.0
        abd = (i > 1 && j > 1 && k > 1) ? cdf[i-1, j-1, k-1] : 0.0
        pmf[i, j, k] = c - a - b2 - d2 + ab + ad + bd - abd
    end
    pmf[pmf .< 0] .= 0
    s = sum(pmf)
    s > 0 && (pmf ./= s)
    return pmf
end


# -----------------------------------------------------------------------------
# Row-level evaluators (raw 1730-vector → moments)
# -----------------------------------------------------------------------------
function _extract_xi(row::AbstractVector{<:Real}, measure::Symbol)
    measure in MEASURES || error("measure must be one of $MEASURES, got $measure")
    m_idx = findfirst(==(measure), MEASURES) - 1   # 0-based
    start = N_MUTABLE_COP + m_idx * GRID_PCF + 1
    return row[start : start + GRID_PCF - 1]
end


"""
    quantile_from_row(row, measure, u)

Marginal quantile Ξ⁻¹_{measure}(u) computed from a raw 1730-coefficient row
(handy when `row` is synthesized rather than read from a CSV).
"""
function quantile_from_row(row::AbstractVector{<:Real}, measure::Symbol, u)
    ξ = _extract_xi(row, measure)
    u_vec = u isa Real ? [Float64(u)] : Vector{Float64}(u)
    basis = hcat([Q_m(o, u_vec) for o in 0:GRID_PCF-1]...)
    out = sinh.(basis * ξ)   # stored ξ are asinh-scale; see quantile_at
    return u isa Real ? out[1] : out
end


"""
    copula_density_from_row(row, u_c, u_y, u_w)

Copula density dC(u_c, u_y, u_w) from a raw 1730-coefficient row.
"""
function copula_density_from_row(row::AbstractVector{<:Real}, u_c, u_y, u_w)
    κ = unflatten_to_kappa(row)
    uc = u_c isa Real ? [Float64(u_c)] : Vector{Float64}(u_c)
    uy = u_y isa Real ? [Float64(u_y)] : Vector{Float64}(u_y)
    uw = u_w isa Real ? [Float64(u_w)] : Vector{Float64}(u_w)
    @assert length(uc) == length(uy) == length(uw)
    B_c = reduce(vcat, [reshape(Q_m(o, uc), 1, :) for o in 0:GRID_COP-1])
    B_y = reduce(vcat, [reshape(Q_m(o, uy), 1, :) for o in 0:GRID_COP-1])
    B_w = reduce(vcat, [reshape(Q_m(o, uw), 1, :) for o in 0:GRID_COP-1])
    n = length(uc)
    out = zeros(n)
    @inbounds for a in 1:GRID_COP, b in 1:GRID_COP, c in 1:GRID_COP
        κabc = κ[a, b, c]
        κabc == 0 && continue
        for k in 1:n
            out[k] += κabc * B_c[a, k] * B_y[b, k] * B_w[c, k]
        end
    end
    return u_c isa Real ? out[1] : out
end


# -----------------------------------------------------------------------------
# FactorMap — `dis_data_rep == "smoothed_factors_dd"` from
# Distributional_Counterfactuals/SupportPrepData.jl, ported. Self-contained:
# uses the published `smoothed_factors.csv` and a published coefficients file
# to learn the factor → coefficient map by block-standardizing then OLS-fitting
# Λ̂ against the 4-quarter-averaged smoothed factors (which matches the
# annual-dataset structure of Gⱼ in the state-space model).
#
# Identity used to predict a coefficient row from a factor vector F (n_factors):
#
#     coef_std_t  =  α  +  Λ̂ · F_4q_t
#     coef_t      =  coef_std_t ⊙ stds_blockwise  +  means
# -----------------------------------------------------------------------------
"""
    FactorMap(coefs_csv, factors_csv; n_factors=8)

Self-contained smoothed factors → coefficient row map, built off the public
CSVs. Use the `_coefficients_average.csv` variant — it carries only a constant
trend per coefficient, so the smoothed factors recover the row exactly
(R² ≈ 1). Fitting on `_coefficients_normal.csv` (with the time-varying HP
trend) is discouraged — R² drops to ~0.4.

Mirrors `dis_data_rep == "smoothed_factors_dd"` in
`Distributional_Counterfactuals/5_Code/SupportPrepData.jl`:

  1. Drop rows with any NaN in the coefficient matrix.
  2. Block-standardize the coefs (one std per object: copula + each marginal).
  3. Build F_4q = (F_t + F_{t-1} + F_{t-2} + F_{t-3}) / 4 from `x1..x32`
     of `smoothed_factors.csv`.
  4. OLS: standardized coef ~ α + Λ̂·F_4q.

Use:

```julia
fm = FactorMap(
    "data/synthetic/PSID_coefficients_average.csv",
    "data/synthetic/smoothed_factors.csv";
    n_factors = 8,
)
F = factors_at(fm, "2008-Q3")          # 4q-averaged factor at that date
F[1] += 1.0
quantile_at(fm, F, :consum, [0.1, 0.5, 0.9])
copula_density_at(fm, F, 0.5, 0.5, 0.5)
```
"""
struct FactorMap
    α::Vector{Float64}                # (n_coefs,)
    Λ::Matrix{Float64}                # (n_coefs, n_factors)
    means::Vector{Float64}            # (n_coefs,)
    stds::Vector{Float64}             # (n_coefs,) — expanded
    block_stds::Vector{Float64}       # length D+1
    r_squared::Vector{Float64}        # (n_coefs,)
    n_factors::Int
    n_coefs::Int
    factors_4q::Matrix{Float64}       # (T_used, n_factors)
    factors_t::Matrix{Float64}        # (T_used, n_factors)
    dates_used::Vector{String}
    n_obs_total::Int
    n_obs_used::Int
    n_obs_dropped::Int
    coefs_csv::String
    factors_csv::String
end


function FactorMap(coefs_csv::AbstractString, factors_csv::AbstractString;
        n_factors::Int = 8)
    # 1. Load + align
    Y_df = CSV.read(coefs_csv, DataFrame)
    F_df = CSV.read(factors_csv, DataFrame)
    ("time" in names(Y_df) && "time" in names(F_df)) ||
        error("both CSVs must have a 'time' column")
    Y_df.time = string.(Y_df.time); F_df.time = string.(F_df.time)
    common = sort(collect(intersect(Set(Y_df.time), Set(F_df.time))))
    isempty(common) && error("no overlapping dates between factors and coefs")
    Y_c = filter(r -> r.time in Set(common), Y_df); sort!(Y_c, :time)
    F_c = filter(r -> r.time in Set(common), F_df); sort!(F_c, :time)
    Y_all = Matrix{Float64}(Y_c[!, Not(:time)])
    n_coefs_total = size(Y_all, 2)

    # 2. Drop NaN rows
    valid = .!vec(any(isnan, Y_all; dims = 2))
    n_obs_total = length(valid)
    n_used = sum(valid)
    n_used >= n_factors + 2 ||
        error("only $n_used clean rows; need at least n_factors+2 = $(n_factors + 2)")
    dates_used = [d for (d, ok) in zip(common, valid) if ok]
    Y = Y_all[valid, :]
    T_used = size(Y, 1)

    # 3. Block-wise demean + standardize
    means = vec(mean(Y; dims = 1))
    Yc = Y .- means'
    n_per_marg = GRID_PCF                        # 12
    n_marg_block = D * GRID_PCF                  # 36
    stds_expanded = Vector{Float64}(undef, n_coefs_total)
    if n_coefs_total > n_marg_block
        ncop = n_coefs_total - n_marg_block
        slices = (1:ncop,
                  ncop+1 : ncop+n_per_marg,
                  ncop+n_per_marg+1 : ncop+2*n_per_marg,
                  ncop+2*n_per_marg+1 : n_coefs_total)
        block_stds = Float64[]
        for s in slices
            σ = std(Yc[:, s])
            σ = σ < 1e-10 ? 1.0 : σ
            push!(block_stds, σ)
            stds_expanded[s] .= σ
        end
    else
        per_col = vec(std(Y; dims = 1, corrected = false))
        per_col[per_col .< 1e-10] .= 1.0
        stds_expanded .= per_col
        block_stds = fill(mean(per_col), D + 1)
    end
    Y_std = Yc ./ stds_expanded'

    # 4. 4-quarter average smoothed factors
    nF = n_factors
    cols_needed = ["x$i" for i in 1:4*nF]
    missing_cols = [c for c in cols_needed if !(c in names(F_c))]
    isempty(missing_cols) ||
        error("smoothed_factors.csv missing columns $(missing_cols); " *
              "n_factors=$nF requires x1..x$(4*nF)")
    F_full_all = Matrix{Float64}(F_c[!, cols_needed])
    F_full = F_full_all[valid, :]
    F_4q = (F_full[:, 1:nF] .+ F_full[:, nF+1:2*nF] .+
            F_full[:, 2*nF+1:3*nF] .+ F_full[:, 3*nF+1:4*nF]) ./ 4
    F_t = F_full[:, 1:nF]

    # 5. OLS
    Xa = hcat(ones(T_used), F_4q)               # (T_used, 1 + nF)
    β = Xa \ Y_std                              # (1 + nF, n_coefs)
    Y_std_hat = Xa * β
    res = Y_std .- Y_std_hat
    ss_res = vec(sum(res .^ 2; dims = 1))
    ss_tot = vec(sum((Y_std .- mean(Y_std; dims = 1)) .^ 2; dims = 1))
    r2 = [t > 0 ? 1 - r / t : NaN for (r, t) in zip(ss_res, ss_tot)]

    return FactorMap(
        Vector{Float64}(β[1, :]),               # α
        Matrix{Float64}(β[2:end, :]'),           # Λ (n_coefs × nF)
        means, stds_expanded, block_stds, r2,
        nF, n_coefs_total, F_4q, F_t, dates_used,
        n_obs_total, n_used, n_obs_total - n_used,
        String(coefs_csv), String(factors_csv),
    )
end


"""
    factors_at(fm::FactorMap, date; kind="4q")

In-sample factor vector at `date`. `kind="4q"` (default) is the
4-quarter average used by the OLS; `kind="t"` is the current-period
factor `x1..x_K`.
"""
function factors_at(fm::FactorMap, date::AbstractString; kind::AbstractString = "4q")
    idx = findfirst(==(String(date)), fm.dates_used)
    isnothing(idx) && throw(KeyError("date $date not in fit sample; " *
        "first/last used: $(fm.dates_used[1])..$(fm.dates_used[end])"))
    return kind == "4q" ? copy(fm.factors_4q[idx, :]) :
           kind == "t"  ? copy(fm.factors_t[idx, :])  :
           error("kind must be \"4q\" or \"t\", got $kind")
end


"""
    predict(fm::FactorMap, factors)

Map factor values (length `fm.n_factors`) to a coefficient row.
Interprets `factors` as the 4-quarter-averaged factor used by the OLS fit.
"""
function predict(fm::FactorMap, factors::AbstractVector{<:Real})
    length(factors) == fm.n_factors ||
        error("factors must have length $(fm.n_factors), got $(length(factors))")
    Y_std_hat = fm.α .+ fm.Λ * Vector{Float64}(factors)
    return Y_std_hat .* fm.stds .+ fm.means
end


quantile_at(fm::FactorMap, factors::AbstractVector{<:Real}, measure::Symbol, u) =
    quantile_from_row(predict(fm, factors), measure, u)

copula_density_at(fm::FactorMap, factors::AbstractVector{<:Real}, u_c, u_y, u_w) =
    copula_density_from_row(predict(fm, factors), u_c, u_y, u_w)


function summary(fm::FactorMap)
    r2 = filter(!isnan, fm.r_squared)
    med = median(r2)
    qs = quantile(r2, [0.25, 0.75])
    return "FactorMap: K=$(fm.n_factors), T_used=$(fm.n_obs_used) " *
           "(dropped $(fm.n_obs_dropped) NaN rows of $(fm.n_obs_total)), " *
           "R² median=$(round(med, digits = 3)), " *
           "R² P25/P75=($(round(qs[1], digits = 3)), $(round(qs[2], digits = 3)))"
end


end # module
