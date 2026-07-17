#!/usr/bin/env python3
"""
posterior_bands.py — posterior bands on any moment, from the factor draws.

Pipeline:  posterior factor draws  --(FactorMap)-->  coefficients  -->  moment.

`FactorMap` (in code/python/reconstruct.py) learns the linear map factors ->
coefficients from the published point-estimate files. Feeding each posterior
factor draw through it yields a posterior distribution over any moment
(marginal quantiles, copula density, top-share, …). Here we demo marginal
deciles; swap in whatever moment you need.

    python posterior_bands.py                              # wealth deciles, 2008-Q3
    python posterior_bands.py --measure income --date 2020-Q3 --lo 0.10 --hi 0.90

Needs the factor draws (data/synthetic/smoothed_factor_draws.csv). Writes
`posterior_bands_output.csv` and a plot next to this script.

Dependencies: numpy, pandas, matplotlib.
"""
from __future__ import annotations

import argparse
import os
import sys

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SYNTH = os.path.join(REPO, "data", "synthetic")
sys.path.insert(0, os.path.join(REPO, "code", "python"))
from reconstruct import FactorMap  # noqa: E402


def factors_4q_for_draw(sub: pd.DataFrame, date: str, K: int) -> np.ndarray | None:
    """4-quarter-average of factors x1..xK ending at `date`, for one draw.

    Mirrors FactorMap's F_4q = mean(F_t, F_{t-1}, F_{t-2}, F_{t-3}); annual
    surveys average four quarters of the factor path.
    """
    sub = sub.sort_values("time").reset_index(drop=True)
    if date not in set(sub["time"]):
        return None
    j = sub.index[sub["time"] == date][0]
    if j < 3:
        return None
    block = sub.loc[j - 3:j, [f"x{i}" for i in range(1, K + 1)]].to_numpy()
    return block.mean(axis=0)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dataset", default="PSID", choices=["PSID", "SCF", "CEX"])
    ap.add_argument("--measure", default="wealth", choices=["consum", "income", "wealth"])
    ap.add_argument("--date", default="2008-Q3")
    ap.add_argument("--draws", default=os.path.join(SYNTH, "smoothed_factor_draws.csv"))
    ap.add_argument("--lo", type=float, default=0.05)
    ap.add_argument("--hi", type=float, default=0.95)
    args = ap.parse_args()

    if not os.path.exists(args.draws):
        raise SystemExit(
            f"Draws file not found: {args.draws}\n"
            "Run Stage 2 then the post-estimation export (export_factor_draws)."
        )

    # FactorMap fit on the point estimate (average-trend variant → intercept
    # absorbs the constant trend, R^2 ~ 1.0).
    coeff = os.path.join(SYNTH, f"{args.dataset}_coefficients_average.csv")
    fm = FactorMap(coeff, os.path.join(SYNTH, "smoothed_factors.csv"))
    K = fm.K

    draws = pd.read_csv(args.draws)
    u = np.round(np.arange(0.1, 1.0, 0.1), 2)   # deciles

    # point estimate
    q_point = fm.quantile_at(fm.factors_at(args.date), args.measure, u)

    # posterior: one moment vector per draw
    per_draw = []
    for _, sub in draws.groupby("draw"):
        F = factors_4q_for_draw(sub, args.date, K)
        if F is None:
            continue
        per_draw.append(fm.quantile_at(F, args.measure, u))
    if not per_draw:
        raise SystemExit(f"No draw had 4 quarters of data ending at {args.date}.")
    M = np.vstack(per_draw)                       # (n_draws, 9)

    lo = np.quantile(M, args.lo, axis=0)
    med = np.quantile(M, 0.5, axis=0)
    hi = np.quantile(M, args.hi, axis=0)

    out = pd.DataFrame({
        "decile": u, "point": q_point, "post_median": med,
        f"p{int(args.lo*100):02d}": lo, f"p{int(args.hi*100):02d}": hi,
    })
    dest = os.path.join(HERE, "posterior_bands_output.csv")
    out.to_csv(dest, index=False)
    print(f"{args.measure} deciles at {args.date} ({M.shape[0]} draws):")
    print(out.to_string(index=False, float_format=lambda v: f"{v:7.3f}"))
    print(f"\nWrote {dest}")

    fig, ax = plt.subplots(figsize=(6.5, 4))
    ax.fill_between(u, lo, hi, alpha=0.3, color="#c44",
                    label=f"{int(args.lo*100)}–{int(args.hi*100)}% posterior")
    ax.plot(u, med, color="#c44", lw=1.2, label="posterior median")
    ax.plot(u, q_point, "k--", lw=1.2, label="point estimate")
    ax.set_xlabel("Quantile u")
    ax.set_ylabel(f"{args.measure} (relative to mean)")
    ax.set_title(f"{args.dataset} {args.measure} deciles — {args.date}")
    ax.legend(fontsize=8)
    fig.tight_layout()
    png = os.path.join(HERE, "posterior_bands_output.png")
    fig.savefig(png, dpi=150, bbox_inches="tight")
    print(f"Wrote {png}")


if __name__ == "__main__":
    main()
