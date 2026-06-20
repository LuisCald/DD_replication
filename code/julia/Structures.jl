# General helper that works even if start/stop aren't on Q1/Q4 boundaries
# This is for the CEX, every 4 years
function muted_quarters_between(start::QuarterlyDate, stop::QuarterlyDate)
    y0, y1 = year(start), year(stop)

    # keep every 4th year counting from the start year (y0)
    is_kept_year(y) = (y - y0) % 4 == 0

    # for partial edge years (if any)
    qstart(y) = (y == y0) ? quarter(start) : 1
    qstop(y) = (y == y1) ? quarter(stop) : 4

    muted_years = filter(y -> !is_kept_year(y), y0:y1)

    [QuarterlyDate(y, q)
     for y in muted_years
     for q in qstart(y):qstop(y)]
end

# Only necessary for HANK exercise
# GLOBAL_ECON = "8"
# GLOBAL_ECON = get(ENV, "HANK_ECON", "1")
# println("Running with GLOBAL_ECON = $GLOBAL_ECON")


# File of Structures 
function retrieve_data_files()
    local files::Dict
    base_path = DATA_PROCESSING * "/"

    # For HANK exercise, we have different files for each economy, so we need to specify the economy in the file names.
    # files = Dict(
    #     "HANK a $(GLOBAL_ECON)" => joinpath(base_path, "HANK_PSID_$(GLOBAL_ECON).csv"),
    #     "HANK b $(GLOBAL_ECON)" => joinpath(base_path, "HANK_CPS_$(GLOBAL_ECON).csv"),
    #     "HANK c $(GLOBAL_ECON)" => joinpath(base_path, "HANK_CEX_$(GLOBAL_ECON).csv"),
    #     "HANK d $(GLOBAL_ECON)" => joinpath(base_path, "HANK_SCF_$(GLOBAL_ECON).csv"),
    # )

    # For the generation of main results
    files = Dict(
    "SCF" => joinpath(base_path, "SCF.csv"),
    "PSID" => joinpath(base_path, "PSID.csv"),
    "CEX" => joinpath(base_path, "CEX.csv"),
    "CPS" => joinpath(base_path, "CPS.csv"),
    "CPS2" => joinpath(base_path, "CPS2.csv"),
    "SIPP1" => joinpath(base_path, "SIPP1.csv"),
    "SIPP2" => joinpath(base_path, "SIPP2.csv"),
    "SIPP3" => joinpath(base_path, "SIPP3.csv"),
    )

    return files
end


function retrieve_aggregate_data(sheet)
    local aggregate_data::DataFrame
    base_path = DATA_PROCESSING * "/"
    
    # Read as .csv if .xlsx fails
    # aggregate_data = CSV.read(joinpath(base_path, "HANK_shocks_economy_$(GLOBAL_ECON).csv"), DataFrame)
    aggregate_data = DataFrame(XLSX.readtable(joinpath(base_path, "aggregates_HHs_NPs.xlsx"), sheet, header=true,))
    
    return aggregate_data

end


function retrieve_rgdp()
    local aggregate_data
    base_path = DATA_PROCESSING * "/"

    aggregate_data = DataFrame(XLSX.readtable(joinpath(base_path, "inflation_corrected_correction_series.xlsx"), "data", header=true,))
    # aggregate_data = CSV.read(joinpath(base_path, "HANK_truth_$(GLOBAL_ECON).csv"), DataFrame)

    return aggregate_data
end


function retrieve_data(files::Dict)
    data = Vector{DataFrame}(undef, length(keys(files)))
    df_names = String[]

    for (i, k) in enumerate(sort(collect(keys(files))))
        # data[i] = XLSX.readxlsx(files[k])
        push!(df_names, k)
        data[i] = CSV.read(files[k], DataFrame)
    end
    return (data=data, df_names=df_names)
end


# Estimator and prior families. Only `SeriesEstimator` is active in the
# published runs. `HistogramEstimator` and `KernelEstimator` are scaffolding
# for alternative copula/quantile estimators referenced in some dispatch
# branches but never instantiated in the main pipeline.
abstract type AbstractEstimator end
abstract type AbstractPrior end


"""
    ObservedData

Inputs to the model: the raw microdata files, aggregate macro series, and
per-household aggregate "correction" series. All fields are populated by
calling the helpers in `DataConstructor.jl`; users typically don't construct
this themselves — use the global `obs_data = ObservedData()` instead.
"""
@with_kw struct ObservedData{S<:String,D<:DataFrame,NT<:NamedTuple}
    files::Dict{S,S} = retrieve_data_files()                    # dataset → CSV path
    agg_data::D = retrieve_aggregate_data("stationary_series")   # stationary macro series
    gdp_series::D = retrieve_rgdp()                              # per-HH aggregates (consum/income/wealth)
    df_vec::NT = retrieve_data(files)                            # loaded microdata, one per survey
