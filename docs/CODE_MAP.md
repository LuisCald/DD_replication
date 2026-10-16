# Code map

Package contents and the main entry points. Paths are relative to the repository root
(`5_Code/`). Run instructions are in the [README](../README.md).

## Package contents

```
├── README.md                     Landing page: data availability, requirements, replication map
├── LICENSE
├── master.sh                     Master replication script
│
├── code/
│   ├── julia/
│   │   ├── DistributionalDynamics.jl   Main Julia entry point (loads all modules)
│   │   ├── run_estimation.jl           Stage 2: MCMC estimation
│   │   ├── run_postestimation.jl       Stage 3: results, figures, tables
│   │   ├── run_mdd.jl, run_mdd_table.jl  Marginal data densities → Tables/MDD.tex
│   │   ├── run_dropwave.jl, run_dropwave_table.jl  Drop-one-wave exercise (diagnostic; not in the paper)
│   │   ├── run_recession_panels.jl     Re-plot the recession panels
│   │   ├── run_proof_of_concept.jl     Proof-of-concept figures
│   │   ├── RecessionPanels.jl          Recession panels (consumption by income × wealth)
│   │   ├── plot_HANK.jl                HANK validation table and Figure 10 panels
│   │   ├── SeriesEstimator.jl          Order analysis / local vs. global estimator
│   │   ├── examples/                   DD_EXAMPLE configurations (Structures_<name>.jl)
│   │   ├── config.jl                   Path configuration
│   │   ├── Structures.jl              Data structures and model options
│   │   ├── DataConstructor.jl         Data loading and preprocessing
│   │   ├── ModelPrep.jl               Functional data preparation and PCA
│   │   ├── Model.jl                   State-space model specification
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
│   │   ├── AllPlots.jl                Proof-of-concept and main figures
│   │   ├── CEXFunctions.jl            CEX data utilities
│   │   ├── MDD.jl                     Marginal data density
│   │   ├── SupportingFunctions.jl     Utility functions
│   │   └── env/                       Julia environment (Project.toml, Manifest.toml)
│   ├── stata/
│   │   ├── 00_master_data.do          Master Stata script (Stage 1)
│   │   ├── data_cleaning.do           Main survey data cleaning (SCF, PSID, CEX, ACS, CPS)
│   │   ├── clean_SCF_2022.do          SCF 2022 wave cleaning
│   │   ├── master_sipp_file.do        SIPP construction (raw panels → SIPP1-3.csv)
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
│   │   ├── consumption_recessions.do  Recession consumption panels (post-estimation)
│   │   ├── other_results.do           Aggregate correlations
│   │   └── SIPP/                      Legacy Census ASCII readers (unused by the pipeline)
│   ├── python/
│   │   ├── convert_monthly_to_quarterly.py  Frequency conversion
│   │   ├── make_stationary.py         Stationarity transformations
│   │   ├── make_stationary_x12.py     Post-X12 stationarity tests
│   │   ├── generateForbes400.py       Forbes 400 wealth data
│   │   ├── build_items_ddata.py       DFA item files for DD_data
│   │   ├── MEILC_MEGC.py             Multivariate Gini coefficient
│   │   └── multidim_inequality.py     Multidimensional inequality measures
│   ├── R/
│   │   └── X12_averages.R             X-12 deseasoning of DFA-component anchors (optional)
│   └── hank/                          HANK validation: BASEtoolbox drivers + README
│
├── docs/                              USER_GUIDE.md, DFA_ITEMS.md, CODE_MAP.md (this file)
│
├── data/raw/DOWNLOAD_INSTRUCTIONS.md  Where to get the raw survey data
├── output/estimates/                  Pre-computed posterior-mode parameter vector
│
├── doc/
│   ├── figure10_404020.tex            Assembles the HANK Figure 10 panels
│   └── linearization_notes.tex        Note on linearization in the microdata generation
│
└── CITATION.cff                       Machine-readable citation
```

Files not listed are development or diagnostic scripts not needed for the paper's exhibits.

## Anatomy of the synthetic data (information and interpolation shares)

The paper's "anatomy" figures ask *whose data* the estimate leans on and *where
the panel is data-rich and where it is model-driven*. They come from an exact,
source-additive decomposition of the smoothed states (Koopman & Harvey, 2003):

- [`code/julia/ObservationWeights.jl`](../code/julia/ObservationWeights.jl):
  `observation_weight_decomposition` (per-source contribution to each smoothed
  factor) and `information_shares` (absolute-weight shares $s^b_{k,t}$).
- [`code/julia/ObservationWeightsPlots.jl`](../code/julia/ObservationWeightsPlots.jl):
  the **information-share** figure (stacked $s^b_{k,t}$ by source) and the
  **interpolation-share** figure ($\iota_{k,t}=\sigma^2_{k,t\mid T}/P^\infty_{kk}$,
  data-pinned vs. model-driven).
- [`code/julia/count_observations.jl`](../code/julia/count_observations.jl) +
  [`code/julia/data_timeline.jl`](../code/julia/data_timeline.jl) give the appendix
  data-timeline figure (micro sample sizes and coverage by source over time).

The `ObservationWeights*` functions load with the model
(`DistributionalDynamics.jl`); the two `*timeline*` scripts are standalone
(they activate `code/julia/env` themselves) and read the cleaned survey files in `2_Data_processing/`.
