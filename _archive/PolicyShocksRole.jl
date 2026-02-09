# What is the role of policy shocks in driving the distribution vs aggregate variables?
# using CategoricalArrays
# using CSV 
# using Coverage
# using Random
# using GalacticOptim
# using DualNumbers
# using DataFramesMeta 
# using PyPlot
# using DataSets
# using MatrixEquations
# using SparseArrays
# using RecursiveArrayTools

# using StaticArrays
cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
using Pkg
Pkg.activate("env_dd_v19/")
using ProgressMeter
using QuadGK
using Distributed
# using BAT 
# using ValueShapes
using Optimization
using OptimizationOptimJL
using ReverseDiff
using ForwardDiff
using Optim
using DataFrames
using FreqTables
using DualNumbers
using AdvancedHMC
using CSV
using LineSearches
using Zygote
# using DIMESampler 
using Printf
using ProgressBars
using StatsFuns
using Interpolations
using GR
using Random
using Polynomials
using VectorAutoregressions
GR.inline("pdf")

# using GalacticOptim: AutoReverseDiff
using GenericLinearAlgebra: svd
using Distributions
using StatsPlots
using Plots
using MCMCChains
using HypothesisTests
using GLM
using HPFilter # add https://github.com/sdBrinkmann/HPFilter.jl

using LaTeXTabulars
using Dates
using PeriodicalDates
# URL = "https://github.com/andreasKroepelin/KernelDensity.jl"
# Pkg.add(url=URL)
using KernelDensity
using Measures
using MultivariateStats
# using PlotlyJS
using Parameters
using FFTW
using XLSX
using StatsBase
using LaTeXStrings
using LinearAlgebra
using BenchmarkTools
using TimerOutputs
using Test
using DelimitedFiles
using PDMats
# using MCMCDiagnosticTools
using JLD2
using Trapz
using Combinatorics
using MatrixEquations
using FiniteDiff
using Latexify
using BlackBoxOptim
using KissSmoothing
# using RCall
using NaNStatistics
using JuMP
using HiGHS
using ChebyshevApprox

# First, save factors here:
# jldsave("/home/luisc/Distributional_Dynamics/7_Results/factor_analysis/factors.jld2", factors=x_smoothed)

# Open file:
dfactors = "/Users/lc/Dropbox/Distributional_Dynamics/5_Code/factors.jld2"
factors = jldopen(dfactors, "r") do file
    read(file, "factors")
end

# Open shocks file
shock_file = "/home/luisc/Distributional_Dynamics/2_Data_processing/shocks.csv"
shocks = CSV.read(shock_file, DataFrame)

# Extract the first 8 factors (distributional) and last 25 factors (aggregates) from the smoothed factors
dist_factors = Matrix(factors[1:8, :])
agg_factors = Matrix(factors[4*8+1:end, :])

# Find how much variation is explained by the shocks on each set of factors: "Sequence FEVD"
# We will do this for horizons of 1, 4, 8, 12, 16, 20, 24 months
using LinearAlgebra, Statistics, DataFrames, PrettyTables

# Selectors for your companion form (matches your build_selectors)
function selectors(r::Int, q::Int, n::Int)
    J = zeros(Float64, r, n)
    J[:, 1:r] .= diagm(ones(eltype(Φ), r)) # pick current f_t
    S_f = zeros(Float64, n, r)
    S_f[1:r, 1:r] .= diagm(ones(eltype(Φ), r)) # factor shock locations
    S_y = zeros(Float64, n, q)
    S_y[4r+1:4r+q, 1:q] .= diagm(ones(eltype(Φ), q)) # output shock locations
    return J, S_f, S_y
end

# Robust PSD square-root via eigen (guards tiny negative eigenvalues)
sym_sqrt_psd(Σ; tol=1e-12) = begin
    E = eigen(Symmetric(Σ))
    λ = clamp.(E.values, 0.0, Inf)
    E.vectors * Diagonal(sqrt.(λ)) * E.vectors'
end

