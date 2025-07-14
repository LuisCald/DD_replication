function run_black_box_opt(SSM, param_vector, param_sizes, priors, measures)
    step_ranges = define_step_ranges(param_sizes, priors, param_vector)
    opttime = param_sizes[1][1] * 100
    res = bboptimize(SSM, param_vector; SearchRange=step_ranges, Method=:adaptive_de_rand_1_bin_radiuslimited, MaxTime=opttime, TraceMode=:compact, TraceInterval=60)
    return best_candidate(res)
end

function run_black_box_hyperopt(objective_function, hyperpriors)
    step_ranges = [(hyperpriors[i].μ - 20 * hyperpriors[i].σ, hyperpriors[i].μ + 20 * hyperpriors[i].σ) for i in eachindex(hyperpriors)]
    func_evals = 10000
    res = bboptimize(objective_function; SearchRange=step_ranges, Method=:adaptive_de_rand_1_bin, MaxFuncEvals=func_evals, TraceMode=:compact, TraceInterval=60)

    return best_candidate(res)
end


function define_step_ranges(param_sizes, priors, param_vector)
    step_ranges = Vector{Tuple{Float64,Float64}}(undef, length(param_vector))

    # # For A, B
    # for i in eachindex(priors[1].μ)
    #     step_ranges[i] = (priors[1].μ[i] - priors[1].Σ[i,i], priors[1].μ[i] + priors[1].Σ[i,i]) 
    # end
    # For A 
    for i in 1:prod(param_sizes[1])
        # step_ranges[i] = (-0.99, 0.99) 
        step_ranges[i] = (priors[1].μ[i] - 10 * priors[1].Σ[i, i], priors[1].μ[i] + 10 * priors[1].Σ[i, i])
    end

    # For B
    for i in (prod(param_sizes[1])+1):(prod(param_sizes[1])+prod(param_sizes[2]))
        step_ranges[i] = (priors[1].μ[i] - 10 * priors[1].Σ[i, i], priors[1].μ[i] + 10 * priors[1].Σ[i, i])
    end

    # For D
    for i in (prod(param_sizes[1])+prod(param_sizes[2])+1):(prod(param_sizes[1])+prod(param_sizes[2])+param_sizes[3][1])
        step_ranges[i] = (priors[1].μ[i] - 10 * priors[1].Σ[i, i], priors[1].μ[i] + 10 * priors[1].Σ[i, i])
    end

    # For Ω
    A_B_D = length(priors[1].μ)
    for i in A_B_D+1:A_B_D+param_sizes[4][1]
        step_ranges[i] = (-10 * priors[2].σ + priors[2].μ, 10 * priors[2].σ + priors[2].μ)
    end

    # For Σ
    for (q, i) in enumerate(A_B_D+param_sizes[4][1]+1:A_B_D+param_sizes[4][1]+param_sizes[5][1])
        step_ranges[i] = (-10 * priors[2+q].σ + priors[2+q].μ, 10 * priors[2+q].σ + priors[2+q].μ)
    end

    return step_ranges
end
