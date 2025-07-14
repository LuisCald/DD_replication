# SCRATCH 

data = DataFrame(test["PSID"]["theta"], :auto)
XLSX.writetable("test.xlsx", data)


xf = XLSX.readxlsx(first(values(files)))
            sheet_names = XLSX.sheetnames(xf)
            filter(contains(r"income|wealth"), sheet_names)
            container = []
            for sheet in XLSX.sheetnames(xf)
            a =[match.match for match in eachmatch(r"^([a-z]+?)(?=[0-9])", sheet)] 
            append!(container, a)
            end 

            measures = Matrix{Float64}(undef, length(y[1]), 0)
            for (i,m) in enumerate(y)
                measures = hcat(measures, y[i])
            end 

            measure_dim = size(measures, 2) - count(isnan.(measures[1,:]))
            isnan.(measures[1,:])

            G = [ 1 0
                 1 0 
                 0 1
                 0 1]

            y = [NaN, NaN, 5, 4]
            G = G[(!isnan).(y),:]

            ones(2,1)[(!isnan).(measures[1, :]), :]
            ones(1,1)[(!isnan).(measures[1, 1]),:] 

            state_container = Matrix{Matrix{Float64}}(undef, 100, 2)
            state_container[1, 1] = [-0.21808193061388373;;], [-0.2672258429093767;;]

            [[-0.21808193061388373;;], [-0.2672258429093767;;]], 2

           [only(mean(kalman_dict["data"][df]["loadings"], dims=1)) for df in collect(keys(kalman_dict["data"]))]

            mean(kalman_dict["data"]["PSID"]["loadings"], dims=1) 

            only([-0.21808193061388373;;])

            state_container[1, 1] = [1,2]'

            j = Matrix{Any}(undef, 100, 2)
a = 1
            j[1,1] = rand(2,2)
            a = rand(2,2)
            b = rand(2,2)
            a / b 
            a * inv(b)

            G = ones(2,1)
            comp1 = kalman_dict["A"] * ones(1,1) * G' 
            comp2 = G * ones(1,1) * G' + I
            K = comp1 / comp2

            sigma_updated = Array{Float64}(undef, 2,2, 100)

            sigma_updated[:,:,1]

        using StateSpaceModels
        for_VAR = Matrix{Float64}(undef, T, n)
        for m in 1:n  # We take one measurement and compute its LOM and SCov. This is the one state case 
            a             = for_VAR[:,m]
            a[isnan.(a)] .= only(mean(filter(!isnan, a), dims=1))  # Fill missing with mean for VAR to run smoothly 
            for_VAR[:,m]  = a 
        end
        V = VAR(for_VAR, 1, false)
        A = V.β  # state equation matrix. Must be a square matrix or Int64 
        Q = V.Σ  # state VCV


        data_matrix = data["SCF"]["copula_densities"]["DCT"]
        

        dfs         = ["SCF", "PSID"]
        pooled_data = Vector{Array{Float64}}(undef, length(dfs))
            # Construct DCT matrix of copulas and percentile functions
            for (j, df) in enumerate(dfs)
                dct_mat  = (data[df]["copula_densities"]["DCT"] .- mean(data[df]["copula_densities"]["DCT"], dims=2)) ./ std(data[df]["copula_densities"]["DCT"], dims=2)
                a = dct_mat == standardize(ZScoreTransform, data[df]["copula_densities"]["DCT"], dims=2)
                println(a)
                measures = collect(keys(data[df]["perc_funcs"]))
                for m in measures
                    mea_mat = (data[df]["perc_funcs"][m]["DCT"] .- mean(data[df]["perc_funcs"][m]["DCT"])) ./ std(data[df]["perc_funcs"][m]["DCT"])  
                    dct_mat = vcat(dct_mat, mea_mat)
                end
                dct_mat
                pooled_data[j] = dct_mat
            end
            # Factor Analysis 
            var                     = 0.95
            od                      = 24
            data_matrix             = hcat(pooled_data...)            
            M                       = fit(PCA, data_matrix; pratio=var)  # PCA model, centers data as default, pratio is how much variation you want, maxoutdim is how many components you'd like 
            data["Projection"]      = projection(M)
            pcs                     = MultivariateStats.transform(M, data_matrix)  # proj' * (data_matrix - mean(data_matrix, dims=2))  #TODO: can be used for validation 
            MultivariateStats.principalvars(M)
            # Reconstruction 
            stop                    = min(od, size(pcs, 1))
            theta_pca               = MultivariateStats.reconstruct(M, pcs[begin:24, :]) 














