# User guide

This package supports three kinds of users. Pick the lane that matches what you want:

| Lane | You want… | Start here |
|---|---|---|
| 1 | The published data, or custom moments / micro data computed from it | [github.com/LuisCald/DD_data](https://github.com/LuisCald/DD_data) |
| 2 | To re-run the model with your own settings (different tag, factor count, muted waves, etc.) | [§ Run the model](#run-the-model-yourself) |
| 3 | To estimate the model on **your own microdata** (another country, firms, …) | [§ Estimate on your own data](#estimate-on-your-own-data) |

---

## The data and its helpers moved to DD_data

Everything user-facing — the quarterly CSVs (factors + posterior draws,
coefficients, synthetic microdata, aggregate anchors) and the stage scripts
(`factors_to_coefficients`, `coefficients_to_moments`,
`coefficients_to_micro_data`, `posterior_bands`, `plot_factor_bands`, plus the
`reconstruct` core library in Julia and Python) — lives in
[**DD_data**](https://github.com/LuisCald/DD_data). Its README covers file
formats, units, quick starts, and posterior bands.

This guide covers what stays here: running the estimation itself.

---

## Run the model yourself

The entry points are:

```bash
bash master.sh data        # Stage 1: clean raw survey data (~1 h)
bash master.sh estimate    # Stage 2: MCMC estimation (~48–72 h)
bash master.sh results     # Stage 3: post-estimation, figures, tables (~3 h)
```

The single file you actually edit when configuring a new run is [`code/julia/Structures.jl`](../code/julia/Structures.jl) — specifically the [`ModelOptions`](../code/julia/Structures.jl) struct. Its docstring lists every field; the seven you'll touch in practice are:

| Field | What it controls | Typical change |
|---|---|---|
| `tag` | Result-folder suffix | `" my_experiment"` (leading space) — outputs go to `7_Results/<m_label><tag>/...` |
| `measures` | Which household variables to model jointly | Always `["consum", "income", "wealth"]` in the paper |
| `number_of_dfs` | # of distributional factors retained from PCA | Default `8` (~99% of business-cycle variation) |
| `lags` / `agg_lags` | AR depth of states and aggregate factors | Defaults `1` / `4` |
| `blind_to` | Mute a measure in a specific survey | `Dict("CEX" => ["wealth"])` etc. |
| `data_to_mute` | Drop survey waves entirely (validation experiments) | `Dict("SCF" => muted_quarters_between(QuarterlyDate(2004,1), QuarterlyDate(2009,4)))` |
| `estimator` | `SeriesEstimator` polynomial order / output grid | `SeriesEstimator(grid_pcf=14, grid_cop=14, …)` for higher-order |

The block of comments immediately below `ModelOptions` lists tag conventions used in the paper's validation runs (e.g., `" excluding housing cycle wealth"`, `" every 4 years"`, `" 6 factors"`), with the matching `data_to_mute` recipes. Use them as templates.

### Output layout for a fresh tag

When you bump `tag` to something new, the pipeline writes to a brand-new tree (the `mkpath` calls scattered through the post-estimation code ensure every subfolder is created on first write):

```
7_Results/
└── consum_and_income_and_wealth<tag>/
    ├── from_mcmc/
    │   ├── data/        ← *_coefficients_*.csv, smoothed_factors.csv, *_functional_data*.csv
    │   ├── plots/       ← quantile / copula plots + correlation tables
    │   └── bayesian_convergence/
    └── other_results/    ← counterfactuals, raw data, likelihood diagnostics
```

### Sanity checks before kicking off

* `model_options.tag` is new (won't collide with old results)
* If you set `compare_to_other_est = true`, the baseline run with the comparison tag must already exist
* `data_to_mute` keys match an actual dataset name in `obs_data.files`

When the run finishes, the pipeline writes the regenerated `*_coefficients_*.csv`, `*_functional_data*.csv`, and `smoothed_factors.csv` to `data/synthetic/` (untracked here). To publish them, run `bash publish_to_DD_data.sh` from the repo root — it copies the canonical file set into a DD_data checkout for review and commit there.

---

## Estimate on your own data

Everything above re-runs the paper's surveys. This lane is for bringing your
own microdata — the recipe is the same whether it's households in another
country or something else entirely. Running example throughout: **firm data**
— an annual census observing employment, sales, and debt, plus a quarterly
business survey observing only employment.

### The three ingredients

**1. Microdata** — one CSV per source, one row per unit, repeated cross-sections:

| employment | sales | debt | weight | year | quarter |
|---|---|---|---|---|---|
| 12.0 | 1.4e6 | 2.1e5 | 830.2 | 1998 | 3 |

* One column per measure, named exactly as in `measures` below.
* `weight` (sampling weight) and `year` are required. Add `quarter` (or
  `month`) when a source is sub-annual — each source's frequency is
  auto-detected from which time columns it has.
* Sources don't need to agree on timing, frequency, or coverage. A source
  lacking a measure's column is auto-detected as not observing it, and gaps
  between waves are exactly what the model fills in.
* Negative values are fine (the marginals are fit on an asinh scale).

**2. Per-unit anchors** — one quarterly series per measure. A table with a
`time` column (quarterly dates), one `<measure>_per_hh` column per measure
(the aggregate per-unit mean — e.g. employment per firm from BDS/QCEW), and
`tot_hhs` (number of units). The `hh` in the column names is historical; read
it as "per unit". The model works with distributions *relative to the
per-unit mean* — the anchors pin down levels and make waves comparable.

**3. Aggregate indicator series** — the high-frequency information. A set of
quarterly, **stationary**, seasonally-adjusted macro series that plausibly
co-move with your distribution (for firms: industrial production, business
formation, credit spreads, …). They enter the state equation as aggregate
factors and are what moves the distribution *between* survey waves. Stage 1
(`make_stationary.py`, X-13) shows how the paper's series were prepared.

### Cleaning your data: field notes

Hard-won lessons from preparing the paper's surveys — read before writing
your cleaning code:

* **Be data-efficient: never drop a row because one variable is missing.**
  A firm observed on employment but not debt still informs the employment
  marginal. Code the value as missing and keep the row; deleting it throws
  away information the model would have used.
* **Copula timing: measure the joint distribution at one point in time.**
  Surveys often time variables differently — e.g. income asked for last
  calendar year (Q4) while wealth is as of the interview (Q2). The joint
  ranks are then distorted. Fix it by growing the mistimed variable to the
  other's date using aggregate growth rates — `GrowthCorrection.jl` (Stage
  1c) is the working template; it aligns PSID/SCF income to the wealth date.
* **Put flows at a common annual rate.** Income, consumption, sales:
  whatever the observation window, express them at annual rates, and make
  the anchor series (ingredient 2) the same units — the paper's
  `consum_per_hh` is an annual rate (SAAR) for exactly this reason. Stocks
  (wealth, debt) are point-in-time and need no annualizing.
* **Deflate everything with the same price index.** Relative-to-mean values
  are unit-free, but the growth correction and the anchors are not —
  one deflator across all sources and anchors.
* **Distinguish true zeros from missing.** Zero debt is information (and,
  if common, an `atom_measures` case); missing debt is not. Conflating them
  puts a spurious atom in the distribution.
* **Keep the unit definition consistent across sources.** Household vs.
  tax unit vs. person (or establishment vs. firm) must match across every
  CSV *and* the anchors — otherwise the anchors re-scale each source
  differently. The `equivalized` option exists for OECD-equivalization.
* **Mind the top tail.** Top-coded or tail-trimmed sources understate the
  upper tail the model then reproduces; the paper augments the SCF with the
  Forbes 400 (`generateForbes400.py`) for exactly this reason.

### One file to write

The whole configuration is one Julia file in `code/julia/examples/`,
selected with the `DD_EXAMPLE` environment variable. The twelve shipped
examples are templates; `Structures_stocks.jl` is the closest in spirit
(it adds a new measure with an atom at zero).

```julia
# code/julia/examples/Structures_firms.jl
const model_options = ModelOptions(
    measures      = sort(["employment", "sales", "debt"]),
    atom_measures = ["debt"],          # semicontinuous: many firms hold zero debt
    tag           = " firm economy",   # results go to "7_Results/..._firm economy/"
)

files = Dict(
    "Census"    => joinpath(DATA_PROCESSING, "firm_census.csv"),     # ingredient 1
    "BizSurvey" => joinpath(DATA_PROCESSING, "biz_survey.csv"),
)
const obs_data = ObservedData(
    files      = files,
    gdp_series = CSV.read(joinpath(DATA_PROCESSING, "firm_anchors.csv"), DataFrame),     # ingredient 2
    agg_data   = CSV.read(joinpath(DATA_PROCESSING, "firm_indicators.csv"), DataFrame),  # ingredient 3
)
```

Then skip Stage 1 (your data is already clean) and run:

```bash
DD_EXAMPLE=firms julia --project=code/julia/env code/julia/run_estimation.jl
```

Budget ~48–72 h for the MCMC. Outputs land in `7_Results/` in exactly the
format documented in [DD_data](https://github.com/LuisCald/DD_data) —
smoothed factors, coefficient files, synthetic microdata — so all of
DD_data's `reconstruct` helpers work on your run out of the box.

### Knobs that matter for a new domain

| Knob | When to touch it |
|---|---|
| `atom_measures` | Any measure where a large share of units sits exactly at zero (firm debt, stocks). Fits participation + conditional distribution separately — a single continuous fit fails badly for a large atom. |
| `number_of_dfs` | Default 8 factors. Sensible starting point; check the PCA scree output for your data. |
| `estimator` | `SeriesEstimator(grid_pcf=12, grid_cop=12, …)` — polynomial orders of the marginal/copula fit. |
| `data_cutoffs` | Restrict the sample period. |
| `blind_to` | Only to *deliberately* mute a measure a source does observe — absence is auto-detected. |

### What's fixed

* **Three measures modeled jointly.** Every shipped configuration models
  exactly three; swap which variables fill the slots, but don't treat the
  count as a config knob.
* **Quarterly output frequency** (inputs may be any frequency).
* The degree-11 Legendre basis truncates extreme upper tails (the paper's
  Forbes-400 problem). Firm size distributions are heavier-tailed than
  wealth — inspect the reconstructed top decile before trusting it.
