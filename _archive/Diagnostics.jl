function run_diagnostics(chain_results, mcmc_acceptance_rate, diagnostics_options)
    """https://mambajl.readthedocs.io/en/latest/mcmc/chains.html#section-gelmandiag.    
    
    1. Compute the Gelman, Rubin and Brooks diagnostics [^Gelman1992] [^Brooks1998].  Values of the
    diagnostic’s potential scale reduction factor (PSRF) that are close to one suggest
    convergence.  As a rule-of-thumb, convergence is rejected if the 97.5 percentile of a PSRF
    is greater than 1.2.

    [^Gelman1992]: Gelman, A., & Rubin, D. B. (1992). Inference from iterative simulation using multiple sequences. Statistical science, 7(4), 457-472.
    [^Brooks1998]: Brooks, S. P., & Gelman, A. (1998). General methods for monitoring convergence of iterative simulations. Journal of computational and graphical statistics, 7(4), 434-455.

    2. The diagnostic is designed to assess convergence of posterior means estimated with
    autocorrelated samples.  It computes a normal-based test statistic comparing the sample
    means in two windows containing proportions of the first and last iterations.  Users should
    ensure that there is sufficient separation between the two windows to assume that their
    samples are independent.  A non-significant test p-value indicates convergence.  Significant
    p-values indicate non-convergence and the possible need to discard initial samples as a
    burn-in sequence or to simulate additional samples.

    [^Geweke1991]: Geweke, J. F. (1991). Evaluating the accuracy of sampling-based approaches to the calculation of posterior moments (No. 148). Federal Reserve Bank of Minneapolis.
    """
    @unpack alpha, first_opt, last_opt, etype = diagnostics_options

    # Common Diagnostics 
    gelman_tuple = gelmandiag(chain_results; alpha)  # tests for non-convergence of posterior mean estimates. 
    geweke_tuple = gewekediag(Chains(chain_results); first_opt, last_opt, etype)  # tests for non-convergence of posterior mean estimates, tells us whether the burn in period was too short. 

    # More modern diagnostics 
    ess = ess_rhat(chain_results)[1]  # get the effective sample sizes 

    # Store Diagnosis 

    return DiagnosticResults(mcmc_acceptance_rate, ess, gelman_tuple, geweke_tuple)
end

function analyze_mcmc(diagnos)
    @unpack acceptance_rate, ess, gelman, geweke = diagnos
    println("----------------------------------------------")
    if any(ess .< 200)
        perc = sum(ess .< 200) / length(ess)
        println("$perc" * "% of the parameters have an ESS less than 200." * " More MCMC draws may be required to generate independent samples.")
    else
        println("Enough independent samples were generated.")
    end
    println("----------------------------------------------")

    if any(acceptance_rate .> .5)
        s = sum(acceptance_rate .> .5) / length(acceptance_rate)
        println("Acceptance rate may be too high for $s chains.")
    elseif any(acceptance_rate .< .2)
        s = sum(acceptance_rate .< .2) / length(acceptance_rate)
        println("Acceptance rate may be too low for $s chains.")
    elseif all(acceptance_rate .< .5) && all(acceptance_rate .> .2)
        println("All chains seem to be within reasonable acceptance rates.")
    end
    println("----------------------------------------------")

    if any(gelman[1] .> 1.2)
        s = 100 * sum(gelman[1] .> 1.2) / length(gelman[1])
        println("$s" * "%" * " of the parameters have an gelman stat of greater than 1.2. This indicates the possibility of non-convergence.")
    else
        println("Parameters seemed to have converged.")
    end
    println("----------------------------------------------")

    for i in eachindex(acceptance_rate)
        s = 100 * sum(geweke[i][:, :pvalue] .> 0.05) / length(geweke[i][:, :pvalue])  # means distant samples in mcmc are independent
        println("For chain $i, $s percent of the parameters have late samples correlated with early samples. Probably needs more draws.")
    end  
    println("----------------------------------------------")
end

function store_diagnosis(mcmc_acceptance_rate, ess, gelman_tuple, geweke_tuple)
    DelimitedFiles.writedlm(pwd() * "/diagnostics/$mcmc_acceptance_rate" * "_$label.csv",  mcmc_acceptance_rate, ',') 
    DelimitedFiles.writedlm(pwd() * "/diagnostics/$mcmc_acceptance_rate" * "_$label.csv",  ess, ',') 
    DelimitedFiles.writedlm(pwd() * "/diagnostics/$mcmc_acceptance_rate" * "_$label.csv",  gelman_tuple[1], ',') 
    DelimitedFiles.writedlm(pwd() * "/diagnostics/$mcmc_acceptance_rate" * "_$label.csv",  geweke_tuple[], ',') 
end

# # rstar(
# #     RandomForestClassifier,
# #     new_p_chain,
# #     chain_indices
# # )
# using MLJ 
# using DecisionTree
# # Supervised model needed
# chain_indices = vcat(repeat([1], 116 * 4), repeat([2], 116 * 4), repeat([3], 116 * 4), repeat([4], 116 * 4))
# new_p_chain = reshape(parameter_chain, (1001, 464))