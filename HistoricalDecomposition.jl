########################
# Historical Decomposition for f_t (with per-shock option)
########################
"""
    build_selectors(r, q)

Same as before.
"""
function build_selectors(r::Int, q::Int)
    n = 4r + q
    J = zeros(eltype(1.0), r, n)
    id_mat = diagm(ones(eltype(1.0), r))
    J[:, 1:r] .= id_mat
    S_f = zeros(eltype(1.0), n, r)
    S_f[1:r, 1:r] .= id_mat
    S_y = zeros(eltype(1.0), n, q)
    id_mat = diagm(ones(eltype(1.0), q))
    S_y[4r+1:4r+q, 1:q] .= id_mat
    return J, S_f, S_y, n
end

"""
    smoothed_innovations(x_smooth, Φ; x0=nothing)

Same as before.
"""
function smoothed_innovations(x_smooth::AbstractMatrix, Φ::AbstractMatrix; x0=nothing)
    n, T = size(x_smooth)
    ε = zeros(eltype(x_smooth), n, T)
    if x0 === nothing
        @views ε[:, 1] .= 0
    else
        @views ε[:, 1] .= x_smooth[:, 1] - Φ * x0
    end
    @inbounds for t in 2:T
        @views ε[:, t] .= x_smooth[:, t] - Φ * x_smooth[:, t-1]
    end
    return ε
end

"""
    historical_decomp_factors(Φ; r, q, ε̂=nothing, x_smooth=nothing, x0=nothing,
                              splitting=:group,
                              factor_names=nothing, agg_names=nothing)

Historical contributions to f_t from:
- factor shocks (η_t ∈ ℝ^r),
- aggregate shocks (ζ_t ∈ ℝ^q),
- optional initial state x0.

Arguments:
- If `ε̂` is not provided, pass `x_smooth` and it will be computed.
- `splitting`:
    :group     -> returns grouped matrices (cf, cy, c0) as before,
                  and a 3D cube with shocks [:factors, :aggregate, :initial]
    :by_shock  -> returns a 3D cube separating each of the r+q shocks + initial
- `factor_names` and `agg_names` (Vectors of Symbols) are optional labels for shocks.

Returns NamedTuple:
  (cf, cy, c0, fhat, recon, maxerr, cube, order, ids)

- `cube` is r × T × S, where S is:
    S = 3          if splitting = :group
    S = r + q (+1) if splitting = :by_shock (the +1 is for :initial when x0 is provided)
- `order` :: Vector{Symbol} lists shock names in the 3rd dim order of `cube`
- `ids` is a NamedTuple mapping each factor name to its index (for plotting convenience)
"""
# HD = historical_decomp_factors(L; r, q, ε̂=εhat, x_smooth=xsm, x0=x0,
#     splitting=:by_shock,
#     factor_names=[:f1, :f2, :f3],   # optional
#     agg_names=[:y1, :y2])           # optional

