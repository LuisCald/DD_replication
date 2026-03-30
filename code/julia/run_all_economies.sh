#!/bin/bash
# Run HANK economies in parallel batches
# Usage (in tmux): bash 5_Code/code/julia/run_all_economies.sh 2>&1 | tee run_all.log

cd "$(dirname "$0")/../../.."

# Batch size: 3 economies at a time (~20 threads each = 60 threads)
for batch in "2 3 4" "5 6 7" "8 9 10"; do
    echo "========================================"
    echo "  Starting batch: $batch at $(date)"
    echo "========================================"

    for ECON in $batch; do
        echo "[Econ $ECON] Starting at $(date)"
        HANK_ECON=$ECON julia --project=5_Code/code/julia/env \
              --threads=18 \
              5_Code/code/julia/run_estimation.jl \
              > "run_econ_${ECON}.log" 2>&1 &
    done

    wait  # wait for all 3 to finish before next batch
    echo "Batch ($batch) complete at $(date)"
    echo ""
done

echo "All economies complete at $(date)"