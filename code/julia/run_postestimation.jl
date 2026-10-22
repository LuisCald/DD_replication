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

# Results tree for this spec (some writers — Validation.jl, Correlations.jl,
# CreateTimeSeries.jl — don't mkpath their folders)
let rd = BASE_PATH * "/7_Results/" * measures_folder(model_options.measures) * model_options.tag
    for sub in ("other_results/noise_distributions/measurement_noise", "other_results/noise_distributions/process_noise",
                "plots/correlations", "from_mcmc/parameter_vectors", "from_mcmc/plots/correlations",
                "from_mcmc/bayesian_convergence", "from_mcmc/data")
        mkpath(joinpath(rd, sub))
    end
    mkpath(BASE_PATH * "/7_Results/factor_analysis"); mkpath(BASE_PATH * "/7_Results/MDD"); mkpath(BASE_PATH * "/posterior_draws")
    @info "Results folder: $rd"
end

@info "═══ Stages 3-5: Post-estimation ═══"
@info "BASE_PATH = $BASE_PATH"

# ── Unpack options ────────────────────────────────────────────
@unpack measures, data_cutoffs, tag, case = model_options
label = "3D_$case"
m_label = measures_folder(measures)
kind_of_plots = :mcmc
opttag = "from_mcmc"

# DD_SKIP: comma list of steps to leave out on a (re)run, e.g. DD_SKIP=bands,draws,fevd,hd,anatomy,forecasts
#   bands     credible bands (also reused automatically when newer than the posterior; DD_REDO_BANDS=1 forces)
#   draws     export of posterior factor draws (data/synthetic)
#   fevd, hd  FEVD / historical decomposition (hd needs fevd)
#   anatomy   observation-weight anatomy
#   forecasts drop-one-SCF-wave + CEX every-4-years forecasts
const DD_SKIP = Set(strip.(split(get(ENV, "DD_SKIP", ""), ","; keepempty = false)))
skipstep(s) = (s in DD_SKIP) && (@info "DD_SKIP: skipping $s"; true)

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
hyperpriors = st_hyperpriors(priors, param_sizes)

SSM(par) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]
SSM(par, _) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]

@unpack tmin, tmax = time_params
@unpack gdp_series = obs_data
@unpack data_sources = func_data
user_t = (deepcopy(tmin), deepcopy(tmax))

# ── Step 2: Load estimated parameters ────────────────────────
@info "Loading estimated parameters..."
par_final = get_param_vector(measures, kind_of_plots, label, data_cutoffs, tag)
length(par_final) == length(param_vector) ||
    error("mode has $(length(par_final)) parameters but this configuration has $(length(param_vector)) — " *
          "the run was estimated under a different spec (factor count, trend block, object_factors). Match the switches.")
report_mode_dynamics(par_final, param_sizes, model_options)

# ── Persistence counterfactual (DD_PERSIST_TARGET=<radius>) ─────────────
# Raise A's spectral radius to the target at the loaded mode, hold everything
# else fixed, and run the rest of post-estimation into a separate tag folder
# (" persist<target>"). See PersistenceCounterfactual.jl for what it changes.
if haskey(ENV, "DD_PERSIST_TARGET")
    _tgt = parse(Float64, ENV["DD_PERSIST_TARGET"])
    _ll_before, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
    par_final, _pc = persistence_counterfactual(par_final, param_sizes, model_options;
        target = _tgt, keep_var = get(ENV, "DD_PERSIST_KEEPVAR", "1") == "1")
    _ll_after, _alarm = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
    @info "Persistence counterfactual: dist radius $(round(_pc.ρ0; digits = 3)) → $(round(_pc.ρ1; digits = 3)) (shift c = $(round(_pc.c; digits = 4))); " *
          "joint radius $(round(_pc.joint0; digits = 3)) → $(round(_pc.joint1; digits = 3)); innovation sds × $(round(_pc.g; digits = 3)); " *
          "log-lik $(round(_ll_before; digits = 1)) → $(round(_ll_after; digits = 1))$(_alarm ? "  ⚠ ALARM" : "")"
    report_mode_dynamics(par_final, param_sizes, model_options)
    _alarm && error("persistence counterfactual: the modified parameters are rejected by the likelihood — no point reconstructing")
    let sm_cf = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth = true)[1]
        xmax = maximum(abs, sm_cf.x_smoothed)
        xmax > 1e3 && error("persistence counterfactual: smoothed states reach $(round(xmax; sigdigits = 3)) — the smoother has degenerated (a near-singular state direction); reconstruction would be garbage. Try a lower target, or DD_PERSIST_KEEPVAR=0 if it was on.")
        @info "persistence counterfactual: smoothed path sane (max |x| = $(round(xmax; sigdigits = 3)))"
    end
    model_options.tag = tag * " persist$(ENV["DD_PERSIST_TARGET"])"
    tag = model_options.tag
    @info "outputs go to tag: $(tag)"
end
logV, alarm = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
@info "Log-likelihood at loaded parameters: $logV"


