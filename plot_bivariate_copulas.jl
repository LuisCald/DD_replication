# Plot bivariate copula densities (consumption-income, consumption-wealth, income-wealth)
#
# Input: a CSV like `PSID_functional_data_*.csv` containing copula coefficients columns named `ciw_*`.
# Output: PNGs that show the time evolution of each bivariate copula density around the Great Recession.
#
# Notes
# - This script assumes your copula is over (c,i,w) in that order, consistent with `ciw`.
# - It reconstructs the *3D* copula density per date and then integrates out one dimension
#   to get each bivariate density.
# - It uses the existing reconstruction machinery in `ReconstructionOLD.jl`.

cd(@__DIR__)

using Pkg
Pkg.activate("env_dd_v19/"; io=devnull)

using CSV
using DataFrames
using Dates
using Statistics
using LinearAlgebra

include("ReconstructionOLD.jl")

# -------------------------
# Small helpers
# -------------------------

"""Parse column name like `ciw_123` into (a,b,c) digit indices."""
function parse_ciw_triplet(col::AbstractString)
    m = match(r"^ciw_(\d+)$", col)
    m === nothing && return nothing
    s = m.captures[1]
    length(s) == 3 || return nothing
    a = parse(Int, s[1])
    b = parse(Int, s[2])
    c = parse(Int, s[3])
    return (a, b, c)
end

"""Build a dense tensor of copula coefficients from a DataFrame.

Returns a NamedTuple:
- coefs :: Array{Float64,4} with size (g,g,g,T)
- dates :: Vector{Date}

The tensor is filled with NaN when a coefficient is missing.
"""
function build_ciw_tensor(df::DataFrame; date_col::Symbol=:date)
    # Detect date column
    hasproperty(df, date_col) || error("Expected a date column named `$(date_col)`.")

    dates = Date.(df[!, date_col])
    T = nrow(df)

    # Collect ciw columns and parse indices
    ciw_cols = [String(nm) for nm in names(df) if occursin("ciw_", String(nm))]
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
    X = fill(NaN, g, g, g, T)

    for (c, (a, b, d)) in triples
        # Julia is 1-indexed; the digits are assumed 1..g already (decile regions)
        X[a, b, d, :] .= Float64.(df[!, Symbol(c)])
    end

    return (coefs=X, dates=dates, g=g)
end

"""Reconstruct 3D copula density path from ciw coefficient tensor."""
function reconstruct_ciw_densities(cop_coef::Array{Float64,4}; grid_size::Int=12)
    measures = ["consumption", "income", "wealth"]

    # Precompute integrals once
    x = select_grid_points(grid_size)
    x[end] = x[end] - 1e-6
    N = size(cop_coef, 1) - 1
    g_int = precompute_integrals(N, x)

    dens = generate_copula_densities(cop_coef, measures, grid_size; given_integrals=g_int)
    # dens has size (grid_size,grid_size,grid_size,T)
    return dens
end

"""Integrate out one dimension to get a bivariate density."""
function bivariate_from_3d(dens3::Array{Float64,4}, which::Symbol)
    # dens3: (gc,gc,gw,T) with axes (c,i,w)
    if which == :ci
        # integrate out wealth (3)
        A = dropdims(sum(dens3; dims=3), dims=3) # (c,i,T)
    elseif which == :cw
        # integrate out income (2)
        A = dropdims(sum(dens3; dims=2), dims=2) # (c,w,T)
    elseif which == :iw
        # integrate out consumption (1)
        A = dropdims(sum(dens3; dims=1), dims=1) # (i,w,T)
    else
        error("which must be :ci, :cw, or :iw")
    end
    return A
end

"""Pick a window around the Great Recession for plots.

Defaults to 2006-01 through 2012-12 (adjust as you like).
"""
function recession_window(dates::Vector{Date}; start=Date(2006, 1, 1), stop=Date(2012, 12, 31))
    idx = findall(d -> start <= d <= stop, dates)
    isempty(idx) && error("No dates in requested window ($start to $stop).")
    return idx
end

# -------------------------
# Main entry
# -------------------------

