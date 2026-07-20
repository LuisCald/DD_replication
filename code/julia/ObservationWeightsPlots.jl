# ============================================================================
# ObservationWeightsPlots.jl — figures for the observation-weight decomposition
# (companion to ObservationWeights.jl; "anatomy of the synthetic data").
#
# House style: LaTeX everywhere (ticks, labels, legends), large fonts, no
# titles. All calls Plots.-qualified (GR is also loaded in this codebase).
#
# NOTE ON "state dynamics": in the VALUE decomposition, the prior/deterministic
# term is ~0 by construction (demeaned data, zero-mean prior) — the dynamics
# transport observations across time rather than adding a term of their own,
# so between-wave estimates load on the ever-present aggregates block. The
# honest "interpolation share" is VARIANCE-based: sigma_smoothed relative to
# the stationary (unconditional) variance — see plot_interpolation_share().
#
# Server/headless: set ENV["GKSwstype"] = "100" before `using Plots`.
#
# Usage:
#   include("ObservationWeightsPlots.jl")
#   dec2  = merge_groups(dec)
#   dates = collect(QuarterlyDate(time_params.tmin["year"], time_params.tmin["quarter"]) .+
#                   Quarter.(0:size(dec.full,2)-1))
#   outdir = joinpath(BASE_PATH, "7_Results", "anatomy")
#   plot_all_factors(dec2; r=8, dates=dates, outdir=outdir)
#
#   # variance-based interpolation share (needs smoother covs + system matrices):
#   sm, _, _ = likeli(model_elements, par_final, param_sizes, priors, Σ_ids,
#                     model_options; smooth=true)
#   A,B,C,D,Ω_var,Ω_corr,Σm = matrisize(par_final[1:end-param_sizes[end][1]], param_sizes)
#   Ω = ... (as in likeli: softplus diag, corr reconstruction)  # or reuse from a likeli hack
#   Φ, Ωbig = build_Phi_Omega(A, B, C, D, Ω, 4)
#   P∞ = stationary_cov(Φ, Ωbig)
#   plot_interpolation_share(sm.sigma_smoothed, P∞; states=1:8, dates=dates,
#                            outfile=joinpath(outdir,"ow_interp_share.pdf"))
# ============================================================================

using Plots
using LaTeXStrings
using Dates

const OW_ORDER  = ["PSID", "SCF", "CEX", "CPS", "SIPP", "aggregates"]
const OW_COLORS = Dict(
    "PSID"           => "#2a78d6",
    "SCF"            => "#1baf7a",
    "CEX"            => "#eda100",
    "CPS"            => "#008300",
    "SIPP"           => "#4a3aa7",
    "aggregates"     => "#e34948",
    "state dynamics" => "#a5a39b",
)
# _ow_color(name) = get(OW_COLORS, name, "#7a4dbf")
# HANK replica sources ("HANK a 3", …) inherit their target dataset's color
# (a→PSID, b→CPS, c→CEX, d→SCF, e→SIPP); previously they all fell to the
# purple default and were indistinguishable in the anatomy plots.
function _ow_color(name)
    haskey(OW_COLORS, name) && return OW_COLORS[name]
    if occursin("HANK", name)
        target = occursin("HANK a", name) ? "PSID" :
                 occursin("HANK b", name) ? "CPS" :
                 occursin("HANK c", name) ? "CEX" :
                 occursin("HANK d", name) ? "SCF" :
                 occursin("HANK e", name) ? "SIPP" : ""
        target != "" && return OW_COLORS[target]
    end
    return "#7a4dbf"
end
_ow_label(name) = latexstring("\\textrm{", replace(uppercasefirst(name), " " => "\\ "), "}")

const OW_STYLE = (guidefontsize=22, xtickfontsize=20, ytickfontsize=20,
                  legendfontsize=16, framestyle=:box, grid=:y)
const OW_SIZE  = (1500, 640)

# Numeric time axis so the :latex tick formatter is safe for dates too.
_numeric_dates(::Nothing, T) = collect(1.0:T)
_numeric_dates(x::AbstractVector{<:Real}, T) = collect(float.(x))
_numeric_dates(x, T) = [year(d) + (quarter(d) - 1) / 4 for d in x]

"""
    merge_groups(dec; groups=Dict("SIPP"=>["SIPP1","SIPP2","SIPP3"], "CPS"=>["CPS","CPS2"]))

Additively merge related source blocks (contributions are exactly additive).
"""
function merge_groups(dec; groups=Dict("SIPP" => ["SIPP1", "SIPP2", "SIPP3"],
                                       "CPS"  => ["CPS", "CPS2"]))
    contribs = Dict{String,Matrix{Float64}}()
    merged_members = Set(vcat(values(groups)...))
    for (k, v) in dec.contributions
        k in merged_members && continue
        contribs[k] = copy(v)
    end
    for (gname, members) in groups
        acc = nothing
        for m in members
            haskey(dec.contributions, m) || continue
            acc = acc === nothing ? copy(dec.contributions[m]) : acc .+ dec.contributions[m]
        end
        acc !== nothing && (contribs[gname] = haskey(contribs, gname) ?
                                              contribs[gname] .+ acc : acc)
    end
    return (full=dec.full, prior=dec.prior, contributions=contribs, check=dec.check)
