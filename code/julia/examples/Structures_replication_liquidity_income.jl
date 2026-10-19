# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: consumption × income × liquid — a third joint-distribution product (Oct 2026)
#
# Same spec and liquid definition as Structures_replication_liquidity.jl
#   liquid = deposits + CDs + savings bonds + stocks/mutual funds − consumer debt (Kaplan–Violante style)
# Observed in: PSID (all three, 1999 on; income from 1968, liquid from 1984), SCF (income × liquid,
# 1962 on), CEX (consumption × income), CPS/CPS2 and SIPP1–3 (income), as in the paper.
# Inputs: 2_Data_processing/{SCF,PSID,CEX}_liq.csv (code/python/make_liquidity_data.py), the paper's
# CPS/SIPP files; anchors income_per_hh, consum_per_hh and the liquid anchor of liquidity_anchors().
#
#   DD_EXAMPLE=replication_liquidity_income julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_MEASURES"] = "consum,income,liquid"
ENV["DD_LIQUIDITY"] = "1"

include(joinpath(@__DIR__, "Structures_replication.jl"))
