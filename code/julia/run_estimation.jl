# ─────────────────────────────────────────────────────────────
# run_estimation.jl — Stage 2: MCMC estimation
# ─────────────────────────────────────────────────────────────
#
# Usage (from repo root):
#   julia --project=code/julia/env code/julia/run_estimation.jl
#
# This script:
#   1. Loads all packages and source files via DistributionalDynamics.jl
#   2. Prepares functional data from survey microdata
#   3. Sets up parameters and priors
#   4. Runs black-box optimization + DIME sampler (MCMC)
#   5. Saves parameter vectors and chains to 7_Results/
#
# ─────────────────────────────────────────────────────────────

include(joinpath(@__DIR__, "DistributionalDynamics.jl"))

@info "═══ Stage 2: MCMC Estimation ═══"
@info "BASE_PATH = $BASE_PATH"

# ── Step 1: Prepare data ──────────────────────────────────────
@info "Preparing functional data..."
const func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
@info "Data preparation complete."

# ── Step 2: Set parameters and priors ─────────────────────────
@info "Setting parameters and priors..."
const (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)
@info "Parameters set. Dimension: $(length(param_vector))"

# ── Step 3: Run DIME sampler (black-box opt + MCMC) ───────────
niter = 400
bbo_opttime = length(param_vector) * 12 # seconds for black-box optimization
@info "Starting DIME sampler with $niter iterations..."
par_final = run_DIME_sampler(model_elements, niter, param_vector, param_sizes, priors, meas_ind, Σ_ids, model_options; bbo_opttime=bbo_opttime)
@info "Estimation complete."

@info "═══ Stage 2 finished ═══"
@info "═══ Stages 3-5: Post-estimation ═══"
@info "BASE_PATH = $BASE_PATH"

# ── Unpack options ────────────────────────────────────────────
@unpack measures, data_cutoffs, tag, case = model_options
label = "3D_$case"
m_label = measures_folder(measures)
kind_of_plots = :mcmc
opttag = "from_mcmc"

# ── Step 1: Prepare data ─────────────────────────────────────
@info "Preparing functional data..."
hyperpriors = priors[end-5:end]

SSM(par) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]
SSM(par, _) = -likeli(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)[1]

@unpack tmin, tmax = time_params
@unpack gdp_series = obs_data
@unpack data_sources = func_data
user_t = (deepcopy(tmin), deepcopy(tmax))

# ── Step 2: Load estimated parameters ────────────────────────
@info "Loading estimated parameters..."
logV, alarm = likeli(model_elements, par_final, param_sizes, hyperpriors, Σ_ids, model_options)
@info "Log-likelihood at loaded parameters: $logV"


# ── Step 4: Export time series, validate, generate figures ───
@info "Exporting time series and generating validation plots..."
include("Reconstruction.jl")
include("CreateTimeSeries.jl")
include("Validation.jl")
include("ModelPrep.jl")
include("plot_HANK.jl")

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

