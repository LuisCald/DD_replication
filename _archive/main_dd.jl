
# # Define a mapping from the axis label to the corresponding key in the `bounds` dict
# bounds_key_map = Dict("Bonds" => "b", "Capital" => "k", "Human Capital" => "h")

# # Determine the x-limits based on the first axis label
# x_label = lab_grid[1]
# x_bounds_key = get(bounds_key_map, x_label, "") # Safely get the key
# x_limits = haskey(bounds, x_bounds_key) ? bounds[x_bounds_key] : :auto

# # Determine the y-limits based on the second axis label
# y_label = lab_grid[2]
# y_bounds_key = get(bounds_key_map, y_label, "") # Safely get the key
# y_limits = haskey(bounds, y_bounds_key) ? bounds[y_bounds_key] : :auto

# horizon = 100

# anim = @animate for i ∈ 1:horizon
#     Plots.surface(
#         dist_grid[1],
#         dist_grid[2],
#         data[:, :, i]';
#         camera = (70, 30),
#         size = (600, 500),
#         xlabel = "\n" * lab_grid[1],
#         ylabel = "\n" * lab_grid[2],
#         zlabel = density_or_mv,
#         xlims = x_limits,
#         ylims = y_limits,
#         color = :winter,
#         legend = legend,
#         title = "$lab for shock to $i_shock_lab,\n Horizon: $i",
#         titlefontsize = 10,
#         display_option = Plots.GR.OPTION_SHADED_MESH,
#     )

using Plots
using Statistics
# ---------------------------
# Arbitrary filler definitions
# ---------------------------

# Labels for the two axes (must match keys in bounds_key_map if you want bounds to apply)
lab_grid = ["Bonds", "Capital"]

# Bounds dict + mapping (your original logic)
bounds = Dict("b" => (0, 4.0), "k" => (0.0, 10.0), "h" => (0.0, 5.0))

bounds_key_map = Dict("Bonds" => "b", "Capital" => "k", "Human Capital" => "h")

# Determine the x-limits based on the first axis label
x_label = lab_grid[1]
x_bounds_key = get(bounds_key_map, x_label, "") # Safely get the key
x_limits = haskey(bounds, x_bounds_key) ? bounds[x_bounds_key] : :auto

# Determine the y-limits based on the second axis label
y_label = lab_grid[2]
y_bounds_key = get(bounds_key_map, y_label, "") # Safely get the key
y_limits = haskey(bounds, y_bounds_key) ? bounds[y_bounds_key] : :auto

# Grid for the two dimensions
dist_grid = (
    range(
        x_limits == :auto ? 0 : x_limits[1],
        x_limits == :auto ? 2 : x_limits[2];
        length = 200,
    ),
    range(
        y_limits == :auto ? 0 : y_limits[1],
        y_limits == :auto ? 10 : y_limits[2];
        length = 300,
    ),
)

# Horizon and data array: (x, y, t)
horizon = 50
nx, ny = length(dist_grid[1]), length(dist_grid[2])

using Random

# ... keep your nx, ny, horizon, dist_grid, etc.

Random.seed!(123)  # deterministic "randomness"

data = Array{Float64}(undef, nx, ny, horizon)

# Pre-draw fixed bump centers so it’s not just a blob sliding around
nb = 6
centers = [(rand(dist_grid[1]), rand(dist_grid[2])) for _ = 1:nb]
widths = [0.15 + 0.35 * rand() for _ = 1:nb]
amps = [0.6 + 0.8 * rand() for _ = 1:nb]

for t = 1:horizon
    # time-varying weights and a slow rotation to change the “shape” over time
    θ = 0.01t
    cθ, sθ = cos(θ), sin(θ)

    # phase shifts for waves
    ϕ1 = 0.07t
    ϕ2 = 0.11t

    for ix = 1:nx, iy = 1:ny
        x = dist_grid[1][ix]
        y = dist_grid[2][iy]

        # rotate coordinates about the grid midpoints (adds changing structure)
        x0 = x - mean(dist_grid[1])
        y0 = y - mean(dist_grid[2])
        xr = cθ * x0 + sθ * y0
        yr = -sθ * x0 + cθ * y0

        z = 0.0

        # # multiple “bumps” that breathe and wobble (not just translate)
        # for j in 1:nb
        #     cx, cy = centers[j]
        #     # slight orbiting + breathing width
        #     cx_t = cx + 0.15*sin(0.04t + 0.9j)
        #     cy_t = cy + 0.15*cos(0.05t + 0.7j)
        #     w    = widths[j] * (1.0 + 0.25*sin(0.06t + j))
        #     a    = amps[j]   * (1.0 + 0.35*cos(0.03t + 1.3j))

        #     z += a * exp(-((x - cx_t)^2 + (y - cy_t)^2) / (2w^2))
        # end

        # ridges / wave interference (adds variety)
        z += 0.25 * sin(0.8 * xr + 1.1 * yr + ϕ1) + 0.18 * cos(1.6 * xr - 0.7 * yr + ϕ2)
        z += 0.12 * sin(2.2 * x + 0.4 * y + 0.03t) * cos(0.6 * x - 1.7 * y)

        # rotating saddle / basin (prevents “all-positive mountain” look)
        z += 0.08 * (xr^2 - 0.7 * yr^2)

        # small noise (optional)
        z += 0.02 * randn()

        data[ix, iy, t] = z
    end

    # optional: normalize each frame so colors don’t blow up over time
    m = maximum(abs, data[:, :, t])
    if m > 0
        data[:, :, t] ./= m
    end

    # Divide by its sum to make it a density
    s = sum(data[:, :, t])
    if s != 0
        data[:, :, t] ./= s
    end

    # Ensure non-negativity (for density-like plots)
    data[:, :, t] .-= minimum(data[:, :, t])
end

# Strings and flags used in your plotting call
density_or_mv = "Density"
legend = false
lab = "Example Surface"
i_shock_lab = 1  # arbitrary

# ---------------------------
# Your animation loop
# ---------------------------
using Plots
gr()  # assuming you're using GR

# Set global defaults
default(;
    fontfamily = "Computer Modern",
    titlefont = font("Computer Modern", 10),
    guidefont = font("Computer Modern", 11),
    tickfont = font("Computer Modern", 9),
    legendfont = font("Computer Modern", 9),
)

anim = @animate for i ∈ 1:horizon
    Plots.surface(
        dist_grid[1],
        dist_grid[2],
        data[:, :, i]';   # note transpose to match your original
        camera = (70, 30),
        size = (600, 500),
        xlabel = "\n" * lab_grid[1],
        ylabel = "\n" * lab_grid[2],
        zlabel = density_or_mv,
        xlims = x_limits,
        ylims = y_limits,
        zformatter = _ -> "",   # hide y-axis numbers
        # color = :winter,
        legend = legend,
        # title = "$lab for shock to $i_shock_lab,\n Horizon: $i",
        titlefontsize = 10,
        zguidefontrotation = 0,   # <- make z label horizontal
        display_option = Plots.GR.OPTION_SHADED_MESH,
    )
end

# Save the animation (optional but usually what you want)
gif(anim, "surface_anim.gif"; fps = 20)
