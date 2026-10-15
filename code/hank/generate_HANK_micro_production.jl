"""
Mainboard for the baseline example of the BASEforHANK package, no estimation.
"""

using PrettyTables, Printf;

## ------------------------------------------------------------------------------------------
## Header: set up paths, pre-process user inputs, load module
## ------------------------------------------------------------------------------------------

root_dir = replace(Base.current_project(), "Project.toml" => "");
cd(root_dir);

# set up paths for the project.
# NB: pinned explicitly rather than via @__DIR__ so the script ALSO works when
# pasted into / include()d from a REPL (there @__DIR__ is just pwd(), which
# used to send the preprocessor looking for Model/ in the wrong place).
example_dir = joinpath(root_dir, "examples", "baseline_micro");
paths = Dict(
    "root" => root_dir,
    "src" => joinpath(root_dir, "src"),
    "bld" => joinpath(root_dir, "bld"),
    "src_example" => example_dir,
    "bld_example" => joinpath(root_dir, "bld", "baseline_micro") * "_noestim",
);

# create bld directory for the current example
mkpath(paths["bld_example"]);

# pre-process user inputs for model setup
include(paths["src"] * "/Preprocessor/PreprocessInputs.jl");
include(paths["src"] * "/BASEforHANK.jl");
using .BASEforHANK;

# set BLAS threads to the number of Julia threads, prevents grabbing all
BASEforHANK.LinearAlgebra.BLAS.set_num_threads(Threads.nthreads());

## ------------------------------------------------------------------------------------------
## Initialize: set up model parameters
## ------------------------------------------------------------------------------------------

m_par = ModelParameters();
e_set = BASEforHANK.e_set;

@set! m_par.ξ = 4.0;
@set! m_par.γ = 2.0;
@set! m_par.β = 0.98255;
@set! m_par.λ = 0.065;
@set! m_par.ρ_h = 0.98;
@set! m_par.σ_h = 0.12;
@set! m_par.ι = 0.0625;
@set! m_par.ζ = 0.00022222222222222223;
@set! m_par.α = 0.318;
@set! m_par.δ_0 = 0.021500000000000002;
@set! m_par.δ_s = 0.7055720197078786;
@set! m_par.ϕ = 1.9409223183717077;
@set! m_par.μ = 1.1;
@set! m_par.κ = 0.1456082664986374;
@set! m_par.μw = 1.1;
@set! m_par.κw = 0.23931075416274708;
@set! m_par.Tlev = 1.0 + (1 - 0.8225);
@set! m_par.Tprog = 1.0 + 0.1022;
@set! m_par.RRB = 1.0;
@set! m_par.Rbar = 0.021778180864641117;
@set! m_par.ωΠ = 0.2;
@set! m_par.ιΠ = 0.016;
@set! m_par.shiftΠ = 0.7002848330469671;
@set! m_par.ρ_A = 0.9724112284399131;
@set! m_par.σ_A = 0.0015812471705012755;
@set! m_par.ρ_Z = 0.9978155269262137;
@set! m_par.σ_Z = 0.00600947811158941;
@set! m_par.ρ_ZI = 0.7637111671257767;
@set! m_par.σ_ZI = 0.0721141538701523;
@set! m_par.ρ_μ = 0.903740078830077;
@set! m_par.σ_μ = 0.01350860622318172;
@set! m_par.ρ_μw = 0.9057892147641305;
@set! m_par.σ_μw = 0.035058308969408175;
@set! m_par.ρ_s = 0.544722245741144;
@set! m_par.σ_Sshock = 0.6918558038597916;
@set! m_par.Σ_n = 28.879770107327673;
@set! m_par.ρ_R = 0.8030565250630299;
@set! m_par.σ_Rshock = 0.002306627917745612;
@set! m_par.θ_π = 2.0780841671981856;
@set! m_par.θ_Y = 0.21872568927661648;
@set! m_par.γ_B = 0.020131162775595176;
@set! m_par.γ_π = -2.1737350397931947;
@set! m_par.γ_Y = -0.4363130165391906;
@set! m_par.ρ_Gshock = 0.9682224473297878;
@set! m_par.σ_Gshock = 0.003761816459554433;
@set! m_par.ρ_τ = 0.4926482696848203;
@set! m_par.γ_Bτ = 3.293063617271948;
@set! m_par.γ_Yτ = -0.9207283604196101;
@set! m_par.ρ_P = 0.9194235885358465;
@set! m_par.σ_Tprogshock = 0.06865440038519788;
@set! m_par.γ_BP = 0.0;
@set! m_par.γ_YP = 0.0;
@set! m_par.γ_WP = 0.0;
@set! m_par.ρ_Rshock = 1.0e-8;
@set! m_par.ρ_Tprogshock = 1.0e-8;
@set! m_par.ρ_Sshock = 1.0e-8;

