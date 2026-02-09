# Robust symmetric "square root" for a (near) PSD matrix
function sym_psd(Σ::AbstractMatrix{<:Real}; tol=1e-12)
    F = Symmetric(Σ)
    E = eigen(F)                     # Σ = V*Diagonal(λ)*V'
    λ = clamp.(E.values, 0.0, Inf)   # guard tiny negatives
    V = E.vectors
    return V * Diagonal(λ) * V'   # principal square root
end

"""
    fevd_dist_vs_agg(Φ, Ω; r, q, horizon=20, factor_names=nothing)

Compute FEVD shares (in %) for each of the r "distributional" factors:
two columns: Distributional vs Aggregates, at horizon `horizon`.

Assumes your companion ordering with 4 lags of factors (size 4r) and q aggregates:
ε_t has nonzero entries only in rows 1:r (current factors) and 4r+1:4r+q (aggregates).

Inputs
------
- Φ :: n×n  (state transition)
- Ω :: n×n  (innovation covariance)
- r, q :: Int
- horizon :: Int = 20
- factor_names :: Vector{String} (optional, length r)

Returns
-------
DataFrame with columns: :Factor, :Distributional, :Aggregates
"""
function fevd_dist_vs_agg(
    model_elements,
    model_options,
    obs_data,
    Φ_sub,
    Ω;
    r,
    q,
    horizon=20,
    factor_names=nothing,
    shock_order=:dist_first,
    data_tag="PSID"
)
    @unpack measures, case, equivalized, bottom_coded, estimator, tag = model_options
    @unpack grid_cop, grid_pcf, integral_pcf_grid, integral_cop_grid = estimator
    @unpack trend, Gⱼ, means, stds = model_elements
    @unpack df_vec = obs_data

    grid_data_size_cop = typeof(estimator) <: SeriesEstimator ? integral_cop_grid : grid_cop

    grid_data_size_pcf = typeof(estimator) <: SeriesEstimator ? integral_pcf_grid : grid_pcf

    n = size(Φ_sub, 1)
    @assert size(Φ_sub, 2) == n && size(Ω, 1) == n && size(Ω, 2) == n
    # @assert n == 4r + q "Expected state dimension n = 4r + q for the quarterly companion form."

    # Selector for IRFs
    J = zeros(eltype(Φ_sub), r, n) # distributional factors by all factors
    J[:, 1:r] .= diagm(ones(eltype(Φ_sub), r))          # pick current f_t from state

    # Selector for (S)hocks, though basically the identity in our setting
    S_f = zeros(eltype(Φ_sub), n, r)
    S_f[1:r, 1:r] .= diagm(ones(eltype(Φ_sub), r))      # factor shock locations

    S_y = zeros(eltype(Φ_sub), n, q)
    S_y[r+1:r+q, 1:q] .= diagm(ones(eltype(Φ_sub), q))  # aggregate shock locations

    # S = hcat(S_f, S_y)               # n × (r+q) --- in the general case, its basically the identity
    if shock_order === :dist_first
        println("--- FEVD: Distributional shocks ordered first ---")
        # Original ordering: [Distributional, Aggregates]
        S = hcat(S_f, S_y)
        dist_shock_indices = 1:r
        agg_shock_indices = (r+1):(r+q)
    elseif shock_order === :agg_first
        println("--- FEVD: Aggregate shocks ordered first ---")
        # New ordering: [Aggregates, Distributional]
        S = hcat(S_y, S_f) # Concatenate Y shocks first
        agg_shock_indices = 1:q         # Aggregate shocks are now first
        dist_shock_indices = (q+1):(q+r) # Distributional shocks are now second
    else
        error("Invalid shock_order. Must be :dist_first or :agg_first.")
    end

    B = get_structural_mat(Ω, S, r, q; type=:block_cholesky, shock_order=shock_order)

    # Check that B * B' matches Ω_sub
    # Ω_reconstructed = B * B'
    # println(Ω_reconstructed)
    # println(Symmetric(S' * Ω * S))
    # @assert isapprox(Ω_reconstructed, Symmetric(S' * Ω * S); atol=1e-6) "Reconstructed Ω does not match original Ω_sub."

    # FEVD accumulators
    num_dist = zeros(Float64, r)
    num_agg = zeros(Float64, r)
    denom = zeros(Float64, r)

    # Generate impulse responses and accumulate FEVD parts
    ψ = zeros(eltype(Φ_sub), r, r + q, horizon)  # n × (r+q)
    Φs = I(n)        # to store, within iteration, everything
    for s in 0:(horizon-1)
        ψ[:, :, s+1] = J * Φs * B                         # r × (r+q)
        @views begin
            num_dist .+= sum(abs2, ψ[:, dist_shock_indices, s+1]; dims=2)[:]
            num_agg .+= sum(abs2, ψ[:, agg_shock_indices, s+1]; dims=2)[:]
            denom .+= sum(abs2, ψ[:, :, s+1]; dims=2)[:]
        end
        Φs = Φs * Φ_sub
    end

    share_dist = 100 .* (num_dist ./ denom)
    share_agg = 100 .* (num_agg ./ denom)

    names = factor_names === nothing ? ["Factor $(i)" for i in 1:r] : factor_names
    @assert length(names) == r

    tbl = DataFrame(Factor=names, Variation_from_Distributional=share_dist,
        Variation_from_Aggregates=share_agg)

    lt = df_to_latex_fevd_factors(tbl)
    println(lt)

    #################################################
    # Map these contributions to the observable space
    #################################################
    D = length(measures)
    data_id = findfirst(==(data_tag), df_vec.df_names)  # hardcoded for now, but could be an input
    new_trend = select_trend(trend, "average") # for later

    Δobs = Vector{Matrix{Float64}}(undef, horizon)

    for h in axes(ψ, 3)
        Δobs[h] = (Gⱼ[data_id][:, 1:r] * ψ[:, :, h]) # n_coefs by r+q
    end
    # add_variance!(estimator, Δobs, stds, measures)
    # Δobs = [Δobs[h] .+ means[data_id] for h in 1:horizon]  # Add means

    # # Add linear-trend back
    # for h in 1:horizon
    #     # For copula, weights do not seem to be affected
    #     Δobs[h] .+= new_trend[data_id]
    # end

    # Add the immutable part
    for h in eachindex(Δobs)
        Δobs[h] = add_multidimensional_immutable(estimator, Δobs[h], grid_cop, measures)
    end

    # split into copula and pcfs
    split_Δobs = Vector(undef, horizon)
    for h in eachindex(Δobs)
        split_Δobs[h] = undo_functional_treatment(estimator, Δobs[h], measures)
    end

    # Generate container to store the data of choice 
    new_data_pcf = [zeros(integral_pcf_grid, r + q, horizon) for _ in 1:D] # obs x shocks x horizon, for each pcf
    grid_points_pcf = select_grid_points(grid_data_size_pcf)
    intervals = vcat([0.0] .+ 1e-6, grid_points_pcf)

    # We need to generate new data_pcf, which are the average quantiles over the intervals (e.g., deciles)
    for h in 1:horizon
        for s in 1:r+q
            # split the pcfs
            pcf_coefs = split_Δobs[h][2][:, s]  # second element is the pcfs
            split_pcfs = [pcf_coefs[I] for I in Iterators.partition(axes(pcf_coefs, 1), grid_pcf)]  # split by measure 
            for m in eachindex(split_pcfs)
                if all(isnan.(split_pcfs[m]))
                    new_data_pcf[m][:, s, h] .= NaN
                else
                    for i in 1:integral_pcf_grid
                        # Using coefs, generate pcf function and then integrate pcf function over diff. intervals
                        # integral, _ = quadgk(u -> reverse_inverse_hyperbolic_sine(eval_quantile_function(split_pcfs[m][:, h, s], grid_pcf - 1, u))[1] .* select_series[s, correction_names[m]], intervals[i], intervals[i+1], rtol=1e-8)
                        integral, _ = quadgk(u -> eval_quantile_function(split_pcfs[m], grid_pcf - 1, u)[1], intervals[i], intervals[i+1], rtol=1e-8)

                        # Undo treatment of data => gives us average quantile within the interval
                        new_data_pcf[m][i, s, h] = integral / (intervals[i+1] - intervals[i]) #reverse_inverse_hyperbolic_sine(integral)[1] .* select_series[t, correction_names[m]] #./ (intervals[i+1] - intervals[i])
                    end
                end
            end
        end
    end

    for m in eachindex(new_data_pcf)
        for s in 1:(r+q)
            # @show s, norm(new_data_pcf[m][:, s, :])
        end
    end


    # To store FEVD
    stats_dict = Dict()

    # For the copula: reconstruct copula densities and compute variance shares
    # NOTE: `generate_copula_densities` (defined elsewhere) expects an array whose *first* dimensions
    # correspond to copula coefficients and the last dimension is time/period. Here we treat each
    # shock-horizon pair as a separate "period".
    if typeof(estimator) <: SeriesEstimator
        # Split coefs: split_Δobs[h][1] are the copula coefficients.
        # In your code base these can be a tensor like 12×12×12×(r+q).
        cop_coefs_1 = split_Δobs[1][1]
        @assert ndims(cop_coefs_1) == D + 1 "Expected copula coefficients with dimensions (coef-grid)^D × (r+q)."
        @assert size(cop_coefs_1, D + 1) == (r + q) "Last dimension of copula coeffs must equal number of shocks (r+q)."

        gcoef = size(cop_coefs_1, 1)
        @assert all(size(cop_coefs_1, d) == gcoef for d in 1:D) "Copula coefficient grid must be square across dimensions."

        n_events = (r + q) * horizon
        coef_size = tuple([gcoef for _ in 1:D]...)
        cop_coef_events = Array{Float64}(undef, coef_size..., n_events)

        # Flatten (shock, horizon) into "event" index so we can reuse generate_copula_densities
        idx = 1
        for h in 1:horizon
            for s in 1:(r+q)
                @views cop_coef_events[ntuple(_ -> Colon(), D)..., idx] .= split_Δobs[h][1][ntuple(_ -> Colon(), D)..., s]
                idx += 1
            end
        end

        # Reconstruct copula densities on the desired grid
        # Grid points 
        x = select_grid_points(grid_data_size_cop)
        x[end] = x[end] - 1e-6  # to avoid numerical issues with the last point

        # Compute the integrals first
        N = size(cop_coef_events, 1) - 1
        g_intg = precompute_integrals(N, x)
        cop_dens_events = generate_copula_densities(cop_coef_events, measures, grid_data_size_cop; given_integrals=g_intg)
        cop_dens_events = reshape(cop_dens_events, :, n_events) # (grid_data_size_cop^D) × events

        # FEVD shares for the copula (overall, across the entire copula grid)
        dist_events = collect(Iterators.flatten(((h - 1) * (r + q) .+ dist_shock_indices) for h in 1:horizon))
        agg_events = collect(Iterators.flatten(((h - 1) * (r + q) .+ agg_shock_indices) for h in 1:horizon))

        cop_tot = sum(abs2, cop_dens_events)
        stats_dict["copula"] = Dict(
            "all" => [
                sum(abs2, view(cop_dens_events, :, dist_events)) / (cop_tot + eps()),
                sum(abs2, view(cop_dens_events, :, agg_events)) / (cop_tot + eps())
            ]
        )

        # Group decomposition using copula *mass*.
        # - If (income, wealth, consumption) are present: 2×2×2 = 8 groups → 16 numbers (dist vs agg per group)
        # - Else fallback to (income, wealth): 2×2 = 4 groups → 8 numbers
        if D >= 2
            g = grid_data_size_cop

            half = g ÷ 2
            low = 1:half
            high = (half+1):g

            # Identify measure indices.
            inc_idx = findfirst(==("income"), measures)
            wlt_idx = findfirst(x -> x == "wealth" || x == "netwealth" || x == "nw" || x == "w", measures)
            cns_idx = findfirst(x -> x == "consumption" || x == "consum" || x == "c", measures)

            dist_ev_set = Set(dist_events)

            if inc_idx !== nothing && wlt_idx !== nothing && cns_idx !== nothing && D >= 3
                # 3D: integrate out all dims except (inc, wealth, cons), then sum mass in each low/high cube.
                stats_dict["copula_groups"] = Dict()

                combos = [
                    ("Low", low),
                    ("High", high)
                ]

                group_keys = Tuple{String,Tuple{UnitRange{Int},UnitRange{Int},UnitRange{Int}}}[]
                for (ilab, irng) in combos, (wlab, wrng) in combos, (clab, crng) in combos
                    gname = "$(ilab)Inc_$(wlab)Wealth_$(clab)Cons"
                    push!(group_keys, (gname, (irng, wrng, crng)))
                    stats_dict["copula_groups"][gname] = [0.0, 0.0]  # (dist_mass, agg_mass)
                end

                # for each event, reshape and reduce to the 3D array with axes (inc, wealth, cons)
                keep = sort([inc_idx, wlt_idx, cns_idx])
                perm = (findfirst(==(inc_idx), keep), findfirst(==(wlt_idx), keep), findfirst(==(cns_idx), keep))
                dims_to_drop = tuple(filter(d -> !(d in keep), 1:D)...)

                for ev in 1:n_events
                    densD = reshape(view(cop_dens_events, :, ev), ntuple(_ -> g, D)...)
                    A = isempty(dims_to_drop) ? densD : dropdims(sum(densD; dims=dims_to_drop); dims=dims_to_drop)
                    # reorder to (inc, wealth, cons)
                    if perm != (1, 2, 3)
                        A = permutedims(A, perm)
                    end

                    if ev in dist_ev_set
                        for (gname, (irng, wrng, crng)) in group_keys
                            stats_dict["copula_groups"][gname][1] += sum(@view A[irng, wrng, crng])
                        end
                    else
                        for (gname, (irng, wrng, crng)) in group_keys
                            stats_dict["copula_groups"][gname][2] += sum(@view A[irng, wrng, crng])
                        end
                    end
                end

                # normalize within-group: dist_share + agg_share = 1 for each group
                for (gname, _) in group_keys
                    dm, am = stats_dict["copula_groups"][gname]
                    denom = dm + am + eps()
                    stats_dict["copula_groups"][gname] = [dm / denom, am / denom]
                end

            elseif inc_idx !== nothing && wlt_idx !== nothing
                # 2D fallback: (income, wealth) quadrants.
                quad_keys = [
                    "LowInc_LowWealth" => (low, low),
                    "LowInc_HighWealth" => (low, high),
                    "HighInc_LowWealth" => (high, low),
                    "HighInc_HighWealth" => (high, high)
                ]

                stats_dict["copula_quadrants"] = Dict()
                for (qname, _) in quad_keys
                    stats_dict["copula_quadrants"][qname] = [0.0, 0.0]  # (dist_mass, agg_mass)
                end

                for ev in 1:n_events
                    densD = reshape(view(cop_dens_events, :, ev), ntuple(_ -> g, D)...)

                    A = densD
                    for d in reverse(1:D)
                        if d != inc_idx && d != wlt_idx
                            A = sum(A; dims=d)
                        end
                    end

                    A2 = dropdims(A; dims=tuple(filter(d -> d != inc_idx && d != wlt_idx, 1:D)...))
                    if inc_idx > wlt_idx
                        A2 = permutedims(A2)
                    end

                    mLL = sum(@view A2[low, low])
                    mLH = sum(@view A2[low, high])
                    mHL = sum(@view A2[high, low])
                    mHH = sum(@view A2[high, high])

                    if ev in dist_ev_set
                        stats_dict["copula_quadrants"]["LowInc_LowWealth"][1] += mLL
                        stats_dict["copula_quadrants"]["LowInc_HighWealth"][1] += mLH
                        stats_dict["copula_quadrants"]["HighInc_LowWealth"][1] += mHL
                        stats_dict["copula_quadrants"]["HighInc_HighWealth"][1] += mHH
                    else
                        stats_dict["copula_quadrants"]["LowInc_LowWealth"][2] += mLL
                        stats_dict["copula_quadrants"]["LowInc_HighWealth"][2] += mLH
                        stats_dict["copula_quadrants"]["HighInc_LowWealth"][2] += mHL
                        stats_dict["copula_quadrants"]["HighInc_HighWealth"][2] += mHH
                    end
                end

                for (qname, _) in quad_keys
                    dm, am = stats_dict["copula_quadrants"][qname]
                    denom = dm + am + eps()
                    stats_dict["copula_quadrants"][qname] = [dm / denom, am / denom]
                end
            end
        end
    end

    # For the pcfs, find the contributions by distribution and aggregate (as reference, new_data_pcf[m][i, h, s])
    if integral_pcf_grid == 10
        for m in eachindex(new_data_pcf)
            total50 = sum(abs2, new_data_pcf[m][1:5, :, :])
            total40 = sum(abs2, new_data_pcf[m][6:9, :, :])
            total10 = sum(abs2, new_data_pcf[m][10, :, :])
            stats_dict[measures[m]] = Dict()
            stats_dict[measures[m]]["bottom50"] = [sum(abs2, new_data_pcf[m][1:5, dist_shock_indices, :]) / total50, sum(abs2, new_data_pcf[m][1:5, agg_shock_indices, :]) / total50] # distributional, aggregate
            stats_dict[measures[m]]["next40"] = [sum(abs2, new_data_pcf[m][6:9, dist_shock_indices, :]) / total40, sum(abs2, new_data_pcf[m][6:9, agg_shock_indices, :]) / total40]
            stats_dict[measures[m]]["top10"] = [sum(abs2, new_data_pcf[m][10, dist_shock_indices, :]) / total10, sum(abs2, new_data_pcf[m][10, agg_shock_indices, :]) / total10]

            # Do bottom20, 20-40, 40-80, top20 
            b20 = sum(abs2, new_data_pcf[m][1:2, :, :])
            n20_40 = sum(abs2, new_data_pcf[m][3:4, :, :])
            n40_80 = sum(abs2, new_data_pcf[m][5:8, :, :])
            t20 = sum(abs2, new_data_pcf[m][9:10, :, :])
            stats_dict[measures[m]]["bottom20"] = [sum(abs2, new_data_pcf[m][1:2, dist_shock_indices, :]) / b20, sum(abs2, new_data_pcf[m][1:2, agg_shock_indices, :]) / b20]
            stats_dict[measures[m]]["20_40"] = [sum(abs2, new_data_pcf[m][3:4, dist_shock_indices, :]) / n20_40, sum(abs2, new_data_pcf[m][3:4, agg_shock_indices, :]) / n20_40]
            stats_dict[measures[m]]["40_80"] = [sum(abs2, new_data_pcf[m][5:8, dist_shock_indices, :]) / n40_80, sum(abs2, new_data_pcf[m][5:8, agg_shock_indices, :]) / n40_80]
            stats_dict[measures[m]]["top20"] = [sum(abs2, new_data_pcf[m][9:10, dist_shock_indices, :]) / t20, sum(abs2, new_data_pcf[m][9:10, agg_shock_indices, :]) / t20]

        end
    elseif integral_pcf_grid == 5
        for m in eachindex(new_data_pcf)
            bottom40 = sum(abs2, new_data_pcf[m][1:2, :, :])
            middle40 = sum(abs2, new_data_pcf[m][3:4, :, :])
            top20 = sum(abs2, new_data_pcf[m][5, :, :])
            stats_dict[measures[m]] = Dict()
            stats_dict[measures[m]]["bottom40"] = [sum(abs2, new_data_pcf[m][1:2, dist_shock_indices, :]) / bottom40, sum(abs2, new_data_pcf[m][1:2, agg_shock_indices, :]) / bottom40] # distributional, aggregate
            stats_dict[measures[m]]["middle40"] = [sum(abs2, new_data_pcf[m][3:4, dist_shock_indices, :]) / middle40, sum(abs2, new_data_pcf[m][3:4, agg_shock_indices, :]) / middle40]
            stats_dict[measures[m]]["top20"] = [sum(abs2, new_data_pcf[m][5, dist_shock_indices, :]) / top20, sum(abs2, new_data_pcf[m][5, agg_shock_indices, :]) / top20]

            # std_across_s = std.(eachrow(reshape(new_data_pcf[m][:, :, :], :, r + q)))
            # println("Std. across shocks (last measure): $(std_across_s)")
        end
    else
        error("FEVD stats not implemented for integral_pcf_grid = $integral_pcf_grid")
    end


    # # Generate Latex Table. Include copula entries if present.
    meas_for_tbl = copy(measures)
    if haskey(stats_dict, "copula_groups")
        pushfirst!(meas_for_tbl, "copula_groups")
    elseif haskey(stats_dict, "copula_quadrants")
        pushfirst!(meas_for_tbl, "copula_quadrants")
    end
    if haskey(stats_dict, "copula")
        pushfirst!(meas_for_tbl, "copula")
    end
    # Add 3 bivariate copula rows for the 3D case (if computed)
    for k in keys(stats_dict)
        if startswith(String(k), "copula_") && k != "copula"
            push!(meas_for_tbl, String(k))
        end
    end

    # Prefer the wide layout (measures as column groups) when the classic 3 measures are present.
    # Fall back to the old single-measure blocks otherwise.
    if all(m -> haskey(stats_dict, m), ["consumption", "income", "wealth"])
        measures_main = ["consumption", "income", "wealth"]

        # Choose the group ordering from the first measure.
        groups_main = collect(keys(stats_dict[measures_main[1]]))

        # Optional copula panel: for copula_groups we treat columns as Low/High consumption and
        # rows as income×wealth groups.
        cop_key = haskey(stats_dict, "copula_groups") ? "copula_groups" : (haskey(stats_dict, "copula_quadrants") ? "copula_quadrants" : nothing)

        if cop_key == "copula_groups"
            groups_cop = [
                "LowInc_LowWealth",
                "LowInc_HighWealth",
                "HighInc_LowWealth",
                "HighInc_HighWealth",
            ]
            cop_cols = [("LowCons", "Low Consumption"), ("HighCons", "High Consumption")]
            latex_tbl = make_latex_table_obs_wide(
                stats_dict;
                measures_main=measures_main,
                groups_main=groups_main,
                panel1_title="Conditional means of ...",
                copula_block_key=cop_key,
                groups_copula=groups_cop,
                copula_columns=cop_cols,
                panel2_title="Population shares with ...",
                caption="FEVD contributions",
                label="tab:fevd_contrib"
            )
            println(latex_tbl)
        elseif cop_key == "copula_quadrants"
            groups_cop = [
                "LowInc_LowWealth",
                "LowInc_HighWealth",
                "HighInc_LowWealth",
                "HighInc_HighWealth",
            ]
            # single 2-col block
            cop_cols = [("", "")]
            latex_tbl = make_latex_table_obs_wide(
                stats_dict;
                measures_main=measures_main,
                groups_main=groups_main,
                panel1_title="Conditional means of ...",
                copula_block_key=cop_key,
                groups_copula=groups_cop,
                copula_columns=cop_cols,
                panel2_title="Population shares with ...",
                caption="FEVD contributions",
                label="tab:fevd_contrib"
            )
            println(latex_tbl)
        else
            latex_tbl = make_latex_table_obs_wide(
                stats_dict;
                measures_main=measures_main,
                groups_main=groups_main,
                panel1_title="Conditional means of ...",
                caption="FEVD contributions",
                label="tab:fevd_contrib"
            )
            println(latex_tbl)
        end
    else
        latex_tbl = make_latex_table_obs(stats_dict, meas_for_tbl; caption="FEVD contributions", label="tab:fevd_contrib")
        println(latex_tbl)
    end


    return tbl

