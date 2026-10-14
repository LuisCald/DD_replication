# ─────────────────────────────────────────────────────────────────────────────
# RecessionPanels.jl — the paper's "Comparison of Consumption Dynamics during
# Recessions" figure (relcons{dotcom,greatrecession,covid}{income,wealth,iw}),
# ported from code/stata/consumption_recessions.do.
#
# Same groups, normalisation and look as the Stata panels, but the group means
# are EXACT: E[consum | income rank ∈ G_y, wealth rank ∈ G_w] is integrated from
# the continuous copula and quantile functions (closed-form Legendre integrals on
# the conditioning side, Gauss–Legendre on the outcome side — the box version of
# compute_cross_conditional_means_continuous). Stata instead summed 10×10×10
# copula cells, each carrying the UNCONDITIONAL consumption-decile mean, and
# dropped negative cells.
#
#   compute (inside export_functional_data) → from_mcmc/data/<k>_recession_groups.csv
#   plot    plot_recession_panels(results_dir)  → <results_dir>/Application/relcons*.pdf/.png
#
# plot_recession_panels needs only CSV/DataFrames/Plots, so this file can be
# included on its own to re-plot (see run_recession_panels.jl).
# ─────────────────────────────────────────────────────────────────────────────

# Group boxes on the rank scale, as in consumption_recessions.do (grid g ↦ ranks
# ((g-1)/10, g/10]): income/wealth groups 1–2, 3–4, 5–8, 9–10; iw groups are the
# do-file's iwgroups 1–4 (group 2: income ≤ 4 & wealth ≥ 8).
const RECESSION_GROUPS = [
    ("income", [Dict("income" => (0.0, 0.2)), Dict("income" => (0.2, 0.4)),
                Dict("income" => (0.4, 0.8)), Dict("income" => (0.8, 1.0))]),
    ("wealth", [Dict("wealth" => (0.0, 0.2)), Dict("wealth" => (0.2, 0.4)),
                Dict("wealth" => (0.4, 0.8)), Dict("wealth" => (0.8, 1.0))]),
    ("iw",     [Dict("income" => (0.0, 0.2), "wealth" => (0.0, 0.2)),
                Dict("income" => (0.0, 0.4), "wealth" => (0.7, 1.0)),
                Dict("income" => (0.4, 0.8), "wealth" => (0.4, 0.8)),
                Dict("income" => (0.8, 1.0), "wealth" => (0.8, 1.0))]),
]

"""
    box_conditional_means(cop_coefs, split_pcfs, measures, corr_mat, outcome, boxes; ...)

E[outcome | u_d ∈ box_d for every conditioning dimension d] per quarter, plus the
box's population mass and the unconditional mean. `boxes` is a vector of
Dict(measure => (lo, hi)); a measure not in the Dict is unrestricted.
Returns (means = nB×T, masses = nB×T, popmean = T).
"""
function box_conditional_means(cop_coefs, split_pcfs, measures, corr_mat, outcome, boxes;
                               max_order::Int = size(split_pcfs[1], 1) - 1,
                               atom_dim = nothing, atom_π = nothing)
    D = length(measures)
    T = size(split_pcfs[1], 2)
    K = size(cop_coefs, 1)
    oi = findfirst(==(outcome), measures)
    nB = length(boxes)
    means, masses, popmean = fill(NaN, nB, T), fill(NaN, nB, T), fill(NaN, T)
    oi === nothing && return (means = means, masses = masses, popmean = popmean)

    # conditioning side, closed form: ∫_lo^hi Q_k du (unrestricted ⇒ e₁)
    segint(lo, hi) = [integrate_legendre_polynomial(k, hi) - integrate_legendre_polynomial(k, lo) for k = 0:(K-1)]
    W = [[segint(get(b, measures[d], (0.0, 1.0))...) for d = 1:D] for b in boxes]
    e1 = [k == 1 ? 1.0 : 0.0 for k = 1:K]
    colons = ntuple(_ -> Colon(), D)

    for t = 1:T
        coefs_o = split_pcfs[oi][:, t]
        any(isnan, coefs_o) && continue
        κt = cop_coefs[colons..., t]
        any(isnan, κt) && continue

        corr_o = corr_mat[t, oi]
        Vfun = if oi === atom_dim && atom_π !== nothing
            πt = atom_π[t]
            u -> u <= πt ? 0.0 :
                reverse_inverse_hyperbolic_sine(eval_quantile_function(coefs_o, max_order, (u - πt) / (1 - πt)))[1] * corr_o
        else
            u -> reverse_inverse_hyperbolic_sine(eval_quantile_function(coefs_o, max_order, u))[1] * corr_o
        end
        # outcome side: A[j+1] = ∫₀¹ Q_j(u) V_t(u) du, composite over deciles for the tails
        A = [sum(gauss_legendre_integrate(u -> Q_m(j, u) * Vfun(u), b / 10, (b + 1) / 10) for b = 0:9) for j = 0:(K-1)]
        popmean[t] = A[1]   # Q_0 ≡ 1

        for bi = 1:nB
            num = den = 0.0
            for I in CartesianIndices(κt)
                c = κt[I]
                wcond = 1.0
                for d = 1:D
                    d == oi && continue
                    wcond *= W[bi][d][I[d]]
                end
                num += c * wcond * A[I[oi]]
                den += c * wcond * e1[I[oi]]
            end
            masses[bi, t] = den
            means[bi, t] = den > 0 ? num / den : NaN
        end
    end
    return (means = means, masses = masses, popmean = popmean)
end

