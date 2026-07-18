# ─────────────────────────────────────────────────────────────
# run_postestimation.jl — Stages 3-5: results, figures, tables
# ─────────────────────────────────────────────────────────────
#
# Usage (from repo root):
#   julia --project=code/julia/env code/julia/run_postestimation.jl
#
# This script loads pre-computed parameter estimates and generates
# all post-estimation results, figures, and tables for the paper:
#   - Reconstruction of synthetic distributions
#   - Validation against external sources (DFA, WID, SCF, CPS, ACS)
#   - Forecast error variance decomposition (FEVD)
#   - Historical decomposition
#   - Counterfactual exercises
#   - Correlation tables
#   - Cyclicality of consumption analysis
#   - Out-of-sample forecasts
#
# Requires: completed estimation (Stage 2) with saved parameter
# vectors in 7_Results/.
# ─────────────────────────────────────────────────────────────

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))

@info "═══ Stages 3-5: Post-estimation ═══"
@info "BASE_PATH = $BASE_PATH"

# ── Unpack options ────────────────────────────────────────────
@unpack measures, data_cutoffs, tag, case = model_options
label = "3D_$case"
m_label = measures_folder(measures)
kind_of_plots = :mcmc
opttag = "from_mcmc"

# ── Step 1: Prepare data ─────────────────────────────────────
# DD_PLOT_PROOF=1 also writes the proof-of-concept figures (Legendre coefs,
# copula weights, quantile/KL approximation — Plots/proof_of_concept/*) during
# data preparation. Off by default (adds runtime to estimation_prep).
if get(ENV, "DD_PLOT_PROOF", "0") == "1"
    model_options.plot_proof = true
end
@info "Preparing functional data..."
const func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)
hyperpriors = priors[end-5:end]

SSM(par) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]
SSM(par, _) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]

@unpack tmin, tmax = time_params
@unpack gdp_series = obs_data
@unpack data_sources = func_data
user_t = (deepcopy(tmin), deepcopy(tmax))

# ── Step 2: Load estimated parameters ────────────────────────
@info "Loading estimated parameters..."
par_final = get_param_vector(measures, kind_of_plots, label, data_cutoffs, tag)
logV, alarm = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
@info "Log-likelihood at loaded parameters: $logV"


# ── Step 4: Export time series, validate, generate figures ───
@info "Exporting time series and generating validation plots..."
# include("Reconstruction.jl")
# include("CreateTimeSeries.jl")
# include("Validation.jl")
# include("ModelPrep.jl")
# include("plot_HANK.jl")

# ── Step 3: Reconstruct synthetic distributions ──────────────
@info "Reconstructing synthetic distributions..."
dv, _ = reconstruct_data(
    par_final, param_sizes, hyperpriors, meas_ind, Σ_ids,
    model_elements, obs_data, model_options, time_params, data_sources
)
within_stat_dict = Dict()
for (c, k) in enumerate(keys(dv))
    if occursin("HANK", tag) && k == "consensus"
        continue
    end

    within_stat_dict[k] = Dict()
    for ty in ["normal"]
        within_stat_dict[k][ty], dv[k][ty] = export_functional_data(
            dv[k][ty], ty, k, kind_of_plots, obs_data, func_data,
            time_params, user_t, model_options, false, true;
        )

        if c == length(keys(dv)) && ty == "normal"
            init_path = BASE_PATH
            dict_path = init_path * "/7_Results/$m_label" * "$tag" * "/$opttag/plots/"
            compare_to_data(dv, ty, func_data, obs_data, user_t, time_params, model_options, kind_of_plots, label)
            export_combined_stat_dict_to_latex(within_stat_dict, [measures..., "copula"], dict_path, label)
            if !occursin(" HANK", tag)
                compare_to_external_sources(dv, ty, func_data, obs_data, user_t, time_params, model_options, kind_of_plots, label)
            end
        end
    end
end
@info "Time series export and validation complete."

