cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
using Pkg
Pkg.activate("env_dd_v19/")
using CSV
using DataFrames
psid = CSV.read("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/PSID_functional_data_A non-diag_.csv", DataFrame)

# Extract the copula columns 
df_cop_names = vcat(names(psid)[contains.(names(psid), "ciw")], ["time"])

# Given this, plot the BIVARIATE copula densities: consumption-income, consumption-wealth, income-wealth
#
# IMPORTANT: per your clarification, the `ciw_###` columns are already *copula masses*
# (cell probabilities on a 3D decile grid), not coefficients.
#
# So we do NOT reconstruct densities. We instead:
#  1) rebuild the 3D mass tensor M[c,i,w,t] directly from the CSV
#  2) get bivariate masses by summing out the third dimension
#  3) store them as vectors of matrices (one matrix per date)
#  4) plot their evolution around the Great Recession

using Dates
using Statistics
using LaTeXStrings

"""Parse a name like `ciw_123` into (c,i,w) indices."""
function parse_ciw_triplet(col::AbstractString)
    # Some files have a trailing ".0" in the column name (e.g. `ciw_123.0`).
    m = match(r"^ciw_(\d+)(?:\.0)?$", col)
    m === nothing && return nothing
    s = m.captures[1]
    length(s) == 3 || return nothing
    return (parse(Int, s[1]), parse(Int, s[2]), parse(Int, s[3]))
end

"""Pick a date column from the DataFrame (tries a few common names)."""
function detect_date_col(df::DataFrame)
    for c in (:time, :date, :Date, :DATE, :month, :Month, :ym, :YM)
        if hasproperty(df, c)
            return c
        end
    end
    error("Could not find a date column. Add one (e.g. `date`) or edit `detect_date_col`. Columns: $(names(df))")
end

"""Convert a vector column to Dates (handles Date already, strings, and numbers)."""
function as_dates(v)
    if eltype(v) <: Date
        return collect(v)
    end
    # try parsing strings directly
    try
        return Date.(string.(v))
    catch
    end
    error("Could not convert date column to Date. Provide ISO date strings like 2007-01-01 or edit `as_dates`. eltype=$(eltype(v))")
end

"""Build 3D mass tensor M[g,g,g,T] from `ciw_###` columns."""
function build_ciw_tensor(df::DataFrame, ciw_cols::Vector{String})
    triples = Dict{String,Tuple{Int,Int,Int}}()
    maxidx = 0
    for c in ciw_cols
        t = parse_ciw_triplet(c)
        t === nothing && continue
        triples[c] = t
        maxidx = max(maxidx, maximum(t))
    end
    maxidx > 0 || error("No columns matching pattern `ciw_###` found.")
    g = maxidx
    T = nrow(df)
    M = fill(NaN, g, g, g, T)
    for (c, (a, b, d)) in triples
        M[a, b, d, :] .= Float64.(df[!, Symbol(c)])
    end
    return M
end

"""Integrate out one dimension from M[c,i,w,t] to get a bivariate mass path."""
function bivariate_from_3d(M::Array{Float64,4}, which::Symbol)
    if which == :ci
        return dropdims(sum(M; dims=3), dims=3) # (c,i,T)
    elseif which == :cw
        return dropdims(sum(M; dims=2), dims=2) # (c,w,T)
    elseif which == :iw
        return dropdims(sum(M; dims=1), dims=1) # (i,w,T)
    else
        error("which must be :ci, :cw, or :iw")
    end
end

"""Return indices for a Great Recession window (defaults 2006-01 to 2012-12)."""
function recession_window(dates; start=Date(2006, 1, 1), stop=Date(2012, 12, 31))
    idx = findall(d -> start <= d <= stop, dates)
    isempty(idx) && error("No dates in requested window ($start to $stop).")
    return idx
end

# -------------------------
# Run
# -------------------------
using PeriodicalDates
date_col = detect_date_col(psid)
dates = QuarterlyDate.(psid[!, date_col])

ciw_cols = [String(nm) for nm in names(psid) if startswith(String(nm), "ciw_")]
M = build_ciw_tensor(psid, ciw_cols)

ci = bivariate_from_3d(M, :ci)
cw = bivariate_from_3d(M, :cw)
iw = bivariate_from_3d(M, :iw)

# Vector-of-matrices output you asked for
win = recession_window(dates)
dates_win = dates[win]

copula_mats = Dict(
    :ci => [ci[:, :, t] for t in win],
    :cw => [cw[:, :, t] for t in win],
    :iw => [iw[:, :, t] for t in win],
)

# -------------------------
# Plot snapshots + animations
# -------------------------

using Plots
using Measures

outdir = joinpath("..", "7_Results", "copula_plots")
mkpath(outdir)

