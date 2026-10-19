"""make_liquidity_data.py — inputs for the liquidity and debt products (Oct 2026).

Writes 2_Data_processing/{SCF,PSID,CEX}_liq.csv: the processed survey files with these measures
redefined/added. The CIW files are not touched.

  liquid    Kaplan–Violante-style net liquid wealth: deposits, CDs, savings bonds, directly held
            stocks and mutual funds, minus consumer (non-housing) debt  = processed `liquid` + `finast`
  grossliq  gross liquid assets: the same assets without subtracting debt     = `liquid` + `pdebt`
  debt      consumer (non-housing) debt, the part net liquid subtracts       = `pdebt`
  illiquid  net housing + net other real estate + other bonds + life insurance + vehicles +
            business equity, WITHOUT pensions                         = processed `illiqd` − `pension`
            (bonds other than savings bonds stay illiquid: the processed SCF+ files carry them
            only inside `illiqd`)
  totassets total assets without pensions (as in the SCF and PSID wealth measures)  = processed `assets`
  totdebt   total debt: mortgages, other real-estate debt, consumer debt         = processed `tdebt`
  mortdebt  mortgage debt on the primary residence (as the published mortgages item) = processed `hdebt`
            (totassets − totdebt = processed wealth in every SCF wave before 2022 and in the PSID)

SCF 2022: the processed file lacks the split, so it is built from the Fed's public summary
extract (rscfp2022.dta, 1_Data/SCF_2022_extract/) with the same definitions and deflated with the
row's processed-wealth / extract (NETWORTH − RETQLIQ) ratio (processed 2022 wealth excludes retirement accounts
since issue #9; the factor converts the extract's dollars to the processed files' 2019 dollars):
  liquid   = liq + cds + savbnd + stocks + nmmf − (ccbal + install + odebt + othloc)
  grossliq = liq + cds + savbnd + stocks + nmmf;   debt = ccbal + install + odebt + othloc
  illiquid = houses − mrthel + oresre + nnresre − resdbt + bond + cashli + vehic + bus
  totassets = asset − retqliq (pensions out, as before 2022);   totdebt = debt;   mortdebt = mrthel
The processed 2022 wealth includes retirement accounts (clean_SCF_2022.do), unlike 1950–2019, which exclude
pensions; totassets − totdebt here follows the 1950–2019 definition.
SCF illiquid is floored at zero (Oct 18): about 0.6% of households have slightly negative illiquid wealth
(mostly underwater homeowners). Illiquid gets the atom (point mass at zero) treatment, which takes zero as the
lowest value; the negatives otherwise sat just above the zeros and gave a second decile below the first in
the early SCF+ waves. The PSID has no negative illiquid values.
PSID: illiqd has no pension component to remove (IRAs are not in the PSID asset split used here).
CEX: consumption only (its liquid series is too sparse); the liquid column is dropped (a survey
without a measure's column simply does not observe it; an all-missing column breaks the loader).

Usage (where 2_Data_processing has the current processed files, e.g. Marvin):
    python3 5_Code/code/python/make_liquidity_data.py
"""
import os
import numpy as np
import pandas as pd

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
DP = os.path.join(ROOT, "2_Data_processing")
EXTRACT = os.path.join(ROOT, "1_Data", "SCF_2022_extract", "rscfp2022.dta")


