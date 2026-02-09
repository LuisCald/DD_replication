# ─────────────────────────────────────────────────────────────
# config.jl — Path configuration for the replication package
# ─────────────────────────────────────────────────────────────
#
# All paths used by the code are derived from BASE_PATH.
# To run on a different machine, change BASE_PATH below.
#
# When running from the repo root (recommended):
#   julia --project=code/julia/env code/julia/DistributionalDynamics.jl
#
# BASE_PATH should point to the top-level project directory
# (the parent of code/, data/, output/).
# ─────────────────────────────────────────────────────────────

# Auto-detect: if pwd() ends with a code subdirectory, go up
function _detect_base_path()
    p = pwd()
    # If we're in code/julia (inside 5_Code), go up three levels to Distributional_Dynamics/
    if endswith(p, "code/julia") || endswith(p, "code\\julia")
        return dirname(dirname(dirname(p)))
    end
    # If we're in 5_Code directly, go up one level to Distributional_Dynamics/
    if endswith(p, "5_Code")
        return dirname(p)
    end
    # Legacy layout: check if parent directory ends with "Dynamics"
    parent = dirname(p)
    if length(parent) >= 8 && parent[end-7:end] == "Dynamics"
        return parent
    end
    # Otherwise assume we're already at the project root
    return p
end

const BASE_PATH = _detect_base_path()

# ── Derived paths ───────────────────────────────────────────
const DATA_RAW         = joinpath(BASE_PATH, "data", "raw")
const DATA_PROCESSED   = joinpath(BASE_PATH, "data", "processed")
const DATA_SYNTHETIC   = joinpath(BASE_PATH, "data", "synthetic")
const DATA_AGGREGATES  = joinpath(BASE_PATH, "data", "aggregates")
const OUTPUT_FIGURES   = joinpath(BASE_PATH, "output", "figures")
const OUTPUT_TABLES    = joinpath(BASE_PATH, "output", "tables")
const OUTPUT_ESTIMATES = joinpath(BASE_PATH, "output", "estimates")

# ── Legacy paths (for backward compatibility during transition) ─
# These match the old Dropbox layout so existing code keeps working.
const DATA_PROCESSING  = joinpath(BASE_PATH, "2_Data_processing")
const RAW_DATA         = joinpath(BASE_PATH, "1_Data")
const RESULTS_DIR      = joinpath(BASE_PATH, "7_Results")
const POSTERIOR_DRAWS  = joinpath(BASE_PATH, "posterior_draws")
const CODE_DIR         = joinpath(BASE_PATH, "5_Code")
