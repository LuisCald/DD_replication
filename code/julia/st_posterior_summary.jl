# ─────────────────────────────────────────────────────────────────────────────
# st_posterior_summary.jl — S5 diagnostics for the stochastic-trend spec.
#
# Standalone (no DistributionalDynamics load, no model prep). Reads the run's
# artifacts and prints:
#   1. ω_τ (trend innovation sd) per factor at the mode + posterior quantiles
#      from the DIME chains (if the .jld2 is available), plus ψ_j and λ —
#      i.e. did the global–local prior shrink the trends, and which factors
#      kept a trend?
#   2. τ-path diagnostics from smoothed_trends.csv (if present): range, sd of
#      Δτ vs sd of Δf_core per factor, and the share of low-frequency
#      movement carried by τ.
#
# Usage:
#   julia --project=5_Code/code/julia/env 5_Code/code/julia/st_posterior_summary.jl \
#         "/path/to/7_Results/consum_and_income_and_wealth stochastic trend PSID SCF" \
#         [/path/to/posterior_draws/consum_and_income_and_wealth_ stochastic trend PSID SCF.jld2]
# ─────────────────────────────────────────────────────────────────────────────
using DelimitedFiles, Statistics, Printf

const Q_AGG = 11                      # Mdim (MDD-pinned aggregate factor count)
sp(x) = log1p(exp(x))                 # softplus, as in st_likeli

results_dir = length(ARGS) >= 1 ? ARGS[1] : error("pass the tag's 7_Results folder")
jld_path    = length(ARGS) >= 2 ? ARGS[2] : nothing

# ── mode vector + factor count ───────────────────────────────────────────────
pv_dir  = joinpath(results_dir, "from_mcmc", "parameter_vectors")
sol     = first(filter(f -> startswith(f, "solution") && endswith(f, ".csv"), readdir(pv_dir)))
par     = vec(readdlm(joinpath(pv_dir, sol), ','))
fac_csv = joinpath(results_dir, "from_mcmc", "data", "smoothed_factors.csv")
hdr     = split(readline(fac_csv), ',')
n_states = length(hdr) - 1            # collapsed layout: 4r + q
r = (n_states - Q_AGG) ÷ 4
@assert 4r + Q_AGG == n_states "state count $n_states not 4r+$Q_AGG"
ntr = 2r + 1
θtr = par[end-ntr+1:end]
ω  = sp.(θtr[1:r]); ψ = sp.(θtr[r+1:2r]); λ = sp(θtr[end])

println("mode vector: $sol  (length $(length(par)), r = $r dist factors, trend block = $ntr)")
println("λ (global scale) = ", @sprintf("%.4f", λ), "   prior C⁺(0, 0.1); init 0.10")
println("\n factor     ω_τ (mode)      ψ_j     λψ_j (local scale)")
for j in 1:r
    @printf(" %4d     %10.5f  %8.3f  %10.5f\n", j, ω[j], ψ[j], λ * ψ[j])
end
println(" (init ω_τ = 0.05 each; shrinkage ⇔ ω_τ ≪ 0.05, active trend ⇔ ω_τ ≳ init)")

# ── posterior quantiles from chains ──────────────────────────────────────────
if jld_path !== nothing && isfile(jld_path)
    using JLD2
    d = JLD2.load(jld_path)
    ch = d["d_chains"]                # (iters kept, nchain, ndim)
    ni, nc, nd = size(ch)
    @assert nd == length(par)
    flat = reshape(permutedims(ch, (1, 2, 3)), ni * nc, nd)
    qs(v) = quantile(v, [0.05, 0.5, 0.95])
    println("\nposterior (last $ni iters × $nc chains):")
    println(" factor        ω_τ  5%      50%      95%")
    for j in 1:r
        q = qs(sp.(flat[:, end-ntr+j]))
        @printf(" %4d       %8.5f %8.5f %8.5f\n", j, q...)
    end
    qλ = qs(sp.(flat[:, end]))
    @printf(" λ          %8.5f %8.5f %8.5f\n", qλ...)
else
    println("\n(no .jld2 given/found — skipping posterior quantiles)")
end

# ── τ paths ──────────────────────────────────────────────────────────────────
tr_csv = joinpath(results_dir, "from_mcmc", "data", "smoothed_trends.csv")
if isfile(tr_csv)
    F, fh = readdlm(fac_csv, ','; header = true)
    Tm, th = readdlm(tr_csv, ','; header = true)
    fac = Float64.(F[:, 2:1+r])       # collapsed f+τ, lag 0 block
    τ   = Float64.(Tm[:, 2:1+r])
    f   = fac .- τ
    println("\nτ paths (T = $(size(τ,1))):")
    println(" factor    range(τ)    sd(Δτ)    sd(Δf)   sd(τ)/sd(f+τ)")
    for j in 1:r
        @printf(" %4d   %9.3f  %8.4f  %8.4f   %8.3f\n", j,
                maximum(τ[:, j]) - minimum(τ[:, j]), std(diff(τ[:, j])), std(diff(f[:, j])),
                std(τ[:, j]) / std(fac[:, j]))
    end
else
    println("\n(no smoothed_trends.csv — produced by runs after the Reconstruction.jl τ-persist change)")
end