"""
    fevd_policy_external(Φ, eps_hat, s_policy; r, q, horizon=20, factor_names=nothing)

Compute FEVD (%) for each factor from an **external policy shock** vs **all other shocks**.

Assumes state layout n = 4r + q and that true shock innovations only occupy rows 1:r and 4r+1:4r+q.

Inputs
------
- Φ        :: n×n  transition
- eps_hat  :: n×T  smoothed innovations ε̂_t (from your smoother; same ordering as state)
- s_policy :: T    external policy shock series (any scale; will be standardized)
- r, q     :: Int
- horizon  :: Int  FEVD horizon (default 20)
- factor_names :: Vector{String} of length r (optional)

Returns
-------
(DataFrame, latex_string)
DataFrame columns: :Factor, :Policy, :Rest    (percentages summing to ~100)
"""
using LinearAlgebra, Statistics, DataFrames, PrettyTables

# -- Selectors for your companion layout n = 4r + q
#    F_t = [f_t; f_{t-1}; f_{t-2}; f_{t-3}] (size 4r), Y_t (size q)
#    Innovations only live in rows 1:r (current f_t) and 4r+1:4r+q (Y_t).
function _selectors(r::Int, q::Int, n::Int)
    @assert n == 4r + q
    # pick current f_t
    J_f = zeros(Float64, r, n)
    J_f[:, 1:r] .= diagm(ones(Float64, r))
    # pick Y_t
    J_y = zeros(Float64, q, n)
    J_y[:, 4r+1:4r+q] .= diagm(ones(Float64, q))

    # shock selectors
    S_f = zeros(Float64, n, r)
    S_f[1:r, 1:r] .= diagm(ones(Float64, r))
    S_y = zeros(Float64, n, q)
    S_y[4r+1:4r+q, 1:q] .= diagm(ones(Float64, q))
    return J_f, J_y, S_f, S_y
end

