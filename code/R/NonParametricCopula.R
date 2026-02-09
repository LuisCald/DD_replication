# Testing out this Vine copula package 
require(ks)
require(rvinecopulib)
require(kdevine)
require(ggraph)
require(ggplot2)
require(plotly)
require(tidyr)
require(dplyr)
require(Hmisc)
require(MEPDF)
require(scatterplot3d)
require(copula)

# Import the SCF data 
data <- read.csv("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF.csv")
subset_data <- subset(data, year == 2019)
subset_data$income_ranked <- rank(subset_data$income) / (nrow(subset_data) + 1)
subset_data$wealth_ranked <- rank(subset_data$wealth) / (nrow(subset_data) + 1)
subset_data$liquid_ranked <- rank(subset_data$liquid) / (nrow(subset_data) + 1)

# The uniform random variables
X <- subset_data[, c("income", "wealth")]
selected_columns <- subset_data[, c("income_ranked", "wealth_ranked")]

# Different grids
n <- 10

# Function to generate Chebyshev nodes on [0,1]
chebyshev_nodes_01 <- function(n) {
  i <- 1:n
  return(0.5 * (1 + cos((2*i - 1) * pi / (2*n))))
}

# Generate Chebyshev nodes on [0,1]
chebyshev_x_01 <- sort(chebyshev_nodes_01(n))

# First estimation: Empirical Beta Kernel 
mesh_grid <- as.matrix(expand.grid(Dim1 = chebyshev_x_01, Dim2 = chebyshev_x_01))
EC = C.n(mesh_grid, X = X, smoothing = "beta")
#EC = C.n(mesh_grid, X = X, smoothing = "checkerboard")
mat_dist <- matrix(EC, nrow = n, ncol = n)

# convert to density 
cop_dis <- matrix(mat_dist, nrow = n, ncol = n)  # Reshaping
cop_den <- matrix(0, nrow = n, ncol = n)  # Initialize a matrix of zeros

for (h in 1:n) {
  for (j in 1:n) {
    if (h == 1 && j == 1) {
      cop_den[h, j] <- cop_dis[h, j]
    } else if (h == 1 && j != 1) {
      cop_den[h, j] <- cop_dis[h, j] - cop_dis[h, j-1]
    } else if (h != 1 && j == 1) {
      cop_den[h, j] <- cop_dis[h, j] - cop_dis[h-1, j]
    } else {
      cop_den[h, j] <- cop_dis[h, j] - cop_dis[h-1, j] - cop_dis[h, j-1] + cop_dis[h-1, j-1]
    }
  }
}
sum(cop_den)
plot_ly(z = cop_den, type = "surface")


# Fits a vine copula model: non-parametric
# Vine copulas are powerful for high dimensions
vcop <- vinecop(
  selected_columns,
  var_types = rep("c", NCOL(selected_columns)), # continuous variables
  nonpar_method = "linear", # local likelihood estimatin of order 1
  mult = 1, # greater than 1 = more smooth
  selcrit = "aic", # criterion for family selection (need to better understand)
  weights = subset_data$weight,
  presel = TRUE, # pre-select families that better represent the data
  trunc_lvl = Inf, # no truncation on the trees -> looks at all pairs of variables vs. making an assumption on certain pairs
  tree_crit = "tau",
)

# Creating a sequence from 0 to 1 in increments of 0.1 for each dimension
dim1 <- seq(.01, 1, by = 0.01)
dim2 <- seq(.01, 1, by = 0.01)
dim1 <- seq(.1, 1, by = 0.1)
dim2 <- seq(.1, 1, by = 0.1)

dim1[dim1 > .99] = .95
dim2[dim2 > .99] = .95

# Number of nodes
n <- 10

# Function to generate Chebyshev nodes on [0,1]
chebyshev_nodes_01 <- function(n) {
  i <- 1:n
  return(0.5 * (1 + cos((2*i - 1) * pi / (2*n))))
}

# Generate Chebyshev nodes on [0,1]
chebyshev_x_01 <- sort(chebyshev_nodes_01(n))
midpoints <- (chebyshev_x_01[-length(chebyshev_x_01)] + chebyshev_x_01[-1]) / 2
chebyshev_x_01 <- c(0 + chebyshev_x_01[1]/2, midpoints)

midpoints <- (dim1[-length(dim1)] + dim1[-1]) / 2
dim1 <- c(0 + dim1[1]/2, midpoints)

chebyshev_x_01[chebyshev_x_01 > .99] = .95


# Creating the mesh grid
mesh_grid <- as.matrix(expand.grid(Dim1 = dim1, Dim2 = dim1))
mesh_grid <- as.matrix(expand.grid(Dim1 = chebyshev_x_01, Dim2 = chebyshev_x_01))



# Distribution and Density
cop_dist <- pvinecop(mesh_grid, vcop, cores = 1)
cop_dens <- dvinecop(mesh_grid, vcop, cores = 1)

mat_dist <- matrix(cop_dist, nrow = n, ncol = n)
mat_dens <- matrix(cop_dens, nrow = n, ncol = n)

# density has this insanely high point -> hard to visualize anything
mat_dens[n,n] <- 10

normalize_density <- function(density) {
  total_density <- sum(density)
  return(density / total_density)
}

# Based on the model 
plot_ly(z = mat_dist, type = "surface")
plot_ly(z = mat_dens, type = "surface")
plot_ly(z = normalize_density(mat_dens), type = "surface")

