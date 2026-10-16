# Replication Package for "Distributional Dynamics"

Christian Bayer, Luis Calderon, Moritz Kuhn

The code combines five U.S. household surveys in a state-space model to estimate the joint
distribution of consumption, income and wealth at quarterly frequency, 1962–2024.

If you only need the data, go to [DD_data](https://github.com/LuisCald/DD_data) or
[distributionaldynamics.com](https://www.distributionaldynamics.com).

## Overview

This package reproduces every computational exhibit of the paper in three stages: data
cleaning, MCMC estimation (DIME ensemble sampler), and post-estimation. The posterior mode
ships in `output/estimates/`, so Stage 2 can be skipped; the
[quick start](#quick-start-without-stage-2) lists what then cannot be reproduced.

| Stage | Command | What | Hardware | Runtime |
|---|---|---|---|---|
| 1: Data | `bash master.sh data` | Clean the surveys and aggregates (Stata, Python, Julia) | Workstation | ~1 h |
| 2: Estimation | `bash master.sh estimate` | MCMC estimation | 16 cores, 64 GB RAM | ~48–72 h |
| 3: Results | `bash master.sh results` | Post-estimation, figures, tables | Workstation | ~3 h |

## Data Availability Statement

All data are publicly available. Some sources require free registration. No restricted or
confidential data are used.

Years follow the paper's coverage table (`Tables/DataCoverage.tex`).

| Dataset | Provider | Access | Years | URL |
|---|---|---|---|---|
| Consumer Expenditure Survey (CEX), Interview Survey | Bureau of Labor Statistics | Public download | 1984Q4–2021Q4 | https://www.bls.gov/cex/ |
| Current Population Survey (CPS), ASEC | Census Bureau, via IPUMS CPS (Flood et al. 2023) | Free registration | ASEC 1968–2023 = income years 1967–2022 (CPS2: 1967–1992, CPS: 1993–2022) | https://cps.ipums.org/ |
| Survey of Consumer Finances (SCF), modern waves | Federal Reserve Board | Public download | 1989–2022 (triennial) | https://www.federalreserve.gov/econres/scfindex.htm |
| SCF+ (historical SCF waves before 1989) | Kuhn, Schularick and Steins (2020) | Public (with the article) | 1962–1983 in the estimation (the file starts in 1950) | https://doi.org/10.1086/708815 |
| Forbes 400 | Forbes (2021–2024); Fernholz and Hagler (2023) (1985–2020) | Public | 1985–2024 | https://www.forbes.com/forbes-400/ |
| Panel Study of Income Dynamics (PSID) | University of Michigan | Free registration | 1968–2021 (wealth from 1984, consumption from 1999) | https://psidonline.isr.umich.edu/ |
| Survey of Income and Program Participation (SIPP) | Census Bureau | Public download | 1983Q3–2022Q4: panels 1984–1993, 1996, 2001, 2004, 2008, 2014 and the annual 2018–2023 releases | https://www.census.gov/programs-surveys/sipp.html |
| World Inequality Database (WID) | WID.world | Public download | 1962–2023 | https://wid.world/ |
| Distributional Financial Accounts (DFA) | Federal Reserve Board | Public download | 1989–2023 | https://www.federalreserve.gov/releases/z1/dataviz/dfa/ |
| FRED and FRED-QD | Federal Reserve Bank of St. Louis; McCracken and Ng (2020) | Public download | Various | https://fred.stlouisfed.org/ |

**SCF.** The SCF series combines the Federal Reserve Board's public SCF files for 1989–2022
(1989–2019 as harmonized in the SCF+ file `HSCF_2019.dta`, 2022 from the Fed's summary extract)
with the historical waves of the SCF+ of Kuhn, Schularick and Steins (2020) before 1989.

**Forbes 400.** The top tail of the SCF is augmented with the Forbes 400: data from Forbes for
2021–2024, and for 1985–2020 the per-capita dataset of Fernholz and Hagler (2023), which covers
nearly all 400 families each year (the Forbes website is incomplete from the 1990s to the late
2000s). See `code/python/generateForbes400.py`.

**Units and definitions.** Dollar values are in 2019Q4 US dollars, deflated with the CPI-U
(FRED `CPIAUCSL`, indexed to 2019-10-01 = 100; see `code/stata/import_aggregates.do`; the PCE
consumption anchor uses the NIPA price indices for nondurables and services). Income is
pre-tax household income including transfers (Appendix "Data" of the paper).

**Included:** the posterior-mode parameter vector (`output/estimates/`), which
`run_postestimation.jl` loads when no Stage-2 run is present. The data product (factors,
posterior draws, coefficient files, synthetic microdata, aggregate anchors, helper scripts) is
published in [DD_data](https://github.com/LuisCald/DD_data).

**Included:** the processed inputs that the estimation reads (Stage-1 output), in
[`data/processed/`](data/processed/README.md): the survey microdata (SCF, PSID, CEX, CPS, CPS2,
SIPP1–3, gzipped CSV) and the two aggregate workbooks `aggregates_HHs_NPs.xlsx` (FRED, FRED-QD
and Financial Accounts series; `code/julia/Structures.jl`, `retrieve_aggregate_data`) and
`inflation_corrected_correction_series.xlsx` (per-household aggregate anchors;
`retrieve_rgdp`). Unzip the CSV files and copy the two workbooks into `2_Data_processing/` to
start at Stage 2 without re-running the data cleaning.

**Not included:** the raw survey downloads. To rebuild the processed files from scratch, download
the sources above following [`data/raw/DOWNLOAD_INSTRUCTIONS.md`](data/raw/DOWNLOAD_INSTRUCTIONS.md)
and run Stage 1. The processed files are derived from data whose providers set their own terms
(PSID and IPUMS-CPS require registration); users should also obtain the original data from the
providers. Questions: luis.calderon@uni-bonn.de.

## Computational Requirements

**Software.**

- Julia 1.10.4 (pinned in `code/julia/env/Manifest.toml`): estimation and all quantitative analysis
- Stata ≥ 17 (MP recommended): survey cleaning and local projections
- Python ≥ 3.10: preprocessing (frequency conversion, stationarity, Forbes 400)
- R ≥ 4.3 (optional, not run by `master.sh`): `code/R/X12_averages.R` de-seasons the Financial Accounts item series (stocks, real estate, pensions) and adds them as columns to `2_Data_processing/aggregates/averages_deseasoned.csv`. `import_aggregates.do` (Stage 1) reads that file, so it must already exist. The R script only adds the item columns and does not create the file.

**Packages.**

- Julia: pinned in `code/julia/env/Project.toml` and `Manifest.toml` (`Pkg.instantiate()`)
- Python: pandas, numpy, scipy, statsmodels
- R (optional): x12 (needs the X-13ARIMA-SEATS binary)

**Hardware.** Minimum 32 GB RAM and 8 cores; 64 GB and 16+ cores recommended for Stage 2.
About 10 GB of storage. Stage 2 ran on a Linux cluster; Stages 1 and 3 run on a workstation.

## Instructions to Replicators

### Directory layout

Clone this repository as `5_Code` inside a project root that also holds the data and
results folders. `master.sh` and `code/julia/config.jl` derive every path from that root.

```
<root>/
├── 1_Data/              raw survey downloads
├── 2_Data_processing/   Stage-1 output (cleaned surveys, aggregates)
├── 5_Code/              this repository
├── 7_Results/           Stage-2/3 output
└── posterior_draws/     MCMC chains, <measures>_<tag>.jld2 (Stage 2)
```

Run the individual `julia` commands below from `<root>/5_Code`.

### Quick start (without Stage 2)

1. Install the software above and run `julia --project=code/julia/env -e 'using Pkg; Pkg.instantiate()'`.
2. Download the raw data into `1_Data/` following `data/raw/DOWNLOAD_INSTRUCTIONS.md`.
3. Run:
   ```bash
   bash master.sh data                         # Stage 1, ~1 h
   DD_SKIP=bands,draws bash master.sh results  # Stage 3, ~3 h
   ```

The quick start uses the shipped posterior mode. Posterior draws, credible bands, the
chain-convergence figure and the MDD table need the MCMC chains in
`posterior_draws/<measures>_<tag>.jld2`, which only Stage 2 writes; `DD_SKIP=bands,draws` skips
the two Stage-3 steps that read them. All other exhibits are evaluated at the posterior mode.

### Full run

`bash master.sh all` runs Stages 1–3 (~50–75 h).

### Small replication / smoke test

To check that the estimation runs end to end without waiting days, cap the number of DIME
sampler iterations with `DD_NITER` (default 400):

```bash
DD_NITER=5 DD_TAG=" smoke" DD_EXAMPLE=replication julia -t ${DD_THREADS:-auto} --project=code/julia/env code/julia/run_estimation.jl
```

The black-box pre-optimization before the sampler is time-budgeted at 3 seconds per parameter
(`run_estimation.jl`), about 24 minutes for the 485-parameter baseline. Data preparation and the
5 iterations add minutes. The resulting mode is not the paper's. `DD_TAG` appends a suffix to the
run tag, so the output goes to its own `7_Results/` folder and does not overwrite a full run.

### Threads (`DD_THREADS`)

`master.sh` starts Julia with `julia -t ${DD_THREADS:-auto}` for Stages 2 and 3, so by default
it uses all cores. Set `DD_THREADS=<n>` to limit it, e.g. `DD_THREADS=16 bash master.sh estimate`.
Stata is called as `${STATA:-stata-mp}`. Set `STATA=stata-se` (or a full path) if needed.

### Configurations (`DD_EXAMPLE`)

`code/julia/Structures.jl` loads `code/julia/examples/Structures_<name>.jl` when
`DD_EXAMPLE=<name>` is set. `master.sh` sets `DD_EXAMPLE=replication` by default.

```bash
DD_EXAMPLE=replication                  # paper: HP trend, complete-case loadings, 8 distributional factors
DD_EXAMPLE=replication_6_factors        # robustness; also replication_{7_factors,no_housing_wealth,no_recent_20q,cex_every_4_years}
DD_EXAMPLE=replication_real_estate      # DFA items: also replication_{mortgages,consumer_credit,pension}
DD_EXAMPLE=HANK                         # HANK validation, see code/hank/README.md
```

### Caveats

**Hard-coded root.** The Julia pipeline finds the project root automatically. Several Stage-1
scripts still hard-code the authors' root `/Users/lc/Dropbox/Distributional_Dynamics`: the
Stata `.do` files, `code/julia/GrowthCorrection.jl`, `code/python/*.py` and
`code/R/X12_averages.R`. Replace it with your own root before running Stage 1.

**Random seeds.** Data preparation sets `Random.seed!(123456789)` (`DataConstructor.jl`) and the
Stage-2 sampler continues from Julia's default generator; a re-estimation can still differ from the
paper up to Monte Carlo error (thread scheduling). Post-estimation draws and bands use fixed seeds.

## Replication map

The `master.sh` stages wrap these Julia commands (run from `5_Code/`):

```bash
DD_EXAMPLE=replication julia --project=code/julia/env code/julia/run_estimation.jl       # Stage 2, ~48–72 h
DD_EXAMPLE=replication julia --project=code/julia/env code/julia/run_postestimation.jl   # Stage 3, ~3 h
DD_EXAMPLE=<name>      julia --project=code/julia/env code/julia/run_estimation.jl       # robustness re-estimations
```

Stage-3 switches (all steps run by default):

| Variable | Effect |
|---|---|
| `DD_FULL_RESULTS=0` | skip Steps 6–9 |
| `DD_PLOT_PROOF=1` | add the proof-of-concept figures |
| `DD_SKIP=bands,draws,fevd,hd,anatomy,forecasts` | skip individual steps (any subset) |
| `DD_N_DRAWS` | number of exported posterior draws (default 200) |
| `DD_EXPORT_DRAWS=0` | skip the posterior factor-draw export |
| `DD_MODE_FROM="<tag>"` | load the posterior mode of another run |
| `HANK_ECON`, `HANK_NDF`, `HANK_TABLE_ECONS`, `HANK_XSHARES`, `HANK_TRUTH_SUFFIX` | HANK validation (see `code/hank/README.md`) |

Output goes to `7_Results/`. Exhibits are listed by LaTeX label; "needs Stage 2" marks those
that require the MCMC chains.

### Main text

| Exhibit | Generated by | Run |
|---|---|---|
| `fig:Lcoefs`, `fig:legendre_poly_coefs`: Legendre coefficients | `AllPlots.jl` | Stage 3, `DD_PLOT_PROOF=1` |
| `fig:proof_pcfs`: quantile functions, raw vs. factor approximation | `AllPlots.jl` | Stage 3, `DD_PLOT_PROOF=1` |
| `fig:KL_div`: copulas, raw vs. approximation | `AllPlots.jl` | Stage 3, `DD_PLOT_PROOF=1` |
| `fig:recon_missing1`: predictability at baseline parameters | `ForecastSSM.jl` | Stage 3, Step 9 |
| `fig:recon_missing2`: predictability, re-estimated model | `CreateTimeSeries.jl` exports | Stages 2–3 with `replication_{cex_every_4_years,no_recent_20q,no_housing_wealth}` |
| `fig:ow_shares`: information shares | `ObservationWeights(Plots).jl` | Stage 3, Step 8 |
| `fig:ow_interp`: interpolation shares | `ObservationWeights(Plots).jl` | Stage 3, Step 8 |
| `tab:hank_avg_corr`: model vs. HANK truth, 10 economies | `plot_HANK.jl` | `code/hank/README.md` (40/40/20 and 50/40/10 runs) |
| `fig:hank_full_v_incomplete_income`: model vs. HANK truth | `plot_HANK.jl`, assembled by `doc/figure10_404020.tex` | `code/hank/README.md` |
| Consumption dynamics across recessions (9 panels) | `RecessionPanels.jl` (`run_recession_panels.jl` re-plots) | Stage 3 |
| `fig:cons_wealth_along_inc`: consumption over recent business cycles | `prep_micro_data.do` + local projections | standalone Stata |
| `Tables/DataCoverage.tex`: data coverage | hand-written | — |

### Appendix

| Exhibit | Generated by | Run |
|---|---|---|
| `fig:data_timeline`: coverage, sample sizes, publication lags | `count_observations.jl` → `data_timeline.jl` | standalone |
| `fig:tails_wealth`, `fig:local_global_coefs`, `fig:local_global_pcf` | `SeriesEstimator.jl` | standalone |
| `Tables/MDD.tex`: marginal data densities | `run_mdd.jl` → `run_mdd_table.jl` | needs Stage 2 for `replication`, `replication_6_factors`, `replication_7_factors` |
| `fig:likelihood_convergence_missing`: chain convergence | `DIMESampler.jl` | written during Stage 2 |
| `fig:recon_data_SCF`: smoothed data vs. survey estimates | `CreateTimeSeries.jl` (`compare_to_data`) | Stage 3, Step 4 |
| `Tables/ModelConservatism.tex` | `export_combined_stat_dict_to_latex` | Stage 3, Step 4 |
| `fig:recon_ext`: cycle vs. external sources (SCF, DFA) | `Validation.jl` | Stage 3, Step 4 |
| `fig:dist_fact`: distributional factors | `Reconstruction.jl` | Stage 3, Step 4 |
| Correlation tables | `Correlations.jl`, `CorrelationTables.jl` | Stage 3, Step 5 |
| FEVD tables (`tab:fevd_factors`, `tab:fevd_obs_*`) | `FEVD.jl` | Stage 3, Step 6 |
| `fig:hist_decomp`: historical decomposition | `HistoricalDecomposition.jl` | Stage 3, Step 7 |
| Posterior factor draws and bands (DD_data) | `PosteriorDraws.jl` | Stage 3, Step 4b; needs Stage 2 |

The inline tables that transcribe the FEVD and correlation output and the TikZ diagrams are
written by hand in the paper's LaTeX sources.

## Code map

Entry points: `master.sh`, `code/stata/00_master_data.do` (Stage 1), `code/julia/run_estimation.jl`
(Stage 2), `code/julia/run_postestimation.jl` (Stage 3). Paths: `code/julia/config.jl`; model
options: `code/julia/Structures.jl`. File-by-file tree and the anatomy (observation-weight) code:
[`docs/CODE_MAP.md`](docs/CODE_MAP.md).

## Extensions

- **DFA balance-sheet items:** real estate, mortgages, consumer credit, pensions and stocks are published in DD_data `data/items/`, built by `code/python/build_items_ddata.py`; stocks only for the next-40% and top-10% wealth groups. See [`docs/DFA_ITEMS.md`](docs/DFA_ITEMS.md).
- **Own settings or own data:** [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md).
- **HANK validation:** [`code/hank/README.md`](code/hank/README.md).

## Citation, license, contact

Please cite the paper (BibTeX below; metadata in [`CITATION.cff`](CITATION.cff)). Code is
released under the MIT License ([`LICENSE`](LICENSE)). Questions: Luis Calderon,
luis.calderon@uni-bonn.de.

```bibtex
@techreport{BayerCalderonKuhn2026,
  author      = {Bayer, Christian and Calderon, Luis and Kuhn, Moritz},
  title       = {Distributional Dynamics},
  institution = {CEPR},
  type        = {Discussion Paper},
  number      = {19829},
  year        = {2026}
}
```

## References

- Bayer, Christian, Luis Calderon, and Moritz Kuhn. "Distributional Dynamics." CEPR Discussion Paper 19829, 2026.
- Board of Governors of the Federal Reserve System. *Survey of Consumer Finances*. Public data, 1989–2022. https://www.federalreserve.gov/econres/scfindex.htm.
- Board of Governors of the Federal Reserve System. *Distributional Financial Accounts*. https://www.federalreserve.gov/releases/z1/dataviz/dfa/.
- Federal Reserve Bank of St. Louis. *FRED Economic Data*. https://fred.stlouisfed.org/.
- Fernholz, Ricardo T., and Kara Hagler. "Rising Inequality and Declining Mobility in the Forbes 400." *Economics Letters* 230 (2023): 111235.
- Forbes. *The Forbes 400*. 2021–2024. https://www.forbes.com/forbes-400/.
- Panel Study of Income Dynamics. *Public Use Dataset*. Survey Research Center, Institute for Social Research, University of Michigan, Ann Arbor, MI. Various years (1968–2021). https://psidonline.isr.umich.edu/.
- Flood, Sarah, Miriam King, Renae Rodgers, Steven Ruggles, J. Robert Warren, Daniel Backman, Annie Chen, Grace Cooper, Stephanie Richards, Megan Schouweiler, and Michael Westberry. *IPUMS CPS: Version 11.0* [dataset]. Minneapolis, MN: IPUMS, 2023. https://doi.org/10.18128/D030.V11.0.
- Kuhn, Moritz, Moritz Schularick, and Ulrike I. Steins. "Income and Wealth Inequality in America, 1949–2016." *Journal of Political Economy* 128, no. 9 (2020): 3469–3519.
- McCracken, Michael W., and Serena Ng. "FRED-QD: A Quarterly Database for Macroeconomic Research." NBER Working Paper 26872, 2020.
- U.S. Bureau of Labor Statistics. *Consumer Expenditure Surveys*, Interview Survey. 1984–2021. https://www.bls.gov/cex/.
- U.S. Census Bureau. *Survey of Income and Program Participation*. Panels 1984–1993, 1996, 2001, 2004, 2008, 2014 and 2018–2023 releases (reference years 1983–2022). https://www.census.gov/programs-surveys/sipp.html.
- World Inequality Database. *WID.world*. https://wid.world/.
