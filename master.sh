#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# master.sh — Replication script for Bayer, Calderon, Kuhn
#              "Distributional Dynamics"
# ─────────────────────────────────────────────────────────────
#
# Usage:
#   bash master.sh [stage]
#
# Stages:
#   data       Stage 1: Clean raw survey data (Stata + Python + Julia)
#   estimate   Stage 2: MCMC estimation (Julia, ~48-72 hrs)
#   results    Stage 3: Post-estimation analysis, figures, tables
#   all        Run everything end-to-end (default)
#
# Requirements:
#   - Julia 1.10.4   (pinned; project environment in code/julia/env/)
#   - Stata >= 17    (called as ${STATA:-stata-mp})
#   - Python >= 3.10 (with pandas, statsmodels, numpy)
#   - R is not used by this script (code/R/X12_averages.R is an optional,
#     manual step for the DFA item anchors; see README)
#
# Environment:
#   DD_THREADS   Julia threads for Stages 2-3 (default: auto = all cores)
#   STATA        Stata executable (default: stata-mp)
#   DD_EXAMPLE   configuration (default: replication)
#
# Notes:
#   - Can be called from any directory: paths are resolved from this
#     script's location (<root>/5_Code/master.sh); the stages run in <root>.
#   - The pre-computed posterior mode in 5_Code/output/estimates/ is loaded
#     by Stage 3 when no Stage-2 run exists, so Stage 2 can be skipped.
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Resolve project root ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If script is in 5_Code/, project root is one level up
if [[ "$(basename "$SCRIPT_DIR")" == "5_Code" ]]; then
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
else
    PROJECT_ROOT="$SCRIPT_DIR"
fi

CODE_DIR="$PROJECT_ROOT/5_Code"
JULIA_DIR="$CODE_DIR/code/julia"
STATA_DIR="$CODE_DIR/code/stata"
PYTHON_DIR="$CODE_DIR/code/python"
R_DIR="$CODE_DIR/code/R"

echo "════════════════════════════════════════════════════════════"
echo "  Distributional Dynamics — Replication Package"
echo "  Project root: $PROJECT_ROOT"
echo "  Started:      $(date)"
echo "════════════════════════════════════════════════════════════"

STAGE="${1:-all}"
STATA="${STATA:-stata-mp}"
JULIA_THREADS="${DD_THREADS:-auto}"

# ── Helper ────────────────────────────────────────────────────
run_stage() {
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo "  $1"
    echo "────────────────────────────────────────────────────────"
}

# ══════════════════════════════════════════════════════════════
# Stage 1: Data cleaning (Stata + Python + Julia)
# ══════════════════════════════════════════════════════════════
run_data() {
    run_stage "Stage 1: Data cleaning and preparation"

    # 1a. Python preprocessing
    echo "[1a] Python: converting monthly series to quarterly..."
    python3 "$PYTHON_DIR/convert_monthly_to_quarterly.py"

    # 1b. Stata data cleaning (writes *_nogrowth.xlsx, SIPP1-3.csv, aggregates)
    echo "[1b] Stata: running master data pipeline..."
    cd "$PROJECT_ROOT"
    "$STATA" -b do "$STATA_DIR/00_master_data.do"

    # 1c. Growth correction (Julia): align PSID/SCF income to the wealth date
    #     *_nogrowth.xlsx -> PSID_new.csv + SCF_noForbes_new.csv
    echo "[1c] Julia: growth correction..."
    julia --project="$JULIA_DIR/env" "$JULIA_DIR/GrowthCorrection.jl"

    # 1d. Forbes-400 augmentation: SCF_noForbes_new.csv -> SCF_new.csv
    #     (runs after Stata and the growth correction, whose output it reads)
    echo "[1d] Python: generating Forbes 400 data..."
    python3 "$PYTHON_DIR/generateForbes400.py"

    # 1e. Python stationarity transformations
    echo "[1e] Python: stationarity transformations..."
    python3 "$PYTHON_DIR/make_stationary.py"
    python3 "$PYTHON_DIR/make_stationary_x12.py"

    # (R is not part of Stage 1. import_aggregates.do reads
    #  2_Data_processing/aggregates/averages_deseasoned.csv, which must already
    #  exist; code/R/X12_averages.R only adds the de-seasoned DFA item columns
    #  to it and is run manually.)

    echo "Stage 1 complete."
}

# ══════════════════════════════════════════════════════════════
# Stage 2: Estimation (Julia MCMC)
# ══════════════════════════════════════════════════════════════
run_estimate() {
    run_stage "Stage 2: MCMC estimation (~48-72 hours)"

    cd "$PROJECT_ROOT"
    DD_EXAMPLE="${DD_EXAMPLE:-replication}" julia -t "$JULIA_THREADS" --project="$JULIA_DIR/env" "$JULIA_DIR/run_estimation.jl"

    echo "Stage 2 complete."
}

# ══════════════════════════════════════════════════════════════
# Stage 3: Post-estimation (results, figures, tables)
# ══════════════════════════════════════════════════════════════
run_results() {
    run_stage "Stage 3: Post-estimation analysis, figures, and tables"

    cd "$PROJECT_ROOT"
    DD_EXAMPLE="${DD_EXAMPLE:-replication}" julia -t "$JULIA_THREADS" --project="$JULIA_DIR/env" "$JULIA_DIR/run_postestimation.jl"

    # Post-estimation Stata analysis (local projections, Ginis)
    echo "[Post-estimation] Stata: preparing micro data for local projections..."
    "$STATA" -b do "$STATA_DIR/prep_micro_data.do"
    "$STATA" -b do "$STATA_DIR/prep_micro_3D.do"
    "$STATA" -b do "$STATA_DIR/prep_macro_3D.do"
    "$STATA" -b do "$STATA_DIR/prep_functional_data.do"
    "$STATA" -b do "$STATA_DIR/prep_actualCEX.do"
    "$STATA" -b do "$STATA_DIR/ginis_and_consumption_trends.do"

    # Multidimensional inequality (Python)
    echo "[Post-estimation] Python: multidimensional inequality..."
    python3 "$PYTHON_DIR/multidim_inequality.py"
    python3 "$PYTHON_DIR/MEILC_MEGC.py"

    echo "Stage 3 complete."
}

# ══════════════════════════════════════════════════════════════
# Dispatch
# ══════════════════════════════════════════════════════════════
case "$STAGE" in
    data)
        run_data
        ;;
    estimate)
        run_estimate
        ;;
    results)
        run_results
        ;;
    all)
        run_data
        run_estimate
        run_results
        ;;
    *)
        echo "Usage: bash master.sh [data|estimate|results|all]"
        echo ""
        echo "  data       Clean raw survey data (Stata + Python + Julia)"
        echo "  estimate   Run MCMC estimation (Julia, ~48-72 hrs)"
        echo "  results    Post-estimation: analysis, figures, tables"
        echo "  all        Everything end-to-end (default)"
        exit 1
        ;;
esac

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Finished: $(date)"
echo "════════════════════════════════════════════════════════════"
