#!/usr/bin/env python3
"""
factors_to_coefficients.py — reconstruct coefficient rows from the smoothed
factors (the FactorMap bridge). Python twin of factors_to_coefficients.jl;
see that file's header. Middle stage of the pipeline

    factors  ->  coefficients  ->  moments / micro data

and the counterfactual hook:

    from factors_to_coefficients import fit
    fm = fit("PSID")
    F = fm.factors_at("2008-Q3"); F[0] += 1.0      # shock factor 1
    row = fm.predict(F)                            # counterfactual coefficients

    python factors_to_coefficients.py              # writes reconstructed rows
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
from reconstruct import FactorMap  # noqa: E402


def fit(dataset: str = "PSID") -> FactorMap:
    return FactorMap(
        os.path.join(REPO, "data", "synthetic", f"{dataset}_coefficients_average.csv"),
        os.path.join(REPO, "data", "synthetic", "smoothed_factors.csv"),
    )


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dataset", default="PSID", choices=["PSID", "SCF", "CEX"])
    args = ap.parse_args()

    fm = fit(args.dataset)
    print(fm.summary())

    rows = np.vstack([fm.predict(fm.factors_4q[i]) for i in range(len(fm.dates_used))])
    out = pd.DataFrame(rows, columns=[f"x{i+1}" for i in range(rows.shape[1])])
    out.insert(0, "time", fm.dates_used)
    dest = os.path.join(HERE, f"{args.dataset}_coefficients_reconstructed.csv")
    out.to_csv(dest, index=False)
    print(f"Wrote {len(out)} reconstructed coefficient rows -> {dest}")


if __name__ == "__main__":
    main()