end


"""
    HistogramEstimator
    KernelEstimator

Scaffolding for non-Series copula/quantile estimators. **Not active in the
current runs** — kept so dispatch on `typeof(estimator) <: HistogramEstimator`
in `DataConstructor.jl`/`ModelPrep.jl` compiles, in case someone wants to
revive the histogram or kernel path. Use `SeriesEstimator` for everything.
"""
@with_kw mutable struct HistogramEstimator{I<:Integer,S<:String} <: AbstractEstimator
    grid_pcf::I
    grid_cop::I
    grid_type_pcf::S
    grid_type_cop::S
end

@with_kw mutable struct KernelEstimator{I<:Integer,S<:String} <: AbstractEstimator
    grid_pcf::I
    grid_cop::I
    grid_type_pcf::S
    grid_type_cop::S
end


"""
    SeriesEstimator(grid_pcf, grid_cop, integral_pcf_grid, integral_cop_grid)

Active estimator for the paper. Distributions are projected onto orthonormal
Legendre polynomials on [0,1]:

* `grid_pcf`  — number of polynomial orders for each marginal quantile
                 function ξ (so the max polynomial order is `grid_pcf - 1`).
* `grid_cop`  — number of polynomial orders per dimension for the copula κ.
                 The full copula tensor has `grid_cop^D` coefficients
                 before the "immutable" leading rays are removed.
* `integral_pcf_grid` — discretization of the post-evaluation quantile grid
                        (used when exporting decile averages).
* `integral_cop_grid` — discretization of the post-evaluation copula grid
                        (the size of the `ciw_*` 3-D output tensor).

Published runs use `grid_pcf = grid_cop = 12` (polynomial orders 0..11) and
`integral_*_grid = 10` (decile output).
"""
@with_kw mutable struct SeriesEstimator{I<:Integer} <: AbstractEstimator
    grid_pcf::I             # polynomial orders for ξ; max order = grid_pcf - 1
    grid_cop::I             # polynomial orders per dim for κ; max order = grid_cop - 1
    integral_pcf_grid::I    # output grid for evaluated quantiles (e.g., deciles)
    integral_cop_grid::I    # output grid for evaluated copula density (e.g., 10×10×10)
end


