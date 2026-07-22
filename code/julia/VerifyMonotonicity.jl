# ── VerifyMonotonicity.jl ────────────────────────────────────────────────────
# Ex-post monotonicity check of the RECONSTRUCTED Legendre quantile functions
# (appendix claim: evaluated on a fine grid, no violations; rearrangement as
# remedy if needed). Monotonicity of the asinh-transformed fit is equivalent
# to monotonicity of the quantile function itself (asinh is monotone), so the
# check runs directly on the coefficient-space reconstruction.
#
# Usage in a session where estimation/post-estimation ran (dv in scope):
#   include("VerifyMonotonicity.jl")
#   verify_monotonicity(dv, model_options)          # all keys, "normal" pass
# or for a single reconstruction matrix X (rows = copula block + pcf blocks):
#   verify_monotonicity_X(X, sort(measures), estimator)
#
# Reports violations per dataset/measure with counts, worst magnitude, and the
# (period, grid point) of the worst offender. Returns a summary Dict.

function verify_monotonicity_X(X::AbstractMatrix, measures, estimator;
    npoints::Int = 10_000, tol::Float64 = 0.0, label::AbstractString = "")

    grid_pcf = estimator.grid_pcf
    grid_cop = estimator.grid_cop
    D = length(measures)
    cop_rows = grid_cop^D - (grid_cop + (D - 1) * (grid_cop - 1))
    T = size(X, 2)

    # Basis matrix Φ (npoints × grid_pcf), shared across all series
    u = collect(range(1 / (2npoints), 1 - 1 / (2npoints); length = npoints))
    Φ = [Q_m(j, ui) for ui in u, j = 0:(grid_pcf-1)]

    out = Dict{String,Any}()
    for (m, meas) in enumerate(measures)
        rows = (cop_rows + (m - 1) * grid_pcf + 1):(cop_rows + m * grid_pcf)
        coefs = X[rows, :]                                   # grid_pcf × T
        nviol = 0
        nseries = 0
        worst = 0.0
        worst_at = (0, 0.0)
        for t = 1:T
            any(isnan, @view(coefs[:, t])) && continue
            nseries += 1
            q̂ = Φ * @view(coefs[:, t])                       # npoints
            d = diff(q̂)
            v = findall(x -> x < -tol, d)
            if !isempty(v)
                nviol += 1
                mn, i = findmin(d)
                if mn < worst
                    worst = mn
                    worst_at = (t, u[i])
                end
            end
        end
        out[String(meas)] = (
            periods_checked = nseries,
            periods_with_violations = nviol,
            evaluations = nseries * npoints,
            worst_violation = worst,
            worst_at_period_u = worst_at,
        )
        stat = nviol == 0 ? "OK" : "VIOLATIONS"
        @info "monotonicity $label/$meas: $stat — $nviol of $nseries periods " *
              "($(nseries * npoints) evaluations)" *
              (nviol > 0 ? "; worst d = $(round(worst; sigdigits = 3)) at (t = $(worst_at[1]), u ≈ $(round(worst_at[2]; digits = 4)))" : "")
    end
    return out
end

function verify_monotonicity(dv::AbstractDict, model_options; ty::AbstractString = "normal", kwargs...)
    measures = sort(model_options.measures)
    estimator = model_options.estimator
    summary = Dict{String,Any}()
    for (k, v) in dv
        haskey(v, ty) || continue
        Xs = v[ty]
        # dv[k][ty] is a vector of per-dataset matrices (or a single matrix)
        if Xs isa AbstractVector
            for (j, X) in enumerate(Xs)
                X isa AbstractMatrix || continue
                summary["$k/$j"] = verify_monotonicity_X(X, measures, estimator; label = "$k/$j", kwargs...)
            end
        elseif Xs isa AbstractMatrix
            summary[String(k)] = verify_monotonicity_X(Xs, measures, estimator; label = String(k), kwargs...)
        end
    end
    total_viol = sum(r.periods_with_violations for s in values(summary) for r in values(s); init = 0)
    total_eval = sum(r.evaluations for s in values(summary) for r in values(s); init = 0)
    @info "monotonicity TOTAL: $(total_viol) violating periods across $(total_eval) evaluations"
    return summary
end