## ------------------------------------------------------------------------------------------
## Calculate Steady State and prepare linearization
## ------------------------------------------------------------------------------------------

# steady state at m_par
ss_full = call_find_steadystate(m_par);

# sparse DCT representation
sr_full = call_prepare_linearization(ss_full, m_par);

## ------------------------------------------------------------------------------------------
## Linearize the full model, find sparse state-space representation
## ------------------------------------------------------------------------------------------

lr_full = linearize_full_model(sr_full, m_par);

# ------------------------------------------------------------------------------------------
## Simulating data
## ------------------------------------------------------------------------------------------
using Random, DataFrames, CSV, StatsBase, Parameters, PeriodicalDates, Dates
using StatsBase: sample, Weights
Random.seed!(1234)

# 1) Choose which exogenous states get i.i.d. shocks each period.
#    Here I mirror your IRF order:
shock_syms = [:Z, :ZI, :μ, :μw, :A, :Rshock, :Gshock, :Tprogshock, :Sshock]

# Map those symbols to their state indices (these must be state positions in S_t)
exovars = [getfield(sr_full.indexes, s) for s in shock_syms]  # Vector{Int}

# 2) Build the vector of standard deviations for the shocks (same order as shock_syms)
#    This matches the naming convention in your m_par (σ_A, σ_Z, σ_Rshock, …).
stds = [getfield(m_par, Symbol("σ_", s)) for s in shock_syms]  # Vector{Float64}
init_val = copy(stds)

# 3) Simulation settings
T = 2700   # PRODUCTION: 15 chunks after burn-in (11 gave only 8 good; export the first 10 good)
# T = 1300   # BASIS CHECK: burnin + one chunk — truth-only run to compare raw vs
#          # *_basis truth columns (restore T = 2300 + the specs Dict after)
burnin = 1200    # dropped from outputs (keep at 1200: Z needs ~1000-1200q to reach ergodic variance)
nn_chunks = Int((T - burnin) / 100)    # single long economy (~3800 quarters)

# Surveys are optional.
# - Set `specs = nothing` to generate *truth only* (no survey samples).
# - Set `specs = :default` to use BASEtoolbox defaults.
# - Or pass a Dict to customize surveys (see below).
specs = nothing   # overwritten below (production)

# Order in which (potential) surveys are generated/exported.
# `generate_microdata` filters this down to the surveys actually present in `specs`.
survey_order = [:CEX, :CPS, :PSID, :SCF, :SIPP] # these names are arbitrary
# survey_order = [:PSID] # these names are arbitrary

# Truth is optional and changes the return shape.
# - :none   -> returns (shocks_vec, surveys)
# - :moments/:micro -> returns (shocks_vec, surveys, truth_vec)
truth_mode = :moments  # :none | :moments | :micro
truth_vec = nothing
measures = [:income, :wealth, :consum] # others :asset_income, :nonasset_income, :earnings, :rental_income

# Example custom specs (uncomment to enable surveys):
# BASIS CHECK: surveys disabled (specs stays `nothing` from above) — truth only.
# Restore this block for production runs.
str_shares = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.05, 0.04, 0.01]
specs = Dict(
    :CEX => (stride = 1, N = 6_000, vars = [:consum, :income]), #  stratify_by = [:consum, :income], strata_shares = str_shares
    :CPS => (
        stride = 4,
        N = 60_000,
        vars = [:income],
        start_quarter = 4,
        # strata_shares = str_shares,
    ),
    :SCF => (
        stride = 12,
        N = 5_000,
        vars = [:income, :wealth],
        start_quarter = 3,
        stratify_by = [:wealth, :income],
        strata_shares = str_shares,
    ),
    :PSID => (
        stride = 8,
        N = 9_000,
        vars = measures,
        start_quarter = 2,
        # stratify_by = [:wealth, :income, :consum],
        # strata_shares = str_shares,
    )
    )
specs[:SIPP] = BASEforHANK.PostEstimation.default_survey_specs()[:SIPP]

