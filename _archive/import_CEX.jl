using Pkg
Pkg.activate("CEX")
using HTTP, CSV
using DataFrames, DataFramesMeta, DataStructures, Dates, DelimitedFiles, Downloads, Logging, Statistics


function download_csv_files(ref_year::String, is_interview_survey::Bool, download_folder::String)
    survey_id = ifelse(is_interview_survey, "intrvw$(ref_year[end-1:end])", "diary$(ref_year[end-1:end])");
    Downloads.download("https://www.bls.gov/cex/pumd/data/comma/$(survey_id).zip", "$(download_folder)/$(survey_id).zip");
    run(`unzip -qq $(download_folder)/$(survey_id).zip -d $(download_folder)/`);
    return survey_id;
end


function csv_files_to_dataframes(survey_id::String, download_folder::String, prefixes::Vector{String})
    
    # Memory pre-allocation: sorting problem
    last   = "";
    buffer = SortedDict{String, DataFrame}()

    # Memory pre-allocation: output
    output = Vector{SortedDict{String, DataFrame}}(undef, length(prefixes))    

    # Accounts for naming inconsistencies in the folders
    survey_path = joinpath(download_folder, survey_id)
    if survey_id ∈ readdir(survey_path)
        survey_path = joinpath(survey_path, survey_id)
    end

    # Loop over the files in the directory and focus on the csv files
    for file_name_ext in filter(isfile, readdir(survey_path))
        file_name   = split(file_name_ext, ".")[1]
        file_prefix = file_name[1:end-3]

        # Proceed if `file_prefix` is in the target prefixes
        if isnothing(findfirst(".", file_name_ext)) || !(file_prefix ∈ prefixes)
            continue
        end

        if file_name[end-2] == '9'
            new_key = "$(file_prefix)_19$(file_name[end-2:end])"
        else
            new_key = "$(file_prefix)_20$(file_name[end-2:end])"
        end

        # Store current csv file as an iterator over rows
        new_dict_item = CSV.File(joinpath(survey_path, file_name_ext), missingstring=["", "."])

        # Include custom identifier for CUs
        if "NEWID" ∈ names(new_dict_item)
            new_dict_item[!, :CUSTOM_CUID] = parse.(Int64, eachrow(new_dict_item[!, :NEWID]) .|> (s -> s[1:end-1]))
        end

        # Add current file to buffer
        if file_prefix == last
            merge!(buffer, Dict(new_key => new_dict_item))
        else
            # Add previous file to output
            if !isempty(buffer)
                output[findfirst(last .== prefixes)] = copy(buffer)
            end

            # Clear buffer and add current file
            empty!(buffer)
            merge!(buffer, Dict(new_key => new_dict_item))
            last = file_prefix
        end
    end

    # Add final file to output
    if !isempty(buffer)
        output[findfirst(last .== prefixes)] = copy(buffer)
    end

    return output
end

function get_data(prefixes::Vector{String}, is_interview_survey::Bool, from_year::Int64, to_year::Int64; verbose::Bool=true)
    
    # Memory pre-allocation: output
    output = Vector{Dict{String, DataFrame}}(undef, length(prefixes))    

    # Memory pre-allocation: download folder
    download_folder = mktempdir(prefix="ce_pumd_", cleanup=true)

    for t = from_year:to_year
        if verbose
            @info("Downloading survey referring to year $(t)")
        end

        survey_id = download_csv_files(string(t), is_interview_survey, download_folder)
        new_entries = csv_files_to_dataframes(survey_id, download_folder, prefixes)

        for i = 1:length(prefixes)
            if haskey(new_entries, i)
                if haskey(output, i)
                    merge!(output[i], new_entries[i])
                else
                    output[i] = new_entries[i]
                end
            end
        end
    end

    return output
end

UCC_column_as_strings!(df::DataFrame, UCCs::Vector{String}) = nothing;

function UCC_column_as_strings!(df::DataFrame, UCCs::Vector{Int64})
    df[!,:UCC] = string.(df[!, :UCC]);
end

