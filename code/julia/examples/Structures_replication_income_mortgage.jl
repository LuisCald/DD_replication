# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: consumption × income × mortgage debt — debt product (Oct 2026)
#
#   mortdebt = mortgage debt on the primary residence (as the published mortgages item); point mass at zero
#              → atom treatment, zero share carried in the state (tag " pis")
# Observed in: PSID (all three; mortgages from 1969), SCF (income × mortdebt), CEX (consumption × income),
# CPS, CPS2, SIPP1–3 (income, as in the paper). Inputs: 2_Data_processing/{SCF,PSID,CEX}_liq.csv
# (code/python/make_liquidity_data.py); anchor mortdebt_per_hh (home mortgages) from liquidity_anchors().
#
#   DD_EXAMPLE=replication_income_mortgage julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_MEASURES"] = "consum,income,mortdebt"
ENV["DD_LIQUIDITY"] = "1"

include(joinpath(@__DIR__, "Structures_replication.jl"))