# Copmuting the histogram from the density
midpoints <- (chebyshev_x_01[-length(chebyshev_x_01)] + chebyshev_x_01[-1]) / 2
midpoints <- c(0 + chebyshev_x_01[1]/2, midpoints)

midpoints <- (dim1[-length(dim1)] + dim1[-1]) / 2
midpoints <- c(0 + dim1[1]/2, midpoints)

mesh_grid <- as.matrix(expand.grid(Dim1 = chebyshev_x_01, Dim2 = chebyshev_x_01))
mesh_grid <- as.matrix(expand.grid(Dim1 = midpoints, Dim2 = midpoints))

cop_dens <- dvinecop(mesh_grid, vcop, cores = 1)
mat_dens <- matrix(cop_dens, nrow = 10, ncol = 10)

spacing_x = diff(sort(c(0,chebyshev_x_01)))
spacing_x = diff(sort(c(0,dim1)))
product_matrix <- outer(spacing_x, spacing_x, FUN = "*")

bin_mass = mat_dens * product_matrix # note: mat_dens are evaluations at the edges
plot_ly(z = bin_mass, type = "surface") 
# note: cheby or not makes a huge difference because the chebyshev grid points are 
# largely spaced apart in the middle (so more mass) than on the edges
sum(bin_mass)

require(ggplot2)
data_for_plot <- data.frame(mesh_grid, Height = c(bin_heights))

# Very slow
xmin <- 0
xmax <- 1
dx <- .11

ymin <- 0
ymax <- 1
dy <- .11

pts.x <- seq(xmin, xmax, dx)
pts.y <- seq(ymin, ymax, dy)
pts <- as.data.frame(expand.grid(x = pts.x, y = pts.y))

# speed depends on grid size 

selected_columns <- subset_data[, c("income_ranked", "wealth_ranked", "liquid_ranked")]
selected_columns <- subset_data[, c("income_ranked", "wealth_ranked")]
# kde <- ks::kcopula.de(x = selected_columns, gridsize=c(10,10,10), xmin = c(0, 0,0), 
#xmax = c(1,1,1), w=subset_data$weight, boundary.kernel="beta")
# gridsize=c(10,10)

# pts is apparently the value at the grid points of interest 
pts1 = 
pts2 = 
pts  = list(chebyshev_x_01, chebyshev_x_01)

evpts <- do.call(expand.grid,  lapply(selected_columns[, c("income_ranked", "wealth_ranked")], quantile, prob=chebyshev_x_01) )

kde_cop <- ks::kcopula.de(x = selected_columns, gridsize = c(20,20), xmin = c(0, 0),
                      xmax = c(1,1), binned=FALSE, boundary.kernel="beta") # gridsize = c(11,11), w=subset_data$weight

kde <- ks::kde(x = selected_columns, eval.points = evpts, density =TRUE, xmin = c(0, 0),
                      xmax = c(1,1)) # gridsize = c(11,11)

# Perspective plot
to_plot <- kde_cop$estimate / sum(kde_cop$estimate)
to_plot <- to_plot[2:19, 2:19]
plot_ly(z = to_plot, type = "surface")

to_plot <- kde$estimate / sum(kde$estimate)
mat_dens <- matrix(kde$estimate, nrow = 10, ncol = 10)
plot_ly(z = mat_dens, type = "surface")


plot(kde, display = "persp", col.fun = viridis::viridis, xlab = "x", ylab = "y")

# what if i simulate data then make the copula histogram?
u <- rvinecop(1000, vcop)

##  Create cuts:
x_c <- cut(u[,1], 20)
y_c <- cut(u[,2], 20)

##  Calculate joint counts at cut levels:
z <- table(x_c, y_c)
z = z / sum(z)

plot_ly(z = z, type = "surface")

# How does the the data look? 
income_ranked <- wtd.quantile(subset_data$income, subset_data$weight, probs = seq(0, .99, by = 0.01))
wealth_ranked <- wtd.quantile(subset_data$wealth, subset_data$weight, probs = seq(0, .99, by = 0.01))
wealth_ranked[8] = 33

subset_data$income_dec <- cut(subset_data$income, breaks = income_ranked, labels=FALSE)
subset_data$wealth_dec <- cut(subset_data$wealth, breaks = wealth_ranked, labels=FALSE)

# Generate frequencies -> then shares
cop_den_emp = as.matrix(table(subset_data$income_dec, subset_data$wealth_dec))
cop_den_emp = cop_den_emp / sum(cop_den_emp)

plot_ly(z = cop_den_emp, type = "surface")
plot_ly(z = mat_dens, type = "surface")

# Generating the histogram from the estimated CDF
N <- 100
cop_dis <- matrix(mat_dist, nrow = N, ncol = N)  # Reshaping
cop_den <- matrix(0, nrow = N, ncol = N)  # Initialize a matrix of zeros

for (h in 1:N) {
  for (j in 1:N) {
    if (h == 1 && j == 1) {
      cop_den[h, j] <- cop_dis[h, j]
    } else if (h == 1 && j != 1) {
      cop_den[h, j] <- cop_dis[h, j] - cop_dis[h, j-1]
    } else if (h != 1 && j == 1) {
      cop_den[h, j] <- cop_dis[h, j] - cop_dis[h-1, j]
    } else {
      cop_den[h, j] <- cop_dis[h, j] - cop_dis[h-1, j] - cop_dis[h, j-1] + cop_dis[h-1, j-1]
    }
  }
}

# Works well because sums to 1 
sum(cop_den)
plot_ly(z = cop_den, type = "surface")