function historical_decomp_factors(Φ, r, q, dε_smoothed, x_smoothed; splitting::Symbol=:group)

    J, S_f, S_y, n = build_selectors(r, q)
    T = size(dε_smoothed, 2)

    # Default names
    factor_names = Symbol.("f", 1:r)
    agg_names = Symbol.("y", 1:q)
    x0 = zeros(eltype(Φ), n)  # if no initial, just zeros

    # Running states for grouped pieces (your original outputs)
    zf = zeros(eltype(Φ), n)   # due to factor shocks (grouped)
    zy = zeros(eltype(Φ), n)   # due to aggregate shocks (grouped)
    z0 = zeros(eltype(Φ), n)

    cf = zeros(eltype(Φ), r, T)
    cy = zeros(eltype(Φ), r, T)
    c0 = zeros(eltype(Φ), r, T)
    fhat = (J * x_smoothed)

    # Optional per-shock tracking
    per_shock = splitting === :by_shock
    Zf = per_shock ? zeros(eltype(Φ), n, r) : nothing
    Zy = per_shock ? zeros(eltype(Φ), n, q) : nothing

    # Prepare cube
    if splitting === :group
        S = 2   # factors, aggregate
    elseif splitting === :by_shock
        S = r + q
    else
        error("splitting must be :group or :by_shock")
    end
    cube = zeros(eltype(Φ), r, T, S)

    # Order of shocks (for the cube's 3rd dimension)
    if splitting === :group
        order = [:factors, :aggregate]
    else
        order = vcat(factor_names, agg_names)
    end

    # Indices in cube for convenience
    idx_factors = splitting === :group ? 1 : (1:r)
    idx_aggregate = splitting === :group ? 2 : (r+1:r+q)

    @inbounds for t in 1:T
        # splitting reduced-form innovations
        ηt = S_f' * dε_smoothed[:, t]           # r
        ζt = S_y' * dε_smoothed[:, t]           # q

        # --- Grouped recursions (for cf, cy, c0)
        zf = Φ * zf + S_f * ηt
        zy = Φ * zy + S_y * ζt
        if x0 !== nothing
            z0 = Φ * z0
        end

        @views cf[:, t] .= J * zf
        @views cy[:, t] .= J * zy
        if x0 !== nothing
            @views c0[:, t] .= J * z0
        end

        # --- Per-shock recursions for cube
        if per_shock
            # propagate each column independently
            Zf = Φ * Zf + S_f * Diagonal(ηt)   # n×r
            Zy = Φ * Zy + S_y * Diagonal(ζt)   # n×q

            # write factor-shock slices
            for j in 1:r
                @views cube[:, t, j] .= J * view(Zf, :, j)
            end
            # write aggregate-shock slices
            for j in 1:q
                @views cube[:, t, r+j] .= J * view(Zy, :, j)
            end
        else
            # grouped: factors, aggregate, optional initial
            @views cube[:, t, 1] .= cf[:, t]
            @views cube[:, t, 2] .= cy[:, t]
        end
    end

    recon = c0 .+ cf .+ cy
    maxerr = maximum(abs.(recon .- fhat))

    # ids: map factor variable names to row indices for plotting
    ids = (; (factor_names[i] => i for i in 1:r)...)

    return (cf=cf, cy=cy, c0=c0, fhat=fhat, recon=recon, maxerr=maxerr,
        cube=cube, order=order, ids=ids)
end