function main(; csv_path::AbstractString,
    date_col::Symbol=:date,
    grid_size::Int=12,
    outdir::AbstractString="7_Results/copula_plots",
    window_start::Date=Date(2006, 1, 1),
    window_stop::Date=Date(2012, 12, 31))

    df = CSV.read(csv_path, DataFrame)

    # Ensure date
    if !(eltype(df[!, date_col]) <: Date)
        try
            df[!, date_col] = Date.(df[!, date_col])
        catch
            # common formats: YYYY-MM, YYYY-MM-DD, etc.
            df[!, date_col] = Date.(string.(df[!, date_col]))
        end
    end

    tens = build_ciw_tensor(df; date_col=date_col)
    dens3 = reconstruct_ciw_densities(tens.coefs; grid_size=grid_size)

    ci = bivariate_from_3d(dens3, :ci)
    cw = bivariate_from_3d(dens3, :cw)
    iw = bivariate_from_3d(dens3, :iw)

    # Return a vector of matrices per copula, restricted to the window
    win = recession_window(tens.dates; start=window_start, stop=window_stop)

    copulas = Dict(
        :ci => [ci[:, :, t] for t in win],
        :cw => [cw[:, :, t] for t in win],
        :iw => [iw[:, :, t] for t in win],
    )

    mkpath(joinpath("..", outdir))

    # Plotting
    # We’re intentionally light-weight: heatmaps for a few dates + a simple animation.
    # (If Plots isn’t in the env, we’ll error with a clear message.)
    @eval begin
        using Plots
    end

    function plot_grid(mats; title_prefix::String, dates::Vector{Date}, fname::String)
        nt = length(mats)
        # pick a few evenly spaced dates to show snapshots
        picks = unique(round.(Int, range(1, nt, length=9)))
        p = plot(layout=(3, 3), size=(900, 900), margin=5Plots.mm)
        for (k, ix) in enumerate(picks)
            heatmap!(p[k], mats[ix], title="$(title_prefix)\n$(dates[ix])", colorbar=false, aspect_ratio=1)
        end
        plot!(p)
        savefig(p, fname)
        return nothing
    end

    function plot_surface_grid(mats; title_prefix::String, dates::Vector{Date}, fname::String)
        nt = length(mats)
        picks = unique(round.(Int, range(1, nt, length=9)))
        p = plot(layout=(3, 3), size=(900, 900), margin=5Plots.mm)
        for (k, ix) in enumerate(picks)
            surface!(p[k], mats[ix], title="$(title_prefix)\n$(dates[ix])", colorbar=false)
        end
        plot!(p)
        savefig(p, fname)
        return nothing
    end

    win_dates = tens.dates[win]
    base = joinpath("..", outdir)

    plot_grid(copulas[:ci]; title_prefix="Copula density: cons × income", dates=win_dates,
        fname=joinpath(base, "copula_ci_snapshots.png"))
    plot_grid(copulas[:cw]; title_prefix="Copula density: cons × wealth", dates=win_dates,
        fname=joinpath(base, "copula_cw_snapshots.png"))
    plot_grid(copulas[:iw]; title_prefix="Copula density: income × wealth", dates=win_dates,
        fname=joinpath(base, "copula_iw_snapshots.png"))

    plot_surface_grid(copulas[:ci]; title_prefix="Copula surface: cons × income", dates=win_dates,
        fname=joinpath(base, "copula_ci_surface_snapshots.png"))
    plot_surface_grid(copulas[:cw]; title_prefix="Copula surface: cons × wealth", dates=win_dates,
        fname=joinpath(base, "copula_cw_surface_snapshots.png"))
    plot_surface_grid(copulas[:iw]; title_prefix="Copula surface: income × wealth", dates=win_dates,
        fname=joinpath(base, "copula_iw_surface_snapshots.png"))

    # Simple GIF animations
    anim_ci = @animate for (m, d) in zip(copulas[:ci], win_dates)
        heatmap(m, title="cons × income — $(d)", clim=(0, maximum(m)), colorbar=true, aspect_ratio=1)
    end
    gif(anim_ci, joinpath(base, "copula_ci.gif"), fps=6)

    anim_cw = @animate for (m, d) in zip(copulas[:cw], win_dates)
        heatmap(m, title="cons × wealth — $(d)", clim=(0, maximum(m)), colorbar=true, aspect_ratio=1)
    end
    gif(anim_cw, joinpath(base, "copula_cw.gif"), fps=6)

    anim_iw = @animate for (m, d) in zip(copulas[:iw], win_dates)
        heatmap(m, title="income × wealth — $(d)", clim=(0, maximum(m)), colorbar=true, aspect_ratio=1)
    end
    gif(anim_iw, joinpath(base, "copula_iw.gif"), fps=6)

    # Surface GIF animations
    anim_ci_s = @animate for (m, d) in zip(copulas[:ci], win_dates)
        surface(m, title="cons × income — $(d)", colorbar=true)
    end
    gif(anim_ci_s, joinpath(base, "copula_ci_surface.gif"), fps=6)

    anim_cw_s = @animate for (m, d) in zip(copulas[:cw], win_dates)
        surface(m, title="cons × wealth — $(d)", colorbar=true)
    end
    gif(anim_cw_s, joinpath(base, "copula_cw_surface.gif"), fps=6)

    anim_iw_s = @animate for (m, d) in zip(copulas[:iw], win_dates)
        surface(m, title="income × wealth — $(d)", colorbar=true)
    end
    gif(anim_iw_s, joinpath(base, "copula_iw_surface.gif"), fps=6)

    return copulas, win_dates
end

# If run as a script, change path/date_col below as needed.
if abspath(PROGRAM_FILE) == @__FILE__
    csv_path = "../2_Data_processing/PSID_functional_data_A non-diag_.csv"
    copulas, dates = main(csv_path=csv_path, date_col=:date)
    @info "Done" n_dates = length(dates)
end