struct PCA{T<:Real} <: LinearDimensionalityReduction
    mean::AbstractVector{T}     # sample mean: of length d (mean can be empty, which indicates zero mean)
    proj::AbstractMatrix{T}     # projection matrix: of size d x p
    prinvars::AbstractVector{T} # principal variances: of length p
    tprinvar::T                 # total principal variance, i.e. sum(prinvars)
    tvar::T                     # total input variance
end

## constructor

function PCA(mean::AbstractVector{T}, proj::AbstractMatrix{T}, pvars::AbstractVector{T}, tvar::T) where {T<:Real}
    d, p = size(proj)
    (isempty(mean) || length(mean) == d) ||
        throw(DimensionMismatch("Dimensions of mean and projection matrix are inconsistent."))
    length(pvars) == p ||
        throw(DimensionMismatch("Dimensions of projection matrix and principal variables are inconsistent."))
    tpvar = sum(pvars)
    tpvar <= tvar || isapprox(tpvar,tvar) || throw(ArgumentError("principal variance cannot exceed total variance."))
    PCA(mean, proj, pvars, tpvar, tvar)
end

function pcasvd(Z::AbstractMatrix{T}, mean::AbstractVector{T}, n::Real;
    maxoutdim::Int=min(size(Z)...),
    pratio::Real=default_pca_pratio) where {T<:Real}

Svd = svd(Z)
v = Svd.S::Vector{T}  # eigenvalues are the principal variances 
U = Svd.U::Matrix{T}  # projection matrix 
for i = 1:length(v)
@inbounds v[i] = abs2(v[i]) / n
end
ord = sortperm(v; rev=true)
vsum = sum(v)
k = choose_pcadim(v, ord, vsum, maxoutdim, pratio)
si = ord[1:k]
PCA(mean, U[:,si], v[si], vsum)
end

Z = data_matrix .- mean(data_matrix, dims=2)
SvD = svd(Z)
loadings = sqrt.(SvD.S)' .* SvD.U    # Are these the time constant loadings or the factors? I think it's the factors because of the dimensions 
transformed = SvD.U' * Z  # These are the factors :D
data = SvD.U * transformed .+ mean(data_matrix, dims=2)

SvD.U * transformed  # this is equation 3 

println(all(isapprox(data_matrix, data, rtol=1e-1)))
println(all(isapprox(SvD.U * transformed, Z, rtol=1e-1)))


reconstructed_pf = data["SCF"]["perc_funcs"]["income"]["Reconstructions"]["1959"]
Plots.plot(reconstructed_pf)
   
SvD.S .> eps()




#UNUSED FUNCTIONS

# pyplot() 
# using Pkg
# Pkg.add("PyCall")




# function percentile_function_reduction!(data::Dict, grid::Int64)
#         n         = copy(grid)
#         T         = length(collect(keys(data["perc_funcs"])))  
#         some_year = first(keys(data["perc_funcs"]))
#         measures  = collect(keys(data["perc_funcs"][some_year]))
#         pf_mat    = zeros(n + 1, T, length(measures))
        
#         # Fill matrix 
#         for (y, year) in enumerate(collect(keys(data["perc_funcs"])))
#             for (m, mes) in enumerate(measures)
#                 pf_mat[:, y, m] = data["perc_funcs"][year][mes][:, 2]  # the values
#             end
#         end
        
#         # Reduction, missing sparsity 
#         data["perc_funcs"]["theta"] = Dict()
#         for (m, mes) in enumerate(measures)
#             dct_mat                          = dct(pf_mat[:, :, m])
#             data["perc_funcs"]["theta"][mes] = dct_mat
#         end 