# ── Step 4b: Export posterior draws of the factors (optional) ─
# Reconstructs the smoothed factors at a sample of posterior θ-draws and
# writes data/synthetic/smoothed_factor_draws.csv (+ a percentile-band file).
# Heavy: runs the Kalman smoother once per draw. Set DD_EXPORT_DRAWS=0 to skip,
# or DD_N_DRAWS to change the number of draws (default 200).
if get(ENV, "DD_EXPORT_DRAWS", "1") != "0"
    @info "Exporting posterior factor draws..."
    n_draws = parse(Int, get(ENV, "DD_N_DRAWS", "200"))
    export_factor_draws(param_sizes, hyperpriors, Σ_ids, model_elements,
                        model_options, time_params; n_draws=n_draws)
    summarize_factor_draws()
    @info "Posterior factor draws exported."
end

# ── Step 5: Correlation tables ────────────────────────────────
@info "Generating correlation tables..."
type = "from_mcmc"
export_table_to_tex_with_strings(measures, :from_mcmc)
generate_correlations_table_for_external_comparisons("SCF", measures, tag, type, "cycle")

# Cross-conditional averaged correlation table (economies 2–10)
if occursin("HANK", tag)
    economy_number = parse(Int, split(strip(tag), " ")[end])
    # Generate the averaged table only on the last economy run
    # if economy_number == 10
    generate_averaged_hank_avg_corr_table(
        11:11,
        ["consum", "income", "wealth"],
        "from_mcmc";
        data_sources = ["c", "a", "d"],
    )
    # end   # (matches the commented-out `if` above; a live `end` here broke parsing)
end
@info "Correlation tables complete."

# ═════════════════════════════════════════════════════════════
# Full results (Steps 6–10). Each step is independent, wrapped in
# try/catch, and gated by DD_FULL_RESULTS (default ON; set =0 to skip).
# These regenerate every baseline-run exhibit of the paper that does not
# require a different estimation spec (those live in examples/ — see the
# README results map).
# ═════════════════════════════════════════════════════════════
run_full = get(ENV, "DD_FULL_RESULTS", "1") != "0"

results_dir = BASE_PATH * "/7_Results/$m_label" * "$tag" * "/from_mcmc"

if run_full

# ── Step 6: FEVD (Decompositions appendix tables) ─────────────
@info "Computing forecast error variance decomposition..."
local Φ, Ω, r, q   # shared with Steps 7/9
try
    r_dist = param_sizes[1][1]
    q_agg = param_sizes[2][2]

    A, B_mat, C, D, Ω_var, Ω_corr, Σ = matrisize(par_final[1:end-6], param_sizes)
    Ω_var[diagind(Ω_var)] = log.(exp.(Ω_var[diagind(Ω_var)]) .+ 1)
    mat_Ω_corr = Matrix(Ω_corr)
    global Ω = Ω_var * mat_Ω_corr * Ω_var'

    global r, q = size(B_mat)
    nₛ = 4r + q
    Tval = eltype(A)

    global Φ = zeros(Tval, nₛ, nₛ)
    AI = Matrix{Tval}(I, r, r)
    @views begin
        Φ[1:r, 1:r] .= A
        Φ[1:r, 4r+1:4r+q] .= B_mat
        Φ[r+1:2r, 1:r] .= AI
        Φ[2r+1:3r, r+1:2r] .= AI
        Φ[3r+1:4r, 2r+1:3r] .= AI
        Φ[4r+1:end, 1:r] .= C
        Φ[4r+1:end, 4r+1:end] .= D
    end

    ids_sub = vcat(1:r, 4r+1:4r+q)
    Φ_sub = Φ[ids_sub, ids_sub]

    tbl = fevd_dist_vs_agg(model_elements, model_options, obs_data, Φ_sub, Ω;
        r, q, horizon=20, factor_names=nothing, shock_order=:agg_first)
    mkpath(results_dir * "/data")
    if tbl isa DataFrame
        CSV.write(results_dir * "/data/fevd_table.csv", tbl)
    else
        open(results_dir * "/data/fevd_table.txt", "w") do io
            show(io, MIME("text/plain"), tbl)
        end
    end
    @info "FEVD complete → $(results_dir)/data/"