end

function _ordered_sources(contribs)
    names = collect(keys(contribs))
    known = [s for s in OW_ORDER if s in names]
    extra = sort([s for s in names if !(s in OW_ORDER)])
    return vcat(known, extra)
end

"""
    plot_information_shares(dec; state=1, dates=nothing, outfile=nothing,
                            include_prior=false, kwargs...)

Stacked-area shares of |contributions| for one state. By default the
prior/deterministic term is EXCLUDED (it is ~0 by construction; see header
note) — set `include_prior=true` to show it.
"""
function plot_information_shares(dec; state=1, dates=nothing, outfile=nothing,
                                 include_prior=false, kwargs...)
    srcs = _ordered_sources(dec.contributions)
    T = size(dec.full, 2)
    x = _numeric_dates(dates, T)

    n = length(srcs) + (include_prior ? 1 : 0)
    A = zeros(n, T)
    for (i, s) in enumerate(srcs)
        A[i, :] = abs.(view(dec.contributions[s], state, :))
    end
    include_prior && (A[end, :] = abs.(view(dec.prior, state, :)))
    denom = max.(sum(A, dims=1), 1e-12)
    A ./= denom
    cum = cumsum(A, dims=1)

    plt = Plots.plot(; size=OW_SIZE, legend=:outertop, legend_columns=4,
                     ylabel=L"\textrm{Share}", ylims=(0, 1),
                     xformatter=:latex, yformatter=:latex,
                     bottom_margin=6Plots.mm, left_margin=10Plots.mm,
                     top_margin=2Plots.mm, OW_STYLE..., kwargs...)
    labels = vcat(srcs, include_prior ? ["state dynamics"] : String[])
    for i in 1:n
        Plots.plot!(plt, x, vec(cum[i, :]);
                    fillrange=(i == 1 ? zeros(T) : vec(cum[i-1, :])),
                    fillcolor=_ow_color(labels[i]), linecolor=:white, linewidth=0.4,
                    label=_ow_label(labels[i]), seriescolor=_ow_color(labels[i]))
    end
    outfile !== nothing && Plots.savefig(plt, outfile)
    return plt
end

"""
    plot_source_contributions(dec; state=1, dates=nothing, outfile=nothing, kwargs...)

Signed contributions per source + prior (dashed) + full smoothed path (dotted).
"""
function plot_source_contributions(dec; state=1, dates=nothing, outfile=nothing, kwargs...)
    srcs = _ordered_sources(dec.contributions)
    T = size(dec.full, 2)
    x = _numeric_dates(dates, T)

    plt = Plots.plot(; size=OW_SIZE, legend=:outertop, legend_columns=4,
                     ylabel=L"\chi^{\,b}_t\,\textrm{(factor\,units)}",
                     xformatter=:latex, yformatter=:latex,
                     bottom_margin=6Plots.mm, left_margin=10Plots.mm,
                     top_margin=2Plots.mm, OW_STYLE..., kwargs...)
    for s in srcs
        Plots.plot!(plt, x, vec(dec.contributions[s][state, :]);
                    color=_ow_color(s), linewidth=1.8, label=_ow_label(s))
    end
    Plots.plot!(plt, x, vec(dec.prior[state, :]); color=_ow_color("state dynamics"),
                linewidth=1.8, linestyle=:dash, label=_ow_label("state dynamics"))
    Plots.plot!(plt, x, vec(dec.full[state, :]); color=:black, linewidth=2.4,
                linestyle=:dot, label=L"\textrm{Full\ (sum)}")
    outfile !== nothing && Plots.savefig(plt, outfile)
    return plt
end

"""
    build_Phi_Omega(A, B, C, D, Ω, p)

Assemble the companion transition matrix Φ (state = [f_t; ...; f_{t-p+1}; Y_t])
and the conformable innovation covariance Ωbig (innovations enter rows 1:r and
the aggregate rows; lag-identity rows carry none), as in the state equation.
"""
function build_Phi_Omega(A, B, C, D, Ω, p)
    r = size(A, 1); q = size(D, 1)
    n = r * p + q
    Φ = zeros(n, n)
    Φ[1:r, 1:r] = A
    Φ[1:r, r*p+1:end] = B
    for l in 2:p
        Φ[(l-1)*r+1:l*r, (l-2)*r+1:(l-1)*r] = Matrix(I, r, r)
    end
    Φ[r*p+1:end, 1:r] = C
    Φ[r*p+1:end, r*p+1:end] = D

    Ωbig = zeros(n, n)
    idx = vcat(1:r, r*p+1:n)                    # rows receiving innovations
    Ωbig[idx, idx] = Ω
    return Φ, Ωbig