#         return data
# end 

# function data_sparser!(data, grid, quality)
#     """Data compression and decompression."""

#     # Sparse representations of Copula distributions 
#     for df in collect(keys(data))
#         reduced_blocks                                 = video_compressor(data, df, quality)
#         data[df]["sparse_copulas"], data[df]["theta"]  = video_decompressor(reduced_blocks, quality)  #TODO: remove and use later, drop last 3 frames. generalize 
#         data[df]                                       = percentile_function_reduction!(data[df], grid)
#     end
#     return data
# end





# function inverse_zig_zag(block)
#     """Given a vector of length 64, it generates an 8 by 8 matrix, populating it in a zig zag fashion."""
#         # initializing the variables
#         h = 1
#         v = 1
        
#         vmin = 1
#         hmin = 1
#         output = zeros(8, 8)
#         i = 1
#         global i, h, v, vmin, hmin 
#         # Fill matrix in an inverse zig zag 
#         while v <= 8 && h <= 8
#             if mod(h + v, 2) == 0  # going up
#                 if v == vmin
#                     output[v, h] = block[i]
#                     if h == 8
#                         v = v + 1
#                     else
#                         h = h + 1
#                     end
        
#                     i = i + 1 
        
#                 elseif h == 8 && v < 8
#                     output[v, h] = block[i]
                    
#                     v = v + 1
#                     i = i + 1
            
#                 elseif v > vmin && h < 8
#                     output[v, h] = block[i]
#                     v = v - 1
#                     h = h + 1
#                     i = i + 1
#                 end
                
#             else                                  
#                if v == 8 && h <= 8
#                     output[v, h] = block[i]
#                     h = h + 1
#                     i = i + 1
                
#                elseif h == hmin
#                     output[v, h] = block[i]
        
#                     if v == 8
#                         h = h + 1
#                     else
#                       v = v + 1
#                     end
        
#                 i = i + 1
        
#                elseif v < 8 && h > hmin
#                     output[v, h] = block[i]
#                     v = v + 1
#                     h = h - 1
#                     i = i + 1
#                 end
        
#             end
        
#             if v == 8 && h == 8
#                 output[v, h] = block[i]
#                 break
#             end
        
#         end
#     return output 
# end 

# function select_quantization(quality)
#     """Allows the user to choose the quantization matrix of their choice with a certain quality level.
#     At the moment, there is no argument for this choice, given that there's only one choice 

#     """

#     Q50 = [16 11 10 16 24 40 51 61 
#         12 12 14 19 26 58 60 55
#         14 13 16 24 40 57 69 56 
#         14 17 22 29 51 87 80 62
#         18 22 37 56 68 109 103 77
#         24 35 55 64 81 104 113 92
#         49 64 78 87 103 121 120 101
#         72 92 95 98 112 100 103 99]
    
#     if quality <= 50
#         quality_factor = 50 / quality 
#     else 
#         quality_factor = (100 - quality) / 50
#     end 

#     Q_quality = Q50 .* quality_factor
    
#     # if vector == "Yes"
#     #     return Q_quality[:]
#     # else 
#     #     return Q_quality
#     # end
# end 


# function zig_zag_collect(block, limit="Yes")
#     """Collect elements from a matrix in a zig zag fashion."""

#     rows, columns = size(block) 
#     first_eight_elements = []
#     solution =  [[] for i in 1:rows + columns]  # [[] for i in range(rows + columns - 1)]

#     for i in 1:rows
#         for j in 1:columns
#             sum = i + j
#             if sum%2 == 0
#                 insert!(solution[sum], 1, block[i, j])
#             else
#                 append!(solution[sum], block[i, j])
#             end 
#         end 
#     end 
              
#     # Extract those 8
#         for i in solution
#             for j in i
#                 if limit == "Yes"
#                     if size(first_eight_elements, 1) == 8
#                         break 
#                     else
#                         append!(first_eight_elements, j)
#                     end
#                 else 
#                     append!(first_eight_elements, j) 
#                 end
#             end 
#         end
#     return Float64.(first_eight_elements)
# end 

