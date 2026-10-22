# check_prep_dates.jl — prep-only check of the measurement layout (Oct 2026): runs estimation_prep under the current
# DD_* switches and prints, per dataset, the quarters at which each measure's rows are observed, so that observation-date
# shifts (ModelOptions.obs_date_shift, e.g. SCF income at Q4 of the reference year) can be verified without estimating.
#   DD_EXAMPLE=replication DD_TAG=" scf22" julia --project=5_Code/code/julia/env 5_Code/code/julia/check_prep_dates.jl
include(joinpath(@__DIR__, "DistributionalDynamics.jl"))
func_data, time_params, model_elements = estimation_prep(obs_data, model_options)
@unpack tmin = time_params
@unpack measures, estimator = model_options
d0 = QuarterlyDate(tmin["year"], tmin["quarter"])
dimension = length(measures)
cop_part, imm_part = retrieve_cop_and_imm_part(estimator, dimension)
cop_rows = cop_part - imm_part
names_sorted = sort(collect(keys(obs_data.files)))
for (j, nm) in enumerate(names_sorted)
    MV = model_elements.MV[j]
    blocks = vcat([("copula", 1:cop_rows)], [(m, (cop_rows + estimator.grid_pcf * (i - 1) + 1):(cop_rows + estimator.grid_pcf * i)) for (i, m) in enumerate(measures)])
    for (lab, rows) in blocks
        cols = [t for t in 1:size(MV, 2) if any(!isnan, view(MV, rows, t))]
        isempty(cols) && continue
        ds = [d0 + Quarter(t - 1) for t in cols]
        println(rpad("$nm/$lab", 18), " n=", lpad(length(cols), 4), "  first ", join(string.(ds[1:min(4, end)]), " "), " … last ", ds[end])
    end
end
println("tag: ", repr(model_options.tag))
