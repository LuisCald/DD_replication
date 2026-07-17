#!/usr/bin/env bash
# Publish regenerated estimation outputs to the DD_data repository.
#
# Usage:  bash publish_to_DD_data.sh [path-to-DD_data-checkout]
#
# Copies the canonical data files from this repo's data/synthetic/ (where the
# pipeline writes them) into DD_data/data/, then stages them there. Review and
# commit in DD_data yourself. Helper-script changes must be ported by hand —
# DD_data is the canonical home of reconstruct.{jl,py} and the stage scripts.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DD_DATA="${1:-$HERE/../DD_data}"
SRC="$HERE/data/synthetic"

[ -d "$DD_DATA/data" ] || { echo "DD_data checkout not found at $DD_DATA" >&2; exit 1; }

FILES=(
  smoothed_factors.csv
  smoothed_factor_draws.csv
  smoothed_factors_bands.csv
  PSID_coefficients_normal.csv PSID_coefficients_average.csv
  SCF_coefficients_normal.csv  SCF_coefficients_average.csv
  CEX_coefficients_normal.csv  CEX_coefficients_average.csv
  PSID_functional_data.csv     PSID_functional_data_detrended.csv
  SCF_functional_data.csv      SCF_functional_data_detrended.csv
  PSID_synthetic_microdata.csv
  aggregate_anchors.csv
)

copied=0
for f in "${FILES[@]}"; do
  if [ -f "$SRC/$f" ]; then
    cp "$SRC/$f" "$DD_DATA/data/$f"
    copied=$((copied + 1))
  else
    echo "skip (not regenerated): $f"
  fi
done

echo "Copied $copied file(s) to $DD_DATA/data/"
git -C "$DD_DATA" add data/
git -C "$DD_DATA" status --short
echo "Review the diff, then commit & push in $DD_DATA."