def scf():
    d = pd.read_csv(os.path.join(DP, "SCF.csv"))
    d["liquid"] = d["liquid"] + d["finast"]
    d["illiquid"] = d["illiqd"] - d["pension"].fillna(0)
    d["grossliq"] = d["liquid"] + d["pdebt"]
    d["debt"] = d["pdebt"]
    d["totassets"] = d["assets"]
    d["totdebt"] = d["tdebt"]
    d["mortdebt"] = d["hdebt"]
    x = pd.read_stata(EXTRACT, columns=["y1", "networth", "liq", "cds", "savbnd", "stocks", "nmmf", "ccbal", "install",
                                         "odebt", "othloc", "houses", "mrthel", "oresre", "nnresre", "resdbt", "bond",
                                         "cashli", "vehic", "bus", "asset", "retqliq", "debt"])
    x["id"] = ("2022" + x["y1"].astype(int).astype(str)).astype(np.int64)
    x["liq22"] = x.liq + x.cds + x.savbnd + x.stocks + x.nmmf - (x.ccbal + x.install + x.odebt + x.othloc)
    x["gl22"] = x.liq + x.cds + x.savbnd + x.stocks + x.nmmf
    x["debt22"] = x.ccbal + x.install + x.odebt + x.othloc
    x["ill22"] = x.houses - x.mrthel + x.oresre + x.nnresre - x.resdbt + x.bond + x.cashli + x.vehic + x.bus
    x["ta22"] = x.asset - x.retqliq
    x["td22"] = x.debt
    x["md22"] = x.mrthel
    x["nw22"] = x.networth - x.retqliq
    m = d.loc[d.year == 2022, ["id", "wealth"]].merge(x[["id", "nw22", "liq22", "ill22", "gl22", "debt22", "ta22", "td22", "md22"]],
                                                      on="id", how="left")
    ok = m.nw22.abs() > 1e4
    ratio = (m.wealth[ok] / m.nw22[ok]).median()
    spread = (m.wealth[ok] / m.nw22[ok]).quantile([0.1, 0.9]).round(4).tolist()
    print(f"SCF 2022: {m.nw22.notna().sum()} of {len(m)} rows matched the extract; deflator {ratio:.4f} (p10/p90 {spread})")
    idx = d.index[d.year == 2022]
    d.loc[idx, "liquid"] = (m.liq22 * ratio).values
    d.loc[idx, "illiquid"] = (m.ill22 * ratio).values
    d.loc[idx, "grossliq"] = (m.gl22 * ratio).values
    d.loc[idx, "debt"] = (m.debt22 * ratio).values
    d.loc[idx, "totassets"] = (m.ta22 * ratio).values
    d.loc[idx, "totdebt"] = (m.td22 * ratio).values
    d.loc[idx, "mortdebt"] = (m.md22 * ratio).values
    neg = (d["illiquid"] < 0).sum()
    d["illiquid"] = d["illiquid"].clip(lower=0)   # floor at zero (atom treatment; see the docstring)
    print(f"SCF: {neg} rows with negative illiquid set to 0")
    return d


def psid():
    d = pd.read_csv(os.path.join(DP, "PSID.csv"))
    d["liquid"] = d["liquid"] + d["finast"]
    d["illiquid"] = d["illiqd"]
    d["grossliq"] = d["liquid"] + d["pdebt"]
    d["debt"] = d["pdebt"]
    d["totassets"] = d["assets"]
    d["totdebt"] = d["tdebt"]
    d["mortdebt"] = d["hdebt"]
    return d


def cex():
    return pd.read_csv(os.path.join(DP, "CEX.csv")).drop(columns=["liquid"])


def summary(name, d):
    for y in sorted(d.year.unique())[-3:]:
        z = d[d.year == y]
        w = z["weight"]
        parts = []
        for c in ("consum", "illiquid", "liquid", "grossliq", "debt", "totassets", "totdebt", "mortdebt"):
            if c in z and z[c].notna().mean() > 0.5:
                v = z[c].notna()
                parts.append(f"{c} mean {np.average(z[c][v], weights=w[v]):,.0f} (<0: {np.average(z[c][v] < 0, weights=w[v]):.0%}, "
                             f"=0: {np.average(z[c][v] == 0, weights=w[v]):.0%})")
        print(f"  {name} {y}: " + "; ".join(parts))


for name, fn in (("SCF", scf), ("PSID", psid), ("CEX", cex)):
    d = fn()
    d.to_csv(os.path.join(DP, f"{name}_liq.csv"), index=False)
    print(f"wrote {name}_liq.csv ({len(d)} rows)")
    summary(name, d)
