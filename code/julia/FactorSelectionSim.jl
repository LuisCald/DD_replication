# ── FactorSelectionSim.jl ────────────────────────────────────────────────────
# Monte Carlo harness for the factor-count criteria in ModelPrep.jl
# (Freyaldenhoven, Bai–Ng ICp2, Ahn–Horenstein eigenvalue/growth ratio).
#
# Question it answers: at DD-like dimensions (T = pooled complete columns,
# N = coefficient series), which criterion recovers the true pervasive count,
# and how do the estimates move as T and N grow — in particular under a strong
# LOCAL factor loading on a subset of series (the "one survey's wave-to-wave
# ringing" scenario that pollutes a pooled PCA spectrum).
#
# Usage in a DD session (ModelPrep.jl already included):
#   include("FactorSelectionSim.jl")
#   factor_selection_sim()                      # default grid, prints a table
#   factor_selection_sim(Ts=[33], Ns=[1730])    # just the DD-sized cell
#
# DGP: r_true pervasive factors with geometrically decaying strength (spectrum
# shaped like the DD distributional pool), iid noise with common-variance share
# `snr_share`, optionally `n_local` strong local factors on `local_frac` of the
# series. Reported per cell: mean k̂ and exact-hit rate per criterion.

function _fss_simulate_X(rng, T, N; r_true = 8, snr_share = 0.7,
                         n_local = 0, local_frac = 0.4, local_scale = 1.0)
    # Variance shares shaped like the DD distributional spectrum: dominant
    # first factor, flat-ish tail (geometric decay would make the last factors
    # undetectable by construction, which the data says they are not).
    shares = [0.50, 0.12, 0.09, 0.07, 0.06, 0.06, 0.05, 0.05][1:min(r_true, 8)]
    r_true > 8 && append!(shares, fill(0.05, r_true - 8))
    s = sqrt.(shares ./ sum(shares))
    X = (randn(rng, T, r_true) .* s') * randn(rng, N, r_true)' .+
        sqrt((1 - snr_share) / snr_share) .* randn(rng, T, N)
    for _ in 1:n_local
        idx = randperm(rng, N)[1:round(Int, local_frac * N)]
        λl = zeros(N)
        λl[idx] .= randn(rng, length(idx))
        X .+= (randn(rng, T) .* (s[1] * local_scale)) * λl'
    end
    return X
end

function factor_selection_sim(; Ts = [15, 33, 60, 120, 250], Ns = [200, 1730],
                              locals_ = [0, 1], reps = 100, r_true = 8,
                              seed = 20260729, kwargs...)
    rng = MersenneTwister(seed)
    fmt(v) = "$(round(mean(v); digits=1)) ($(round(Int, 100 * mean(v .== r_true)))%)"
    @info "factor-selection MC: r_true=$r_true, $(reps) reps/cell; " *
          "cells report mean k̂ (exact-hit %)"
    rows = []
    for T in Ts, N in Ns, nl in locals_
        est = Dict(k => Int[] for k in (:FR, :BN, :ER, :GR))
        for _ in 1:reps
            X = _fss_simulate_X(rng, T, N; r_true, n_local = nl, kwargs...)
            r_max = min(15, minimum(size(X)) - 1)
            push!(est[:FR], n_factors_freyaldenhoven(X, r_max))
            push!(est[:BN], n_factors_bai_ng(X, r_max; gnum = 2))
            push!(est[:ER], n_factors_eigenvalue_ratio(X, r_max))
            push!(est[:GR], n_factors_growth_ratio(X, r_max))
        end
        row = (T = T, N = N, local_factor = nl,
               freyaldenhoven = fmt(est[:FR]), bai_ng = fmt(est[:BN]),
               eig_ratio = fmt(est[:ER]), growth_ratio = fmt(est[:GR]))
        push!(rows, row)
        @info "T=$T N=$N local=$nl | FR $(row.freyaldenhoven) " *
              "BN $(row.bai_ng) ER $(row.eig_ratio) GR $(row.growth_ratio)"
    end
    return rows
end
