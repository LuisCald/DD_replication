# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: liquidity — the second joint-distribution product (Oct 2026)
#
# Joint distribution of (consumption, illiquid, liquid) on the replication spec (8 distributional
# factors, HP trend, ridge 0.05, infl aggregates, COVID-robust aggregate PCA). The main product
# stays (consumption, income, wealth).
#   liquid   = deposits + CDs + savings bonds + stocks/mutual funds − consumer debt (Kaplan–Violante style)
#   illiquid = net housing + net other real estate + other bonds + life insurance + vehicles + business
#              (no pensions)
# Observed in: PSID (all three, 1999 on; liquid from 1984), SCF (illiquid × liquid, 1962 on),
# CEX (consumption). Inputs: 2_Data_processing/{SCF,PSID,CEX}_liq.csv from
# code/python/make_liquidity_data.py; anchors built in Structures_transfer.jl (liquidity_anchors).
#
#   DD_EXAMPLE=replication_liquidity julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_MEASURES"] = "consum,illiquid,liquid"
ENV["DD_LIQUIDITY"] = "1"

include(joinpath(@__DIR__, "Structures_replication.jl"))
