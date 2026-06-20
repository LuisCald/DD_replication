# ─────────────────────────────────────────────────────────────────────────────
# atom_marginal.jl — two-part / hurdle marginal for semicontinuous measures.
#
# Implements Appendix `local_linear.tex` §"Treatment of non-Differentiability of
# the Marginal": a measure Z with a point mass at 0 is split into
#   (i)  π = P(Z = 0)                              (weighted zero share)
#   (ii) conditional quantile of Z | Z>0          (Legendre series on positives)
# and reassembled as the unconditional quantile
#       Ξ⁻¹(u) = 0                         for u ≤ π
#              = Ξ_c⁻¹((u-π)/(1-π))        for u > π.
#
# These are standalone, dependency-light (Base + LinearAlgebra) so they can be
# unit-tested in isolation; they will be wired into treat_quantile_functions /
# series_estimator in DataConstructor.jl behind `atom_measures`. The Legendre
# basis here mirrors the orthonormal shifted-Legendre projection used there.
# Run the self-test with:  julia --startup-file=no atom_marginal.jl
# ─────────────────────────────────────────────────────────────────────────────

# Orthonormal shifted Legendre polynomial of order o on [0,1], evaluated at u.
# P̃_o(u) = sqrt(2o+1) · P_o(2u-1), with P_o the standard Legendre polynomial.
function shifted_legendre(o::Int, u::Real)
    x = 2u - 1                      # map [0,1] -> [-1,1]
    p0 = one(x); o == 0 && return sqrt(1.0) * p0
    p1 = x;      o == 1 && return sqrt(3.0) * p1
    pim1, pi = p0, p1
    for n in 2:o
        pip1 = ((2n - 1) * x * pi - (n - 1) * pim1) / n
        pim1, pi = pi, pip1
    end
    return sqrt(2o + 1) * pi
end

"""
    atom_fraction(z, w; atol=0.0) -> π̂

Weighted fraction of mass at zero: Σ wᵢ·1{zᵢ ≤ atol} / Σ wᵢ. NaNs in z are
dropped (with their weights). `atol` allows treating tiny positive values as 0.
"""
function atom_fraction(z::AbstractVector, w::AbstractVector; atol::Real=0.0)
    num = 0.0; den = 0.0
    @inbounds for i in eachindex(z, w)
        zi, wi = z[i], w[i]
        (isnan(zi) || isnan(wi)) && continue
        den += wi
        if zi <= atol
            num += wi
        end
    end
    den == 0 && return NaN
    return num / den
end

"""
    conditional_legendre_coefs(z, w, order; transform=identity, atol=0.0) -> ξ

Legendre coefficients (orders 0..order) of the conditional quantile function of
the strictly-positive subsample Z|Z>0, in transformed space `transform(z)`.
Ranks are computed within the positive subsample, matching `series_estimator`:
uᵢ = cumsum(w)/sum(w) over z sorted ascending, ξ_o = Σ wᵢ Q_o(uᵢ) y_i / Σ wᵢ.
"""
function conditional_legendre_coefs(z::AbstractVector, w::AbstractVector, order::Int;
                                    transform=identity, atol::Real=0.0)
    idx = [i for i in eachindex(z, w) if !isnan(z[i]) && !isnan(w[i]) && z[i] > atol]
    isempty(idx) && return fill(NaN, order + 1)
    p = sortperm(z[idx])
    zs = z[idx][p]
    ws = float.(w[idx][p])
    ys = [float(transform(v)) for v in zs]
    sw = sum(ws)
    u  = cumsum(ws) ./ sw                      # empirical ranks within positives
    ξ  = zeros(order + 1)
    @inbounds for o in 0:order
        acc = 0.0
        for i in eachindex(ys)
            acc += ws[i] * shifted_legendre(o, u[i]) * ys[i]
        end
        ξ[o + 1] = acc / sw
    end
    return ξ
end

"""
    atom_quantile(π, ξ, u) -> value

Unconditional quantile (in transformed space) at probability point `u` for a
hurdle marginal with zero-mass `π` and conditional Legendre coefs `ξ`.
Flat 0 on [0,π]; rescaled conditional quantile on (π,1].
"""
function atom_quantile(π::Real, ξ::AbstractVector, u::Real)
    u <= π && return 0.0
    v = (u - π) / (1 - π)
    s = 0.0
    @inbounds for o in 0:(length(ξ) - 1)
        s += ξ[o + 1] * shifted_legendre(o, v)
    end
    return s
end

# logit link for carrying π as an unbounded state coefficient (participation_link=:logit)
logit_link(π::Real)    = log(π / (1 - π))
inv_logit_link(x::Real) = 1 / (1 + exp(-x))

# ─────────────────────────────────────────────────────────────────────────────
# Self-test (runs only when this file is executed directly).
# ─────────────────────────────────────────────────────────────────────────────
using Random, Statistics
function _run_atom_selftest()
    Random.seed!(1)

    N        = 200_000
    π_true   = 0.6
    is_zero  = rand(N) .< π_true
    pos      = exp.(1.0 .+ 0.8 .* randn(N))        # lognormal positives
    z        = ifelse.(is_zero, 0.0, pos)
    w        = ones(N)

    # (i) point mass
    π̂ = atom_fraction(z, w)
    println("π̂  = $(round(π̂, digits=4))   (true $(π_true))")
    @assert abs(π̂ - π_true) < 0.005

    # (ii) conditional fit (identity transform for a clean comparison)
    order = 11
    ξ = conditional_legendre_coefs(z, w, order; transform=identity)

    # (iii) reassembly vs empirical quantile of the FULL sample (atom + positives)
    zsorted = sort(z)
    empq(u) = zsorted[clamp(ceil(Int, u * N), 1, N)]
    grid = [0.1, 0.3, 0.55, 0.65, 0.75, 0.85, 0.95, 0.99]
    maxerr_flat = 0.0; maxrelerr_pos = 0.0
    for u in grid
        q̂ = atom_quantile(π̂, ξ, u)
        qe = empq(u)
        if u <= π_true
            maxerr_flat = max(maxerr_flat, abs(q̂ - qe))   # both should be ~0
        else
            maxrelerr_pos = max(maxrelerr_pos, abs(q̂ - qe) / qe)
        end
        println("u=$(u): atom_q=$(round(q̂,digits=3))  emp_q=$(round(qe,digits=3))")
    end
    println("max |q| on atom region = $(round(maxerr_flat, digits=4))")
    println("max rel err on positive region = $(round(maxrelerr_pos, digits=3))")
    @assert maxerr_flat < 1e-9              # flat-zero segment exact
    @assert maxrelerr_pos < 0.08           # series tracks positive quantiles
    println("ALL ATOM-MARGINAL TESTS PASSED")
end

if abspath(PROGRAM_FILE) == @__FILE__
    _run_atom_selftest()
end
