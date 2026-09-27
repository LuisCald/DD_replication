# ─────────────────────────────────────────────────────────────────────────────
# Example experiment: a balance-sheet COMPONENT economy — STOCKS
#
# Run with:   DD_EXAMPLE=stocks julia run_estimation.jl
#
# This is the template for replicating the Fed's Distributional Financial
# Accounts (DFA) one component at a time. Each `examples/Structures_<item>.jl`
# models the joint distribution of (income, wealth, <item>) so we get not just
# the marginal of the item but its distribution *by* income and *by* wealth.
#
# To add another component, copy this file, change `measures`, and ensure:
#   (1) every survey CSV that observes the item has a column with the SAME name
#       as the measure (here "stocks"); datasets lacking it are auto-detected as
#       missing (no need to list them in `blind_to`).
#   (2) the per-household aggregate file carries the matching anchor series
#       (here "stocks_per_hh"), the analogue of consum_per_hh / wealth_per_hh.
#
# STOCKS-SPECIFIC: equities are a SEMICONTINUOUS variable — most households hold
# zero. Listing "stocks" in `atom_measures` switches it to the two-part / hurdle
# treatment (participation scalar π_t + conditional Legendre fit on holders) and
# the participation-split copula. With `atom_measures` empty this file would
# instead fit a single continuous marginal, which fails badly for a large atom.
# See doc/stocks_atom_design.md for the full design.
#
# Everything not set here falls back to the published baseline defaults in
# ModelOptions (see Structures.jl). This file is `include`d from the bottom of
# Structures.jl, so all helper functions (retrieve_data_files, ObservedData, …)
# and the structs are already defined at this point.
# ─────────────────────────────────────────────────────────────────────────────

const model_options = ModelOptions(
    measures      = sort(["income", "wealth", "stocks"]),
    atom_measures = ["stocks"],
    factor_selection = :bai_ng,   # automatic count via Bai-Ng ICp2, clamped to <= 10 (MC-validated at T~33; see FactorSelectionSim.jl)
    tag           = " stocks economy",
    # blind_to left empty: surveys without a `stocks` column (e.g. CEX, CPS) are
    # detected as not observing it. Add entries here only to *deliberately* mute
    # an item that a dataset does observe.
)

# The component columns (stocks, real_estate, business, pension, vehicles) live
# in the canonical PSID.csv/SCF.csv since 2026-09-22, when the regenerated
# "_new" files became the defaults (the " new data" vintage tag was retired).
# The aggregate workbook must carry the matching `stocks_per_hh` anchor;
# otherwise construction errors out, which is the intended signal that the data
# isn't ready yet.
const obs_data = ObservedData()