function plot_hist_decomp(vars_to_plot, HDs_to_plot, order, ids, timeline)

    r, T, S = size(HDs_to_plot)

    # which shocks (3rd-dim slices) to include
    shocks_syms = order
    # Map symbols in shocks_syms to their positions in `order`
    pos = map(shocks_syms) do s
        i = findfirst(==(s), order)
        @assert i !== nothing "Shock $(s) not found in `order`"
        i
    end
    Ssel = length(pos)
    x_axis = collect(1:length(timeline))

    legend_labels = splitting == :group ? [L"\textrm{Distribution}" L"\textrm{Aggregates}"] : Matrix(String.(shocks_syms))
    for (k, (sym, title_str)) in enumerate(vars_to_plot)
        i = getproperty(ids, sym)  # row index for this factor

        # Gather contributions for each selected shock: Ssel × |timeline|
        # (we’ll transpose for bar(...) which expects series in columns)
        contrib = Array{eltype(cube)}(undef, Ssel, length(timeline))
        for (j, sidx) in enumerate(pos)
            @views contrib[j, :] = cube[i, 1:length(timeline), sidx]
        end

        # Stacked bars per time index
        p = groupedbar(x_axis, contrib'; bar_position=:stack, color=[:blue :orange], labels=legend_labels, xticks=(x_axis[1:20:end], [L"%$(date)"[1:5] * "\$" for (_, date) in enumerate(timeline[1:20:end])]), xformatter=:latex, yformatter=:latex, fontsize=14)
        # bar_width=0.5, 

        # Zero line for reference
        hline!(p, [zero(eltype(contrib))]; lw=0.5, alpha=0.6, label=false)

        # # Optional overlay of total (sum across selected shocks)
        # if overlay_total
        #     tot = vec(sum(contrib; dims=1))
        #     plot!(p, timeline, tot; lw=1.5, label="Total")
        # end

        Plots.savefig(p, "/home/luisc/Distributional_Dynamics/5_Code/historical_decomposition_$(sym).pdf")
    end
end

using DataFrames, Statistics, StatsBase, Dates

"""
    make_hd_tables(cube, order, ids, years, quarters;
                   factor_prefix="f", agg_prefix="y",
                   own_vs_other=true,
                   decade_bounds=nothing,
                   event_windows=nothing,
                   fallback_group_labels=Dict(:factors=>"Distribution", :aggregate=>"Aggregates"))

Build summary tables of historical-decomposition contributions by decade and by event windows.

Inputs
------
- cube::Array{<:Real,3}    # r × T × S (HD.cube)
- order::Vector{Symbol}    # names of S slices (HD.order)
- ids::NamedTuple          # target-factor name -> row index (HD.ids)
- years::Vector{Int}       # length T
- quarters::Vector{Int}    # length T, values in 1..4

Keywords
--------
- factor_prefix, agg_prefix :: String
    Used to detect per-shock names, e.g. :f1, :f2, … and :y1, :y2, …
- own_vs_other :: Bool
    If true and per-shock is available, “OtherFactors” excludes a factor’s own shock.
- decade_bounds :: Vector{Int} or nothing
    Year boundaries for decades. Default: 1960:10:2030 (auto from data if nothing)
- event_windows :: Dict{String,UnitRange{Int}} or nothing
    Dict of event name => inclusive integer range (in quarters) around the anchor.
    Defaults provided below, edit as you like.
- fallback_group_labels :: Dict
    Nice labels for grouped cubes (when split=:group)

Returns
-------
(table_by_decade::DataFrame, table_by_event::DataFrame)
"""
using DataFrames, Statistics

"""
    make_hd_tables(cube, order, ids, years, quarters;
                   factor_prefix="f", agg_prefix="y",
                   decade_bounds=nothing,
                   event_windows=nothing,
                   grouped_labels=Dict(:factors=>"Distribution", :aggregate=>"Aggregates"))

Build summary tables of historical-decomposition contributions by decade and by event windows,
splitting sources into OwnFactor, OtherFactors, and Aggregates (when per-shock data is available).

Inputs
------
- cube::Array{<:Real,3}     # r × T × S (HD.cube)
- order::Vector{Symbol}     # names for S slices (HD.order)
- ids::NamedTuple           # mapping factor names to row index (HD.ids)
- years::Vector{Int}        # length T
- quarters::Vector{Int}     # length T in 1..4

Keywords
--------
- factor_prefix, agg_prefix :: String   # detect per-shock names like :f1, :f2, … and :y1, :y2, …
- decade_bounds :: Vector{Int} or nothing
- event_windows :: Dict{String,UnitRange{Int}} or nothing
- grouped_labels :: Dict for pretty names if you only have grouped cube (no per-shock)

Returns
-------
(table_by_decade::DataFrame, table_by_event::DataFrame)
"""
NBER_RECESSIONS = [
    (Date(1969, 12), Date(1970, 11)),
    (Date(1973, 11), Date(1975, 3)),
    (Date(1981, 7), Date(1982, 11)),
    (Date(1990, 7), Date(1991, 3)),
    (Date(2001, 3), Date(2001, 11)),
    (Date(2007, 12), Date(2009, 6)),
    (Date(2020, 2), Date(2020, 4))
]

function quarter_to_date(year::Int, quarter::Int)
    month = 3 * quarter - 2   # Q1→Jan, Q2→Apr, ...
    return Date(year, month, 1)
end

function nber_event_masks(panel_dates)
    masks = Dict{String,Vector{Bool}}()
    for (peak, trough) in NBER_RECESSIONS
        label = "NBER Recession $(year(peak))Q$((month(peak)-1)÷3+1)–$(year(trough))Q$((month(trough)-1)÷3+1)"
        mask = (panel_dates .>= peak) .& (panel_dates .<= trough)
        masks[label] = mask
    end
    return masks
end


function make_hd_tables(cube, order, ids, years, quarters; make_recession_plots=false)
    # NBER recession periods (peak-to-trough) in YYYYQ format
    panel_dates = [quarter_to_date(y, q) for (y, q) in zip(years, quarters)]
    factor_prefix = "f"
    agg_prefix = "y"
    decade_bounds = nothing
    event_windows = nothing
    grouped_labels = Dict(:factors => "Distribution", :aggregate => "Aggregates")

    @assert ndims(cube) == 3 "cube must be r×T×S"
    r, T, S = size(cube)
    @assert length(years) == T && length(quarters) == T "years/quarters must match T"

    # Identify per-shock vs grouped
    is_factor_shock(s::Symbol) = startswith(String(s), factor_prefix)
    is_agg_shock(s::Symbol) = startswith(String(s), agg_prefix)

    factor_slices = findall(s -> is_factor_shock(s), order)
    agg_slices = findall(s -> is_agg_shock(s), order)
    idx_group_f = findfirst(==(Symbol(:factors)), order)
    idx_group_y = findfirst(==(Symbol(:aggregate)), order)

    has_pershock = !isempty(factor_slices) || !isempty(agg_slices)
    has_grouped = idx_group_f !== nothing || idx_group_y !== nothing

    # Reconstructed total series for each factor: sum across shocks (dim=3)
    cube = abs.(cube)   # work with absolute contributions
    recon = Array{eltype(cube)}(undef, r, T)
    @inbounds for i in 1:r
        @views recon[i, :] = sum(cube[i, :, :], dims=2)[:]   # (T,)
    end

    # Build decades (labels like "1990s")
    years_unique = sort(unique(years))
    y_min, y_max = minimum(years_unique), maximum(years_unique)
    if decade_bounds === nothing
        y0 = (y_min ÷ 10) * 10
        decade_bounds = collect(y0:10:(y_max+10))
    end
    decade_label = Vector{String}(undef, T)
    for t in 1:T
        y = years[t]
        b = findlast(b -> b <= y, decade_bounds)
        d0 = b === nothing ? (y ÷ 10) * 10 : decade_bounds[b]
        decade_label[t] = "$(d0)s"
    end

    # Event anchors — replicate your Stata distances
    dist2dotcom = (quarters .- 1) .+ (years .- 2001) .* 4   # 2001Q1
    dist2greatrecession = (quarters .- 4) .+ (years .- 2007) .* 4   # 2007Q4
    dist2covid = (quarters .- 4) .+ (years .- 2019) .* 4   # 2019Q4
    dist2gulf = (quarters .- 3) .+ (years .- 1990) .* 4   # 1990Q3
    dist2iran = (quarters .- 3) .+ (years .- 1981) .* 4   # 1981Q3
    dist2oil = (quarters .- 4) .+ (years .- 1973) .* 4   # 1973Q4
    dist2unemp = (quarters .- 4) .+ (years .- 1969) .* 4   # 1969Q4

    # default_events = Dict(
    #     "Dot-com (2001Q1)" => (-8:12),
    #     "Great Recession (2007Q4)" => (-8:12),
    #     "COVID (2019Q4)" => (-8:12),
    #     "Gulf War (1990Q3)" => (-8:12),
    #     "Iran crisis (1981Q3)" => (-8:12),
    #     "Oil embargo (1973Q4)" => (-8:12),
    #     "Unemployment peak (1969Q4)" => (-8:12),
    # )

    if event_windows !== nothing
        default_events = event_windows
    end

    event_dists = Dict(
        "Dotcom" => dist2dotcom, # (2001Q1)
        "Great Recession" => dist2greatrecession, # (2007Q4)
        "COVID" => dist2covid, # (2019Q4)
        "Gulf War" => dist2gulf, # (1990Q3)
        "Double-Dip" => dist2iran, # (1981Q3)
        "Oil Embargo" => dist2oil, # (1973Q4)
        "Unemployment Recession" => dist2unemp, # (1969Q4)
    )

    # Return three source series for target i over a mask: (own, other, aggs)
    function contrib_own_other_agg(i::Int, mask::AbstractVector{Bool})
        if has_pershock
            own_name = Symbol(factor_prefix * string(i))   # expects :f1, :f2, …
            own_idx = findfirst(==(own_name), order)

            @views fac_all = isempty(factor_slices) ? zeros(eltype(cube), sum(mask)) :
                             sum(cube[i, mask, factor_slices], dims=2)[:]
            @views aggs = isempty(agg_slices) ? zeros(eltype(cube), sum(mask)) :
                          sum(cube[i, mask, agg_slices], dims=2)[:]
            if own_idx === nothing
                # No own slice found -> all factors count as "OtherFactors", OwnFactor is zeros
                own = zeros(eltype(cube), sum(mask))
                other = fac_all
                return own, other, aggs
            else
                @views own = cube[i, mask, own_idx]
                other = fac_all .- own
                return own, other, aggs
            end
        elseif has_grouped
            # Only grouped available — cannot separate own vs other
            fac_lbl = idx_group_f === nothing ? "Distribution" : grouped_labels[:factors]
            agg_lbl = idx_group_y === nothing ? "Aggregates" : grouped_labels[:aggregate]
            @views fac = idx_group_f === nothing ? zeros(eltype(cube), sum(mask)) :
                         cube[i, mask, idx_group_f]
            @views agg = idx_group_y === nothing ? zeros(eltype(cube), sum(mask)) :
                         cube[i, mask, idx_group_y]
            # Emulate: OwnFactor=0, OtherFactors=fac, Aggregates=agg
            own = zeros(eltype(cube), sum(mask))
            return own, fac, agg
        else
            error("Cannot identify factor/aggregate slices in `order`.")
        end
    end

    # Summaries over a window
    # We report: SignedSum, MeanAbs, VarSharePct (variance share of recon over the window)
    function summarize_window(i::Int, mask::AbstractVector{Bool})
        own, other, aggs = contrib_own_other_agg(i, mask)
        @views total = recon[i, mask]
        total_var = sum(total)
        vs = x -> total_var ≈ 0 ? 0.0 : sum(abs.(x)) / total_var
        DataFrame(; Source=["OwnFactor", "OtherFactors", "Aggregates"],
            VarSharePct=[vs(own), vs(other), vs(aggs)])
    end

    # ---------- By DECADE ----------
    rows_dec = DataFrame(TargetFactor=String[], Decade=String[],
        Source=String[], VarSharePct=Float64[])
    for (sym, i) in pairs(ids)
        tf_name = String(sym)
        for dec in unique(decade_label)
            mask = (decade_label .== dec)
            if any(mask)
                summ = summarize_window(i, mask)
                summ.TargetFactor .= tf_name
                summ.Decade .= dec
                append!(rows_dec, summ)
            end
        end
    end
    sort!(rows_dec, [:TargetFactor, :Decade, :Source])

    # ---------- By EVENT WINDOWS ----------
    # rows_evt = DataFrame(TargetFactor=String[], Event=String[], Window=String[],
    #     Source=String[], VarSharePct=Float64[])
    # for (event_name, win) in default_events
    #     dist = event_dists[event_name]
    #     winvec = collect(win)
    #     for (sym, i) in pairs(ids)
    #         tf_name = String(sym)
    #         mask = in.(dist, Ref(winvec))
    #         if any(mask)
    #             summ = summarize_window(i, mask)
    #             summ.TargetFactor .= tf_name
    #             summ.Event .= event_name
    #             summ.Window .= string(first(win), ":", last(win), " qtrs")
    #             append!(rows_evt, summ)
    #         end
    #     end
    # end

    # using Dates, DataFrames, Plots

    # ---- Build NBER labels + masks once (ensures consistent strings everywhere) ----
    fmtq(y, m) = "$(y)Q$(((m-1) ÷ 3) + 1)"
    make_label(peak::Date, trough::Date) = "NBER Recession $(fmtq(year(peak), month(peak)))–$(fmtq(year(trough), month(trough)))"

    quarter_start(y::Int, q::Int) = Date(y, 3q - 2, 1)
    panel_dates = [quarter_start(y, q) for (y, q) in zip(years, quarters)]

    rec_labels = String[]
    rec_masks = Vector{Bool}[]
    for (peak, trough) in NBER_RECESSIONS
        push!(rec_labels, make_label(peak, trough))
        push!(rec_masks, (panel_dates .>= peak) .& (panel_dates .<= trough))
    end
    order_map = Dict(rec_labels[i] => i for i in eachindex(rec_labels))  # label -> position

    # ---- Build rows_nber using the same labels ----
    rows_nber = DataFrame(TargetFactor=String[], Recession=String[],
        Source=String[], VarSharePct=Float64[])

    for (lab, mask) in zip(rec_labels, rec_masks)
        for (sym, i) in pairs(ids)
            if any(mask)
                summ = summarize_window(i, mask)             # <- your existing function (Distribution/Aggregates)
                summ.TargetFactor .= String(sym)
                summ.Recession .= lab
                append!(rows_nber, summ)
            end
        end
    end

    # Sort rows_nber by TargetFactor, then desired recession order, then Source
    perm = sortperm([(String(rows_nber.TargetFactor[k]),
        get(order_map, rows_nber.Recession[k], typemax(Int)),
        String(rows_nber.Source[k])) for k in 1:nrow(rows_nber)])
    rows_nber = rows_nber[perm, :]

    # ---- Optional plotting (side-by-side triplets per recession for each factor) ----
    plots_dict = Dict()
    if make_recession_plots
        colname = :VarSharePct   # or :SignedSum / :MeanAbs

        i = 1
        for (sym, _) in pairs(ids)
            tf = String(sym)
            df = rows_nber[rows_nber.TargetFactor.==tf, [:Recession, :Source, colname]]

            # Ensure rows in your desired recession order (no Categoricals needed)
            ord = sortperm([get(order_map, s, typemax(Int)) for s in df.Recession])
            df = df[ord, :]

            # Wide form: columns "Distribution" and "Aggregates"; align by Recession
            wide = unstack(df, :Recession, :Source, colname)   # has :Recession plus value cols
            # Keep only recessions present (in rec_labels order)
            ord_w = sortperm([get(order_map, s, typemax(Int)) for s in wide.Recession])
            wide = wide[ord_w, :]

            # Pull aligned series (coalesce missing to 0)
            own_fact = hasproperty(wide, :OwnFactor) ? coalesce.(wide.OwnFactor, 0.0) : fill(0.0, nrow(wide))
            other_fact = hasproperty(wide, :OtherFactors) ? coalesce.(wide.OtherFactors, 0.0) : fill(0.0, nrow(wide))
            distr = own_fact .+ other_fact
            aggs = hasproperty(wide, :Aggregates) ? coalesce.(wide.Aggregates, 0.0) : fill(0.0, nrow(wide))
            total = distr .+ aggs

            # cats = Vector{String}(wide.Recession)   # already ordered as desired
            cats = [L"\textrm{1969\,\, Recession}",
                L"\textrm{Oil\,\, Embargo}",
                L"\textrm{Double-Dip}",
                L"\textrm{Gulf\,\, War}",
                L"\textrm{Dotcom}",
                L"\textrm{Financial\,\, Crises}",
                L"\textrm{COVID}"]
            X = hcat(distr, aggs)

            color_for_plot = [palette(:davos10)[1] :orange]

            # Post-2000s
            # Distribution is blue
            # Pre-2000s
            p1 = groupedbar(cats[1:4], X[1:4, :];
                bar_position=:dodge, bar_width=0.8,
                label=[L"\textrm{Distribution}" L"\textrm{Aggregates}"],
                ylabel=L"\textrm{Variance\,\, share\, (\%)}",
                xformatter=:latex,
                yformatter=:latex,
                legend=false,
                color=color_for_plot,
                xtickfontsize=13,
                ytickfontsize=13,
                guidefontsize=13,
                # hatch=["" "//"],
                dpi=500,
                xrotation=15,
            )

            # Post-2000s
            p2 = groupedbar(cats[5:end], X[5:end, :];
                bar_position=:dodge, bar_width=0.8,
                label=[L"\textrm{Distribution}" L"\textrm{Aggregates}"],
                legend=false,
                ylabel=L"\textrm{Variance\,\, share\, (\%)}",
                xformatter=:latex,
                yformatter=:latex,
                color=color_for_plot,
                xtickfontsize=13,
                ytickfontsize=13,
                guidefontsize=13,
                # hatch=["" "//"],
                # xticks=(6:8, collect(keys(event_dists))[6:8]),
                dpi=500,
            )

            Plots.savefig(p1, "hd_recessions_$(tf)_pre2000s.pdf")
            Plots.savefig(p2, "hd_recessions_$(tf).pdf")
            i += 1
        end
    end

    return rows_dec, rows_nber
end



# Example
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

using Plots, StatsPlots
smoother_res, logV, alarm = likeli(model_elements, par_final, param_sizes, priors, meas_ind, Σ_ids, model_options; smooth=true)
@unpack x_smoothed, x_filtered, dε_smoothed = smoother_res               # F̂_t   (nF × T)
HD = historical_decomp_factors(Φ, r, q, dε_smoothed, x_smoothed, splitting=:by_shock)
timeline = QuarterlyDate(user_t[1]["year"], user_t[1]["quarter"]):Quarter(1):QuarterlyDate(user_t[2]["year"], user_t[2]["quarter"])

# suppose:
cube = HD.cube
order = HD.order
ids = HD.ids
T = length(timeline)

# vars_to_plot = [(:f1, "Factor 1"), (:f2, "Factor 2"), (:f3, "Factor 3"), (:f4, "Factor 4"), (:f5, "Factor 5"), (:f6, "Factor 6"), (:f7, "Factor 7"), (:f8, "Factor 8")]

# plt = plot_hist_decomp(vars_to_plot, cube, order, ids, timeline)


# Given your outputs:
years = year.(timeline)
quarters = quarter.(timeline)   # length T, values 1..4

table_by_decade, table_by_event = make_hd_tables(cube, order, ids, years, quarters; make_recession_plots=true)