# function zero_stuffer(image, stuffed_n, n)
#     """Best explained by example: if given a 10 by 10 matrix, it adds 6 columns of zeros and
#     6 rows of zeros beneath that, where 6 = 'stuffed_n' - 'n'

#      """
#     stuffed_image = hcat(image, zeros(n, stuffed_n - n))
#     stuffed_image = vcat(stuffed_image, zeros(stuffed_n - n, size(stuffed_image, 2)))  
#     return stuffed_image
    
# end

# function create_8by8_blocks!(block_sequences, stuffed_dct_video_sequence, t, b)
#     """Retrieves the four blocks of an 2image."""
#     blocks_in_image = floor(Int64, length(stuffed_dct_video_sequence[:, :, t]) / 64)
#     r_start = 1
#     c_start = 1
#     for i in 1:blocks_in_image  # floor is there to get Int64
#         block_sequences[:,:, i, t, b] = stuffed_dct_video_sequence[:, :, t][r_start:r_start + 8 - 1, c_start:c_start + 8 - 1] 
#         if c_start + 8 - 1 == size(stuffed_dct_video_sequence[:, :, t], 2)
#             c_start = 1
#             r_start += 8 
#         else 
#             c_start += 8
#         end
#     end 
#     return block_sequences
# end


# function video_compressor(data, df, quality)
#     """Read distributions in as matrix e.g., 10 by 10 by T and compress."""

#     # The idea now is to ensure that the number of images/distributions are a multiple of 8. If not, repeat the last frame until it is.
#     # In the end, for each group of 8 images, we create one compact matrix. Thus, compression.
#     stuffer        = 8 - mod(size(data[df]["all_cops"], 2), 8)
#     stuffed_T      = size(data[df]["all_cops"], 2) + stuffer
#     # Repeating last frames 
#     n              = floor(Int64, sqrt(size(data[df]["all_cops"], 1)))  # I use floor to convert to int 
#     W              = floor(Int64, stuffed_T/8)  # how many Windows do we have
#     stuffed_data   = hcat(data[df]["all_cops"], repeat(data[df]["all_cops"][:, stuffed_T - stuffer], 1, stuffer)) 
#     video_sequence = zeros(n, n, stuffed_T)
    
#     # Break data into 8 frame blocks 
#     data_8_images           = zeros(n * n, 8, W)  # TODO: Notice that some distributions are measured in uneven intervals 
#     start                   = 1
#     # Fill each window with 8 time periods of data 
#     for b in 1:W
#         data_8_images[:, :, b] = stuffed_data[:, start:start + 7]
#         start                 += 8
#     end
#     # The dimensions of the image have to be a multiple of 8
#     if mod(n, 8) != 0
#         stuffed_n = n + 8 - mod(n, 8)
#     else
#         stuffed_n = copy(n) 
#     end 

#     # Containers 
#     T = 8
#     block_count             = ceil(Int64, stuffed_n^2 / 64)  # blocks per image 
#     block_sequences         = zeros(8, 8, block_count, T, W)  # all blocks. 4 per image, 32 overtime, 96 total across Windows 
#     reduced_block_sequences = zeros(8, 8, block_count, W)  # 1 matrix per inner-block (4), per window (3)

#     # For each Window of frames ... 
#     for b in 1:W
#         # Get 8 frame data 
#         data = data_8_images[:, :, b]  # 100 by 8
#         # Initialize Containers.         # Round up to a whole number of blocks. Added columns and rows are stuffed with zeros later         # Each distriubtion will be broken into 8 by 8 blocks. Thus for each time period, theres a block sequence 
#         dct_video_sequence = zeros(stuffed_n, stuffed_n, T)

#         # For each time period ...
#         for t in 1:T
#             # Create image - Apply 2D-DCT on the image - Transform matrix to have dimensions multiple of 8 by zero stuffing 
#             video_sequence[:, :, t]     = reshape(data[:, t], (n, n))
#             video_sequence[:, :, t]     = dct(video_sequence[:, :, t])  
#             dct_video_sequence[:, :, t] = zero_stuffer(video_sequence[:, :, t], stuffed_n, n)