# ── Step 4: Export time series, validate, generate figures ───
@info "Exporting time series and generating validation plots..."
# include("Reconstruction.jl")
# include("CreateTimeSeries.jl")
# include("Validation.jl")
# include("ModelPrep.jl")
# include("plot_HANK.jl")

# ── Step 2b: Credible bands for the comparison figures ───────
# Posterior bands (parameter + factor uncertainty) drawn in the robustness-comparison
# panels (*w_bounds*); only needed when comparing (DD_COMPARE=1). DD_N_BAND_DRAWS draws.
_bands_dir = BASE_PATH * "/7_Results/$m_label" * "$tag" * "/from_mcmc/data/"
_post_file = BASE_PATH * "/posterior_draws/" * m_label * "_" * tag * ".jld2"
_bands_fresh = all(f -> isfile(_bands_dir * f) && isfile(_post_file) && mtime(_bands_dir * f) > mtime(_post_file),
                   ("SCF_bounds.jld2", "CEX_bounds.jld2"))
if _bands_fresh && get(ENV, "DD_REDO_BANDS", "0") != "1"
    @info "Credible bands: reusing SCF/CEX_bounds.jld2 (newer than the posterior; DD_REDO_BANDS=1 to redraw)"
elseif model_options.compare_to_other_est && !occursin("HANK", tag) && !skipstep("bands")
    try
        generate_credible_bounds(parse(Int, get(ENV, "DD_N_BAND_DRAWS", "100")), ["SCF", "CEX"],
            param_sizes, hyperpriors, meas_ind, Σ_ids, model_elements, obs_data, model_options,
            time_params, data_sources, tag)
    catch e
        @warn "credible bands failed (the w_bounds panels will be missing): $e"
    end
end

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

# Paper figure "Consumption Dynamics during Recessions" (RecessionPanels.jl)
try
    isfile(BASE_PATH * "/7_Results/$m_label" * "$tag" * "/from_mcmc/data/PSID_recession_groups_A non-diag_.csv") &&
        plot_recession_panels(BASE_PATH * "/7_Results/$m_label" * "$tag")
catch e
    @warn "recession panels failed: $e"
end

# ── Step 4b: Export posterior draws of the factors (optional) ─
# Reconstructs the smoothed factors at a sample of posterior θ-draws and
# writes data/synthetic/smoothed_factor_draws.csv (+ a percentile-band file).
# Heavy: runs the Kalman smoother once per draw. Set DD_EXPORT_DRAWS=0 to skip,
# or DD_N_DRAWS to change the number of draws (default 200).
# A tag whose loadings came from run_kalman_em.jl (or any mode-only tag) has no
# chains: skip with a note rather than abort the rest of post-estimation.
_draws_file = BASE_PATH * "/posterior_draws/" * m_label * "_" * tag * ".jld2"
if skipstep("draws")
    nothing
elseif get(ENV, "DD_EXPORT_DRAWS", "1") != "0" && isfile(_draws_file)
    @info "Exporting posterior factor draws..."
    n_draws = parse(Int, get(ENV, "DD_N_DRAWS", "200"))
    export_factor_draws(param_sizes, hyperpriors, Σ_ids, model_elements,
                        model_options, time_params; n_draws=n_draws)
    summarize_factor_draws()
    @info "Posterior factor draws exported."
elseif get(ENV, "DD_EXPORT_DRAWS", "1") != "0"
    @info "No posterior-draws file for this tag ($(basename(_draws_file))) — factor-draw export skipped (mode-only run)"
end

# ── Step 5: Correlation tables ────────────────────────────────
@info "Generating correlation tables..."
type = "from_mcmc"
# Empirical-only tables: they read correlations_dict_cycle_{SCF,CEX}.jld2 and
# the SCF external comparisons, which only the empirical plotting path writes —
# a HANK replica run has neither (crash 2026-09-09 on " HANK 1 stochastic trend").
# The correlations_dict_cycle files exist only with compare_to_other_est (DD_COMPARE=1),
# i.e. when the robustness runs are compared (tab:corr_outsample).
if occursin("HANK", tag)
    @info "HANK run: skipping empirical correlation tables (no SCF/CEX comparisons for replicas)."
elseif !model_options.compare_to_other_est
    @info "compare_to_other_est off (set DD_COMPARE=1 once the robustness runs exist): skipping the comparison correlation tables."
else
    try
        export_table_to_tex_with_strings(measures, :from_mcmc)
        generate_correlations_table_for_external_comparisons("SCF", measures, tag, type, "cycle")
    catch e
        @warn "comparison correlation tables failed: $e"
    end
end

