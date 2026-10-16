# DFA balance-sheet items

Beyond the baseline `(consumption, income, wealth)` model, the code estimates the joint
distribution of `(income, wealth, <item>)` for one balance-sheet item at a time. This
reproduces the Federal Reserve's Distributional Financial Accounts (DFA) line items by
income group and by wealth group.

## What is published

Real estate, mortgages, consumer credit, pensions and stocks are estimated on the paper
specification and published in [DD_data](https://github.com/LuisCald/DD_data)
(`data/items/`). Real estate, mortgages, consumer credit and pensions are published by SCF
wealth group (as in the DFA), by income quintile and by own decile. Stocks are published
only for the next-40% and top-10% wealth groups.

```bash
# from 5_Code/
DD_EXAMPLE=replication_real_estate julia --project=code/julia/env code/julia/run_estimation.jl
DD_EXAMPLE=replication_real_estate julia --project=code/julia/env code/julia/run_postestimation.jl
# likewise replication_{mortgages,consumer_credit,pension,stocks}
python3 code/python/build_items_ddata.py <exports_dir> <out_dir>   # writes <item>_SCF.csv
```

`build_items_ddata.py` reads the item runs' `from_mcmc/data` folders (copied from
`7_Results/`) and writes the long-format DD_data item files.

## Method

Items are semicontinuous: a point mass at zero for non-holders plus a continuous part. They
use a two-part (hurdle) treatment, with a participation scalar and a conditional Legendre
fit (`atom_measures` in `ModelOptions`; building blocks in `code/julia/atom_marginal.jl`).
Group means of one variable by another use the 2D maximum-entropy step (`maxent_density_2d`
in `code/julia/CreateTimeSeries.jl`). It falls back to the truncated series when the moment error exceeds 2e-2.

## Data flow (SCF and PSID)

Each survey's micro file carries the item columns under the same names in both surveys. The
per-household aggregate file carries a matching `<item>_per_hh` anchor.

```
SCF :  data_cleaning.do ──► SCF_noForbes_nogrowth.xlsx
                              │  (GrowthCorrection.jl: align income to the wealth date)
                              ▼
                          SCF_noForbes_new.csv
                              │  (generateForbes400.py: Forbes-400 augmentation)
                              ▼
                          SCF.csv

PSID:  data_cleaning.do ──► PSID_nogrowth.xlsx ──(GrowthCorrection.jl)──► PSID.csv

Aggregates:  import_aggregates.do ──► inflation_corrected_correction_series.xlsx
             (per-HH anchors; the Z.1 item series are de-seasoned by code/R/X12_averages.R)
```

| DFA component | SCF micro | PSID micro | FRED aggregate (`<item>_per_hh`) |
|---|---|---|---|
| Corporate equities + mutual funds (`stocks`) | `equity+mfun` | `finast` | `HNOCEA+HNOMFSA` |
| Real estate (`real_estate`) | `house+oest` | `primary+other_real_estate` | `HNOREMV` |
| Pension entitlements (`pension`) | `pen` | none (no DB) | `HNOPFAQ027S` |
| Home mortgages (`hdebt`) | `hdebt` | `hdebt` | `HHMSDODNS` |
| Consumer credit (`pdebt`) | `pdebt` | `pdebt` | `TOTALSL` |

**Notes.** SIPP does not enter the item models: only aggregate wealth and debt totals are
extracted from it. Consumer durables are dropped because they have no clean DFA counterpart
(the SCF measures vehicles only). DB and DC pensions cannot be separated in any source.

## Files

- `code/julia/Structures.jl`: `atom_measures` / `participation_link` options and the `DD_EXAMPLE` loader
- `code/julia/examples/Structures_replication_<item>.jl`: one config per item
- `code/julia/atom_marginal.jl`: two-part marginal building blocks
- `code/julia/GrowthCorrection.jl`: growth step, carries the item columns
- `code/julia/CreateTimeSeries.jl`: reconstruction mixture and max-entropy group means
- `code/stata/data_cleaning.do`, `code/stata/clean_SCF_2022.do`: item columns (SCF, PSID)
- `code/stata/import_aggregates.do`, `code/stata/other_results.do`: per-HH item anchors
- `code/R/X12_averages.R`: de-seasons the item series into `averages_deseasoned.csv`
- `code/python/build_items_ddata.py`: builds the published DD_data item files
