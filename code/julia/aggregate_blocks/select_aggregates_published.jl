# The PUBLISHED select_aggregates (ModelPrep.jl before the agg_mode refactor of 2026-10-21, from
# 7_Results/archive/aggblocks_code_before_edit_20261021.zip), renamed. aggregate_block_diagnostics.jl includes it
# to verify that the refactored :pca path returns byte-identical scores. Not loaded by the model.
function select_aggregates_published(aggregates, measures, tot_periods, tmin, tmax, agg_lags, tag, best_aggs; until=false)

    aggregates[:, "date"] = QuarterlyDate.(aggregates[:, "time"])

    # # Since aggregates require a lag
    # q_correction = tmin["quarter"] > 1 ? tmin["quarter"] - 1 : 4
    # y_correction = tmin["quarter"] > 1 ? tmin["year"] : tmin["year"] - 1

    # Calculate the quarter correction
    q_correction = tmin["quarter"] > agg_lags ? tmin["quarter"] - agg_lags : 4 - (agg_lags - tmin["quarter"]) % 4 # eg,

    # Calculate the year correction
    y_correction = tmin["quarter"] > agg_lags ? tmin["year"] : trunc(tmin["year"] - ((agg_lags + 3 - 1) / 4) + 1)

    filter!(row -> row.date >= QuarterlyDate(y_correction, q_correction), aggregates)
    # a = filter(row -> row.date >= QuarterlyDate(y_correction, q_correction), aggregates)
    # tot_rows_lb = nrow(a)

    # dropped_rows_lb = tot_rows - tot_rows_lb

    # filter!(row -> row.date <= QuarterlyDate(tmax["year"], tmax["quarter"]), aggregates)
    local b
    if until != false
        b = filter(row -> row.date <= QuarterlyDate(until["year"], until["quarter"]), aggregates)
    else
        b = filter(row -> row.date <= QuarterlyDate(tmax["year"], tmax["quarter"]), aggregates)
    end

    dropped_rows_ub = nrow(aggregates) - nrow(b)

    data_only_aggs = select(aggregates, Not(["date", "time", "year", "quarter"]))

    # @assert size(data_only_aggs, 1) == tot_periods + 1

    # Fill matrix with density, percentile function measurements 
    data_only_aggs = copy(transpose(Matrix{Float64}(data_only_aggs)))  # removes date column, K x T

    if occursin("HANK", tag)
        # HANK: shocks are independent AR(1)s, lags are redundant — use contemporaneous only
        super_aggs = data_only_aggs[:, 1:end-agg_lags]
        standardize_aggs!(super_aggs)
        u_proj, agg_pcs, _ = perform_pca(super_aggs, measures, :aggs, tag)
        agg_pcs = agg_pcs[:, 1:end-dropped_rows_ub]

        # agg_pcs = super_aggs[:, 1:end-dropped_rows_ub]
        # u_proj = rand(9,9) # dummy projection matrix since we are not doing PCA
        agg_count = size(agg_pcs, 1)
        return u_proj, agg_pcs, agg_count
    else
        super_aggs = data_only_aggs[:, 1:end-agg_lags] # N by T

        for i in 1:agg_lags
            super_aggs = vcat(super_aggs, data_only_aggs[:, i+1:end-agg_lags+i])
        end

        standardize_aggs!(super_aggs)

        # Column j of super_aggs stacks dates j … j+agg_lags; its contemporaneous
        # date is row j+agg_lags of `aggregates`. Quarters listed in
        # ModelOptions.aggregate_pca_exclude are kept out of the PCA FIT only
        # (loadings); every quarter is still projected.
        excl = hasproperty(model_options, :aggregate_pca_exclude) ? Set(String.(model_options.aggregate_pca_exclude)) : Set{String}()
        fit_mask = if isempty(excl)
            nothing
        else
            col_dates = aggregates[!, "date"][agg_lags+1:end]
            [!("$(Dates.year(d))-Q$(Dates.quarterofyear(d))" in excl) for d in col_dates]
        end

        u_proj, agg_pcs, _ = perform_pca(super_aggs, measures, :aggs, tag; fit_mask = fit_mask)

        agg_pcs = agg_pcs[:, 1:end-dropped_rows_ub]
        agg_count = size(agg_pcs, 1)
        return u_proj, agg_pcs, agg_count
    end
end
