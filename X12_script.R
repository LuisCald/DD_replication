# Step 1: Import the CSV file
setwd("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing")
data <- read.csv("/Users/lc/Dropbox/Distributional_Oil/1_Data/ExtendingKanzig/extended_oil_data.csv")  # Replace "your_data.csv" with the actual file path

library(x12)

# Step 2: Create a vector of column names to loop over
columns_to_adjust <- c("global_petro_stock")

# Step 3: Loop over columns and apply seasonal adjustment
for (column_name in columns_to_adjust) {
  print(column_name)
  # column_data <- data[[column_name]][!is.na(data[[column_name]])]
  column_data <- data[[column_name]]
  
  x12_object <- new("x12Single", ts = ts(column_data, frequency=4))
  
  # Perform seasonal adjustment using x12
  an.error.occured <- FALSE
  tryCatch( { adjusted_data <- x12(x12_object); print("success") }
            , error = function(e) {an.error.occured <<- TRUE})
  print(an.error.occured)
  
  # Replace the original column with the adjusted data
  data[[column_name]] <- adjusted_data@x12Output@d11
}

a = seas(ts(data[["global_petro_stock"]], frequency=4, start=1975))
# Plot the first series
plot(a[["data"]][, 1],
     type = "l",                    # Plot as a line
     main = "Time Series Plot of a.data",
     xlab = "Time",
     ylab = "Value",
     col = "blue")

# Add the second series as a line.
# Note: Replace 'data' with 'a' if both series come from the same list.
lines(ts(data[["global_petro_stock"]], start=1975), 
      type = "l",                  # Ensure it's a line
      col = "red")

# Add a legend to help differentiate the two lines
legend("topright", 
       legend = c("Series 1", "Global Petro Stock"), 
       col = c("blue", "red"), 
       lty = 1,
       lwd = 2)

# Step 4: Save the adjusted data to a new CSV file
#write.csv(data, "aggregates_deseasoned.csv") 
write.csv(data, "/Users/lc/Dropbox/Distributional_Oil/1_Data/ExtendingKanzig/deseasoned_extended_oil_data.csv") 
