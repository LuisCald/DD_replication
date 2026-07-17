# ============================================================================
# ObservationWeights.jl — exact source decomposition of the smoothed states.
#
# Implements the observation-weight decomposition of Koopman & Harvey (2003,
# "Computing observation weights for signal extraction and filtering", JEDC
# 27(7), 1317-1333) by exploiting the exact linearity of the Kalman smoother
# rather than re-deriving their recursions inside our filter:
#
#   With FIXED parameters and a FIXED missingness pattern, the smoothed state
#   is affine in the observations,  x̂ = c + Σ_b W_b y_b,  over observation
#   blocks b (PSID, SCF, CEX, CPS, SIPP..., aggregates). Running the smoother
#   with all blocks' VALUES zeroed except block b (same NaN pattern → same
#   gains) yields c + W_b y_b; the all-zeros run yields c (the prior /
#   state-equation / deterministic-input term). Contributions are exact and
#   additive:  x̂_full = c + Σ_b (x̂_only-b − c),  which we verify numerically.
#
# This is the engine for the "anatomy of the synthetic data" exercise:
# information shares by source × time (R1-1b / R3-1). Everything here is at
# the FACTOR level; mapping to coefficient space is the fixed linear operator
# D_σ Γ̂ and can be applied to each contribution afterwards.
#
# Usage sketch (post-estimation, fixed parameters — runs in minutes):
#
#   include("DistributionalDynamics.jl")            # or the postestimation setup
#   const func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
#   (param_vector, param_sizes, priors, meas_ind, Σ_ids) = set_params(model_elements, time_params, model_options)
#   par_final = get_param_vector(measures, kind_of_plots, label, data_cutoffs, tag)
#   include("ObservationWeights.jl")
#   dec = observation_weight_decomposition(model_elements, obs_data.df_vec.df_names,
#                                          par_final, param_sizes, priors, Σ_ids, model_options)
#   dec.check            # max |full − (prior + Σ contributions)| — should be ~1e-10
#   dec.contributions    # Dict: source name → (state-dim × T) contribution to x_smoothed
#   dec.prior            # the state-equation / deterministic term c
# ============================================================================

"""
    block_ranges(model_elements, df_names) -> Vector{Pair{String,UnitRange{Int}}}

Row ranges of each dataset block inside `model_elements.y` (stacked as
`vcat(MV...)` then aggregates). Errors if the stacking does not line up
(e.g., a collapsed/whitened representation with changed dimensions).
"""
function block_ranges(model_elements, df_names)
    sizes = [size(M, 1) for M in model_elements.MV]
    offsets = cumsum(vcat(0, sizes))
    blocks = Pair{String,UnitRange{Int}}[]
    for j in eachindex(sizes)
        push!(blocks, String(df_names[j]) => (offsets[j]+1):offsets[j+1])
    end
    nrow_y = size(model_elements.y, 1)
    n_data = offsets[end]
    if nrow_y == n_data + model_elements.agg_count && model_elements.agg_count > 0
        push!(blocks, "aggregates" => (n_data+1):nrow_y)
    elseif nrow_y != n_data
        error("block_ranges: y has $nrow_y rows but MV blocks sum to $n_data " *
              "(+ agg_count = $(model_elements.agg_count)). The measurement vector " *
              "appears collapsed/transformed; block-zeroing is not valid on it as is.")
    end
    return blocks
end

"""
    zeroed_copy(model_elements, keep::Vector{UnitRange{Int}})

Copy of `model_elements` whose observation VALUES are set to zero outside the
row ranges in `keep`, preserving the NaN missingness pattern exactly (so the
filter gains, G matrices, and Σ handling are identical to the full run).
"""
function zeroed_copy(me, keep::Vector{UnitRange{Int}})
    y2 = copy(me.y)
    keeprows = falses(size(y2, 1))
    for r in keep
        keeprows[r] .= true
    end
    @inbounds for i in axes(y2, 1)
        keeprows[i] && continue
        for t in axes(y2, 2)
            if !isnan(y2[i, t])
                y2[i, t] = 0.0
            end
        end
    end
    return StateSpaceModel(me.MV, y2, me.G, me.Gⱼ, me.u, me.pcs, me.means,
                           me.stds, me.proj, me.u_proj, me.factor_count,
                           me.agg_count, me.n_less_than_one, me.βs, me.trend,
                           me.boot_noise_processes)
end

"""
    smoothed_states(me, par, param_sizes, hyperpriors, Σ_ids, model_options)

Run the smoother at fixed parameters; return `x_smoothed` (state-dim × T).
"""
function smoothed_states(me, par, param_sizes, hyperpriors, Σ_ids, model_options)
    out, _, alarm = likeli(me, par, param_sizes, hyperpriors, Σ_ids, model_options; smooth=true)
    alarm && error("smoothed_states: likeli returned alarm at the given parameters.")
    return out.x_smoothed
end

"""
    observation_weight_decomposition(model_elements, df_names, par, param_sizes,
                                     hyperpriors, Σ_ids, model_options;
                                     sources = nothing)

Exact additive decomposition of the smoothed state path by observation source.
Returns a NamedTuple with fields:
  `full`           x_smoothed from all data
  `prior`          the state-equation / deterministic-input term (all values zeroed)
  `contributions`  Dict(source => contribution matrix), contribution := x̂_only-source − prior
  `check`          max abs residual of  full − (prior + Σ contributions)
`sources` restricts to a subset of block names (default: all blocks).
"""
function observation_weight_decomposition(model_elements, df_names, par, param_sizes,
                                          hyperpriors, Σ_ids, model_options;
                                          sources=nothing)
    blocks = block_ranges(model_elements, df_names)
    if sources !== nothing
        blocks = [b for b in blocks if first(b) in sources]
    end

    x_full  = smoothed_states(model_elements, par, param_sizes, hyperpriors, Σ_ids, model_options)
    x_prior = smoothed_states(zeroed_copy(model_elements, UnitRange{Int}[]),
                              par, param_sizes, hyperpriors, Σ_ids, model_options)

    contributions = Dict{String,Matrix{Float64}}()
    for (name, rng) in blocks
        x_b = smoothed_states(zeroed_copy(model_elements, [rng]),
                              par, param_sizes, hyperpriors, Σ_ids, model_options)
        contributions[name] = x_b .- x_prior
    end

    recon = copy(x_prior)
    for v in values(contributions)
        recon .+= v
    end
    check = maximum(abs.(x_full .- recon))

    return (full=x_full, prior=x_prior, contributions=contributions, check=check)
end

"""
    information_shares(dec; states = :, eps = 1e-12)

Absolute-weight shares by source for each state and period:
share_b(i,t) = |contrib_b(i,t)| / (|prior(i,t)| + Σ_b |contrib_b(i,t)|).
Weights can be negative (GLS weights), so shares of absolute contributions are
reported — state the convention wherever these are plotted. Returns
Dict(source => share matrix) including a "state dynamics" entry for the prior.
"""
function information_shares(dec; eps=1e-12)
    denom = abs.(dec.prior)
    for v in values(dec.contributions)
        denom .+= abs.(v)
    end
    denom .= max.(denom, eps)
    shares = Dict{String,Matrix{Float64}}()
    for (k, v) in dec.contributions
        shares[k] = abs.(v) ./ denom
    end
    shares["state dynamics"] = abs.(dec.prior) ./ denom
    return shares
end
