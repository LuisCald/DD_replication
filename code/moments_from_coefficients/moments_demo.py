#!/usr/bin/env python3
"""
moments_demo.py — turn the published coefficient files into economic moments.

Point estimate only (no posterior uncertainty). For posterior bands, see
`posterior_bands.py` in this folder.

Run from anywhere:

    python moments_demo.py                      # uses PSID, date 2008-Q3
    python moments_demo.py --dataset SCF --date 2020-Q3

Writes `moments_demo_output.csv` next to this script.

Only dependencies: numpy, pandas (same as the core helper it wraps).
"""
from __future__ import annotations

import argparse
import os
import sys

import numpy as np
import pandas as pd

# The canonical, single-source reconstruction helper lives in code/python.
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(REPO, "code", "python"))
from reconstruct import Reconstruction  # noqa: E402

MEASURES = ["consum", "income", "wealth"]
DECILES = np.round(np.arange(0.1, 1.0, 0.1), 2)  # 0.1 … 0.9


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dataset", default="PSID", choices=["PSID", "SCF", "CEX"])
    ap.add_argument("--trend", default="normal", choices=["normal", "average"])
    ap.add_argument("--date", default="2008-Q3")
    args = ap.parse_args()

    csv = os.path.join(
        REPO, "data", "synthetic", f"{args.dataset}_coefficients_{args.trend}.csv"
    )
    if not os.path.exists(csv):
        sys.exit(f"Coefficient file not found: {csv}")

    r = Reconstruction(csv)

    # CEX and SCF do not carry every margin — keep only the ones present.
    measures = [m for m in MEASURES if _has_measure(r, args.date, m)]

    print(f"Dataset {args.dataset} ({args.trend} trend), date {args.date}")
    print(f"Margins available: {', '.join(measures)}\n")

    rows = []
    for m in measures:
        q = r.quantile_at(args.date, m, DECILES)   # decile cut points (rel. to mean)
        print(f"{m:>7} deciles:  " + "  ".join(f"{v:6.3f}" for v in q))
        for u, v in zip(DECILES, q):
            rows.append({"date": args.date, "measure": m, "quantile": u, "value": v})

    # A copula moment: dependence at the joint median.
    if len(measures) == 3:
        c_med = float(r.copula_density_at(args.date, 0.5, 0.5, 0.5))
        print(f"\ncopula density at joint median (0.5,0.5,0.5): {c_med:.4f}")
        rows.append({"date": args.date, "measure": "copula_median",
                     "quantile": np.nan, "value": c_med})

    out = os.path.join(HERE, "moments_demo_output.csv")
    pd.DataFrame(rows).to_csv(out, index=False)
    print(f"\nWrote {out}")


def _has_measure(r: Reconstruction, date: str, measure: str) -> bool:
    try:
        r.quantile_at(date, measure, [0.5])
        return True
    except Exception:
        return False


if __name__ == "__main__":
    main()
