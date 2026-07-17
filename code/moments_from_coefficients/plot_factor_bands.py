#!/usr/bin/env python3
"""
plot_factor_bands.py — plot the smoothed latent factors with posterior bands.

Reads
  * data/synthetic/smoothed_factor_draws.csv  (posterior draws: draw,time,x1..xR)
  * data/synthetic/smoothed_factors.csv        (point estimate:  time,x1..xR)

and draws each factor as a point-estimate line inside a shaded posterior band
(default 5–95%). The draws file is produced by the Julia routine
`export_factor_draws` (see PosteriorDraws.jl); run Stage 2 + the post-estimation
export first, or pass --draws to point elsewhere.

    python plot_factor_bands.py                 # first 8 factors, 5-95% band
    python plot_factor_bands.py --n 12 --lo 0.10 --hi 0.90
    python plot_factor_bands.py --factors 1,2,3,8

Dependencies: numpy, pandas, matplotlib.
"""
from __future__ import annotations

import argparse
import os

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SYNTH = os.path.join(REPO, "data", "synthetic")


def _quarter_to_num(s: pd.Series) -> np.ndarray:
    """'1962-Q3' -> 1962.5 (year + (q-1)/4), for a monotone x-axis."""
    yr = s.str.slice(0, 4).astype(int)
    q = s.str.slice(6, 7).astype(int)
    return (yr + (q - 1) / 4.0).to_numpy()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--draws", default=os.path.join(SYNTH, "smoothed_factor_draws.csv"))
    ap.add_argument("--point", default=os.path.join(SYNTH, "smoothed_factors.csv"))
    ap.add_argument("--n", type=int, default=8, help="number of factors (x1..xN)")
    ap.add_argument("--factors", default=None, help="explicit comma list, e.g. 1,2,8")
    ap.add_argument("--lo", type=float, default=0.05)
    ap.add_argument("--hi", type=float, default=0.95)
    ap.add_argument("--out", default=os.path.join(HERE, "factor_posterior_bands.pdf"))
    args = ap.parse_args()

    if not os.path.exists(args.draws):
        raise SystemExit(
            f"Draws file not found: {args.draws}\n"
            "Generate it first: run Stage 2, then the post-estimation export "
            "(export_factor_draws in PosteriorDraws.jl), which writes "
            "data/synthetic/smoothed_factor_draws.csv."
        )

    draws = pd.read_csv(args.draws)
    point = pd.read_csv(args.point) if os.path.exists(args.point) else None

    if args.factors:
        idx = [int(i) for i in args.factors.split(",")]
    else:
        idx = list(range(1, args.n + 1))
    cols = [f"x{i}" for i in idx]
    missing = [c for c in cols if c not in draws.columns]
    if missing:
        raise SystemExit(f"Draws file missing columns: {missing}")

    # posterior percentiles by quarter
    g = draws.groupby("time")
    med = g[cols].median()
    lo = g[cols].quantile(args.lo)
    hi = g[cols].quantile(args.hi)
    times = med.index.to_series()
    x = _quarter_to_num(times)
    order = np.argsort(x)
    x = x[order]

    n_draws = draws["draw"].nunique()

    ncol = 2
    nrow = int(np.ceil(len(cols) / ncol))
    fig, axes = plt.subplots(nrow, ncol, figsize=(11, 2.1 * nrow), sharex=True)
    axes = np.atleast_1d(axes).ravel()

    for ax, c in zip(axes, cols):
        ax.fill_between(x, lo[c].to_numpy()[order], hi[c].to_numpy()[order],
                        alpha=0.28, color="#c44", linewidth=0,
                        label=f"{int(args.lo*100)}–{int(args.hi*100)}%")
        ax.plot(x, med[c].to_numpy()[order], color="#c44", lw=0.9, label="post. median")
        if point is not None and c in point.columns:
            px = _quarter_to_num(point["time"])
            po = np.argsort(px)
            ax.plot(px[po], point[c].to_numpy()[po], color="k", lw=1.0,
                    label="point estimate")
        ax.axhline(0, color="0.7", lw=0.5)
        ax.set_title(f"Factor {c[1:]}", fontsize=9)
        ax.tick_params(labelsize=8)

    for ax in axes[len(cols):]:
        ax.set_visible(False)

    axes[0].legend(fontsize=7, loc="best", framealpha=0.8)
    fig.suptitle(f"Smoothed distributional factors — posterior bands "
                 f"({n_draws} draws)", fontsize=11)
    fig.supxlabel("Year", fontsize=9)
    fig.tight_layout(rect=(0, 0.01, 1, 0.98))
    fig.savefig(args.out, bbox_inches="tight")
    png = os.path.splitext(args.out)[0] + ".png"
    fig.savefig(png, dpi=150, bbox_inches="tight")
    print(f"Wrote {args.out}\nWrote {png}")


if __name__ == "__main__":
    main()