#             # Break DCT'ed image into 8 by 8 blocks, going left to right, top to bottom
#             block_sequences = create_8by8_blocks!(block_sequences, dct_video_sequence, t, b)  
#         end 
#         # For each block ...
#         for i in 1:block_count
#             zig_zag_all = zeros(T * 8)
#             start       = 1
#             # From each time period, extract 8 elements from the block in a zig zag fashion, create vector.  
#             for t in 1:T
#                 zig_zag_all[start:start + 8 - 1] = zig_zag_collect(block_sequences[:,:, i, t, b]) 
#                 start                           += 8
#             end 
#             # Apply a 1D DCT on that - Divide it by the quantization vector - Then construct 8 by 8 matrix in an inverse zig-zag fashion
#             q_vector                            = select_quantization(quality)
#             intem_vector                        = round.(dct(zig_zag_all) ./ q_vector[:], digits=1)
#             reduced_block_sequences[:, :, i, b] = inverse_zig_zag(intem_vector)
#             # Combine reduced blocks to compressed image matrix 
#         end
#     end
#     return reduced_block_sequences
# end 

# function get_block_mean(block_sequences)
#     block_means = copy(block_sequences)
#     ww = size(blocks, 5)
#     T  = size(blocks, 4)  # Always 8
#     bb = size(blocks, 3)

#     for w in 1:ww
#         for t in 1:T
#             for b in 1:bb
#                 block_means[:, :, b, t, w] = repeat(mean(block_sequences[:, :, b, t, w], dims=2), outer = (1,size(block_sequences[:, :, b, t, w])[2]))
#             end
#         end
#     end
#     return block_means
# end


# function video_decompressor(reduced_block_sequences, quality)
#     """Performs IDCT on the blocks and returns the reconstructed images."""
#     q_vector = select_quantization(quality)
#     n   = size(reduced_block_sequences, 1)  # size of block along one dimension 
#     i_b = size(reduced_block_sequences, 3)  # image blocks 
#     v_b = size(reduced_block_sequences, 4)  # video blocks 
#     cu  = zeros(8, 8, 8, 4, v_b)  # Cubes
#     for b in 1:v_b
#         for i in 1:i_b
#             zig_zag_vector    = zig_zag_collect(reduced_block_sequences[:,:, i, b], "No") .* q_vector[:]
#             intem_vector      = idct(zig_zag_vector) 
#             cu[:, :, :, i, b] = construct_cubes(intem_vector) 
#         end
#     end
#     images, dct_coefs = construct_images(cu)

#     return images, dct_coefs
# end

# # function construct_cubes_test(intem_vector, block_mean, i, b)
# #     # Get base for each block. The base is the mean. 
# #     T  = size(block_mean, 4)  # Always 8
# #     # Zig zag collect the elements, make a vector, replace top elements with intem_vector
# #     cube  = zeros(8, 8, 8)
# #     start = 1
# #     for t in 1:T
# #         intem_v       = zig_zag_collect(block_mean[:, :, i, t, b], "No")  # e.g., 8x8x4x8x3
# #         intem_v[1:8]  = intem_vector[start:start + 8 - 1]
# #         cube[:, :, t] = inverse_zig_zag(intem_v)
# #         start         += 8
# #     end
# #     return cube 
# # end 

# function construct_images(cubes)
#     cu = copy(cubes)
#     bb = size(cubes, 3)
#     ww = size(cubes, 5)  # Windows 
#     images = zeros(10, 10, ww * bb)         #TODO: generalize
#     dct_coefs = zeros(10 * 10, ww * bb)  #TODO: generalize

