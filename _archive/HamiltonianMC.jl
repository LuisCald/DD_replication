# Hamiltonian MCMCs
include("DistributionalDynamics.jl")
init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
path = init_path * "/7_Results/income_and_wealth/from_optimization/parameter_vectors/solution2D_A non-diag_copulas and percentile functions_.csv"
θ = vec(Matrix(CSV.read(path, DataFrame, header=0)))
const func_data, time_params, model_elements            = data_prep(obs_data, method_options);
const (param_vector, param_sizes, priors, meas_ind)     = set_params(model_elements, time_params, method_options)

# function hamiltonian_monte_carlo(θ, method_options)
    θ = param_vector
    # @unpack nsave, nburn, chainss = method_options
    nsave    = 3000
    nburn    = 1500
    chainss  = 2

    D          = length(θ) 
    ℓπ(θ)      = likeli(model_elements, θ, param_sizes, priors, meas_ind, Σ_ids, model_options)[1] #logpdf(MvNormal(zeros(D), I), θ)
    # tape       = ReverseDiff.GradientTape(ℓπ, θ)
    g(x)       = ReverseDiff.gradient(ℓπ, x)  
    ℓπ_grad(θ) = (ℓπ(θ), g(θ))  
    # Number of chainss to sample
    chainss_container  = Vector{Any}(undef, chainss)

    # Define a Hamiltonian system
    metric      = DiagEuclideanMetric(D)  # or Dense 
    hamiltonian = Hamiltonian(metric, ℓπ, ℓπ_grad)  # or Zygote

    # Define a leapfrog solver, with initial step size chosen heuristically
    initial_ϵ  = find_good_stepsize(hamiltonian, θ)
    integrator = Leapfrog(initial_ϵ)

    # Define an HMC sampler, with the following components
    #   - multinomial sampling scheme,
    #   - generalised No-U-Turn criteria, and
    #   - windowed adaption for step-size and diagonal mass matrix
    proposal = NUTS{MultinomialTS, GeneralisedNoUTurn}(integrator)
    δ        = 0.8
    adaptor = StanHMCAdaptor(MassMatrixAdaptor(metric), StepSizeAdaptor(δ, integrator))

    # The `samples` from each parallel chain is stored in the `chainss_container` vector 
    # Adjust the `verbose` flag as per need
    v_of_stats = Vector{Any}(undef, chainss)
    Threads.@threads for i in 1:chainss
                        samples, stats        = AdvancedHMC.sample(hamiltonian, proposal, θ, nsave, adaptor, nburn; drop_warmup=true, verbose=false, progress=true)
                        chainss_container[i] = samples
                        v_of_stats[i]        = stats
                    end

                    println("All done.")

                    # mat = [zeros(length(θ), nsave) for i in 1:chainss]
                    # for j in 1:chainss
                    #     for i in 1:nsave
                    #         mat[j][:, i] = chainss_container[j][i]
                    #     end
                    # end

# # describe(mat[1][1,:]) 
# a = vec(mean(mat[1], dims=2))
# println(-likeli(model_elements, a, param_sizes, priors, meas_ind, method_options)[1])
# dv      =  reconstruct_data(a, param_sizes, priors, meas_ind, model_elements, method_options)
# data_dt = create_time_series_dictionary(dv, method_options)
# generate_specific_plots(data_dt, time_params, (1962, 2019), method_options, :mcmc)

# v_of_stats[1][1000]
# b = hcat(a, θ)