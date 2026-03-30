#!/bin/bash
# Run interval estimation for all economies in parallel batches
# Once done, run run_all_economies.sh for estimation + post-estimation
#
# Usage (in tmux): bash 5_Code/code/julia/run_all_intervals.sh 2>&1 | tee run_intervals.log

cd "$(dirname "$0")/../../.."

# 3 at a time (~20 threads each = 60 threads)
for batch in "2 3 4" "5 6 7" "8 9 10"; do
    echo "========================================"
    echo "  Intervals batch: $batch at $(date)"
    echo "========================================"

    for ECON in $batch; do
        echo "[Econ $ECON] Starting intervals at $(date)"
        HANK_ECON=$ECON julia --project=5_Code/code/julia/env \
              --threads=18 \
              5_Code/code/julia/just_intervals.jl \
              > "intervals_econ_${ECON}.log" 2>&1 &
    done

    wait
    echo "Intervals batch ($batch) complete at $(date)"
    echo ""
done

echo "All intervals complete at $(date)"
echo "Now run: bash 5_Code/code/julia/run_all_economies.sh 2>&1 | tee run_all.log"