end

"""
    stationary_cov(Φ, Ωbig; iters=2000, tol=1e-12)

Unconditional state covariance from the Lyapunov fixed point P = Φ P Φ' + Ω.
"""
function stationary_cov(Φ, Ωbig; iters=2000, tol=1e-12)
    P = copy(Ωbig)
    for _ in 1:iters
        Pn = Φ * P * Φ' + Ωbig
        if maximum(abs.(Pn .- P)) < tol
            return Pn
        end
        P = Pn
    end
    @warn "stationary_cov: fixed point not converged to tol; returning last iterate."
    return P
end

"""
    plot_interpolation_share(sigma_smoothed, P∞; states=1:8, dates=nothing,
                             state_labels=nothing, outfile=nothing, kwargs...)

The honest 'where does the model interpolate?' object: posterior variance of
each state relative to its unconditional variance, sigma_t[k,k]/P∞[k,k] —
1 = purely model-carried, →0 = pinned by data. Heatmap over states × time.
`sigma_smoothed` is the vector of smoothed covariance matrices (one per t).
"""
function plot_interpolation_share(sigma_smoothed, P∞; states=1:8, dates=nothing,
                                  state_labels=nothing, outfile=nothing, kwargs...)
    T = length(sigma_smoothed)
    M = zeros(length(states), T)
    for (i, k) in enumerate(states), t in 1:T
        M[i, t] = clamp(sigma_smoothed[t][k, k] / max(P∞[k, k], 1e-12), 0, 1)
    end
    x = _numeric_dates(dates, T)
    ylabs = state_labels === nothing ? [latexstring("f_{$k}") for k in states] : state_labels

    # main heatmap without GR's colorbar (its tick labels cannot be latexified)
    main = Plots.heatmap(x, ylabs, M;
                         c=Plots.cgrad([:white, "#3a3935"]), clims=(0, 1),
                         colorbar=false, xformatter=:latex,
                         guidefontsize=22, xtickfontsize=20, ytickfontsize=20,
                         framestyle=:box,
                         bottom_margin=6Plots.mm, left_margin=8Plots.mm, kwargs...)

    # manual colorbar: thin gradient heatmap whose y-axis carries LaTeX labels
    yy = collect(0.0:0.004:1.0)
    cb = Plots.heatmap([0.0], yy, reshape(yy, :, 1);
                       c=Plots.cgrad([:white, "#3a3935"]), clims=(0, 1),
                       colorbar=false, legend=false, xticks=false, ymirror=true,
                       yticks=(collect(0.0:0.2:1.0),
                               [latexstring(string(v)) for v in 0.0:0.2:1.0]),
                       ylabel=L"\sigma^2_{t\mid T}\,/\,P^{\infty}",
                       guidefontsize=20, ytickfontsize=16, framestyle=:box,
                       left_margin=-2Plots.mm, right_margin=12Plots.mm,
                       bottom_margin=6Plots.mm)

    plt = Plots.plot(main, cb; layout=Plots.grid(1, 2, widths=[0.95, 0.05]),
                     size=(1500, 160 + 48 * length(states)))
    outfile !== nothing && Plots.savefig(plt, outfile)
    return plt
end

"""
    plot_all_factors(dec; r, dates=nothing, outdir=".", prefix="ow")

Per-factor shares and contributions figures for factors 1:r + long CSV.
"""
function plot_all_factors(dec; r, dates=nothing, outdir=".", prefix="ow")
    mkpath(outdir)
    for k in 1:r
        plot_information_shares(dec; state=k, dates=dates,
            outfile=joinpath(outdir, "$(prefix)_shares_f$(k).pdf"))
        plot_source_contributions(dec; state=k, dates=dates,
            outfile=joinpath(outdir, "$(prefix)_contrib_f$(k).pdf"))
    end
    export_decomposition_csv(dec, joinpath(outdir, "$(prefix)_decomposition.csv");
                             dates=dates)
    return outdir
end

"""
    export_decomposition_csv(dec, path; dates=nothing)

Long-format CSV (state, t, date, source, contribution).
"""
function export_decomposition_csv(dec, path; dates=nothing)
    srcs = vcat(_ordered_sources(dec.contributions), ["state dynamics", "full"])
    T = size(dec.full, 2); S = size(dec.full, 1)
    open(path, "w") do io
        println(io, "state,t,date,source,contribution")
        for k in 1:S, t in 1:T
            d = dates === nothing ? "" : string(dates[t])
            for s in srcs
                v = s == "state dynamics" ? dec.prior[k, t] :
                    s == "full"           ? dec.full[k, t]  :
                                            dec.contributions[s][k, t]
                println(io, "$k,$t,$d,$s,$v")
            end
        end
    end
    return path
end
