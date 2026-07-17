# User guide

This package supports three kinds of users. Pick the lane that matches what you want:

| Lane | You want… | Start here |
|---|---|---|
| 1 | The published data, or custom moments / micro data computed from it | [github.com/LuisCald/DD_data](https://github.com/LuisCald/DD_data) |
| 2 | To re-run the model with your own settings (different tag, factor count, muted waves, etc.) | [§ Run the model](#run-the-model-yourself) |

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
