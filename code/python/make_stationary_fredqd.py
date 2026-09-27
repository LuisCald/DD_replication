"""
make_stationary_fredqd.py — build the aggregate input sheet from FRED-QD with the
PUBLISHED McCracken–Ng transformation codes, with prices entering as inflation.

Why (2026-09-25): the existing `stationary_series` sheet (make_stationary.py, ADF
loop) reproduces the FRED-QD codes almost exactly, so the aggregates already enter
stationary. Two things nevertheless make the aggregate FACTORS near-white and inject
quarterly noise into the distributional factors through B:
  1. 49 price series use tcode 6 (second difference of logs = change in inflation),
     mean lag-1 autocorrelation −0.31 by construction. Here they enter as INFLATION
     (tcode 5, first difference of logs), ρ₁ ≈ 0.75 for the CPI.
  2. 2020Q1–2021Q1 hold ~20% of the sheet's standardised variance; that is handled
     on the Julia side (ModelOptions.aggregate_pca_exclude), not here.
Everything else follows FRED-QD: same 198 series as the published sheet, same
259 quarters (1959Q3–2024Q1); the three S&P series (not in FRED_QD.csv) are copied
from the published sheet. Output: a NEW sheet `stationary_series_infl` in
aggregates_HHs_NPs.xlsx — the published `stationary_series` sheet is untouched.
Select it with ObservedData(agg_data = retrieve_aggregate_data("stationary_series_infl")).
"""
import shutil, datetime
import numpy as np, pandas as pd

DP = "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing"
WB = f"{DP}/aggregates_HHs_NPs.xlsx"
REF_SHEET, OUT_SHEET = "stationary_series", "stationary_series_infl"
PRICES_AS_INFLATION = True        # tcode 6 → 5

def transform(x, code):
    x = pd.to_numeric(x, errors="coerce").values.astype(float); out = np.full(len(x), np.nan)
    if code == 6 and PRICES_AS_INFLATION: code = 5
    if code == 1:   out = x
    elif code == 2: out[1:] = np.diff(x)
    elif code == 3: out[2:] = np.diff(np.diff(x))
    elif code == 4: out = np.log(x)
    elif code == 5: out[1:] = np.diff(np.log(x))
    elif code == 6: out[2:] = np.diff(np.diff(np.log(x)))
    elif code == 7: out[2:] = np.diff(x[1:] / x[:-1] - 1.0)
    else: raise ValueError(f"unknown tcode {code}")
    return out

raw = pd.read_csv(f"{DP}/FRED_QD.csv")
assert str(raw.iloc[1, 0]).lower() == "transform", "row 2 of FRED_QD.csv must be the transform codes"
tcode = {c: int(float(v)) for c, v in raw.iloc[1].items() if c != "sasdate" and pd.notna(v)}
data = raw.iloc[2:].reset_index(drop=True)
d = pd.to_datetime(data["sasdate"]); quarters = [f"{y}-Q{(m - 1) // 3 + 1}" for y, m in zip(d.dt.year, d.dt.month)]

ref = pd.read_excel(WB, sheet_name=REF_SHEET); ref["time"] = ref["time"].astype(str)
keep = [c for c in ref.columns if c != "time"]; low = {c.lower(): c for c in raw.columns}
out = pd.DataFrame({"time": quarters}); n_fred = n_copied = 0; n_price = 0
for c in keep:
    if c in low:
        out[c] = transform(data[low[c]], tcode[low[c]]); n_fred += 1; n_price += tcode[low[c]] == 6
    else:                                      # S&P series: not in FRED_QD.csv, carried over
        out[c] = ref.set_index("time").reindex(quarters)[c].values; n_copied += 1
out = out[out["time"].isin(set(ref["time"]))].reset_index(drop=True)
assert out.shape == ref.shape, (out.shape, ref.shape)
assert out.isna().sum().sum() == 0, "NaNs in the rebuilt sheet"

stamp = datetime.date.today().isoformat()
shutil.copy2(WB, f"{DP}/aggregates_HHs_NPs_backup_{stamp}.xlsx")
with pd.ExcelWriter(WB, engine="openpyxl", mode="a", if_sheet_exists="replace") as w:
    out.to_excel(w, sheet_name=OUT_SHEET, index=False)

def ac1(s): s = s[np.isfinite(s)]; return np.corrcoef(s[1:], s[:-1])[0, 1]
print(f"wrote sheet '{OUT_SHEET}': {out.shape} ({n_fred} FRED-QD series, {n_price} of them prices now as inflation, {n_copied} copied), backup {stamp}")
for c in ["gdpc1", "unrate", "cpiaucsl", "pcepilfe", "fedfunds"]:
    if c in out: print(f"  {c:9s} ρ₁ published sheet {ac1(ref[c].values.astype(float)):5.2f} → new {ac1(out[c].values.astype(float)):5.2f}")
