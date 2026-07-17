#!/usr/bin/env python3
"""
coefficients_to_micro_data.py — synthetic micro data from the published
coefficient files. Python twin of coefficients_to_micro_data.jl; see that
file's header for the full documentation (row layout, how it follows
CreateTimeSeries.jl / construct_micro_dataset, and units).

Short version: one weighted synthetic cross-section per quarter — one row per
cell of the 10x10x10 decile copula grid. `cop_share` is the cell's household
weight share; consum/income/wealth are decile AVERAGES relative to the
per-household mean. Scale to dollar levels with
data/synthetic/aggregate_anchors.csv (level = value * <measure>_per_hh).

    python coefficients_to_micro_data.py                        # PSID, all quarters
    python coefficients_to_micro_data.py --dataset PSID --date 2008-Q3

Dependencies: numpy, pandas.
"""
from __future__ import annotations

import argparse
import os
import sys

import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(REPO, "code", "python"))
from reconstruct import Reconstruction  # noqa: E402

MEASURES = ["consum", "income", "wealth"]   # alphabetical — model convention
GRID = 10
NODES_PER_DECILE = 32


def decile_averages(r: Reconstruction, date: str, measure: str) -> np.ndarray:
    """Mean of the quantile function within each decile (mirrors the quadgk
    decile integral in CreateTimeSeries.jl; exact for the polynomial basis)."""
    avgs = np.zeros(GRID)
    for d in range(GRID):
        us = d / GRID + (np.arange(NODES_PER_DECILE) + 0.5) / (GRID * NODES_PER_DECILE)
        avgs[d] = float(np.mean(r.quantile_at(date, measure, us)))
    return avgs


def micro_rows(r: Reconstruction, date: str, digits: int = 6) -> pd.DataFrame:
    pmf = r.copula_pmf_grid(date)                      # 10x10x10, matches ciw_*
    q = {m: np.round(decile_averages(r, date, m), digits) for m in MEASURES}
    rows = []
    for i in range(1, GRID + 1):                        # same order as construct_micro_dataset
        for j in range(1, GRID + 1):
            for k in range(1, GRID + 1):
                rows.append((round(float(pmf[i - 1, j - 1, k - 1]), digits),
                             int(f"{i}{j}{k}"),
                             q["consum"][i - 1], q["income"][j - 1], q["wealth"][k - 1],
                             i, j, k, date))
    return pd.DataFrame(rows, columns=["cop_share", "grid_point", *MEASURES,
                                       "consumgrid", "incomegrid", "wealthgrid", "time"])


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dataset", default="PSID", choices=["PSID", "SCF", "CEX"])
    ap.add_argument("--trend", default="normal", choices=["normal", "average"])
    ap.add_argument("--date", default=None, help="one quarter, e.g. 2008-Q3; omit for all")
    args = ap.parse_args()

    csv = os.path.join(REPO, "data", "synthetic",
                       f"{args.dataset}_coefficients_{args.trend}.csv")
    if not os.path.exists(csv):
        sys.exit(f"Coefficient file not found: {csv}")
    r = Reconstruction(csv)

    dates = [args.date] if args.date else r.available_dates()
    out = pd.concat([micro_rows(r, d) for d in dates], ignore_index=True)

    dest = os.path.join(REPO, "data", "synthetic",
                        f"{args.dataset}_synthetic_microdata.csv")
    out.to_csv(dest, index=False)
    print(f"Wrote {len(out)} rows ({len(dates)} quarters x {GRID**3} cells) -> {dest}")


if __name__ == "__main__":
    main()
