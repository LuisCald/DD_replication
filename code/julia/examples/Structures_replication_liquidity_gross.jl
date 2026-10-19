# ─────────────────────────────────────────────────────────────────────────────
# REPLICATION variant: consumption × gross liquid × debt — liquidity product (Oct 2026)
#
# Same spec as Structures_replication_liquidity.jl, with net liquid split into its two parts:
#   grossliq = deposits + CDs + savings bonds + stocks/mutual funds (no debt subtracted)
#   debt     = consumer (non-housing) debt; point mass at zero → atom treatment (atom_measures)
# Observed in: PSID (all three, 1999 on; grossliq and debt from 1984), SCF (grossliq × debt, 1962 on),
# CEX (consumption). Inputs: 2_Data_processing/{SCF,PSID,CEX}_liq.csv (code/python/make_liquidity_data.py);
# anchors grossliq_per_hh (deposits + Treasury securities + equities/mutual funds) and debt_per_hh
# (consumer credit) from liquidity_anchors() in Structures_transfer.jl.
#
#   DD_EXAMPLE=replication_liquidity_gross julia -t 32 --project=5_Code/code/julia/env 5_Code/code/julia/run_estimation.jl
# ─────────────────────────────────────────────────────────────────────────────

ENV["DD_MEASURES"] = "consum,debt,grossliq"
ENV["DD_LIQUIDITY"] = "1"

include(joinpath(@__DIR__, "Structures_replication.jl"))
