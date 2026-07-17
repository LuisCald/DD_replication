# Replication Package for: "Distributional Dynamics"

> Christian Bayer, Luis Calderon, Moritz Kuhn

## 📥 Synthetic data downloads

**If you just want the ready-to-use, high-frequency distributional series — start here.** All files are quarterly from **1962-Q3 to 2024-Q1**, joint over consumption, income, and wealth.

| Want | File | Size |
|------|------|------|
| The 43 latent factors $\hat F_t$ that summarize all dynamics | [`data/synthetic/smoothed_factors.csv`](data/synthetic/smoothed_factors.csv) | 209 KB |
| Raw $\hat\phi^j_t$ inputs (PSID, with trend / cyclical) | [`PSID_functional_data.csv`](data/synthetic/PSID_functional_data.csv) · [`_detrended`](data/synthetic/PSID_functional_data_detrended.csv) | 2.9 MB · 5.5 MB |
| Raw $\hat\phi^j_t$ inputs (SCF, with trend / cyclical) | [`SCF_functional_data.csv`](data/synthetic/SCF_functional_data.csv) · [`_detrended`](data/synthetic/SCF_functional_data_detrended.csv) | 1.7 MB · 1.7 MB |
| **Reconstructed PSID coefficients** (in-sample, HP trend) | [`PSID_coefficients_normal.csv`](data/synthetic/PSID_coefficients_normal.csv) | 4.5 MB |
| **Reconstructed PSID coefficients** (extrapolation, averaged trend) | [`PSID_coefficients_average.csv`](data/synthetic/PSID_coefficients_average.csv) | 8.3 MB |
| Reconstructed SCF coefficients (HP / averaged trend) | [`_normal`](data/synthetic/SCF_coefficients_normal.csv) · [`_average`](data/synthetic/SCF_coefficients_average.csv) | 2.2 MB each |
| Reconstructed CEX coefficients (HP / averaged trend) | [`_normal`](data/synthetic/CEX_coefficients_normal.csv) · [`_average`](data/synthetic/CEX_coefficients_average.csv) | 2.0 MB · 2.2 MB |

**Trend convention:** `_normal` files add back the **HP-filter trend** (date-anchored — use inside 1962–2024). `_average` files add back the **time-average** of the HP trend (use for extrapolation / dates outside the sample).

