# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION configuration — the specification of the released paper estimates
#
# Run with (from the project root):
#   DD_EXAMPLE=replication julia -t 20 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
#
# It is the transferred model (examples/Structures_transfer.jl, doc/transfer_old_vs_new.tex)
# with two choices pinned:
#   • trend: HP filter per coefficient (DD_TREND=hp) — the stochastic trend in factor
#     space stays available as the development configuration (DD_EXAMPLE=transfer);
#   • loadings: complete-case PCA (DD_PCA=complete_cases) — EM completion lets the
#     factors explain disagreements BETWEEN surveys (e.g. the SIPP1→SIPP2 handover),
#     complete case keeps the common signal (5 factors complete case vs em, 2026-09-28).
# Everything else is shared with the development configuration: weighted copula ranks,
# 40/40/20 cross-conditional groups, per-factor persistence + joint stationarity cap,
# the whitening ridge (observed-row scaling), the inflation-based FRED-QD aggregate
# sheet with the COVID-robust aggregate PCA, the SIPP zero-income and seam fixes.
#
# Robustness / MDD runs of the paper: examples/Structures_replication_<variant>.jl, each
# this spec plus exactly one change.
#
# Each default below can still be overridden from the environment, but the released
# estimates use exactly these values — change them and you are no longer replicating.
# ─────────────────────────────────────────────────────────────────────────────

get!(ENV, "DD_TREND", "hp")
get!(ENV, "DD_PCA", "complete_cases")
get!(ENV, "DD_NDF", "8")   # the paper: eight distributional factors
get!(ENV, "DD_WRIDGE", "0.05")
get!(ENV, "DD_AGG_SHEET", "stationary_series_infl")
get!(ENV, "DD_AGG_XCOVID", "1")

include(joinpath(@__DIR__, "Structures_transfer.jl"))
