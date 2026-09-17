# ─────────────────────────────────────────────────────────────────────────────
# PersistenceCounterfactual.jl — raise the distributional factors' persistence
# by hand at an estimated mode and hold everything else fixed.
#
# Why: the reconstructed series blip at PSID's wave quarters — the smoothed
# factors are jolted when the 1,730 PSID coefficients arrive every eighth
# quarter and, at |eig(A)| ≈ 0.4–0.7, the jolt decays before the next wave. The
# hypothesis is that MORE persistent factors would carry wave information
# between waves and improve the dependence cells. This tests it without a
# re-estimation: shift A's diagonal so its spectral radius hits a target,
# re-run only the reconstruction, read the cells.
#
# What it does to the parameter vector (layout: A r², B rq, C qr, D q, Ω_var …):
#   A ← A + c·I with c chosen by bisection so max|eig(A + cI)| = target
#   c is reduced if the JOINT transition [A B; C D] would exceed a radius of
#   0.99 (the estimation's stationarity guard is 0.995).
#   keep_var = true (default): the distributional innovation sds are scaled by
#   sqrt((1 − target²)/(1 − ρ₀²)) so the factors' unconditional variance is
#   roughly preserved — otherwise raising persistence also inflates every
#   reconstructed series' amplitude, and the two effects would be confounded.
# Hyperparameters (persistence targets ρ_F etc.) are untouched: they enter the
# prior only, and the reconstruction uses A directly.
#
# Used by run_postestimation.jl when DD_PERSIST_TARGET is set; outputs go to a
# separate tag folder (" persist<target>") so nothing is overwritten.
# ─────────────────────────────────────────────────────────────────────────────

function persistence_counterfactual(par::AbstractVector, param_sizes, model_options;
                                    target::Float64, keep_var::Bool = true, joint_max::Float64 = 0.99)
    par = copy(Float64.(par))
    r = param_sizes[1][1]
    q = param_sizes[2][2]
    lA, lB, lC = r * r, r * q, q * r
    A = reshape(par[1:lA], r, r)
    B = reshape(par[lA+1:lA+lB], r, q)
    C = reshape(par[lA+lB+1:lA+lB+lC], q, r)
    Dv = par[lA+lB+lC+1:lA+lB+lC+q]
    ρ(M) = maximum(abs, eigvals(M))
    joint(c) = ρ([A + c * I  B; C  diagm(Dv)])
    ρ0 = ρ(A)
    ρ0 >= target && (@warn "persistence_counterfactual: A already has radius $(round(ρ0; digits = 3)) ≥ target $(target) — nothing changed"; return par, (c = 0.0, ρ0 = ρ0, ρ1 = ρ0, joint0 = joint(0.0), joint1 = joint(0.0), g = 1.0))

    # bisection on the shift c for max|eig(A + cI)| = target
    lo, hi = 0.0, 2.0
    for _ in 1:80
        mid = (lo + hi) / 2
        ρ(A + mid * I) < target ? (lo = mid) : (hi = mid)
    end
    c = (lo + hi) / 2
    # respect the joint stationarity guard
    if joint(c) > joint_max
        lo, hi = 0.0, c
        for _ in 1:80
            mid = (lo + hi) / 2
            joint(mid) < joint_max ? (lo = mid) : (hi = mid)
        end
        c = (lo + hi) / 2
        @warn "persistence_counterfactual: target $(target) would push the joint [A B; C D] radius past $(joint_max); shift reduced to c = $(round(c; digits = 4)) (dist radius $(round(ρ(A + c * I); digits = 3)))"
    end
    for k in 1:r
        par[(k - 1) * r + k] += c
    end
    ρ1 = ρ(A + c * I)

    # keep the factors' unconditional variance roughly fixed
    g = 1.0
    if keep_var
        g = sqrt(max(1 - ρ1^2, 1e-6) / max(1 - ρ0^2, 1e-6))
        sp(x) = x < 35 ? log1p(exp(x)) : x
        isp(y) = y < 35 ? log(expm1(y)) : y
        iΩ = lA + lB + lC + q
        for k in 1:r
            par[iΩ + k] = isp(g * sp(par[iΩ + k]))
        end
    end
    return par, (c = c, ρ0 = ρ0, ρ1 = ρ1, joint0 = joint(0.0), joint1 = joint(c), g = g)
end
