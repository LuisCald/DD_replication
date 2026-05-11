"""
Self-consistency check for `reconstruct.py`.

The published `*_functional_data*.csv` files store the same model output as
`*_coefficients_*.csv`, but already evaluated on a 10x10x10 grid (copula
density) and at decile intervals (marginal quantile). This script checks that
running our reconstruction on the polynomial coefficients reproduces those
evaluated values.

Two tests:

1. **Copula density.** For each date, compare our `copula_density_at` at the
   published grid points to `ciw_<i><j><k>` columns. No aggregate scaling
   needed — the copula is dimension-free. Should match within numerical
   tolerance.

2. **Marginal quantile.** The published `quantiles<measure>_<u>` is
       decile_avg( sinh(our_quantile(u)) ) * per_HH_aggregate(t, measure).
   We do not have the FRED aggregate handy, so we instead check that the
   ratio published / decile_avg(sinh(our_quantile)) is *constant across
   deciles* for a given date — i.e., a single multiplicative constant
   (the aggregate) explains the entire decile profile.

Usage:
    python validate_reconstruction.py PSID
    python validate_reconstruction.py SCF
    python validate_reconstruction.py CEX   # marginals only; CEX has no wealth
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd

# Resolve sibling import
sys.path.insert(0, str(Path(__file__).resolve().parent))
from reconstruct import GRID_COP, GRID_PCF, MEASURES, Q, Reconstruction  # noqa: E402


GRID_X = np.array([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.999999])
DECILE_EDGES = np.concatenate([[1e-6], GRID_X])  # 11 edges -> 10 intervals


def parse_ciw_index(colname: str) -> tuple[int, int, int]:
    """Parse 'ciw_321.0' -> (3, 2, 1). Greedy parse: '10' counted as one digit."""
    s = colname.replace("ciw_", "").rstrip("0").rstrip(".").rstrip("0")
    # Above strips trailing zeros — but we want '111' -> (1,1,1) which after
    # rstrip('0') becomes '111'. For '1010' -> '101', not (10,1,0). Safer:
    s = re.match(r"ciw_(\d+)(?:\.\d+)?", colname).group(1)
    idx = []
    i = 0
    while i < len(s):
        if s[i:i + 2] == "10":
            idx.append(10)
            i += 2
        else:
            idx.append(int(s[i]))
            i += 1
    if len(idx) != 3:
        raise ValueError(f"could not parse {colname!r} into 3 indices, got {idx}")
    return tuple(idx)


def _legendre_integral_table() -> np.ndarray:
    """
    integrals[m, k] = integral of Q_m(u) on [edge_k, edge_{k+1}] (k = 0..9).

    Closed-form antiderivative would be cleaner; here we use 200-point
    Gauss-Legendre once and cache.
    """
    # nodes/weights on [-1, 1]
    nodes, weights = np.polynomial.legendre.leggauss(200)
    tbl = np.zeros((GRID_PCF, 10), dtype=float)
    for k in range(10):
        a, b = DECILE_EDGES[k], DECILE_EDGES[k + 1]
        u = 0.5 * (b - a) * nodes + 0.5 * (a + b)
        for m in range(GRID_PCF):
            tbl[m, k] = 0.5 * (b - a) * np.sum(weights * Q(m, u))
    return tbl


def _decile_avg_of_sinh(xi: np.ndarray) -> np.ndarray:
    """
    Decile averages of sinh( sum_m xi[m] * Q_m(u) ), using 200-point quadrature
    inside each decile interval.
    """
    nodes, weights = np.polynomial.legendre.leggauss(200)
    out = np.zeros(10, dtype=float)
    for k in range(10):
        a, b = DECILE_EDGES[k], DECILE_EDGES[k + 1]
        u = 0.5 * (b - a) * nodes + 0.5 * (a + b)
        q_vals = sum(xi[m] * Q(m, u) for m in range(GRID_PCF))
        out[k] = 0.5 * np.sum(weights * np.sinh(q_vals))  # = integral
        out[k] /= (b - a)
    return out


def _legendre_P(n: int, x: np.ndarray) -> np.ndarray:
    """Standard Legendre P_n on [-1, 1]."""
    if n == 0:
        return np.ones_like(x, dtype=float)
    if n == 1:
        return np.asarray(x, dtype=float)
    pm2 = np.ones_like(x, dtype=float)
    pm1 = np.asarray(x, dtype=float)
    for k in range(2, n + 1):
        p = ((2 * k - 1) * x * pm1 - (k - 1) * pm2) / k
        pm2, pm1 = pm1, p
    return pm1


def _integrate_Q(m: int, u_arr: np.ndarray) -> np.ndarray:
    """
    I_m(u) = integral of Q_m(s) on [0, u], vectorized over u.

    Q_0(u) = 1 -> I_0(u) = u.
    For m >= 1: closed form derived from Bonnet's recursion,
        I_m(u) = (1 / (2*sqrt(2m+1))) * (P_{m+1}(2u-1) - P_{m-1}(2u-1))
    (the boundary terms at -1 cancel because P_n(-1) = (-1)^n).
    """
    u_arr = np.asarray(u_arr, dtype=float)
    if m == 0:
        return u_arr.copy()
    x = 2 * u_arr - 1
    return (_legendre_P(m + 1, x) - _legendre_P(m - 1, x)) / (2 * np.sqrt(2 * m + 1))


def _cdf_to_pmf_3d(cdf: np.ndarray) -> np.ndarray:
    """3D inclusion-exclusion: pmf[i,j,k] = prob. mass in (x_{i-1}, x_i] x ...

    Matches `cdf_to_pdf` in Reconstruction.jl:2164 — including the
    non-negativity clip and final normalization to sum to 1.
    """
    pmf = np.zeros_like(cdf)
    n1, n2, n3 = cdf.shape
    for i in range(n1):
        for j in range(n2):
            for k in range(n3):
                c = cdf[i, j, k]
                a = cdf[i - 1, j, k] if i > 0 else 0.0
                b = cdf[i, j - 1, k] if j > 0 else 0.0
                e = cdf[i, j, k - 1] if k > 0 else 0.0
                ab = cdf[i - 1, j - 1, k] if (i > 0 and j > 0) else 0.0
                ae = cdf[i - 1, j, k - 1] if (i > 0 and k > 0) else 0.0
                be = cdf[i, j - 1, k - 1] if (j > 0 and k > 0) else 0.0
                abe = cdf[i - 1, j - 1, k - 1] if (i > 0 and j > 0 and k > 0) else 0.0
                pmf[i, j, k] = c - a - b - e + ab + ae + be - abe
    pmf[pmf < 0] = 0
    s = pmf.sum()
    if s > 0:
        pmf /= s
    return pmf


def validate_copula(r: Reconstruction, func_df: pd.DataFrame) -> dict:
    """
    The published `ciw_<i><j><k>` is the discrete probability mass in cell
    (x_{i-1}, x_i] x (x_{j-1}, x_j] x (x_{k-1}, x_k], normalized to sum to 1
    (see `cdf_to_pdf` in Reconstruction.jl:2164). We reproduce that by:
      1. Evaluating the copula CDF on the 10x10x10 grid via I_m(x_i):
            C(x_i, x_j, x_k) = sum_m kappa[m] * I_{m1}(x_i) I_{m2}(x_j) I_{m3}(x_k)
      2. Applying 3D inclusion-exclusion + non-neg clip + normalize.
    """
    ciw_cols = [c for c in func_df.columns if c.startswith("ciw_")]
    idx_to_col = {parse_ciw_index(c): c for c in ciw_cols}
    expected_keys = {(i, j, k) for i in range(1, 11) for j in range(1, 11) for k in range(1, 11)}
    missing = expected_keys - idx_to_col.keys()
    if missing:
        raise RuntimeError(f"functional_data missing {len(missing)} ciw columns")

    # Pre-compute I[m, ui] = integral of Q_m on [0, GRID_X[ui]]
    I = np.stack([_integrate_Q(m, GRID_X) for m in range(GRID_COP)], axis=0)  # (12, 10)

    dates_common = sorted(set(r.available_dates()) & set(func_df["time"].astype(str)))
    diffs, mine_all, pub_all = [], [], []
    for date in dates_common:
        try:
            kappa = r._kappa(date)
        except KeyError:
            continue
        # CDF on the grid via einsum over polynomial-order axes
        cdf = np.einsum("abc,ai,bj,ck->ijk", kappa, I, I, I)
        mine = _cdf_to_pmf_3d(cdf)

        row = func_df.loc[func_df["time"].astype(str) == date].iloc[0]
        pub = np.empty_like(mine)
        for (i, j, k), col in idx_to_col.items():
            pub[i - 1, j - 1, k - 1] = row[col]
        if np.any(np.isnan(pub)):
            continue
        diffs.append(np.abs(mine - pub).ravel())
        mine_all.append(mine.ravel())
        pub_all.append(pub.ravel())

    if not diffs:
        return {"n_dates": 0}
    d = np.concatenate(diffs)
    m = np.concatenate(mine_all)
    p = np.concatenate(pub_all)
    return {
        "n_dates": len(diffs),
        "mae": float(np.mean(d)),
        "max_abs_err": float(np.max(d)),
        "median_abs_err": float(np.median(d)),
        "rel_mae_no_zeros": float(np.mean(d[p > 1e-8] / p[p > 1e-8])) if np.any(p > 1e-8) else float("nan"),
        "pearson_r": float(np.corrcoef(m, p)[0, 1]),
    }


def validate_marginals(r: Reconstruction, func_df: pd.DataFrame, dataset: str) -> dict:
    """
    For each (date, measure), check that the multiplicative factor
        c(t, measure) := published_decile / decile_avg(sinh(mine))
    is *constant across deciles*. We report the coefficient of variation
    (std / mean across deciles), averaged over dates.
    """
    out = {}
    for measure in MEASURES:
        prefix = f"quantiles{measure}_"
        cols = [c for c in func_df.columns if c.startswith(prefix)]
        if not cols:
            continue
        # column order in functional_data follows DECILE_EDGES[1:]
        suffixes = [float(c.replace(prefix, "")) for c in cols]
        order = np.argsort(suffixes)
        cols_sorted = [cols[i] for i in order]

        dates_common = sorted(set(r.available_dates()) & set(func_df["time"].astype(str)))
        cvs = []
        for date in dates_common:
            try:
                xi = r._xi(date, measure)
            except KeyError:
                continue
            row = func_df.loc[func_df["time"].astype(str) == date].iloc[0]
            pub = np.asarray([row[c] for c in cols_sorted], dtype=float)
            if np.any(np.isnan(pub)):
                continue
            mine_sinh = _decile_avg_of_sinh(xi)
            if np.any(np.abs(mine_sinh) < 1e-12):
                continue
            ratio = pub / mine_sinh
            cv = float(np.std(ratio) / np.abs(np.mean(ratio)))
            cvs.append(cv)
        if cvs:
            out[measure] = {
                "n_dates": len(cvs),
                "median_cv": float(np.median(cvs)),
                "p95_cv": float(np.quantile(cvs, 0.95)),
                "max_cv": float(np.max(cvs)),
            }
    out["_dataset"] = dataset
    return out


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    p.add_argument("dataset", choices=("PSID", "SCF", "CEX"), help="Which dataset to validate")
    p.add_argument(
        "--data-dir",
        default="data/synthetic",
        help="Folder with the published CSVs",
    )
    args = p.parse_args()

    data = Path(args.data_dir)
    coef_path = data / f"{args.dataset}_coefficients_normal.csv"
    func_path = data / f"{args.dataset}_functional_data.csv"
    if not coef_path.exists() or not func_path.exists():
        sys.exit(f"missing {coef_path} or {func_path}")

    r = Reconstruction(coef_path)
    func_df = pd.read_csv(func_path)

    print(f"=== {args.dataset}: copula density ===")
    if any(c.startswith("ciw_") for c in func_df.columns):
        stats = validate_copula(r, func_df)
        for k, v in stats.items():
            print(f"  {k}: {v}")
    else:
        print("  (no ciw_ columns in functional_data — skipping)")

    print(f"\n=== {args.dataset}: marginals (decile profile invariance) ===")
    print("  Each ratio published / decile_avg(sinh(mine)) should equal the same")
    print("  per-HH aggregate across all 10 deciles.  Coefficient of variation")
    print("  across deciles should be effectively 0 if the reconstruction matches.")
    stats_m = validate_marginals(r, func_df, args.dataset)
    for measure in MEASURES:
        if measure in stats_m:
            s = stats_m[measure]
            print(f"  {measure}: n_dates={s['n_dates']}  median_cv={s['median_cv']:.2e}  p95_cv={s['p95_cv']:.2e}  max_cv={s['max_cv']:.2e}")


if __name__ == "__main__":
    main()