catch e
    @warn "FEVD failed" exception=(e, catch_backtrace())
end

# ── Step 7: Historical decomposition (hd_recessions_f*.pdf) ───
@info "Computing historical decomposition..."
try
    smoother_res, _, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth=true)
    hd = historical_decomp_factors_blockchol(Φ, r, q, smoother_res.dε_smoothed, smoother_res.x_smoothed, Ω;
        splitting=:group, shock_order=:agg_first)
    @info "Historical decomposition: max reconstruction error $(hd.maxerr)"

    dts_hd = QuarterlyDate(tmin["year"], tmin["quarter"]):Quarter(1):QuarterlyDate(tmax["year"], tmax["quarter"])
    hd_dir = results_dir * "/plots/historical_decomposition"
    mkpath(hd_dir)
    make_hd_tables(hd.cube, hd.order, hd.ids, year.(dts_hd), quarter.(dts_hd);
        make_recession_plots=true, out_dir=hd_dir)
    @info "HD recession plots → $hd_dir"
catch e
    @warn "Historical decomposition failed" exception=(e, catch_backtrace())
end

# ── Step 8: Anatomy — information & interpolation shares ──────
@info "Computing observation-weight anatomy (information shares)..."
try
    dec = observation_weight_decomposition(model_elements, obs_data.df_vec.df_names,
        par_final, param_sizes, hyperpriors, Σ_ids, model_options)
    dec2 = merge_groups(dec)
    dts_an = collect(QuarterlyDate(tmin["year"], tmin["quarter"]) .+ Quarter.(0:size(dec.full, 2)-1))
    an_dir = results_dir * "/plots/anatomy"
    mkpath(an_dir)
    plot_all_factors(dec2; r=param_sizes[1][1], dates=dts_an, outdir=an_dir)
    export_decomposition_csv(dec2, an_dir * "/ow_decomposition.csv"; dates=dts_an)

    sm, _, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth=true)
    A2, B2, C2, D2, Ωv2, Ωc2, _ = matrisize(par_final[1:end-6], param_sizes)
    Ωv2[diagind(Ωv2)] = log.(exp.(Ωv2[diagind(Ωv2)]) .+ 1)
    Ω2 = Ωv2 * Matrix(Ωc2) * Ωv2'
    Φ2, Ωbig = build_Phi_Omega(A2, B2, C2, D2, Ω2, 4)
    P∞ = stationary_cov(Φ2, Ωbig)
    plot_interpolation_share(sm.sigma_smoothed, P∞; states=1:param_sizes[1][1], dates=dts_an,
        outfile=an_dir * "/ow_interp_share.pdf")
    @info "Anatomy figures → $an_dir"
catch e
    @warn "Anatomy step failed" exception=(e, catch_backtrace())
end

# (The consumption-across-recessions panels are produced in Stata, not here.)

# ── Step 9: Out-of-sample forecasts (fig: recon_missing1) ─────
@info "Running out-of-sample forecasts (SCF iterative + CEX extensive)..."
try
    how_much = 1
    perform_forecast("SCF", par_final, param_sizes, hyperpriors, meas_ind, Σ_ids, how_much,
        obs_data, model_options, model_elements, time_params, user_t, func_data,
        kind_of_plots, ["iterative"])
catch e
    @warn "SCF iterative forecast failed" exception=(e, catch_backtrace())
end
try
    periods_to_remove = muted_quarters_between(QuarterlyDate(1984, 1), QuarterlyDate(2021, 4))
    filtering_criteria = Dict("periods_to_remove" => periods_to_remove)
    perform_forecast("CEX", par_final, param_sizes, hyperpriors, meas_ind, Σ_ids,
        filtering_criteria, obs_data, model_options, model_elements, time_params,
        user_t, func_data, kind_of_plots, ["extensive", "data_only"])
catch e
    @warn "CEX extensive forecast failed" exception=(e, catch_backtrace())
end

end  # run_full

@info "═══ Stages 3-5 finished ═══"