#     c = 1
#     for b in 1:ww
#         for block in 1:bb
#             top             = hcat(cu[:, :, block, 1, b], cu[:, :, block, 2, b])
#             bottom          = hcat(cu[:, :, block, 3, b], cu[:, :, block, 4, b])
#             reduced_image = vcat(top, bottom)[1:10, 1:10]
#             dct_coefs[:, c] = reduced_image[:]
#             images[:, :, c] = idct(reduced_image)
#             c              += 1
#         end 
#     end
#     return images, dct_coefs
# end 


# function construct_cubes(intem_vector)
#     # Get base for each block. The base is the mean. 
#     mat = zeros(8, 8)
#     start = 1
#     for i in 1:8
#         mat[:, i] = intem_vector[start:start + 8 - 1]
#         start     += 8
#     end 
#     # Stuff bottom of matrix with zeros 
#     mat = vcat(mat, zeros(56,8))

#     # Generate 8 matrices from these 8 vectors 
#     cube = zeros(8, 8, 8)
#     for i in 1:8
#         cube[:, :, i] = inverse_zig_zag(mat[:, i])
#     end 
#     return cube
# end 
     






# function reconstruct_topologies()
        
#         # Initialize Dictionaries 
#         data_dict[df]["theta_pca"]              = Dict()
#         data_dict[df]["sparse_pca_data"]        = Dict()
#         data_dict[df]["sparse_pca_data"]["all"] = zeros(size(data_matrix))  # For kalman later 
#         # Fill Dictionaries with reconstructed matrix of coefs, reconstructed data by year, reconstructed data all together 
#         for (i, year) in enumerate(order_years(data_dict, df))
#             data_dict[df]["theta_pca"]["$year"]           = reshape(theta_pca[i, :], (10, 10))  # I confirmed reshape handles this properly
#             data_dict[df]["sparse_pca_data"]["$year"]     = idct(data_dict[df]["theta_pca"]["$year"])
#             data_dict[df]["sparse_pca_data"]["all"][:, i] = data_dict[df]["sparse_pca_data"]["$year"][:]   
#         end
#     end




# # Top level function 
# function reconstruct_density(dict_of_files::Dict, equivalized::Int, reduc_crit::Float64, plot::Int)
#     """ Organizes data by dataset and year. Then runs DCT.
    
#     Args:
#     dict_of_files (Dict): takes a dictionary where the keys 
#                                 are the data names (e.g., PSID) 
#                                 and the values are the paths to the data. 

#     equivalized (Int): ∈ {0, 1}, where 1 means to use equivalized data.

#     reduc_crit (Float64): an element between 0 and 1, exclusive 

#     Returns:
#     dct_dict (Dict): A dictionary containing (a) the original data 
#                                              (b) sparse data 
#                                              (c) original coefficients matrix 
#                                              (d) sparse coefficients matrix 
#     """

#     data_dict   = collect_data(dict_of_files, equivalized)
#     dct_dict    = time_series_compression!(data_dict, reduc_crit)
#     # Plots the copulas, empirical and sparse, by dataset
#     if plot == 1
#         compare_copulas!(dct_dict)
#     else
#         println("No plots generated, as requested.")
#     end 
#     return dct_dict
# end 




# function time_series_compression!(data_dict::Dict, reduc_crit::Float64)

#     # For each data set, we create a matrix 
#     for df in collect(keys(data_dict))
#         # Create list of years, ordered 
#         ordered_list_of_years = order_years(data_dict, df)
#         some_year             = ordered_list_of_years[1]
#         # Parameters 
#         grid_size             = length(names(data_dict[df]["$some_year"]))  # tells you how many percentile groups  
#         data_matrix           = zeros(grid_size^2, length(ordered_list_of_years)) # TODO: generalize the "2" and lines prior 
        