"""
    ModelOptions

Every knob the user typically touches when configuring a model run.

The defaults reproduce the paper's baseline. The fields users most commonly
edit are:

* `tag`         — string appended to the output folder (e.g.,
                  `"7_Results/<measures>" * tag * "/..."`). Change this when
                  you start a new experiment so it doesn't overwrite an
                  older run. A leading space is conventional.
* `measures`    — which household variables to model jointly. Currently
                  always `["consum", "income", "wealth"]` for the paper.
* `lags` / `agg_lags`
                — autoregressive depth of the state and aggregate factors
                  (1 / 4 in the paper). Increasing these makes the state
                  vector and parameter space larger.
* `number_of_dfs`
                — number of distributional factors retained from PCA. The
                  paper uses 8 (explains ~99% of business-cycle variation).
* `blind_to`    — `Dict("dataset" => ["measure"...])`. Tells the model to
                  ignore a measure in a specific dataset (e.g., useful for
                  counterfactual runs that mute one signal).
* `atom_measures`
                — measures with a non-negligible point mass at zero
                  (e.g. `["stocks"]`). Switches that measure to the two-part
                  treatment: a participation scalar `π_t` plus a conditional
                  Legendre quantile fit on the strictly-positive subsample.
                  Empty (default) reproduces the paper exactly. See
                  `doc/stocks_atom_design.md`.
* `data_to_mute`
                — `Dict("dataset" => Vector{QuarterlyDate})` of survey waves
                  to drop from the smoother. Used by the omitted-wave
                  validation experiments in Section 4.3 of the paper.
* `estimator`   — `SeriesEstimator` instance. Bump `grid_pcf`/`grid_cop` to
                  use higher-order polynomial expansions.

Fields not listed above set up estimation-pipeline machinery and rarely
need tweaking. Search `_archive/` history for tag conventions used in
prior model variants.
"""
@with_kw mutable struct ModelOptions{AE<:AbstractEstimator,AP<:AbstractPrior,B<:Bool,S<:String,I<:Integer,VS<:Vector{String},D<:Dict,DS<:Dict{String,String}}
    # ─── Estimator and prior ──────────────────────────────────────────────
    estimator::AE = SeriesEstimator(grid_pcf=11 + 1, grid_cop=11 + 1,
                                    integral_pcf_grid=10, integral_cop_grid=10)
    prior::AP = Minnesota(hyperparameters=[0.05, 0.1, 0.5, 0.1, 2.0, 0.9, 0.9])

    # ─── What and how to model ────────────────────────────────────────────
    measures::VS = sort(["consum", "wealth", "income"])  # jointly-modeled measures
    number_of_dfs::I = 8                                  # # distributional factors retained from PCA
    estimation_object::S = "copulas and percentile functions"
    case::S = "A non-diag"                                # state-eq covariance pattern: "diag" / "A non-diag" / "A, Σ non-diag"
    information::S = "partial"                            # observation set: "full" or "partial" (default)
    aggregate_rep::Symbol = :as_states                    # aggregates enter as states (:as_states) or inputs (:as_inputs)

    # ─── Time-series structure ────────────────────────────────────────────
    lags::I = 1                                           # state-eq AR depth
    agg_lags::I = 4                                       # aggregate-factor AR depth
    freq::I = 4                                           # output frequency (4 = quarterly)
    agg_freq::I = 4                                       # frequency of aggregate inputs
    constant::B = false                                   # include a deterministic time + quadratic trend in state eq

    # ─── Measurement error specification ──────────────────────────────────
    measurement_error::S = "one per object, per dataset"
    errors_process::S = "one per object, per dataset"
    pre_multiply::B = true                                # premultiply observation eq by Σ_j^{-1/2}

    # ─── PCA / projection details ─────────────────────────────────────────
    pca_perspective::S = "frequentist"                    # PCA fit perspective ("frequentist" or "bayesian")
    best_aggs::B = false                                  # use the curated "best aggregates" subset
    collapse::B = true                                    # collapse identical aggregates across blocks (memory)

    # ─── Data treatment ───────────────────────────────────────────────────
    equivalized::B = false                                # OECD-equivalize income/consumption/wealth
    bottom_coded::Vector{Any} = []                        # variables to floor at a lower bound
    atom_measures::Vector{String} = String[]              # semicontinuous measures with a point mass at 0 (e.g. ["stocks"]); enables the two-part / hurdle treatment. Empty = baseline behavior. See doc/stocks_atom_design.md
    participation_link::Symbol = :logit                   # link for the participation scalar π_t carried alongside the Legendre coefficients of an atom measure (:logit keeps reconstructed π in [0,1]). Inert unless atom_measures is nonempty
    rm_seasonality::B = true                              # X-13 seasonal adjust applicable series
    data_cutoffs::DS = Dict("begin" => "", "end" => "")   # restrict the time index (extensive margin)
    data_to_mute = Dict("begin" => "", "end" => "")       # drop specific waves; see kwarg comments above
    logit_transform::B = false                            # (legacy; not active)
    blind_to::D = Dict()                                  # dataset → measures to ignore, e.g. Dict("CEX" => ["wealth"])

    # ─── Output / experiment management ───────────────────────────────────
    # tag::S = " additional factors"                        # appended to result folder (note the leading space)
    tag::S = " additional factors II"
    compare_to_other_est::B = false                       # produce cross-model comparison tables
    plot_proof::B = false                                 # also write proof-of-concept figures (Figure 4/5)
end


# ─── Tag / `data_to_mute` recipes used in past runs ──────────────────────────
# Useful when reproducing a specific experiment:
#   tag = " additional factors"
#       baseline (8 distributional factors); default in this file
#   tag = " 6 factors" / " 7 factors"
#       fewer distributional factors retained from PCA (`number_of_dfs = 6/7`)
#   tag = " excluding housing cycle wealth"
#       set `data_to_mute = Dict("SCF" => muted_quarters_between(
#           QuarterlyDate(2004, 1), QuarterlyDate(2009, 4)))`
#   tag = " excluding recent 20 quarters"
#       data_to_mute spans QuarterlyDate(2020, 1) → QuarterlyDate(2024, 1)
#   tag = " every 4 years"
#       data_to_mute = Dict("CEX" => muted_quarters_between(
#           QuarterlyDate(1984, 1), QuarterlyDate(2021, 4)))  with stride 4
#
# When introducing a new tag, sanity-check `tag`, `data_to_mute`, and
# `compare_to_other_est` together — they tend to be coupled.