# Cross-conditional averaged correlation table, averaged over all economies.
# Generated once, when the LAST economy's post-estimation runs (needs every
# economy's correlations file to exist).
if occursin("HANK", tag)
    economy_number = parse(Int, hank_economy(tag))
    # HANK_TABLE_ECONS: economies averaged in the table, "1-10" (default) or e.g. "1";
    # the table is built when the LAST of them finishes post-estimation.
    _te = split(get(ENV, "HANK_TABLE_ECONS", "1-10"), "-")
    table_econs = parse(Int, _te[1]):parse(Int, _te[end])
    if economy_number == last(table_econs)
        generate_averaged_hank_avg_corr_table(
            table_econs,
            ["consum", "income", "wealth"],
            "from_mcmc";
            data_sources = ["c", "a", "d"],
            tag = tag,
        )
    end
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
# shared with Steps 7/9 — top-level bindings; the `global` assignments inside
# the try blocks write them (a `local` declaration here conflicts with those)
Φ = nothing; Ω = nothing; r = 0; q = 0
if !skipstep("fevd")
try
    r_dist = param_sizes[1][1]
    q_agg = param_sizes[2][2]

    A, B_mat, C, D, Ω_var, Ω_corr, Σ = matrisize(st_core_params(par_final, param_sizes), param_sizes)
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

    # the observable mapping reads one survey's loadings: PSID, or the PSID replica in HANK
    fevd_data = occursin("HANK", tag) ? "HANK a $(hank_economy(tag))" : "PSID"
    tbl = fevd_dist_vs_agg(model_elements, model_options, obs_data, Φ_sub, Ω;
        r, q, horizon=20, factor_names=nothing, shock_order=:agg_first, data_tag=fevd_data)
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
end  # fevd

# ── Step 7: Historical decomposition (hd_recessions_f*.pdf) ───
@info "Computing historical decomposition..."
if !skipstep("hd")
try
    smoother_res, _, _ = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options; smooth=true)
    # The smoother's state is [f_t, f_{t-1}, f_{t-2}, f_{t-3}, a_t] (4r+q); the decomposition
    # works on the current-period block [f_t, a_t] (r+q), where the innovations live.
    ids_hd = vcat(1:r, 4r+1:4r+q)     # (ids_sub / Φ_sub of Step 6 are local to its try block)
    hd = historical_decomp_factors_blockchol(Φ[ids_hd, ids_hd], r, q, smoother_res.dε_smoothed[ids_hd, :], smoother_res.x_smoothed[ids_hd, :], Ω;
        splitting=:group, shock_order=:agg_first)
    @info "Historical decomposition: max reconstruction error $(hd.maxerr)"

    dts_hd = QuarterlyDate(tmin["year"], tmin["quarter"]):Quarter(1):QuarterlyDate(tmax["year"], tmax["quarter"])
    hd_dir = results_dir * "/plots/historical_decomposition"
    mkpath(hd_dir)
    make_hd_tables(hd.cube, hd.order, hd.ids, year.(dts_hd), quarter.(dts_hd);
        make_recession_plots=!occursin("HANK", tag), out_dir=hd_dir)   # US-recession panels need real dates; HANK economies are simulated
    @info "HD recession plots → $hd_dir"
catch e
    @warn "Historical decomposition failed" exception=(e, catch_backtrace())
end
end  # hd

# ── Step 8: Anatomy — information & interpolation shares ──────
@info "Computing observation-weight anatomy (information shares)..."
if !skipstep("anatomy")
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
    A2, B2, C2, D2, Ωv2, Ωc2, _ = matrisize(st_core_params(par_final, param_sizes), param_sizes)
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
end  # anatomy

# (The consumption-across-recessions panels are produced in Stata, not here.)

# ── Step 9: Out-of-sample forecasts (fig: recon_missing1) ─────
# If HANK do not run
if !occursin("HANK", tag) && !skipstep("forecasts")
    @info "Running out-of-sample forecasts (SCF iterative + CEX extensive)..."
    try
        how_much = 1
        perform_forecast("SCF", par_final, param_sizes, hyperpriors, meas_ind, Σ_ids, how_much,
            obs_data, model_options, model_elements, time_params, user_t, func_data,
            kind_of_plots, ["iterative"])
    catch e
        @warn "SCF iterative forecast failed" exception=(e, catch_backtrace())
    end
    # real-time version: everything dated after the dropped wave removed (DD_NOWCAST=0 skips)
    if get(ENV, "DD_NOWCAST", "1") == "1"
        try
            perform_forecast("SCF", par_final, param_sizes, hyperpriors, meas_ind, Σ_ids, 1,
                obs_data, model_options, model_elements, time_params, user_t, func_data,
                kind_of_plots, ["iterative"]; nowcast = true)
        catch e
            @warn "SCF nowcast failed" exception=(e, catch_backtrace())
        end
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
end

end  # run_full

# For the Python step of the Marvin job (5_Code/marvin/postestimation.sbatch): this run's results folder and measures.
let jobfile = BASE_PATH * "/logs/postestimation_" * get(ENV, "SLURM_JOB_ID", "local") * ".txt"
    mkpath(dirname(jobfile))
    open(jobfile, "w") do io
        println(io, BASE_PATH * "/7_Results/" * m_label * tag * "/from_mcmc/data")
        println(io, join(sort(measures), ","))
    end
end
@info "═══ Stages 3-5 finished ═══"
