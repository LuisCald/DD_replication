"""Build the balance-sheet item files for DD_data from the item post-estimation exports.

Usage: python3 build_items_ddata.py <exports_dir> <out_dir>
  <exports_dir> holds the item runs' from_mcmc/data folders (SCF_cross_conditional_dfa_*
  and SCF_functional_data_*), as copied from 7_Results/.
Writes <out_dir>/<item>_SCF.csv (long format: date, grouping, group, mean_per_hh, share).
"""
import glob, os, sys
import numpy as np, pandas as pd

ITEMS = {"real_estate": "real_estate", "pension": "pension", "hdebt": "mortgages", "pdebt": "consumer_credit"}
WG = [("bot50", 0.5), ("mid40", 0.4), ("top10", 0.1)]
QG = [(f"q{i}", 0.2) for i in range(1, 6)]
QLAB = {f"q{i}": f"{20 * (i - 1)}-{20 * i}" for i in range(1, 6)}
WLAB = {"bot50": "bottom50", "mid40": "next40", "top10": "top10"}

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
for item, name in ITEMS.items():
    run = glob.glob(f"{src}/*8 factors pf wr0.05 infl xcovid {item} economy/from_mcmc/data")[0]
    x = pd.read_csv(f"{run}/SCF_cross_conditional_dfa_A non-diag_.csv")
    fd = pd.read_csv(f"{run}/SCF_functional_data_A non-diag_.csv")
    rows = []
    for grouping, cond, groups, labels in (("wealth_groups", "wealth", WG, WLAB), ("income_quintiles", "income", QG, QLAB)):
        per = pd.DataFrame({g: x[f"{item}_by_{cond}_{g}"] for g, _ in groups})
        tot = sum(per[g] * w for g, w in groups)
        for g, w in groups:
            rows.append(pd.DataFrame({"date": x.time, "grouping": grouping, "group": labels[g],
                                      "mean_per_hh": per[g], "share": per[g] * w / tot}))
    q = fd[[c for c in fd.columns if c.startswith("quantiles" + item)]].values
    s = fd[[c for c in fd.columns if c.startswith("shares" + item)]].values
    for d in range(10):
        rows.append(pd.DataFrame({"date": fd.time, "grouping": f"own_deciles", "group": f"d{d + 1}",
                                  "mean_per_hh": q[:, d], "share": s[:, d]}))
    df = pd.concat(rows, ignore_index=True).sort_values(["grouping", "group", "date"], kind="stable")
    df = df[df.mean_per_hh.notna()]
    df.to_csv(f"{out}/{name}_SCF.csv", index=False, float_format="%.6g")
    w = df[df.grouping == "wealth_groups"]
    chk = w.groupby("date").share.sum()
    print(f"{name:16s} {len(df):6d} rows  {df.date.min()}..{df.date.max()}  wealth-group shares sum to 1: {np.allclose(chk, 1)}")
