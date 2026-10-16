function run_black_box_opt(SSM, param_vector, param_sizes, priors, measures; opttime::Int = length(param_vector) * 3, pop_size::Int = 200)
    step_ranges = define_step_ranges(param_sizes, priors, param_vector)
    res = bboptimize(SSM, param_vector; SearchRange=step_ranges, Method=:adaptive_de_rand_1_bin_radiuslimited, MaxTime=opttime, PopulationSize=pop_size, TraceMode=:compact, TraceInterval=60)
    return best_candidate(res)
end

# # OLD: default PopulationSize (50)
# function run_black_box_opt(SSM, param_vector, param_sizes, priors, measures; opttime::Int = length(param_vector) * 3)
#     step_ranges = define_step_ranges(param_sizes, priors, param_vector)
#     res = bboptimize(SSM, param_vector; SearchRange=step_ranges, Method=:adaptive_de_rand_1_bin_radiuslimited, MaxTime=opttime, TraceMode=:compact, TraceInterval=60)
#     return best_candidate(res)
# end


function define_step_ranges(param_sizes, priors, param_vector)
    # stochastic-trend dispatch (appended 9th block; logic in StochasticTrend.jl)
    length(param_sizes) == 9 && return st_define_step_ranges(param_sizes, priors, param_vector)

    step_ranges = Vector{Tuple{Float64,Float64}}(undef, length(param_vector))

    # # For A, B
    # for i in eachindex(priors[1].μ)
    #     step_ranges[i] = (priors[1].μ[i] - priors[1].Σ[i,i], priors[1].μ[i] + priors[1].Σ[i,i]) 
    # end
    # For A 
    l_A = prod(param_sizes[1])
    l_B = prod(param_sizes[2])
    l_C = prod(param_sizes[3])
    l_D = param_sizes[4][1]
    l_Ωf = param_sizes[1][1]
    l_Ωy = param_sizes[2][2]
    l_Ω_corr = param_sizes[6][1]
    l_Σ = param_sizes[7][1]
    l_H = param_sizes[8][1]

    for i in 1:l_A
        # step_ranges[i] = (-0.99, 0.99) 
        σ_a = priors[1].Σ[i, i]
        step_ranges[i] = (priors[1].μ[i] - 3 * σ_a, priors[1].μ[i] + 3 * σ_a)
    end

    # For B
    for i in (l_A+1):(l_A+l_B)
        σ_b = priors[1].Σ[i, i]
        step_ranges[i] = (priors[1].μ[i] - 3 * σ_b, priors[1].μ[i] + 3 * σ_b)
    end

    # For C
    for i in (l_A+l_B+1):(l_A+l_B+l_C)
        σ_c = priors[1].Σ[i, i]
        step_ranges[i] = (priors[1].μ[i] - 3 * σ_c, priors[1].μ[i] + 3 * σ_c)
    end

    # For D
    for i in (l_A+l_B+l_C+1):(l_A+l_B+l_C+l_D)
        σ_d = priors[1].Σ[i, i]
        step_ranges[i] = (priors[1].μ[i] - 3 * σ_d, priors[1].μ[i] + 3 * σ_d)
    end

    # For Ωf (priors[2] is a Vector{Normal}, one per factor, under persistence_prior = :per_factor)
    for (q, i) in enumerate((l_A+l_B+l_C+l_D+1):(l_A+l_B+l_C+l_D+l_Ωf))
        dΩf = priors[2] isa AbstractVector ? priors[2][q] : priors[2]
        step_ranges[i] = (-3 * dΩf.σ + dΩf.μ, 3 * dΩf.σ + dΩf.μ)
    end

    # For Ωy
    for (q, i) in enumerate((l_A+l_B+l_C+l_D+l_Ωf+1):(l_A+l_B+l_C+l_D+l_Ωf+l_Ωy))
        dΩy = priors[3] isa AbstractVector ? priors[3][q] : priors[3]   # per aggregate under :per_factor_agg
        step_ranges[i] = (-3 * dΩy.σ + dΩy.μ, 3 * dΩy.σ + dΩy.μ)
    end

    # For Ω_corr (unconstrained → tanh maps to correlations; tanh(3)=0.995, tanh(10)≈1 causes degeneracy)
    for (q, i) in enumerate((l_A+l_B+l_C+l_D+l_Ωf+l_Ωy+1):(l_A+l_B+l_C+l_D+l_Ωf+l_Ωy+l_Ω_corr))
        # # OLD: (-10, 10) — allows tanh saturation to ±1, trapping optimizer
        # step_ranges[i] = (-10, 10)
        step_ranges[i] = (-3, 3)
    end

    # For Σ
    for (q, i) in enumerate((l_A+l_B+l_C+l_D+l_Ωf+l_Ωy+l_Ω_corr+1):(l_A+l_B+l_C+l_D+l_Ωf+l_Ωy+l_Ω_corr+l_Σ))
        step_ranges[i] = (-3 * priors[4+q].σ + priors[4+q].μ, 3 * priors[4+q].σ + priors[4+q].μ)
    end

    # For H
    for (q, i) in enumerate((l_A+l_B+l_C+l_D+l_Ωf+l_Ωy+l_Ω_corr+l_Σ+1):(l_A+l_B+l_C+l_D+l_Ωf+l_Ωy+l_Ω_corr+l_Σ+l_H))
        try
            step_ranges[i] = (-3 * priors[4+l_Σ+q].σ + priors[4+l_Σ+q].μ, 3 * priors[4+l_Σ+q].σ + priors[4+l_Σ+q].μ)
        catch e
            # Uniform distribution
            step_ranges[i] = (priors[4+l_Σ+q].a, priors[4+l_Σ+q].b)
        end
    end

    return step_ranges
end