#         # I need to "generalize" this to have more dimensions, like, adding male/female, race, education, etc. 
#         # Mentally, if we add one more dimension, then we'd have one data matrix per group in the third dimension.
#         # For example, if our third dimension was sex, then we'd have one data matrix for male and another for female 
#         # If we had another dimension, like education, then we have 13 tables for male and 13 for female 
#         # Math is: Total Tables: 1 * # of groups in third dimension * # of groups in the next dimension  
#         # Easy to implement, but would be good to know what kind of things we plan to use on the third dimension. 
#         # Fill matrix column by column, so we have 1 column per year, in order 
#         for (c_id, year) in enumerate(ordered_list_of_years) 
#             corresponding_year_data = convert(Matrix{Float64}, Matrix(data_dict[df]["$year"]))
#             coefs                   = dct(corresponding_year_data)
#             data_matrix[:,c_id]     = coefs[:]
#         end
#         # Save coefs for this dataset 
#         data_dict[df]["theta"] = data_matrix
#     end
#     data_dict = dct_sparser!(data_dict, reduc_crit)  # sparse data
#     # data_dict = reshape_sparse_data!(data_dict)  # To reconstruct data in the same shape as orig. data. To compare plots 
#     return data_dict
# end

# function dct_sparser!(data_dict::Dict, reduc_crit::Float64)
#     """ At the moment, it provides one way to represent the data in a sparse way. 
#     By computing an average over time for each (wealth, income) group (represented by a row) and using that 
#     as our reference frame, we can measure the "distance" from this reference frame to each frame. Those with 
#     the greatest contribution to the variance are kept. Variance will be this measure of distance from the reference frame. 
    
#     Args:
#         data_dict (Dict): 
#         reduc_crit (Float64): an element between 0 and 1, exclusive, which specifies how sparse you'd like the data 

#     Returns:
#         data_dict (Dict): Data containing sparse data as well as theta_hat 

#     """
#     # For each dataset, get coefs and sparse 
#     for df in collect(keys(data_dict))  # e.g., PSID 
#         # Preliminaries
#         data_dict[df]["sparse_data"] = Dict()
#         ordered_list_of_years = order_years(data_dict, df)
#         # Sparsing 
#         theta                        = data_dict[df]["theta"]  # matrix of coefs, across time 
#         var_theta                    = var(theta, dims=2)  # variance by row, measure of distance from reference frame = average of row 
#         sum_var_theta                = sum(var_theta)  # aggregate variance up 
#         contribution_to_var          = var_theta ./ sum_var_theta
#         importance_ind               = sortperm(contribution_to_var[:], rev=true)  # returns id, sorted from most contributing to least
#         running_var_sum              = cumsum(contribution_to_var[importance_ind])  
#         keep                         = max(count(running_var_sum .< reduc_crit), 1)  # counts how many rows in "running_sum" are less than the reduc_crit
#         indices_of_most_contributing = importance_ind[1:keep]
#         theta_hat                    = zeros(size(theta))
#         theta_hat                    = repeat(mean(theta, dims=2), outer = (1,size(theta)[2])) # Fill each column with the mean, which was calculated over time  
#         # Fill theta hat with the most contributing coefs, based on reduc_crit. Other rows remain constant, containing respective mean 
#         for id in indices_of_most_contributing
#             theta_hat[id, :] = theta[id, :]
#         end 
#         # Initialize Theta hat dict and store important indices 
#         data_dict[df]["theta_hat_full"] = theta_hat
#         data_dict[df]["theta_hat"] = Dict()
#         data_dict[df]["imp_ind"] = indices_of_most_contributing
#         # Fill theta hat by year, idct it 
#         for (i, year) in enumerate(ordered_list_of_years)
#             data_dict[df]["theta_hat"]["$year"]   = reshape(theta_hat[:,i], (10, 10))  # I confirmed reshape handles this properly
#             data_dict[df]["sparse_data"]["$year"] = idct(data_dict[df]["theta_hat"]["$year"])
#         end
#         println("For the $df the number of coefficients are: ", length(indices_of_most_contributing), " for $reduc_crit of the variation.")
#     end 
#     return data_dict
# end



# function reshape_sparse_data!(data_dict::Dict)
#     """Takes the sparse data and reshapes it so that we can compare (a) original copula with (b) sparse copula.
    
