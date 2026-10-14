# run_proof_of_concept.jl — the paper's proof-of-concept figures, with the data sources of
# the footnotes (raw survey vs. approximation from the 8 most important PCA factors):
#   fig:proof_pcfs   consumption + income panels from CEX, wealth panel from SCF
#   fig:KL_div       (a) PSID (C, Y, W)   (b) SCF (Y, W)   (c) CEX (C, Y)
# One Julia process per measure set (the measure set is fixed at load time):
#   for m in "consum,income,wealth" "income,wealth" "consum,income"; do
#     DD_EXAMPLE=replication DD_MEASURES=$m julia --project=5_Code/code/julia/env 5_Code/code/julia/run_proof_of_concept.jl
#   done
# (or: sbatch 5_Code/marvin/proof_of_concept.sbatch). Outputs are copied, under the
# paper's file names, to 7_Results/proof_of_concept/paper/. No bootstrap intervals needed.

ENV["DD_PROOF_ONLY"] = "1"
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))

model_options.plot_proof = true
estimation_prep(obs_data, model_options)

meas = sort(model_options.measures)
src = joinpath(BASE_PATH, "7_Results", "proof_of_concept", measures_folder(meas))
dst = joinpath(BASE_PATH, "7_Results", "proof_of_concept", "paper"); mkpath(dst)
# (file in this run's folder) => (paper file name)
copies = meas == ["consum", "income", "wealth"] ? ["KL_divergence_no_covid.pdf" => "KL_divergence_no_covid.pdf"] :
         meas == ["income", "wealth"] ? ["KL_divergence_no_covid.pdf" => "KL_divergence_no_covid_YW.pdf",
                                         "wealth_quantiles_top_quantiles.pdf" => "wealth_quantiles_top_quantiles.pdf"] :
         meas == ["consum", "income"] ? ["KL_divergence_no_covid.pdf" => "KL_divergence_no_covid_CY.pdf",
                                         "consum_quantiles_bottom_quantiles.pdf" => "consum_quantiles_bottom_quantiles.pdf",
                                         "income_quantiles_middle_quantiles.pdf" => "income_quantiles_middle_quantiles.pdf"] : Pair{String,String}[]
for (a, b) in copies
    f = joinpath(src, a)
    isfile(f) ? cp(f, joinpath(dst, b); force = true) : @warn "proof of concept: $f not produced"
end
@info "Proof of concept ($(join(meas, ", "))): $(length(copies)) figure(s) → $dst"
