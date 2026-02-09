@unpack agg_data = obs_data

aggregate_data = DataFrame(XLSX.readtable(raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/test_deseasoned.XLSX", "Sheet1", header=true,))

# Drop missings 
aggregate_data = dropmissing(aggregate_data, disallowmissing=true)


a = aggregate_data[!, "GDP"] .- HP(aggregate_data[!, "GDP"], 32000)
b = aggregate_data[!, "GDP"] .- HP(aggregate_data[!, "GDP"], 1600)
c = rand(100)
d = HP(c, 1)
# Remove seasonality!! 

Plots.plot(axes(a), a)
Plots.plot!(axes(a), b)
Plots.savefig("test.png")

Plots.plot(axes(c), c)
Plots.plot!(axes(d), d)
Plots.savefig("test.png")


a = deepcopy(dfs[3][82:101, :])
for i in axes(a, 1)
    condition = .!isnan.(a[i, :])
    Plots.plot(axes(a[i, :][condition]), a[i, :][condition])
    Plots.plot!(axes(a[i, :][condition]), denoise(a[i, :][condition], factor=0.7)[1])
    Plots.plot!(axes(a[i, :][condition]), denoise(a[i, :][condition], factor=0.9)[1])
    Plots.savefig("test_$i.pdf")
end


for i in 60:81
    condition = .!isnan.(data_matrix[i, :])
    Plots.plot(axes(data_matrix[i, :][condition]), data_matrix[i, :][condition])
    Plots.plot!(axes(data_matrix[i, :][condition]), denoise(data_matrix[i, :][condition], factor=0.7)[1])
    Plots.plot!(axes(data_matrix[i, :][condition]), denoise(data_matrix[i, :][condition], factor=0.9)[1])
    Plots.savefig("test_$i.pdf")
end


for i in axes(a, 1)
    condition = .!isnan.(a[i, :])
    println(describe(a[i, :][condition]))
end

Plots.plot(axes(dfs[3][82, :]), dfs[3][83, :])
# Plots.plot!(axes(dfs[1][82, :]), a[2,:])
# Plots.plot!(axes(dfs[1][82, :]), b[2,:])
# Plots.plot!(axes(dfs[1][82, :]), denoise(dfs[1][83, :], factor=0.2))
# Plots.plot!(axes(dfs[1][82, :]), denoise(dfs[1][83, :], factor=0.6))
# Plots.plot!(axes(dfs[1][82, :]), denoise(dfs[1][83, :], factor=0.7)[1])
Plots.savefig("test.png")


Plots.plot(axes(dfs[2][82, :]), dfs[2][82:91, :]')
Plots.plot!(axes(dfs[2][82, :]), HP(dfs[2][82,:], 1))
Plots.savefig("test1.png")

Plots.plot(axes(dfs[3][82, :]), dfs[3][82:91, :]')
Plots.savefig("test2.png")

Plots.plot(axes(dfs[4][82, :]), dfs[4][82:91, :]')
Plots.savefig("test3.png")

# 3 dimensional 
a = deepcopy(dfs[1][973:1002, :])
# Plots.plot!(axes(dfs[1][993, :]), HP(a[1, :], 1))
# Plots.plot!(axes(dfs[1][82, :]), a[2,:])
# Plots.plot!(axes(dfs[1][82, :]), b[2,:])
# Plots.plot!(axes(dfs[1][82, :]), denoise(dfs[1][83, :], factor=0.2))
# Plots.plot!(axes(dfs[1][82, :]), denoise(dfs[1][83, :], factor=0.6))
for i in axes(a, 1)
    j = i + 30
    condition = .!isnan.(a[i, :])
    Plots.plot(axes(a[i, :][condition]), a[i, :][condition])
    # Plots.plot!(axes(a[i, :][condition]), denoise(a[i, :][condition], factor=0.8)[1])
    Plots.savefig("test_$j.png")
end

a = deepcopy(dfs[1][973:1002, :])
for i in axes(a, 1)
    condition = .!isnan.(a[i, :])
    Plots.plot(axes(a[i, :][condition]), a[i, :][condition])
    Plots.savefig("testSA_$i.pdf")
end

a = deepcopy(pool[973:1002, :])
for i in axes(a, 1)
    condition = .!isnan.(a[i, 1:152])
    Plots.plot(axes(a[i, 1:152][condition]), a[i, 1:152][condition])
    # Plots.plot!(axes(a[i, :][condition]), denoise(a[i, :][condition], factor=0.8)[1])
    Plots.savefig("test_$i.png")
end





X = LinRange(0,10pi,1000)
Y = sin.(X) .+ randn(length(X))./7 
Z = cos.(X) .+ randn(length(X))./7 
M = [Y Z]

@unpack func_dict = func_struct

copula_histogram = reshape(func_dict["PSID"]["copulas"]["data"][:,end-2], (10,10))

# Define the standard deviation for the Gaussian kernel
sigma = 0.4

# Create a 2D Gaussian kernel
kernel_size = 1  # Adjust the kernel size as needed
kernel = [exp(-(x^2 + y^2) / (2 * sigma^2)) for x in -kernel_size:kernel_size, y in -kernel_size:kernel_size]

# Normalize the kernel to sum to 1
kernel /= sum(kernel)

# Create an empty matrix for the smoothed result
smoothed_matrix = similar(copula_histogram)

# Iterate over each element in the copula histogram
for i in 1:size(copula_histogram, 1)
    for j in 1:size(copula_histogram, 2)
        # Compute the smoothed value for the current element
        smoothed_value = sum(
            kernel[m + kernel_size + 1, n + kernel_size + 1] *
            getindex(copula_histogram, i - m, j - n)
            for m in -kernel_size:kernel_size, n in -kernel_size:kernel_size
            if 1 <= i - m <= size(copula_histogram, 1) && 1 <= j - n <= size(copula_histogram, 2)
        )
        
        # Assign the smoothed value to the corresponding element in the result matrix
        setindex!(smoothed_matrix, smoothed_value, i, j)
    end
end
axis = 1:10
Plots.surface(
    axis, 
    axis, 
    smoothed_matrix,
    legend=false, 
    camera = (30,10), 
    size=(400,400),
    color=:winter, 
    display_option=Plots.GR.OPTION_SHADED_MESH)

Plots.savefig("test.png")

Plots.surface(
    axis, 
    axis, 
    copula_histogram,
    legend=false, 
    camera = (30,10), 
    size=(400,400),
    color=:winter, 
    display_option=Plots.GR.OPTION_SHADED_MESH)

Plots.savefig("test1.png")