function plot_snapshots(mats::Vector{<:AbstractMatrix}, dts, title_prefix::String, outpath::String)
    nt = length(mats)
    picks = unique(round.(Int, range(1, nt, length=min(9, nt))))
    p = plot(layout=(3, 3), size=(900, 900), margin=5Plots.mm)
    for (k, ix) in enumerate(picks)
        heatmap!(p[k], mats[ix], title="$(title_prefix)\n$(dts[ix])", colorbar=false, aspect_ratio=1)
    end
    savefig(p, outpath)
    return nothing
end

function animate_copula(mats::Vector{<:AbstractMatrix}, dts, title_prefix::String, outpath::String; fps::Int=6)
    anim = @animate for (m, d) in zip(mats, dts)
        heatmap(m, title="$(title_prefix) — $(d)", colorbar=true, aspect_ratio=1)
    end
    gif(anim, outpath, fps=fps)
    return nothing
end



function plot_surface_snapshots(mats::Vector{<:AbstractMatrix}, meas_pair, dts,
    title_prefix::String, outpath::String)

    zlabel = meas_pair == :ci ? L"dC(C, Y)" :
             meas_pair == :cw ? L"dC(C, W)" :
             meas_pair == :iw ? L"dC(Y, W)" : ""

    nt = length(mats)
    picks = unique(round.(Int, range(1, nt, length=min(9, nt))))

    p = plot(layout=(3, 3), size=(1200, 1200), margin=5Plots.mm)

    parent_n = 9  # 3x3

    for (k, ix) in enumerate(picks)
        # --- main surface in subplot k ---
        surface!(p,
            1:size(mats[ix], 1),
            1:size(mats[ix], 2),
            mats[ix];
            subplot=k,
            title=L"%$(dts[ix])",
            xlabel=L"\textrm{Decile}",
            ylabel=L"\textrm{Decile}",
            zlabel=zlabel,
            xformatter=:latex,
            yformatter=:latex,
            zformatter=:latex,
            dpi=300,
            camera=(30, 10),
            color=:winter,
            colorbar=false,
            legend=false,
            display_option=Plots.GR.OPTION_SHADED_MESH,
        )

        # --- inset heatmap as a NEW subplot (index parent_n + k),
        #     placed inside parent subplot k ---
        heatmap!(p,
            1:size(mats[ix], 1),
            1:size(mats[ix], 2),
            mats[ix];
            subplot=parent_n + k,
            inset=(k, bbox(0.04, 0.04, 0.34, 0.34, :top, :right)),  # tweak numbers
            aspect_ratio=1,
            framestyle=:box,
            ticks=nothing,
            xlabel="",
            ylabel="",
            # color=:winter,
            colorbar=false,
            legend=false,
            bg_inside=nothing,   # keeps inset clean
        )
    end

    savefig(p, outpath)
    return nothing
end



# # Surface versions (3D)
# function plot_surface_snapshots(mats::Vector{<:AbstractMatrix}, meas_pair, dts, title_prefix::String, outpath::String)
#     local zlabel
#     if meas_pair == :ci
#         zlabel = L"dC(C, Y)"
#     elseif meas_pair == :cw
#         zlabel = L"dC(C, W)"
#     elseif meas_pair == :iw
#         zlabel = L"dC(Y, W)"
#     end

#     nt = length(mats)
#     picks = unique(round.(Int, range(1, nt, length=min(9, nt))))
#     p = plot(layout=(3, 3), size=(1200, 1200), margin=5Plots.mm)
#     for (k, ix) in enumerate(picks)
#         # Main surface
#         surface!(p[k],
#             1:size(mats[ix], 1),
#             1:size(mats[ix], 2),
#             mats[ix],
#             title=L"%$(dts[ix])",
#             xlabel=L"\textrm{Decile}",
#             ylabel=L"\textrm{Decile}",
#             zlabel=zlabel,
#             xformatter=:latex,
#             yformatter=:latex,
#             zformatter=:latex,
#             legend=false,
#             xtickfontsize=10,
#             ytickfontsize=10,
#             legendfontsize=10,
#             guidefontsize=10,
#             camera=(30, 10),
#             color=:winter,
#             size=(1200, 1200),
#             display_option=Plots.GR.OPTION_SHADED_MESH,
#             colorbar=false)

#         # Inset heatmap (top-right)
#         # GR/Plots expects an AbsoluteBox (uses Measures units like mm) here.
#         # (Passing an origin like :topleft triggers warnings and then a resolve() MethodError.)
#         inset_bb = Measures.AbsoluteBox(80mm, 80mm, 140mm, 140mm)
#         p_in = heatmap(
#             1:size(mats[ix], 1),
#             1:size(mats[ix], 2),
#             mats[ix],
#             xformatter=:latex,
#             yformatter=:latex,
#             legend=false,
#             color=:winter,
#             colorbar=false,
#             xtickfontsize=6,
#             ytickfontsize=6,
#             guidefontsize=6,
#             xlabel="",
#             ylabel="",
#             framestyle=:box,
#             aspect_ratio=1
#         )
#         plot!(p[k], inset_subplots=[(inset_bb, p_in)])
#     end
#     savefig(p, outpath)
#     return nothing
# end