end

function get_structural_mat(Ω, S, r, q; type=:block_cholesky, shock_order=:dist_first)
    Ω_sub = Symmetric(S' * Ω * S)           # (r+q)×(r+q), already in desired order

    if type != :block_cholesky
        C_psd = sym_psd(Matrix(Ω_sub))
        B_small = cholesky(C_psd).L         # (r+q)×(r+q)
        return S * B_small                  # full impact matrix: n×(r+q)
    else
        B_small = zeros(eltype(Ω), r + q, r + q)

        if shock_order === :dist_first
            # Ω_sub ordering: [F(1:r), Y(r+1:r+q)]
            Ω_FF = Ω_sub[1:r, 1:r]
            Ω_YF = Ω_sub[r+1:r+q, 1:r]
            Ω_YY = Ω_sub[r+1:r+q, r+1:r+q]

            B_FF = cholesky(Symmetric(Ω_FF)).L
            B_YF = (B_FF \ Ω_YF')'             # q×r
            Ω_YY_res = Ω_YY - B_YF * B_YF'
            B_YY = cholesky(Symmetric(Ω_YY_res)).L

            B_small[1:r, 1:r] = B_FF
            B_small[r+1:r+q, 1:r] = B_YF
            B_small[r+1:r+q, r+1:r+q] = B_YY

        elseif shock_order === :agg_first
            # Ω_sub ordering: [Y(1:q), F(q+1:q+r)]
            Ω_YY = Ω_sub[1:q, 1:q]
            Ω_FY = Ω_sub[q+1:q+r, 1:q]
            Ω_FF = Ω_sub[q+1:q+r, q+1:q+r]

            B_YY = cholesky(Symmetric(Ω_YY)).L
            B_FY = (B_YY \ Ω_FY')'            # r×q
            Ω_FF_res = Ω_FF - B_FY * B_FY'
            B_FF = cholesky(Symmetric(Ω_FF_res)).L

            B_small[1:q, 1:q] = B_YY
            B_small[q+1:q+r, 1:q] = B_FY
            B_small[q+1:q+r, q+1:q+r] = B_FF
        else
            error("Invalid shock_order")
        end
        return S * B_small   # n×(r+q)
    end
end


using Printf

function make_latex_table_obs(stats_dict, measures;
    caption="Decomposition of the Observables",
    label="tab:fevd_obs",
    notes="\\textit{Notes:} Table reports the generalized forecast error variance decomposition (GFEVD) of Table \\ref{tab:fevd_dist} mapped to observables consumption, income, and wealth, across three household groups. Entries show the share of variation explained by distributional shocks versus aggregate shocks. Household groups are defined as the bottom 50\\%, middle 50--90\\%, and top 10\\% of the respective marginal distribution, which is italicized. This is over a five-year horizon.",
    group_order=nothing,          # optional: vector of group strings in desired order
    italicize_measures=true       # optional: wrap measure headers in \textit{...}
)

    rows = String[]
    push!(rows, "\\begin{table}[!htbp]")
    push!(rows, "\\centering")
    push!(rows, "\\caption{$caption}")
    push!(rows, "\\begin{tabular}{lccc}")
    push!(rows, "\\toprule")
    push!(rows, " Group & Distributional (\\%) & Aggregate (\\%) \\\\")
    push!(rows, "\\midrule\\vspace{1mm}")

    for (mi, meas) in enumerate(measures)
        meas_hdr = italicize_measures ? "\\textit{$meas}" : string(meas)
        push!(rows, "&\\multicolumn{2}{c}{$meas_hdr}\\\\")

        gs = group_order === nothing ? collect(keys(stats_dict[meas])) : group_order
        for g in gs
            dist, agg = stats_dict[meas][g]
            denom = dist + agg + eps()
            dist_share = 100 * dist / denom
            agg_share = 100 * agg / denom
            push!(rows, @sprintf("  %s  & %.2f & %.2f \\\\", g, dist_share, agg_share))
        end

        # blank line between blocks (matches your LaTeX)
        if mi < length(measures)
            push!(rows, "\\\\")
        end
    end

    push!(rows, "\\bottomrule")
    push!(rows, "\\end{tabular}")
    push!(rows, "\\captionsetup{font={footnotesize}, width={.6\\textwidth}, justification=justified, skip=2pt}")
    push!(rows, "\\caption*{\\footnotesize{$notes}}")
    push!(rows, "\\label{$label}")
    push!(rows, "\\end{table}")

    return join(rows, "\n")
end


"""Create a wide LaTeX FEVD table with measures as column groups (2 columns per measure).

This matches a layout like:

    & \\multicolumn{2}{c}{Consumption} && \\multicolumn{2}{c}{Income} && ...
    Group & D.-shocks & A.-shocks && D.-shocks & A.-shocks && ...

Optionally, it can add a second panel for copula group shares where the "measures" are
e.g. Low/High consumption and the rows are income×wealth (or other) groups.
"""
function make_latex_table_obs_wide(stats_dict;
    # panel 1 (main observables)
    measures_main::Vector{String},
    groups_main::Vector{String},
    panel1_title::String="Conditional means of ...",
    # panel 2 (optional copula)
    copula_block_key::Union{Nothing,String}=nothing,   # e.g. "copula_groups" or "copula_quadrants"
    groups_copula::Union{Nothing,Vector{String}}=nothing,
    copula_columns::Union{Nothing,Vector{Tuple{String,String}}}=nothing, # (colname, label)
    panel2_title::String="Population shares with ...",
    # formatting
    caption::String="FEVD contributions",
    label::String="tab:fevd_contrib",
    italicize_headers::Bool=true,
    percent_digits::Int=0,                 # 0 -> integers like your example; 2 -> 2 decimals
    spacer::String="&&"                    # insert between 2-col blocks (matches your example)
)

    # local numeric formatting helper (avoids @sprintf)
    fmt_pct(x::Real) = percent_digits == 0 ? string(Int(round(x))) :
                       (percent_digits == 1 ? string(round(x; digits=1)) : string(round(x; digits=2)))

    # Helper: pretty header
    fmt_hdr(s) = italicize_headers ? "\\textit{$s}" : s

    # We emulate your `&&` gaps by inserting explicit spacer columns into the tabular.
    # Column pattern: Group | (D A) | gap | (D A) | gap | (D A)
    nm = length(measures_main)
    colspec_parts = ["l"]
    for k in 1:nm
        push!(colspec_parts, "cc")
        if k < nm
            push!(colspec_parts, "@{\\hskip 0.8em}")
        end
    end
    colspec = join(colspec_parts, "")

    rows = String[]
    push!(rows, "\\begin{table}[!htbp]")
    push!(rows, "\\centering")
    # Panel title line inside the tabular, like your example
    push!(rows, "\\begin{tabular}{" * colspec * "}")
    push!(rows, "\\toprule")

    push!(rows, "&\\multicolumn{" * string(2 * nm + (nm - 1) * 0) * "}{c}{" * panel1_title * "}\\\\")
    push!(rows, "\\midrule")

    # Row: measure group headers
    # Build: &\multicolumn{2}{c}{Meas1}&&\multicolumn{2}{c}{Meas2}&&...
    hdr = "&" * join(["\\multicolumn{2}{c}{" * fmt_hdr(m) * "}" for m in measures_main], " $spacer ") * "\\\\"
    push!(rows, hdr)

    # cmidrules aligned to the 2-col blocks
    # columns are: 1=Group, then for each measure: D=2k, A=2k+1. So block k sits at (2k,2k+1).
    cmids = String[]
    for k in 1:nm
        # With our colspec, columns are: 1=Group, then D/A are 2 and 3 for k=1,
        # and increase by 2 plus a spacer column in between.
        # In LaTeX's column counting, @{} columns don't count, so we can treat it as contiguous.
        c1 = 2 + 2 * (k - 1)
        c2 = c1 + 1
        push!(cmids, "\\cmidrule(lr{0.25em}){" * string(c1) * "-" * string(c2) * "}")
    end
    push!(rows, join(cmids, " "))

    # Column labels
    push!(rows, "Group " * join(["& D.-shocks & A.-shocks" for _ in 1:nm], " $spacer ") * " \\\\ ")
    push!(rows, "\\midrule")

    # Body
    for g in groups_main
        parts = String[]
        for m in measures_main
            dist, agg = stats_dict[m][g]
            denom = dist + agg + eps()
            dist_share = 100 * dist / denom
            agg_share = 100 * agg / denom
            push!(parts, fmt_pct(dist_share) * " & " * fmt_pct(agg_share))
        end
        push!(rows, "  $g & " * join(parts, " $spacer ") * " \\\\ ")
    end

    # Optional second panel for copula groups
    if copula_block_key !== nothing
        block = stats_dict[copula_block_key]
        groups_copula === nothing && error("groups_copula must be provided when copula_block_key is set")
        copula_columns === nothing && error("copula_columns must be provided when copula_block_key is set")

        push!(rows, "\\midrule")
        push!(rows, "&\\multicolumn{" * string(2 * nm) * "}{c}{$panel2_title}\\\\")
        push!(rows, "\\midrule")

        # For panel 2, columns are specified by copula_columns = [(prefix,label), ...]
        # We print those as measure headers, and for each group row we look up keys in the block.
        nm2 = length(copula_columns)
        hdr2 = "&" * join(["\\multicolumn{2}{c}{" * fmt_hdr(lbl) * "}" for (_, lbl) in copula_columns], " $spacer ") * "\\\\"
        push!(rows, hdr2)
        cmids2 = String[]
        for k in 1:nm2
            c1 = 2 + 2 * (k - 1)
            c2 = c1 + 1
            push!(cmids2, "\\cmidrule(lr{0.25em}){" * string(c1) * "-" * string(c2) * "}")
        end
        push!(rows, join(cmids2, " "))
        push!(rows, "Group " * join(["& D.-shocks & A.-shocks" for _ in 1:nm2], " $spacer ") * " \\\\ ")
        push!(rows, "\\midrule")

        for g in groups_copula
            parts = String[]
            for (prefix, _) in copula_columns
                key = prefix == "" ? g : "$(g)_$(prefix)"
                dist, agg = block[key]
                denom = dist + agg + eps()
                dist_share = 100 * dist / denom
                agg_share = 100 * agg / denom
                push!(parts, fmt_pct(dist_share) * " & " * fmt_pct(agg_share))
            end
            push!(rows, "  $g & " * join(parts, " $spacer ") * " \\\\ ")
        end
    end

    push!(rows, "\\bottomrule")
    push!(rows, "\\end{tabular}")
    push!(rows, "\\label{$label}")
    push!(rows, "\\end{table}")

    return join(rows, "\n")
end

using DataFrames

function df_to_latex_fevd_factors(df::DataFrame;
    caption="GFEVD on the Distributional Factors",
    label="tab:fevd_dist",
    notes="\\textit{Notes:} Table reports a forecast error variance decomposition (FEVD) for the eight estimated distributional factors. The columns show the percentage of variation in each factor explained by distributional shocks versus aggregate shocks. This is over a five-year horizon.",
    factor_col::Symbol=:Factor,
    dist_col::Symbol=:Variation_from_Distributional,
    agg_col::Symbol=:Variation_from_Aggregates
)
    rows = String[]
    push!(rows, "\\begin{table}[htbp]")
    push!(rows, "\\centering")
    push!(rows, "\\caption{$caption}")
    push!(rows, "\\begin{tabular}{lcc}")
    push!(rows, "\\toprule")
    push!(rows, "Factor & Distributional (\\%) & Aggregate (\\%) \\\\")
    push!(rows, "\\midrule")

    for r in eachrow(df)
        dist = r[dist_col]
        agg = r[agg_col]
        denom = dist + agg + eps()         # safe even if already percentages
        dist_share = 100 * dist / denom
        agg_share = 100 * agg / denom
        push!(rows, @sprintf("%s & %.2f & %.2f \\\\",
            r[factor_col], dist_share, agg_share))
    end

    push!(rows, "\\bottomrule")
    push!(rows, "\\end{tabular}")
    push!(rows, "\\captionsetup{font={footnotesize}, width={.5\\textwidth}, justification=justified, skip=2pt}")
    push!(rows, "\\caption*{\\footnotesize{$notes}}")
    push!(rows, "\\label{$label}")
    push!(rows, "\\end{table}")

    return join(rows, "\n")
end