# SIPP replica ("sample E"): quarterly income cross-sections with wealth
# observed once per year, dated to Q4 (mirrors the real SIPP's Dec-31
# measurement; see the Q4-only rule in master_sipp_file.do). No wealth
# oversample — deliberate realism: the real SIPP misses the top tail.
# Reuse the canonical package spec so the Q4 predicate (`quarter(t) == 4`)
# is constructed in package scope, where PeriodicalDates.quarter resolves.

out = generate_microdata(
    exovars,
    shock_syms,
    lr_full.State2Control,
    lr_full.LOMstate,
    sr_full.XSS,
    sr_full.indexes;
    T = T,
    burnin = burnin,
    init_val = init_val,
    shock_scale = 1.0,
    comp_ids = sr_full.compressionIndexes,
    n_par = sr_full.n_par,
    λ = m_par.λ,
    m_par = m_par,
    # Use first-order (steady-state) linearized policies for shock-scale invariance.
    policy_mode = :linearized,
    no_entrepreneurs = false, # Remove in the long-run: can be set in input_parameters.jl
    truth_mode = truth_mode,
    truth_vars = measures,
    n_chunks = nn_chunks,  # generate extra chunks; bad ones are filtered below
    # Bin means: quintiles/deciles/ventiles/etc.
    truth_bin_counts = [5],
    truth_bin_shares = [[0.5, 0.4, 0.1]], # Optional: specify bin shares for uneven bins (must sum to 1)
    truth_cross_bin_shares = [[0.4, 0.4, 0.2]], # CROSS-conditional truth (<out>_by_<cond>_bot40/mid40/top20); marginals stay 50/40/10. An order-12 copula cannot resolve a 0.1-wide top window; for steep profiles (wealth as outcome) do not make these groups too granular (DD ModelOptions.cross_conditional_shares, 2026-09-21)
    # Optional explicit quantiles (can be large; e.g. percentiles):
    shock_clip = 3.0,
    # truth_aggregate = :decile,  # REMOVED: decile aggregation assigns whole grid points
    #   to groups via ceil(cum*10) — an integer threshold on the drifting marginal CDF.
    #   Fat cells flipping groups produced persistent ~0.8pp cliffs in top-share truth
    #   series (2005Q1/2009Q4/end-of-sample) and a -0.9pp level bias from group-mean
    #   coarsening of the tail. It also skipped the within-cell smearing, so truth and
    #   surveys described different populations. Full resolution + S=15 smearing instead.
    truth_aggregate = :none,
    truth_smear_points = 11,  # quadrature dial: artifact ~S³, so 11 is still ~10× finer
    #                         # than the old 5-point rule at ~half the cost/memory of 15
    specs = specs,
    survey_order = survey_order,
    fix_asset_prices = false, # Use steady-state asset prices in the microdata, for consistency with linearized policies.
    entrepreneur_scale = 2.5,
    copula_fix = :project,
);

# ------------------------------------------------------------------------------------------
# Post-filter and export
# ------------------------------------------------------------------------------------------
data_path = joinpath(paths["bld_example"], "simulated_data")

good_idx, bad_idx, bad_reasons = filter_chunks(out; max_ratio = 5.0)

@info "Chunk filter: $(length(good_idx)) good, $(length(bad_idx)) bad out of $(length(good_idx) + length(bad_idx))"
for (i, reason) in bad_reasons
    @info "  Chunk $i rejected: $reason"
end

# Hand-picked chunks (indices into good_idx), re-indexed 1, 2, 3, ...
length(good_idx) >= 10 || error("only $(length(good_idx)) good chunks; need 10")
export_selected_chunks(
    out,
    good_idx[1:10];
    survey_names = survey_order,
    dir = data_path,
    prefix = "HANK",
    truth_wide_nbins = 5,
    truth_wide_shares = [0.5, 0.4, 0.1],
    truth_wide_cross_shares = [0.4, 0.4, 0.2],   # must match truth_cross_bin_shares above
)
println("Finished exporting selected chunks.")

# # ------------------------------------------------------------------------------------------
# # Shock elasticity decomposition: which shocks drive distributional dynamics?
# # ------------------------------------------------------------------------------------------
# # OLS of truth quintile means on reconstructed shock states.
# # "var share" = fraction of quintile-mean variance explained by each shock.
# using Statistics, LinearAlgebra
# if !isempty(good_idx)
#     @info "Running shock elasticity decomposition on chunk $(good_idx[1])..."
#     var_shares, betas = shock_elasticity_decomp(
#         out, shock_syms, exovars, lr_full.LOMstate;
#         chunk_idx = 1, nlags=1
#     )
# end

# println('\a') # beep when done