**Functional data vs coefficients:** `*_functional_data*.csv` are the *inputs* to the state-space model (per-dataset estimates with NaN where the survey wasn't run). `*_coefficients_*.csv` are the *outputs* of the Kalman smoother — dense across all 248 quarters.

See [`data/synthetic/README.md`](data/synthetic/README.md) for column naming, file formats, and a quick-start snippet.

**Want to compute custom moments?** [`code/moments_from_coefficients/`](code/moments_from_coefficients/) is a small, self-contained folder with runnable demos (Julia-first, Python twin) that turn the `*_coefficients_*.csv` files into marginal quantile functions $\Xi^{-1}_{m,t}(u)$ and the trivariate copula density $dC_t(u_c, u_y, u_w)$ at arbitrary points. They wrap the canonical helpers [`code/julia/reconstruct.jl`](code/julia/reconstruct.jl) / [`code/python/reconstruct.py`](code/python/reconstruct.py), which also ship a `FactorMap` helper for factors → coefficients counterfactuals.

**Want posterior uncertainty, not just the point estimate?** [`data/synthetic/smoothed_factor_draws.csv`](data/synthetic/smoothed_factor_draws.csv) stacks the smoothed factors over posterior draws of the model parameters. Push each draw through `FactorMap` to get a posterior band on *any* moment — [`code/moments_from_coefficients/posterior_bands.jl`](code/moments_from_coefficients/posterior_bands.jl) and [`plot_factor_bands.jl`](code/moments_from_coefficients/plot_factor_bands.jl) do this out of the box. Generate the draws with [`code/julia/export_draws.jl`](code/julia/export_draws.jl) (the raw parameter draws are large and not shipped in git).

**Want to run the model with your own settings?** See [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md) for a walkthrough of `ModelOptions` and the output folder layout, and the docstring on [`ModelOptions`](code/julia/Structures.jl) itself.

---

## Overview

This package provides all code and instructions needed to reproduce the results in "Distributional Dynamics." The code estimates a state-space model that combines multiple household surveys (PSID, SCF, CEX, CPS, SIPP) to reconstruct the joint distribution of income, wealth, and consumption at quarterly frequency from 1962 to 2024.

The replication package is organized into three stages:

| Stage | Command | Description | Approx. Runtime |
|-------|---------|-------------|-----------------|
| 1: Data | `bash master.sh data` | Clean raw survey data | ~1 hour |
| 2: Estimation | `bash master.sh estimate` | MCMC estimation (4 chains) | ~48-72 hours |
| 3: Results | `bash master.sh results` | Post-estimation analysis, figures, tables | ~3 hours |

Pre-computed posterior estimates are provided in `output/estimates/`, allowing replicators to skip Stage 2 and go directly from Stage 1 to Stage 3.

## DFA balance-sheet components (semicontinuous extension)

Beyond the baseline `(consumption, income, wealth)` model, the code can model the joint
distribution of `(income, wealth, <balance-sheet component>)` to replicate the Federal
Reserve's **Distributional Financial Accounts (DFA)** one line item at a time — giving each
component's distribution *by income group* and *by wealth group*. Components are
**semicontinuous** (a point mass at 0 for non-holders plus a continuous part), so they use a
two-part / hurdle treatment. See [`doc/stocks_atom_design.md`](doc/stocks_atom_design.md) for
the design (participation scalar `π` + conditional Legendre fit; participation-split copula).

**Selecting an experiment.** `Structures.jl` reads the `DD_EXAMPLE` environment variable and,
if set, loads `code/julia/examples/Structures_<name>.jl` instead of the baseline options
(unset = published baseline, unchanged):

```bash
DD_EXAMPLE=stocks julia run_estimation.jl   # also: real_estate, business, pension, mortgages, consumer_credit
```

**Data flow that feeds these (SCF and PSID).** Each survey's micro file carries the component
columns (same name across surveys), and the per-household aggregate "correction" file carries a
matching `<component>_per_hh` anchor:

```
SCF :  data_cleaning.do ──► SCF_noForbes_nogrowth.xlsx
                              │  (GrowthCorrection.jl: align income to the wealth date)
                              ▼
                          SCF_noForbes.csv
                              │  (generateForbes400.py: Forbes-400 augmentation)
                              ▼
                          SCF.csv                      ← read by the model

PSID:  data_cleaning.do ──► PSID_nogrowth.xlsx ──(GrowthCorrection.jl)──► PSID.csv

Aggregates:  import_aggregates.do ──► inflation_corrected_correction_series.xlsx
             (per-HH anchors; component anchors need the new FRED series de-seasoned —
              run code/R/X12_averages.R, then re-enable the anchors in import_aggregates.do)
```

Component → micro variable → FRED aggregate (`<x>_per_hh`):

| DFA component | SCF micro | PSID micro | FRED aggregate |
|---|---|---|---|
| Corporate equities + mutual funds (`stocks`) | `equity+mfun` | `finast` | `HNOCEA+HNOMFSA` |
| Real estate (`real_estate`) | `house+oest` | `primary+other_real_estate` | `HNOREMV` |
| Unincorporated business (`business`) | `ffabus` | `business` | `BOGZ1LM152090205Q` |
| Pension entitlements (`pension`) | `pen` | — (no DB) | `HNOPFAQ027S` |
| Home mortgages (`hdebt`) | `hdebt` | `hdebt` | `HHMSDODNS` |
| Consumer credit (`pdebt`) | `pdebt` | `pdebt` | `TOTALSL` |

SIPP is excluded from the component work (only aggregate wealth/debt totals are extracted, and
the raw files exceed local memory). Consumer durables has no clean DFA mapping (SCF captures
vehicles only) and is dropped. DB vs DC pension cannot be separated in any source.

**Files added/modified for this extension** (estimation core — marginal hurdle, copula split,
reconstruction mixture — is still in progress; the data layer above is complete and run):

- `code/julia/Structures.jl` — `atom_measures` / `participation_link` options; `DD_EXAMPLE` loader
- `code/julia/examples/Structures_*.jl` — per-component experiment configs
- `code/julia/atom_marginal.jl` — tested two-part / hurdle marginal building blocks
- `code/julia/GrowthCorrection.jl` — growth step (recovered + carries the component columns)
- `code/stata/data_cleaning.do`, `clean_SCF_2022.do` — surface component columns (SCF + PSID)
- `code/stata/import_aggregates.do`, `other_results.do` — per-HH component anchors; canonical-writer fix
- `code/R/X12_averages.R` — de-season the new component series into `averages_deseasoned.csv`
- `doc/stocks_atom_design.md` — design note

## Anatomy of the synthetic data (information & interpolation shares)

The paper's "anatomy" figures ask *whose data* the estimate leans on and *where
the panel is data-rich vs. model-driven*. They come from an exact,
source-additive decomposition of the smoothed states (Koopman & Harvey, 2003):

- [`code/julia/ObservationWeights.jl`](code/julia/ObservationWeights.jl) —
  `observation_weight_decomposition` (per-source contribution to each smoothed
  factor) and `information_shares` (absolute-weight shares $s^b_{k,t}$).
- [`code/julia/ObservationWeightsPlots.jl`](code/julia/ObservationWeightsPlots.jl) —
  the **information-share** figure (stacked $s^b_{k,t}$ by source) and the
  **interpolation-share** figure ($\iota_{k,t}=\sigma^2_{k,t\mid T}/P^\infty_{kk}$,
  data-pinned vs. model-driven).
- [`code/julia/count_observations.jl`](code/julia/count_observations.jl) +
  [`code/julia/data_timeline.jl`](code/julia/data_timeline.jl) — the appendix
  data-timeline figure (micro sample sizes and coverage by source over time).

The `ObservationWeights*` functions load with the model
(`DistributionalDynamics.jl`); the two `*timeline*` scripts are standalone
(they activate `code/julia/env` themselves) and run on the estimation machine.

## Data Availability Statement

All data used in this paper are publicly available. Some datasets require free registration. No restricted-access or confidential data are used.

| Dataset | Provider | Access | Years | URL |
|---------|----------|--------|-------|-----|
| Panel Study of Income Dynamics (PSID) | University of Michigan | Free registration | 1968-2021 | https://psidonline.isr.umich.edu/ |
| Survey of Consumer Finances (SCF) | Federal Reserve Board | Public download | 1962-2022 | https://www.federalreserve.gov/econres/scfindex.htm |
| Consumer Expenditure Survey (CEX) | Bureau of Labor Statistics | Public download | 1984-2023 | https://www.bls.gov/cex/ |
| Current Population Survey (CPS) | Census Bureau / IPUMS | Free registration | 1964-2023 | https://cps.ipums.org/ |
| Survey of Income and Program Participation (SIPP) | Census Bureau | Public download | 1984-2022 | https://www.census.gov/programs-surveys/sipp.html |
| World Inequality Database (WID) | WID.world | Public download | 1962-2023 | https://wid.world/ |
| Distributional Financial Accounts (DFA) | Federal Reserve Board | Public download | 1989-2023 | https://www.federalreserve.gov/releases/z1/dataviz/dfa/ |
| FRED Economic Data | Federal Reserve Bank of St. Louis | Public download | Various | https://fred.stlouisfed.org/ |
| Forbes 400 | Forbes / Fernholz & Haslberger (2023) | Public | 1985-2024 | https://www.forbes.com/forbes-400/ |

**Forbes 400 details:** The SCF+ is augmented with the Forbes 400. For the years 2021 to 2024, we use data directly from Forbes. For the years 1985 to 2020, we use the per capita dataset of Fernholz and Haslberger (2023), whose observations originate from families of the Forbes 400. This provides more complete coverage (nearly all 400 observations each year) than the Forbes website alone, which has incomplete records from the 1990s through the late 2000s.

**Included in this package:** Synthetic (model-generated) microdata are provided in `data/synthetic/PSID_synthetic_microdata.csv` (weighted quarterly cross-sections; regenerate or customize with `code/moments_from_coefficients/coefficients_to_micro_data.jl`), alongside the factor estimates, posterior draws, coefficient files, and per-household aggregate anchors in `data/synthetic/`. The pre-computed posterior-mode parameter vector is provided in `output/estimates/` (loaded automatically by `run_postestimation.jl` when no estimation run is present).

**Not included:** Raw survey microdata must be downloaded by the replicator from the sources above. See `data/raw/DOWNLOAD_INSTRUCTIONS.md` for detailed variable lists and extraction instructions.

## Computational Requirements

### Software

| Software | Version | Purpose |
|----------|---------|---------|
| Julia | >= 1.10 | Model estimation and all quantitative analysis |
| Stata | >= 17 (MP recommended) | Survey data cleaning and local projections |
| Python | >= 3.10 | Data preprocessing (stationarity, seasonal adjustment) |
| R | >= 4.3 | Hermite series estimation, copula estimation, X-12 |

### Julia Packages

All Julia dependencies are pinned in `code/julia/env/Project.toml` and `code/julia/env/Manifest.toml`. Key packages include: Optimization, AdvancedHMC, Distributions, Interpolations, KernelDensity, JLD2, BlackBoxOptim, JuMP, HiGHS, ChebyshevApprox, RCall.

### Python Packages

pandas, numpy, statsmodels, scipy.

### R Packages

seasonal, x12.

### Hardware

- **Minimum:** 32 GB RAM, 8 CPU cores
- **Recommended:** 64 GB RAM, 16+ cores (estimation benefits from parallelization)
- **Storage:** ~10 GB for data and results

Estimation (Stage 2) was performed on a Linux computing cluster. Post-estimation (Stage 3) can run on a standard workstation.

### Runtime

| Stage | Hardware | Approximate Time |
|-------|----------|-----------------|
| 1: Data | Standard workstation | ~1 hour |
| 2: Estimation | 16-core server, 64 GB RAM | ~48-72 hours |
| 3: Results | Standard workstation | ~3 hours |

Using pre-computed estimates (skipping Stage 2), the total runtime is approximately 4 hours.

## Package Contents

```
├── README.md                     This file
├── LICENSE
├── master.sh                     Master replication script
│
├── code/
│   ├── julia/
│   │   ├── DistributionalDynamics.jl   Main Julia entry point (loads all modules)
│   │   ├── run_estimation.jl           Stage 2: MCMC estimation
│   │   ├── run_postestimation.jl       Stages 3-5: results, figures, tables
│   │   ├── config.jl                   Path configuration
│   │   ├── Structures.jl              Data structures and model options
│   │   ├── DataConstructor.jl         Data loading and preprocessing
│   │   ├── ModelPrep.jl               Functional data preparation and PCA
│   │   ├── Model.jl                   State-space model specification
│   │   ├── MCMC.jl                    MCMC sampling and optimization
│   │   ├── SelectPrior.jl             Minnesota prior construction
│   │   ├── DIMES.jl                   DIME sampler integration
│   │   ├── DIMESampler.jl             DIME sampler implementation
│   │   ├── SeparationStrategy.jl      Distributional/aggregate factor separation
│   │   ├── BlackBoxSSM.jl             Black-box optimization
│   │   ├── EM.jl                      EM algorithm
│   │   ├── RobustProjection.jl        Robust factor projection
│   │   ├── HyperparameterOptimization.jl  Hyperparameter tuning
│   │   ├── Reconstruction.jl          Synthetic distribution reconstruction
│   │   ├── PosteriorDraws.jl          Export posterior draws of the smoothed factors
│   │   ├── export_draws.jl            Server-runnable driver for PosteriorDraws.jl
│   │   ├── CreateTimeSeries.jl        Time series export (quantiles, shares, levels)
│   │   ├── IntervalEstimation.jl      Confidence interval estimation
│   │   ├── ForecastSSM.jl             Out-of-sample forecasting
│   │   ├── ObservationWeights.jl      Anatomy: Koopman–Harvey source decomposition of the smoothed states
│   │   ├── ObservationWeightsPlots.jl  Anatomy figures: information shares + interpolation shares
│   │   ├── count_observations.jl      Micro-obs counts per (dataset, year, quarter) — data timeline
│   │   ├── data_timeline.jl           Appendix data-timeline figure
│   │   ├── Validation.jl              External validation (DFA, WID, SCF, CPS, ACS)
│   │   ├── Correlations.jl            Correlation analysis
│   │   ├── CorrelationTables.jl       Correlation table export
│   │   ├── FEVD.jl                    Forecast error variance decomposition
│   │   ├── HistoricalDecomposition.jl Historical decomposition
│   │   ├── CounterfactualRuns.jl      Counterfactual exercises
│   │   ├── CyclicalityOfConsumption2.jl  Recession consumption dynamics
│   │   ├── AllPlots.jl                Proof-of-concept and main figures
│   │   ├── CEXFunctions.jl            CEX data utilities
│   │   ├── MDD.jl                     Marginal data density
│   │   ├── SupportingFunctions.jl     Utility functions
│   │   └── env/                       Julia environment (Project.toml, Manifest.toml)
│   ├── stata/
│   │   ├── 00_master_data.do          Master Stata script (Stage 1)
│   │   ├── data_cleaning.do           Main survey data cleaning (SCF, PSID, CEX, ACS, CPS)
│   │   ├── clean_SCF_2022.do          SCF 2022 wave cleaning
│   │   ├── clean_SIPP_panels.do       SIPP panel cleaning
│   │   ├── connect_SIPP_panels.do     SIPP panel concatenation
│   │   ├── sipp_panel_constructor.do  SIPP quarterly aggregation
│   │   ├── master_sipp_file.do        SIPP utilities
│   │   ├── insert_interview_dates.do  PSID interview date formatting
│   │   ├── import_aggregates.do       FRED macro series import
│   │   ├── x12series.do               X-12 seasonal adjustment
│   │   ├── process_WIDq.do            WID quarterly data processing
│   │   ├── prep_micro_data.do         Micro data for local projections
│   │   ├── prep_micro_3D.do           3D micro data preparation
│   │   ├── prep_macro_3D.do           3D correlation measures
│   │   ├── prep_functional_data.do    Functional data preparation
│   │   ├── prep_actualCEX.do          CEX data with income imputation
│   │   ├── ginis_and_consumption_trends.do  Gini coefficients and trends
│   │   ├── other_results.do           Aggregate correlations
│   │   └── SIPP/                      SIPP panel do-files by wave
│   ├── python/
│   │   ├── convert_monthly_to_quarterly.py  Frequency conversion
│   │   ├── make_stationary.py         Stationarity transformations
│   │   ├── make_stationary_x12.py     Post-X12 stationarity tests
│   │   ├── generateForbes400.py       Forbes 400 wealth data
│   │   ├── clean_brake_data.py        Geographic data cleaning
│   │   ├── MEILC_MEGC.py             Multivariate Gini coefficient
│   │   └── multidim_inequality.py     Multidimensional inequality measures
│   ├── R/
│   │   ├── HermiteSeriesEstimator.R   Hermite series density estimation
│   │   ├── NonParametricCopula.R      Non-parametric copula estimation
│   │   └── X12_script.R              X-12 seasonal adjustment
│   └── moments_from_coefficients/     ⭐ Self-contained: factors → coefficients → moments / micro data
│       ├── README.md
│       ├── factors_to_coefficients.jl / .py    FactorMap bridge (+ counterfactual hook)
│       ├── coefficients_to_moments.jl / .py    Decile cut points + copula density
│       ├── coefficients_to_micro_data.jl / .py Weighted synthetic cross-sections
│       ├── posterior_bands.jl / .py   Posterior bands on any moment (via FactorMap)
│       └── plot_factor_bands.jl / .py Plot factors with posterior bands
│
├── data/
│   ├── raw/                           Raw survey data (user-provided)
│   │   └── DOWNLOAD_INSTRUCTIONS.md
│   ├── processed/                     Cleaned data (generated by Stage 1)
│   ├── synthetic/                     ⭐ READY-TO-USE quarterly distributional series
│   │   ├── README.md                  File-by-file documentation
│   │   ├── smoothed_factors.csv       Latent factors F_t
│   │   ├── *_functional_data*.csv     Inputs: raw phi-hat per dataset
│   │   └── *_coefficients_*.csv       Outputs: Kalman-smoother reconstructions
│   └── aggregates/                    Public macro data
│
├── output/
│   ├── figures/                       Generated figures
│   ├── tables/                        Generated LaTeX tables
│   └── estimates/                     Pre-computed parameter vectors
│
├── slides/                            Conference / seminar slide decks
│   └── brazil/                        Brazil 2026 (full + short 20-min version)
│
├── doc/                               Methodological notes
│   └── linearization_notes.tex
│
└── CITATION.cff                       Machine-readable citation
```

## Instructions to Replicators

### Quick Start (using pre-computed estimates)

1. Install Julia >= 1.10, Stata >= 17, Python >= 3.10, R >= 4.3.
2. Download raw survey data following `data/raw/DOWNLOAD_INSTRUCTIONS.md`.
3. From the project root directory, run:
   ```bash
   bash master.sh data      # Stage 1: ~1 hour
   bash master.sh results   # Stages 3-5: ~3 hours
   ```

### Full Replication (including estimation)

1. Complete Steps 1-2 above.
2. From the project root directory, run:
   ```bash
   bash master.sh all       # All stages: ~50-75 hours
   ```
   Or run stages individually:
   ```bash
   bash master.sh data      # Stage 1: clean data
   bash master.sh estimate  # Stage 2: MCMC estimation
   bash master.sh results   # Stage 3: post-estimation
   ```

### Configuration

All paths are configured in `code/julia/config.jl`. The script auto-detects the project root directory. No manual path editing should be necessary.

### Random Seed

The MCMC sampler uses Julia's default random number generator. For exact replication of the estimation, set `Random.seed!(12345)` at the top of `run_estimation.jl`. Post-estimation results are deterministic given the parameter estimates.

## List of Tables and Figures

### Main Text

| Exhibit | Source Code |
|---------|-------------|
| Figure 1 | TikZ (in main.tex) |
| Figure 2 | `SeriesEstimators.jl` |
| Figure 3 | TikZ (in main.tex) |
| Figure 4 | `AllPlots.jl`: `gen_proof_of_concept_*()` |
| Figure 5 | `AllPlots.jl`: `gen_proof_of_concept_*()` |
| Figure 6 | `ForecastSSM.jl` |
| Figure 7 | `CreateTimeSeries.jl`: `generate_specific_plots()` |
| Figure 8 | Separate HANK replication package (not included) |
| Figure 9 | Stata (TBD) |
| Figure 10 | `OrderAnalysis.jl` |
| Figure 11 | `OrderAnalysis.jl` |
| Figure 12 | `OrderAnalysis.jl` |
| Figure 13 | `DIMESampler.jl` |
| Figure 14 | `CreateTimeSeries.jl` |
| Figure 15 | `Validation.jl` |
| Table 1 | `.tex` (manual) |
| Table 2 | TBD |
| Table 3 | `FEVD.jl` |
| Table 4 | `FEVD.jl` |
| Table 5 | `MDD.jl` |
| Table 6 | TBD |
| Table 7 | TBD |
| Table 8 | TBD |
| Table 9 | TBD |

## References

Bayer, Christian, Luis Calderon, and Moritz Kuhn. "Distributional Dynamics." CEPR Discussion Paper 19829, 2026.

Board of Governors of the Federal Reserve System. *Survey of Consumer Finances*. Various years (1962-2022). https://www.federalreserve.gov/econres/scfindex.htm.

Board of Governors of the Federal Reserve System. *Distributional Financial Accounts*. https://www.federalreserve.gov/releases/z1/dataviz/dfa/.

Federal Reserve Bank of St. Louis. *FRED Economic Data*. https://fred.stlouisfed.org/.

Panel Study of Income Dynamics. *Public Use Dataset*. Produced and distributed by the Survey Research Center, Institute for Social Research, University of Michigan, Ann Arbor, MI. Various years (1968-2021). https://psidonline.isr.umich.edu/.

Fernholz, Ricardo T. and Haslberger, Christoph. "Rising Concentration and Group Lending: The Forbes 400 in General Equilibrium." *Journal of Economic Dynamics and Control*, 2023.

Ruggles, Steven, Sarah Flood, Ronald Goeken, et al. *IPUMS CPS: Version 11.0* [Current Population Survey]. Minneapolis, MN: IPUMS. https://cps.ipums.org/.

U.S. Bureau of Labor Statistics. *Consumer Expenditure Surveys*. Various years (1984-2023). https://www.bls.gov/cex/.

U.S. Census Bureau. *Survey of Income and Program Participation*. Various panels (1984-2008). https://www.census.gov/programs-surveys/sipp.html.

World Inequality Database. *WID.world*. https://wid.world/.
