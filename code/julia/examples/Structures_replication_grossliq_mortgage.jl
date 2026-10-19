# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: consumption × gross liquid × mortgage debt — debt product (Oct 2026)
#
#   grossliq = deposits + CDs + savings bonds + stocks/mutual funds (no debt subtracted)
#   mortdebt = mortgage debt on the primary residence (as the published mortgages item); point mass at zero
#              → atom treatment, zero share carried in the state (tag " pis")
# Observed in: SCF (grossliq × mortdebt, 1962 on), PSID (all three; mortgages from 1969, grossliq from 1984),
# CEX (consumption). Inputs: 2_Data_processing/{SCF,PSID,CEX}_liq.csv (code/python/make_liquidity_data.py);
# anchors grossliq_per_hh and mortdebt_per_hh (home mortgages) from liquidity_anchors() in Structures_transfer.jl.
#
#   DD_EXAMPLE=replication_grossliq_mortgage julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_MEASURES"] = "consum,grossliq,mortdebt"
ENV["DD_LIQUIDITY"] = "1"

include(joinpath(@__DIR__, "Structures_replication.jl"))