"""
    recession_groups_table(cop_coefs, split_pcfs, measures, corr_mat, dates; ...)

DataFrame with year, quarter, popmean_consum and <set>_g<i>_mean / _mass for the
RECESSION_GROUPS, or `nothing` if the dataset lacks consum, income or wealth.
"""
function recession_groups_table(cop_coefs, split_pcfs, measures, corr_mat, dates; kw...)
    all(m -> m in measures, ("consum", "income", "wealth")) || return nothing
    X = DataFrame(year = year.(dates), quarter = quarter.(dates))
    for (set, boxes) in RECESSION_GROUPS
        r = box_conditional_means(cop_coefs, split_pcfs, measures, corr_mat, "consum", boxes; kw...)
        X[!, "popmean_consum"] = r.popmean
        for i in eachindex(boxes)
            X[!, "$(set)_g$(i)_mean"] = r.means[i, :]
            X[!, "$(set)_g$(i)_mass"] = r.masses[i, :]
        end
    end
    all(isnan, X.popmean_consum) && return nothing
    return X
end

# ── Figure ───────────────────────────────────────────────────────────────────
# Recession start (distance 0) and NBER shading on the distance axis, as in the
# do-file and the paper panels.
const RECESSIONS = [
    ("dotcom",         (2001, 1), (0, 3)),   # 2001Q1–2001Q4
    ("greatrecession", (2007, 4), (0, 6)),   # 2007Q4–2009Q2
    ("covid",          (2019, 4), (1, 2)),   # 2020Q1–2020Q2, distance from 2019Q4
]

# Stata tssmooth ma window(1 1 1): centred 3-quarter mean over available neighbours
function _ma3(x)
    n = length(x)
    [begin
         v = filter(!isnan, x[max(1, i - 1):min(n, i + 1)])
         isempty(v) ? NaN : sum(v) / length(v)
     end for i = 1:n]
end

"""
    plot_recession_panels(results_dir; dataset = "PSID", data_tag = "", label = "_A non-diag_")

Reads `<results_dir>/from_mcmc/data/<dataset>_recession_groups<data_tag><label>.csv`
and writes the nine paper panels to `<results_dir>/Application/` as PDF and PNG.
"""
function plot_recession_panels(results_dir; dataset = "PSID", data_tag = "", label = "_A non-diag_")
    file = joinpath(results_dir, "from_mcmc", "data", dataset * "_recession_groups" * data_tag * label * ".csv")
    X = CSV.read(file, DataFrame)
    outdir = joinpath(results_dir, "Application")
    mkpath(outdir)
    qidx = X.year .* 4 .+ X.quarter

    colors  = [:blue, :red, :green, Plots.RGB(0.5, 0.2, 0.1)]
    markers = [:circle, :rect, :diamond, :utriangle]

    for (set, boxes) in RECESSION_GROUPS
        cols = set == "iw" ? [colors[1], :purple, colors[3], colors[4]] : colors

        # 1) normalised series for the three recessions of this row
        series = Dict{String,Any}()
        for (rname, (ry, rq), _) in RECESSIONS
            dist = qidx .- (ry * 4 + rq)
            win = findall(d -> -8 <= d <= 8, dist)
            i0 = findfirst(==(0), dist)
            lines = []
            for i in eachindex(boxes)
                rel = X[!, "$(set)_g$(i)_mean"] ./ X.popmean_consum
                ma = _ma3(rel)
                (i0 === nothing || isnan(ma[i0])) && continue
                relw, maw = rel[win] ./ ma[i0], ma[win] ./ ma[i0]
                maw[isnan.(relw)] .= NaN   # no line where the quarter itself is unobserved (as in the paper)
                push!(lines, (i, dist[win], relw, maw))
            end
            series[rname] = lines
        end

        # 2) one zoomed y-range per row, so the three panels stay comparable
        vals = filter(!isnan, vcat([vcat(l[3], l[4]) for r in values(series) for l in r]...))
        lo, hi = isempty(vals) ? (0.9, 1.1) : (minimum(vals) - 0.005, maximum(vals) + 0.005)
        ystep = hi - lo <= 0.08 ? 0.02 : hi - lo <= 0.3 ? 0.05 : 0.1
        yt = collect(ceil(lo / ystep - 1e-9) * ystep:ystep:hi)
        ylab = [string(round(v; digits = 3)) for v in yt]   # ASCII labels (GR's Unicode minus has no Times glyph)

        # 3) draw
        for (rname, _, (s0, s1)) in RECESSIONS
            p = Plots.plot(; legend = false, xlims = (-10, 10),
                     xticks = (-10:5:10, string.(-10:5:10)),   # ASCII minus: GR's "−" printed as "?" in the PDF
                     ylims = (lo, hi), yticks = (yt, ylab), size = (600, 450),
                     grid = false, framestyle = :box, tickfontsize = 16,
                     fontfamily = "Times", left_margin = 4Plots.mm, bottom_margin = 3Plots.mm)
            Plots.vspan!(p, [s0, s1]; color = :grey85, alpha = 0.7, linewidth = 0, linealpha = 0)   # seamless band, no outline
            Plots.hline!(p, [1.0]; color = :grey80, linewidth = 0.5)
            for (i, d, relw, maw) in series[rname]
                Plots.plot!(p, d, maw; color = cols[i], linestyle = :dash, linewidth = 1)
                Plots.scatter!(p, d, relw; color = cols[i], marker = markers[i],
                         markersize = 6, markerstrokewidth = 0)
            end
            for ext in ("pdf", "png")
                Plots.savefig(p, joinpath(outdir, "relcons$(rname)$(set).$ext"))
            end
        end
    end
    @info "Recession panels written to $outdir"
    return outdir
end