"""
    Minnesota(hyperparameters=[κ_overall, κ_cross, κ_lag, κ_exo, κ_decay, κ_persist_own, κ_persist_cross])

Minnesota-style shrinkage prior for the state-equation coefficients `(A, B)`.
The 7 hyperparameters control overall tightness, cross-variable shrinkage,
lag decay, exogenous-block tightness, decay rate, and own/cross persistence
priors respectively. Adjust via the `prior` field of `ModelOptions`.
"""
@with_kw mutable struct Minnesota{VF<:Vector{Float64}} <: AbstractPrior
    hyperparameters::VF = [0.2, 0.3, 0.01, 5, 2.0, 0.90, 0.90]
end

"""
    TimeParams

Time-index bookkeeping built from the data: `tmin`/`tmax` are dictionaries
with `"year"` / `"quarter"` keys, `year_vec` is per-dataset coverage, and
`tot_periods` is the total number of quarters spanned. Populated by
`DataConstructor.jl`; users rarely construct directly.
"""
mutable struct TimeParams{D<:Dict,VV<:Vector{Vector{Int64}},I<:Int64,VS<:Vector{String}}
    year_vec::VV
    tmin::D
    tmax::D
    tot_years::I
    tot_periods::I
    time_dict::D
    freq_type::VS
end

"""
    StateSpaceModel

Container for everything the Kalman filter / smoother needs:
measurement vector by dataset, period-specific selection matrices, controls,
the PCA projection used to map between latent factors and coefficients,
and assorted dimensions. Built by `ModelPrep.jl`.
"""
mutable struct StateSpaceModel{A<:Array{Float64},V<:Vector{Float64},VV<:Vector{Vector{Float64}},M<:Matrix{Float64},VM<:Vector{Matrix{Float64}},I<:Int64}
    #    years::I
    MV::VM            # Vector of measurements, split by dataset 
    y::M              # Matrix of all measurements 
    G::VM             # Vector of selection matrices, one per period
    Gⱼ::VM             # Selection matrix for the j-th measurement
    u::M
    pcs::M
    means::VV
    stds::V
    proj::M
    u_proj::M
    factor_count::I
    agg_count::I
    n_less_than_one::I
    βs::A
    trend::VM
    boot_noise_processes
end

mutable struct FunctionalData{D<:Dict,VS<:Vector{String}}
    func_dict::D
    confidence_intervals::D
    year_vec
    data_sources::VS
end

# Structure for defining the prior 
#mutable struct Prior{VS<:Vector{Distribution{Multivariate, Continuous}}, V<:Vector{AbstractMatrix{Float64}}}
mutable struct Prior
    priors
    param_vector
end


"""
    SmootherResults

Output of the Kalman filter / smoother used in the post-estimation pipeline.
Holds filtered, updated, and smoothed states with their covariances, plus
the smoothed innovations `dε_smoothed` (used in the FEVD computation).
"""
struct SmootherResults{MF<:Matrix{Float64},VMF<:Vector{Matrix{Float64}}}
    x_filtered::MF
    sigma_filtered::VMF
    x_updated::MF
    sigma_updated::VMF
    x_smoothed::MF
    sigma_smoothed::VMF
    cross_covariances::VMF
    dε_smoothed::MF
end


# Canonical instances. `model_options` carries every knob the user typically
# touches; `obs_data` loads the raw survey + aggregate data.
#
# Experiment variants live in `examples/Structures_<name>.jl`. Select one by
# setting the `DD_EXAMPLE` environment variable before launching Julia, e.g.
#     DD_EXAMPLE=stocks julia run_estimation.jl
# A variant file is plain Julia that defines `const model_options` and
# `const obs_data` with whatever measures / data files / options it needs.
# With `DD_EXAMPLE` unset (the default) the published baseline below runs
# unchanged.
const DD_EXAMPLE = get(ENV, "DD_EXAMPLE", "")

if isempty(DD_EXAMPLE)
    const model_options = ModelOptions()
    const obs_data = ObservedData()
else
    let example_file = joinpath(@__DIR__, "examples", "Structures_$(DD_EXAMPLE).jl")
        isfile(example_file) || error("DD_EXAMPLE=\"$(DD_EXAMPLE)\" but $(example_file) does not exist.")
        @info "Loading experiment configuration: $(example_file)"
        include(example_file)
    end
end

@assert (@isdefined model_options) "examples/Structures_$(DD_EXAMPLE).jl must define `const model_options`."
@assert (@isdefined obs_data) "examples/Structures_$(DD_EXAMPLE).jl must define `const obs_data`."

