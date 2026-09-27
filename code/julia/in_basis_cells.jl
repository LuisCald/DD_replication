# ─────────────────────────────────────────────────────────────────────────────
# in_basis_cells.jl — "survey-in-basis" ceiling for the HANK cross-conditional
# cells (bot50 / mid40 / top10 of <outcome>_by_<conditioning>).
#
# Question it answers: how much of the truth's conditional-mean movement is
# still present once a replica's microdata has been projected onto the model's
# basis (order-11 Legendre percentile functions + order-11 copula, immutables
# removed) — BEFORE any factor compression, filtering or estimation?
#
# It takes each dataset's RAW coefficient matrix exactly as the estimation
# receives it (data_constructor → the 1730 × T block, no detrending, no
# standardisation), re-inserts the immutable copula coefficients, and pushes it
# through the SAME cell operator the reconstruction uses
# (compute_cross_conditional_means_continuous, closed-form Legendre segment
# integrals). The result is compared with the truth at the dataset's own
# observation dates, normalised by the truth's <outcome>_per_hh like plot_HANK.
#
# Reading the output:
#   in-basis ≈ replica-microdata ceiling (PSID 80/79/76, SCF 96/94/93, SIPP 90/93/93)
#       ⇒ the basis carries the cells; whatever the model loses is estimation.
#   in-basis ≪ ceiling for a cell
#       ⇒ no estimator working in this basis can recover that cell; the fix is
#          the marginal/copula representation, not factors, loadings or Σ.
#
# Run (server, from the repo root; only DD_EXAMPLE/HANK_ECON matter, the other
# switches are accepted and ignored):
#   DD_EXAMPLE=HANK HANK_ECON=1 julia -t 8 --project=5_Code/code/julia/env 5_Code/code/julia/in_basis_cells.jl
# Optional: DD_INBASIS_SETS="a,d,e" restricts to those datasets (default: a,d,e;
# "all" = every dataset in obs_data.files). Output: 7_Results/in_basis/*.csv +
# the correlation table in the log.
# ─────────────────────────────────────────────────────────────────────────────

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))

@info "═══ in-basis cells ═══"
@info "BASE_PATH = $BASE_PATH"

@unpack measures, estimator = model_options
@unpack grid_pcf, grid_cop = estimator
measures = sort(String.(measures))
D = length(measures)

# ── dataset subset ────────────────────────────────────────────────────────────
sets_env = get(ENV, "DD_INBASIS_SETS", "a,d,e")
files_all = obs_data.files
files_use = if sets_env == "all"
    files_all
else
    letters = strip.(split(sets_env, ","))                 # keys look like "HANK a 1"
    Dict(k => v for (k, v) in files_all if any(l -> occursin(" $(l) ", k), letters))
end
isempty(files_use) && error("DD_INBASIS_SETS=$(sets_env) matched none of $(sort(collect(keys(files_all))))")
@info "datasets: $(sort(collect(keys(files_use))))"

obs_sub = ObservedData(files = files_use, agg_data = obs_data.agg_data, gdp_series = copy(obs_data.gdp_series))

# ── raw coefficients, exactly as the estimation receives them ─────────────────
dfs, _, time_vec, time_dict, freq_type = data_constructor(obs_sub, model_options)
gdp_series = obs_sub.gdp_series                      # time is a QuarterlyDate now
df_names = obs_sub.df_vec.df_names
gdp_row = Dict(gdp_series.time[i] => i for i in axes(gdp_series, 1))

# ── truth (the gdp_series file IS the truth file for HANK; re-read it clean) ──
truth = CSV.read(joinpath(DATA_PROCESSING, "HANK_truth_$(HANK_ECON).csv"), DataFrame)
truth.date = QuarterlyDate.(truth.time)
truth_row = Dict(truth.date[i] => i for i in axes(truth, 1))

cross_shares = cross_conditional_shares(model_options)     # 40/40/20 by default (ModelOptions)
share_labels = cross_group_labels(cross_shares)
outdir = joinpath(RESULTS_DIR, "in_basis")
mkpath(outdir)

corr_or_nan(x, y) = (length(x) >= 3 && std(x) > 0 && std(y) > 0) ? cor(x, y) : NaN
function r2_dm(x, y)
    length(x) < 3 && return NaN
    xd = x .- mean(x); yd = y .- mean(y)
    v = sum(abs2, yd)
    v > 0 ? 1 - sum(abs2, xd .- yd) / v : NaN
