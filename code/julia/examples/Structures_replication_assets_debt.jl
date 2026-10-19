# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: consumption × total assets × total debt — debt product (Oct 2026)
#
# Net worth split into its two sides:
#   totassets = total assets without pensions (as in the SCF and PSID wealth measures)
#   totdebt   = mortgages + other real-estate debt + consumer debt; point mass at zero → atom treatment,
#               zero share carried in the state (tag " pis")
# Observed in: SCF (totassets × totdebt, 1962 on), PSID (all three; assets from 1984), CEX (consumption).
# Inputs: 2_Data_processing/{SCF,PSID,CEX}_liq.csv (code/python/make_liquidity_data.py); anchors
# totassets_per_hh (net worth + mortgages + consumer credit) and totdebt_per_hh (mortgages + consumer credit)
# from liquidity_anchors() in Structures_transfer.jl.
#
#   DD_EXAMPLE=replication_assets_debt julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_MEASURES"] = "consum,totassets,totdebt"
ENV["DD_LIQUIDITY"] = "1"

include(joinpath(@__DIR__, "Structures_replication.jl"))
