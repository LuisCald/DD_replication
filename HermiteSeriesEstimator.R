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
require(hermiter)

# Import the SCF data 
data <- read.csv("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/SCF.csv")
subset_data <- subset(data, year == 2019)

# Inverse sine 
income = log(subset_data$income + sqrt(subset_data$income^2 + 1))

# Series estimator using Hermite basis
hermite_est <- hermite_estimator(N=3, standardize=TRUE, observations = income)
p <- seq(0.1,1,0.10)
p[10] = .99
quantile_est <- quant(hermite_est,p)

# Reverse the process ... looks good, but how can we generate the weights ...
income_est = (exp(2 * quantile_est) - 1) / (2 * exp(quantile_est))

# plot 
# Plot the first line
x1 <- 1:10

plot(x1, income_est, type = "l", col = "blue", ylim = c(0, 30), xlab = "X axis", ylab = "Y axis", main = "Plot of Two Lines")
# Add the second line
lines(x2, y2, col = "red")