function quarterly_hh_level!(df::DataFrame)

    # Construct :REFMO from :REF_DATE
    transform!(df, :REF_DATE => ByRow(x -> Dates.month(x)) => :REFMO)

    # Convert monthly reference periods to end of quarters
    transform!(df, :REF_DATE => ByRow(x -> Dates.lastdayofquarter(x)), renamecols=false)

    # Aggregate at quarterly frequency
    by_cols = [:CUSTOM_CUID, :REF_DATE]
    transform!(df, [:HH_DATA], :HH_DATA => sum)
    transform!(df, :REFMO => (x -> length(unique(x))) => :MONTHS_PER_REF_DATE)
    filter!(row -> row.MONTHS_PER_REF_DATE == 3, df)
    select!(df, Not(:MONTHS_PER_REF_DATE))
    rename!(df, Dict(:HH_DATA_sum => "HH_DATA"))

    # Return output
    return nothing
end

function merge_fmli_files(fmli_files::SortedDict{String, DataFrame}, mnemonics::Vector{String})

    # Convenient conversion
    mnemonics_sym = Symbol.(unique(vcat("QINTRVYR", "QINTRVMO", mnemonics)))
    
    # Pre-allocate output DataFrame with correct size
    nrows = sum(size(df, 1) for df in values(fmli_files))
    output = DataFrame(REF_DATE = Date[], vcat(mnemonics_sym[1], mnemonics_sym[3:end]) => zeros(nrows, length(mnemonics_sym) - 1))

    i = 1
    for df in values(fmli_files)
        # Select target variables
        v_selection = df[!, mnemonics_sym]

        # Update year format using broadcasting
        v_selection[!, :QINTRVYR] .= ifelse.(v_selection[!, :QINTRVYR] .< 100, v_selection[!, :QINTRVYR] .+ 1900, v_selection[!, :QINTRVYR] .+ 2000)

        # Add :REF_DATE
        @transform! v_selection @byrow :REF_DATE = Dates.lastdayofmonth(Date(row[:QINTRVYR], row[:QINTRVMO], 1))

        # Update output
        output[i:i+size(v_selection, 1)-1, :] .= v_selection
        i += size(v_selection, 1)
    end

    return output
end


function get_hh_level(input_dict::SortedDict{String, DataFrame}; is_itbi::Bool=false, is_mtbi::Bool=false, UCC_selection::Union{Nothing, Vector{String}}=nothing, quarterly_aggregation::Bool=false)
    
    if (is_itbi && is_mtbi) || (!is_itbi && !is_mtbi)
        error("`is_itbi` or `is_mtbi` must be true.");
    end

    if is_itbi
        ref_year = :REFYR;
        ref_month = :REFMO;
    else
        ref_year = :REF_YR;
        ref_month = :REF_MO;
    end

    # Pre-allocate output DataFrame with correct size
    nrows = sum(size(df, 1) for df in values(input_dict))
    output = DataFrame(CUSTOM_CUID = vcat([df.CUSTOM_CUID for df in values(input_dict)]...), REF_DATE = Date[], HH_DATA = zeros(nrows))

    i = 1
    for df in values(input_dict)

        UCC_column_as_strings!(df, df[!,:UCC]); #TODO: may not need 

        # Update year format using broadcasting
        df[!, ref_year] .= ifelse.(df[!, ref_year] .< 100, df[!, ref_year] .+ 1900, df[!, ref_year] .+ 2000)

        # Filter rows based on UCC_selection
        if !isnothing(UCC_selection)
            filter_rows = [row[:UCC] in UCC_selection for row in eachrow(df)]
            df = df[filter_rows, :]
        end

        # Aggregate at monthly frequency to remove duplicates
        transform!(df, [ref_year, ref_month] => ByRow((year, month) -> Dates.lastdayofmonth(Date(year, month))) => :REF_DATE)

        col = if is_itbi
            :VALUE
        else
            :COST
        end
    
        v_grouped = combine(df, col => sum, group = [:CUSTOM_CUID, :REF_DATE])
        rename!(v_grouped, :sum => :HH_DATA)
        
        # Update output
        output[i:i+size(v_grouped, 1)-1, :] .= v_grouped
        i += size(v_grouped, 1)
    end

    # Return output
    if quarterly_aggregation
        quarterly_hh_level!(output)
    end
    return output
end