#     """
#     for df in collect(keys(data_dict))
#         sparse_data = data_dict[df]["sparse_data"]  
#         grid_size = length(names(data_dict[df]["2004"]))
#         # For later, in assigning the correct year
#         years_string          = filter(!contains(r"\b(theta|sparse_data|theta_hat)\b"), keys(data_dict[df]))  # only years
#         years_num             = parse.(Int64, years_string)
#         ordered_list_of_years = sort!(years_num)
#         # Looping over the years 
#         for c = 1:length(years_string)
#             year               = ordered_list_of_years[c]
#             new_data           = zeros(grid_size, grid_size)  # To be filled 
#             sparse_column_data = sparse_data[:,c]  # data in one column 
#             n                  = 1
#             # Fill columns, one by one 
#             for i=1:grid_size
#                 new_data[:,i] = sparse_column_data[1 + grid_size * (n - 1):grid_size * n]  # 1 to 10, 11 to 20 ... 
#                 n += 1
#             end
#             # To get the correct year in the column, I need to generate the ordered list of years again 
#             data_dict[df]["$year" * "_sparse"] = new_data  # I HAVE TO CHECK THAT THIS WORKS
#         end
#     end
#     return data_dict 
# end

# function dct_sparser!(multidimensional_dct, threshold::Float64)
#     """Finds fraction of DCT coefficients containing (THRESHOLD)% of the "energy" in the density"""

#     vect_multi_dct = multidimensional_dct[:]  # produces matrix columns into 1 vector  
#     abs_vect_multi_dct = broadcast(abs, vect_multi_dct)  # A, loosely speaking, is the "absolute value of the vector"
#     rank_ind = sortperm(abs_vect_multi_dct,rev=true)  # sorts then ranks
#     coeffs = 0;
#     while norm(vect_multi_dct[rank_ind[1:coeffs + 1]])/norm(vect_multi_dct) < threshold  # Stops when it finds the vector of coefficients that equal or exceed threshold
#         coeffs +=  1;
#     end
#     println(coeffs)
#     abs_multi = broadcast(abs, multidimensional_dct)
#     abs_threshold = broadcast(abs, multidimensional_dct[:][rank_ind[coeffs]])  # this gives us the smallest acceptable value. Another lower = 0
#     multidimensional_dct[abs_multi .< abs_threshold] .= 0;  # performs element wise replacement of the small coefs
#     sparse_dct = multidimensional_dct
#     return sparse_dct
# end

# function discrete_cosine_transform!(data_dict::Dict)
#     """Fits cosine functions on the functional data"""
#     for df in collect(keys(data_dict))  # apparently using collect here is not necessary, but I use it to be general
#         copula_keys = filter(contains(r"copula"), collect(keys(data_dict[df])))  # collect all keys with copula name 
#         for copula in collect(copula_keys)  # you must use collect. keys() is not the same as in python
#             density          = data_dict[df][copula].density  # in the Bivate object, we extract the density 
#             multi_dct        = FFTW.r2r!(density, FFTW.REDFT00)  # Multi-dimensional DCT, checked with MATLAB
#             sparse_dct       = dct_sparser!(multi_dct, 0.998)
#             inv_along_column = FFTW.idct!(sparse_dct, 2)  # column first for inverse
#             inv_along_row    = FFTW.idct!(inv_along_column, 1)

#             new_key_name = copula[begin:4] * "_dct"  # e.g., 1992_dct     
#             data_dict[df][new_key_name] = inv_along_row  # density reconstructed in a sparse way
#         end
#     end 
#     return data_dict
# end 

# function excel_to_csv(dict_of_files)
#     """Converts excel sheets to csv files"""
#     saving_path = raw"/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing/PSID"[begin:end-4] * "csv_files"

#     for df in collect(keys(dict_of_files))
#         excel_file = dict_of_files[df] * ".xlsx"  # add extension, I do this for a reason
#         main_data = DataFrame(XLSX.readtable(excel_file, "dec_data", stop_in_empty_row=false)...)
#         eq_data = DataFrame(XLSX.readtable(excel_file, "dec_data_eq", stop_in_empty_row=false)...)
#         CSV.write(saving_path * df * "_main.csv", main_data)
#         CSV.write(saving_path * df * "_eq.csv", eq_data)
#     end
# end