function animate_surface(mats::Vector{<:AbstractMatrix}, dts, title_prefix::String, outpath::String;
    fps::Int=1,
    xlabel=L"\\textrm{Decile}",
    ylabel=L"\\textrm{Decile}",
    zlabel=L"dC(\\cdot,\\cdot)"
)
    anim = @animate for (m, d) in zip(mats, dts)
        surface(
            1:size(m, 1),
            1:size(m, 2),
            m,
            title=L"%$(d)",
            xlabel=xlabel,
            ylabel=ylabel,
            zlabel=zlabel,
            xformatter=:latex,
            yformatter=:latex,
            zformatter=:latex,
            legend=false,
            dpi=300,
            xtickfontsize=10,
            ytickfontsize=10,
            legendfontsize=10,
            guidefontsize=10,
            camera=(30, 10),
            color=:winter,
            size=(400, 400),
            display_option=Plots.GR.OPTION_SHADED_MESH
        )
    end
    gif(anim, outpath, fps=fps)
    return nothing
end

# plot_snapshots(copula_mats[:ci], dates_win, "Copula density: consumption × income", joinpath(outdir, "copula_ci_snapshots.png"))
# plot_snapshots(copula_mats[:cw], dates_win, "Copula density: consumption × wealth", joinpath(outdir, "copula_cw_snapshots.png"))
# plot_snapshots(copula_mats[:iw], dates_win, "Copula density: income × wealth", joinpath(outdir, "copula_iw_snapshots.png"))

animate_copula(copula_mats[:ci], dates_win, "consumption × income", joinpath(outdir, "copula_ci.gif"))
animate_copula(copula_mats[:cw], dates_win, "consumption × wealth", joinpath(outdir, "copula_cw.gif"))
animate_copula(copula_mats[:iw], dates_win, "income × wealth", joinpath(outdir, "copula_iw.gif"))

# Surface plots + animations
plot_surface_snapshots(copula_mats[:ci], :ci, dates_win, "", joinpath(outdir, "copula_ci_surface_snapshots.png"))
plot_surface_snapshots(copula_mats[:cw], :cw, dates_win, "", joinpath(outdir, "copula_cw_surface_snapshots.png"))
plot_surface_snapshots(copula_mats[:iw], :iw, dates_win, "", joinpath(outdir, "copula_iw_surface_snapshots.png"))


animate_surface(copula_mats[:ci], dates_win, "", joinpath(outdir, "copula_ci_surface.gif");
    xlabel=L"\textrm{Consumption}", ylabel=L"\textrm{Income}", zlabel=L"dC(C, Y)")
animate_surface(copula_mats[:cw], dates_win, "", joinpath(outdir, "copula_cw_surface.gif");
    xlabel=L"\textrm{Consumption}", ylabel=L"\textrm{Wealth}", zlabel=L"dC(C, W)")
animate_surface(copula_mats[:iw], dates_win, "", joinpath(outdir, "copula_iw_surface.gif");
    xlabel=L"\textrm{Income}", ylabel=L"\textrm{Wealth}", zlabel=L"dC(Y, W)")

# Generate new set of plots but around covid
win_covid = recession_window(dates; start=Date(2019, 1, 1), stop=Date(2022, 12, 31))
dates_covid = dates[win_covid]
copula_mats_covid = Dict(
    :ci => [ci[:, :, t] for t in win_covid],
    :cw => [cw[:, :, t] for t in win_covid],
    :iw => [iw[:, :, t] for t in win_covid],
)
plot_surface_snapshots(copula_mats_covid[:ci], :ci, dates_covid, "", joinpath(outdir, "copula_ci_surface_snapshots_covid.png"))
plot_surface_snapshots(copula_mats_covid[:cw], :cw, dates_covid, "", joinpath(outdir, "copula_cw_surface_snapshots_covid.png"))
plot_surface_snapshots(copula_mats_covid[:iw], :iw, dates_covid, "", joinpath(outdir, "copula_iw_surface_snapshots_covid.png"))
animate_surface(copula_mats_covid[:ci], dates_covid, "", joinpath(outdir, "copula_ci_surface_covid.gif");
    xlabel=L"\textrm{Consumption}", ylabel=L"\textrm{Income}", zlabel=L"dC(C, Y)")
animate_surface(copula_mats_covid[:cw], dates_covid, "", joinpath(outdir, "copula_cw_surface_covid.gif");
    xlabel=L"\textrm{Consumption}", ylabel=L"\textrm{Wealth}", zlabel=L"dC(C, W)")
animate_surface(copula_mats_covid[:iw], dates_covid, "", joinpath(outdir, "copula_iw_surface_covid.gif");
    xlabel=L"\textrm{Income}", ylabel=L"\textrm{Wealth}", zlabel=L"dC(Y, W)")