# User guide

This package supports three kinds of users. Pick the lane that matches what you want:

| Lane | You want… | Start here |
|---|---|---|
| 1 | The published quarterly distributional data — straight off the shelf | [§ 1](#1-just-the-data) |
| 2 | Custom moments (quantiles, copula density, counterfactual factor values) computed from the published coefficients | [§ 2](#2-compute-custom-moments-from-coefficients) |
| 3 | To re-run the model with your own settings (different tag, factor count, muted waves, etc.) | [§ 3](#3-run-the-model-yourself) |

---

## 1. Just the data

Every CSV in [`data/synthetic/`](../data/synthetic/) is quarterly **1962-Q3 → 2024-Q1**, joint over consumption, income, and wealth. See [`data/synthetic/README.md`](../data/synthetic/README.md) for column-by-column documentation. The two most useful files for a quick start:

```python
import pandas as pd

# 43 latent factors F_t — most compact summary of the joint dynamics
F = pd.read_csv("data/synthetic/smoothed_factors.csv", index_col="time")

# Reconstructed PSID coefficients (in-sample, HP-trend conventions)
psid = pd.read_csv("data/synthetic/PSID_coefficients_normal.csv", index_col="time")
```

**Trend convention.** Files named `_normal` re-add the HP-filter trend (date-anchored, use inside 1962–2024). Files named `_average` re-add the time-averaged trend (extrapolation-friendly).

**Functional data vs coefficients.** `*_functional_data*.csv` are *inputs* to the state-space model (per-dataset $\hat\phi^j_t$, NaN where the survey wasn't run). `*_coefficients_*.csv` are *outputs* (Kalman-smoother reconstructions, dense across all 248 quarters).

---

## 2. Compute custom moments from coefficients

The published coefficient files store Legendre polynomial weights. To turn them into moments you can plot (decile means, copula densities at arbitrary points, etc.), use the small standalone helpers shipped with the repo:

* Python: [`code/python/reconstruct.py`](../code/python/reconstruct.py) — needs only `numpy` + `pandas`
* Julia: [`code/julia/reconstruct.jl`](../code/julia/reconstruct.jl) — needs only `CSV.jl` + `DataFrames.jl`

Both implement the same orthonormal Legendre basis $Q_o(u) = \sqrt{2o+1}\,P_o(2u-1)$ and agree to machine precision.

### Marginal quantile function

```python
from reconstruct import Reconstruction
r = Reconstruction("data/synthetic/PSID_coefficients_normal.csv")
r.quantile_at("2008-Q3", "consum", [0.1, 0.5, 0.9])
# → array([0.320, 0.734, 1.386])    (relative to per-HH mean)
```

```julia
using .DistributionalReconstruction
r = Reconstruction("data/synthetic/PSID_coefficients_normal.csv")
quantile_at(r, "2008-Q3", :consum, [0.1, 0.5, 0.9])
```

### Copula density

```python
r.copula_density_at("2008-Q3", 0.5, 0.5, 0.5)        # density at the joint median
r.copula_density_grid("2008-Q3", n=30)               # 30³ grid for plotting
r.copula_pmf_grid("2008-Q3")                         # 10³ probability masses (matches the published ciw_*)
```

### Factor → coefficient mapping (`FactorMap`)

If you want to ask *"what would the joint distribution look like if factor 3 were one standard deviation higher?"*, you can learn an OLS map from the published `smoothed_factors.csv` to any coefficient time series, and then plug arbitrary factor vectors through it:

```python
from reconstruct import FactorMap

# Learn the OLS map (one regression per coefficient)
fm = FactorMap(
    "data/synthetic/smoothed_factors.csv",
    "data/synthetic/PSID_coefficients_normal.csv",
    n_factors=8,                  # 8 distributional factors; use 43 for all
)
print(fm.summary())
# FactorMap: K=8, T_used=100 (dropped 147 NaN rows of 247),
#   R² median=0.222, R² P25/P75=(0.155, 0.301)

# Pick a factor vector — historical mid-2008 values, then perturb F_1 by +1 SD
import numpy as np
F = np.zeros(8); F[0] = 1.0
fm.quantile_at(F, "consum", [0.1, 0.5, 0.9])
fm.copula_density_at(F, 0.5, 0.5, 0.5)
```

Julia mirrors the API:

```julia
fm = FactorMap("data/synthetic/smoothed_factors.csv",
               "data/synthetic/PSID_coefficients_normal.csv";
               n_factors=8)
println(DistributionalReconstruction.summary(fm))

F = zeros(8); F[1] = 1.0
quantile_at(fm, F, :consum, [0.1, 0.5, 0.9])
copula_density_at(fm, F, 0.5, 0.5, 0.5)
```

R² is moderate at K=8 (the model's own state-space recovery uses PCA + Kalman smoothing — OLS is a linear approximation). Adding more factors (`n_factors=43` uses the full file) drives R² up significantly.

### How `FactorMap` works

For each coefficient column $j$ separately, the helper runs

$$\text{coef}_{j,t} = \alpha_j + \beta_j^\top F_t + \varepsilon_{j,t}$$

on the rows where every coefficient is fully observed (NaN rows are dropped — necessary because some surveys are absent in some periods). The Y side is standardized for numerical stability; predictions are un-standardized before being returned.

---

## 3. Run the model yourself

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

When the run finishes, drop the newly generated `*_coefficients_*.csv`, `*_functional_data*.csv`, and `smoothed_factors.csv` into `data/synthetic/` (overwriting the previous publication) and re-run the validation in [`code/python/validate_reconstruction.py`](../code/python/validate_reconstruction.py) to confirm coherence between the coefficient and functional-data outputs.