"""
    fevd_policy_external_both(Φ, eps_hat, s_policy; r, q, horizon=20,
                              factor_names=nothing, agg_names=nothing)

Policy-vs-Rest FEVD (%) for BOTH:
  (i) the r distributional factors f_t, and
  (ii) the q aggregate variables Y_t.

- `Φ`      :: n×n transition
- `eps_hat`:: n×T smoothed innovations (same ordering as the state)
- `s_policy`:: length-T external policy shock series (will be standardized)
- `r, q`   :: Int (n must be 4r + q)
- `horizon`:: Int FEVD horizon (default 20)
- `factor_names` :: Vector{String} length r (optional)
- `agg_names`    :: Vector{String} length q (optional)

Returns:
  df_factors::DataFrame  (columns: Factor, Policy, Rest)
  df_aggregs::DataFrame  (columns: Aggregate, Policy, Rest)
  latex_factors::String
  latex_aggregs::String
"""
function fevd_policy_external_both(Φ::AbstractMatrix, eps_hat::AbstractMatrix, s_policy::AbstractVector;
    r::Int, q::Int, horizon::Int=20,
    factor_names=nothing, agg_names=nothing)

    n, T = size(eps_hat)
    @assert n == size(Φ, 1) == size(Φ, 2) == 4r + q "State dimension must be n = 4r + q."
    @assert length(s_policy) == T "Policy series length must match T."

    # Selectors
    J_f, J_y, S_f, S_y = _selectors(r, q, n)
    S = hcat(S_f, S_y)                 # n×(r+q)
    ξ̂ = S' * eps_hat                   # (r+q)×T  (true shock innovations only)

    # Standardize policy series; demean innovations row-wise
    ξ̂c = ξ̂ .- mean(ξ̂; dims=2)
    sp = s_policy .- mean(s_policy)
    sp ./= std(sp) + eps()               # unit variance

    # Policy impact in active shock space: a = Cov(ξ̂, sp) since Var(sp)=1
    a = (ξ̂c * sp) / (T - 1)           # (r+q)×1

    # Residual covariance after removing the policy component
    Σξ = (ξ̂c * ξ̂c') / (T - 1)        # (r+q)×(r+q)
    Σres = Symmetric(Σξ - a * a')        # residual subspace (PSD up to num. tol)

    # Orthonormal shock basis: first col = policy; remainder spans residual covariance
    Eval = eigen(Σres)
    λ = clamp.(Eval.values, 0.0, Inf)
    V = Eval.vectors
    perm = sortperm(λ; rev=true)
    λs, Vs = λ[perm], V[:, perm]
    k = r + q
    m = min(k - 1, count(>(1e-12), λs))
    C_res = m == 0 ? zeros(k, 0) : Vs[:, 1:m] * Diagonal(sqrt.(λs[1:m]))  # k×m

    # Impact in state space: ε = B u, with u orthonormal and columns [policy | rest...]
    B = S * hcat(a, C_res)               # n×(1+m)

    # Generic FEVD accumulator for any selection J_• (rows = variables of interest)
    function shares_for(J::AbstractMatrix)
        p = size(J, 1)
        num_pol = zeros(Float64, p)
        num_rst = zeros(Float64, p)
        denom = zeros(Float64, p)

        Φs = I(n)
        for s in 0:(horizon-1)
            Θs = J * Φs * B                           # p×(1+m)
            @views begin
                num_pol .+= abs2.(Θs[:, 1])                  # policy col
                if size(Θs, 2) > 1
                    num_rst .+= sum(abs2, Θs[:, 2:end]; dims=2)[:]
                end
                denom .+= sum(abs2, Θs; dims=2)[:]
            end
            Φs = Φs * Φ
        end

        denom_safe = denom
        100 .* (num_pol ./ denom_safe), 100 .* (num_rst ./ denom_safe)
    end

    # Factors (f_t)
    pol_f, rst_f = shares_for(J_f)
    names_f = factor_names === nothing ? ["Factor $(i)" for i in 1:r] : factor_names
    @assert length(names_f) == r
    df_f = DataFrame(Factor=names_f, Policy=pol_f, Rest=rst_f)

    # Aggregates (Y_t)
    pol_y, rst_y = shares_for(J_y)
    names_y = agg_names === nothing ? ["Aggregate $(j)" for j in 1:q] : agg_names
    @assert length(names_y) == q
    df_y = DataFrame(Aggregate=names_y, Policy=pol_y, Rest=rst_y)

    # LaTeX strings
    latex_f = pretty_table(df_f; backend=Val(:latex), tf=tf_latex_default)
    latex_y = pretty_table(df_y; backend=Val(:latex), tf=tf_latex_default)

    return df_f, df_y, latex_f, latex_y
end

# Given: Φ (n×n), eps_hat (n×T), external policy shock series s_policy (length T)
r = 8
q = 25  # for example

A, B, C, D, Ω_big, Σ = matrisize(par_final, param_sizes)
r, q = size(B)
nₛ = 4r + q
Tval = eltype(A)

# --------- constant matrices ------------------------------------
AI = Matrix{Tval}(I, r, r)

Φ = zeros(Tval, nₛ, nₛ)
@views begin
    Φ[1:r, 1:r] .= A
    Φ[1:r, 4r+1:4r+q] .= B
    Φ[r+1:2r, 1:r] .= AI
    Φ[2r+1:3r, r+1:2r] .= AI
    Φ[3r+1:4r, 2r+1:3r] .= AI
    Φ[4r+1:end, 1:r] .= C
    Φ[4r+1:end, 4r+1:end] .= D
end
smoother_res, logV, alarm = likeli(model_elements, par_final, param_sizes, priors, meas_ind, Σ_ids, model_options; smooth=true)
@unpack x_smoothed, x_filtered, dε_smoothed = smoother_res               # F̂_t   (nF × T)

select!(shocks, [:time, :MPS_orth_sum])
shocks = shocks[completecases(shocks), :]

shocks_time = QuarterlyDate.(shocks[!, :time])

# Align shocks with factors by time
@unpack tmin, tmax = time_params
dts = collect(QuarterlyDate(tmin["year"], tmin["quarter"]):Quarter(1):QuarterlyDate(tmax["year"], tmax["quarter"]))
ids_dts = findall(in(shocks_time), dts)
s_policy = shocks[!, :MPS_orth_sum]

# Subset dε_smoothed
dε_smoothed_sub = dε_smoothed[:, ids_dts]


df_f, df_y, latex_f, latex_y = fevd_policy_external_both(
    Φ, dε_smoothed_sub, s_policy; r=8, q=q, horizon=20,
    factor_names=["Distributional Factor $(i)" for i in 1:8],
    agg_names=["Aggregate $(j)" for j in 1:q],
)
# Save the LaTeX table
open("fevd_policy_vs_rest_h20.tex", "w") do io
    write(io, latex_f)
    write(io, latex_y)
end