end

summary_rows = DataFrame(dataset = String[], cell = String[], group = String[], n = Int[], corr = Float64[], r2 = Float64[],
                         level_inbasis = Float64[], level_truth = Float64[])

for (k, name) in enumerate(df_names)
    X = dfs[k]                                        # (1694 + 36) × T_k raw coefficients
    T = size(X, 2)

    # observation dates in the order data_constructor stacked them
    dates = QuarterlyDate[]
    for y in sort(collect(keys(time_dict[k]))), p in sort(time_dict[k][y])
        push!(dates, freq_type[k] == "quarter" ? QuarterlyDate(Int(y), Int(round(p))) : QuarterlyDate(Int(y), 4))
    end
    length(dates) == T || error("$name: $(length(dates)) dates vs $T coefficient columns")

    # immutables back in, coefficient tensor (K,…,K,T) + asinh-Legendre pcf coefficients
    cont = add_multidimensional_immutable(estimator, X, grid_cop, measures)
    dv = undo_functional_treatment_validation(estimator, cont, grid_pcf, grid_cop, measures, gdp_series, time_dict[k], freq_type[k])
    cop_coefs = dv[1]
    pcf_coefs = dv[2]
    split_pcfs = [pcf_coefs[I, :] for I in Iterators.partition(axes(pcf_coefs, 1), grid_pcf)]

    # per-HH anchors at the observation dates (same series the reconstruction uses)
    corr_mat = fill(NaN, T, D)
    for (t, d) in enumerate(dates)
        haskey(gdp_row, d) || error("$name: no per_hh anchor for $d")
        for (m, meas) in enumerate(measures)
            corr_mat[t, m] = gdp_series[gdp_row[d], meas * "_per_hh"]
        end
    end

    cells = compute_cross_conditional_means_continuous(cop_coefs, split_pcfs, measures, corr_mat; share_spec = cross_shares)

    # export + compare
    out = DataFrame(time = string.(dates))
    println("\n── $name  ($(T) observation dates, $(freq_type[k])ly) — in-basis vs truth, normalised by <outcome>_per_hh")
    println(rpad("cell", 20), "  ", join(rpad.(share_labels, 16)), "   (corr / R²)")
    for key in sort(collect(keys(cells)))
        M = cells[key]
        for (si, sl) in enumerate(share_labels)
            out[!, "$(key)_$(sl)"] = M[si, :]
        end
        out_meas = split(key, "_by_")[1]
        line = rpad(key, 20) * "  "
        for (si, sl) in enumerate(share_labels)
            xs = Float64[]; ys = Float64[]
            for (t, d) in enumerate(dates)
                haskey(truth_row, d) || continue
                r = truth_row[d]
                tcol = "$(key)_$(sl)"
                hasproperty(truth, tcol) || continue
                nrm = truth[r, out_meas * "_per_hh"]
                v = M[si, t]
                tv = truth[r, tcol]
                (isnan(v) || ismissing(nrm) || nrm == 0 || ismissing(tv) || isnan(tv)) && continue   # truth may be NaN (e.g. blanked boundary row)
                push!(xs, v / nrm); push!(ys, tv / nrm)
            end
            c = corr_or_nan(xs, ys); r2 = r2_dm(xs, ys)
            push!(summary_rows, (name, key, sl, length(xs), c, r2, isempty(xs) ? NaN : mean(xs), isempty(ys) ? NaN : mean(ys)))
            line *= rpad(isnan(c) ? "   --    " : "$(lpad(round(Int, 100c), 4))/$(lpad(round(Int, 100r2), 4))", 16)
        end
        println(line)
    end
    CSV.write(joinpath(outdir, "$(name)_in_basis_cells.csv"), out)
end

CSV.write(joinpath(outdir, "in_basis_summary.csv"), summary_rows)
println("\nlevels (mean over the dataset's dates), wealth_by_income:")
for r in eachrow(filter(r -> r.cell == "wealth_by_income", summary_rows))
    println("  $(r.dataset) $(r.group): in-basis $(round(r.level_inbasis; digits = 3)) vs truth $(round(r.level_truth; digits = 3))")
end
@info "written: $(outdir)"
@info "═══ in-basis cells finished ═══"
