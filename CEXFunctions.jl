# using Pkg 
# Pkg.activate("CEX")
# using CeMicrodata, CSV, Dates, DataFrames, Statistics, DataFramesMeta;
# IS_prefixes =["mtbi", "fmli"];  # interview, good for everything
# # DS_prefixes =["expd", "fmld"];  # diary, for 2-week sequence, good for frequent purchases 

# # Creating large dictionary, broken into segments based on whether measures are missing or not 
# mtbi_cols = Dict(
#     "IS_80s"       => ["210110", "500110", "220121", "490110", "490211", "490212", "490220", "490231", "490232", "490311", "490312", "490313", "490314", "490315", "490411", "490412", "490413", "490900", "490318", "490319", "470220", "480110", "480211", "490500", "520530", "530411", "340210", "800721"],
#     "IS_80s_late"  => [],
#     "IS_90s_early" => ["800721", "210110", "500110", "220121", "490110", "490211", "490212", "490220", "490231", "490232", "490311", "490312", "490313", "490314", "490315", "490411", "490412", "490413", "490900", "490318", "490319", "470220", "480110", "480211", "490500", "520530", "520531", "520532", "530411", "530411", "340210"],
#     "IS_90s_late"  => ["800721", "220121", "520530", "520531", "520532", "530411", "530411"],
#     "IS_00s"       => ["800721", "220121", "520530", "520531", "520532", "530411", "530411"],
#     "IS_10s"       => ["800721", "220121", "520530", "520531", "520532", "530411", "530411"],
# )
# CEX_dict = Dict(
#     "IS_80s"       => get_data(IS_prefixes, true, 1980, 1981)
#     )

# can_be_parsed = tryparse.(Int, CEX_dict["IS_80s"][1]["mtbi_20804"][:, :REF_MO]) .!== nothing
# CEX_dict["IS_80s"][1]["mtbi_20804"] = CEX_dict["IS_80s"][1]["mtbi_20804"][can_be_parsed, :]
# CEX_dict["IS_80s"][1]["mtbi_20804"][!, :REF_MO] = parse.(Int64, CEX_dict["IS_80s"][1]["mtbi_20804"][!, :REF_MO])

# input_dict    = CEX_dict["IS_80s"][1]
# is_mtbi       = true
# is_itbi       = false
# UCC_selection =[mtbi_cols["IS_80s"]...]
# v             = input_dict["mtbi_20801"]


key_selector(y) = y < 1983 ? "IS_80s" : y >= 1984 && y < 1990 ? "IS_80s_late" : y >= 1990 && y <= 1993 ? "IS_90s_early" : "IS_rest"

function import_additional_files(sep_files_cols, sep_files_yrs)
    dfs = Dict()
    
    for k in collect(keys(sep_files_cols))
        df = import_specific_file(sep_files_yrs[k], [k], true, true)

        for j in collect(keys(df[1]))
            select!(df[1][j], sep_files_cols[k])

            df[1][j][!, :year]           = parse.(Int, [convert_year(string(x)[1:end-1]) for x in df[1][j][!, "QYEAR"]])
            df[1][j][!, :quarter]        = df[1][j][!, :QYEAR] .% 10
            cond                         = df[1][j][!, :quarter] .== 5
            df[1][j][!, :quarter][cond] .= 1
            df[1][j][!, :REF_DATE]       = QuarterlyDate.(df[1][j][!, :year], df[1][j][!, :quarter]) # this data undergoes some adjustment so that the date is the reference period 
        
            # Shift the REF_DATE back 1 quarter if REC_ORIG == 4
            # df[1][j][!, :REF_DATE] = [coalesce(x, 5) == 4 ? y - Quarter(1) : y for (x,y) in zip(df[1][j][:, :REC_ORIG], df[1][j][:, :REF_DATE])]
        
            # Aggregate by CU and date
            if k == "mor" 
                df[1][j][!, :mortgage] = coalesce.(df[1][j][!, :QBLNCM3X], 0) # coalesce.(df[1][j][!, :QBLNCM3X], df[1][j][!, :QBLNCM2X], df[1][j][!, :QBLNCM1X])
                df[1][j] = combine(groupby(df[1][j], [:CUSTOM_CUID, :REF_DATE]), :mortgage=>sum) # does nothing 

                # Convert the zeros to missing
                df[1][j][!, :mortgage_sum] = [x == 0 ? missing : x for x in df[1][j][!, :mortgage_sum]]

            elseif k == "fn2"
                # df[1][j][!, :REF_DATE] .= df[1][j][!, :REF_DATE] .- Quarter(1) # Ahead of MTBI, which has the actual reference period 
                df[1][j] = combine(groupby(df[1][j], [:CUSTOM_CUID, :REF_DATE]), :CREDITX1=>sum)
            
            elseif k == "fna"
                # df[1][j][!, :REF_DATE] .= df[1][j][!, :REF_DATE] .- Quarter(1)
                df[1][j] = combine(groupby(df[1][j], [:CUSTOM_CUID, :REF_DATE]), :CREDITX5=>sum)
                
            elseif k == "oph"
                try
                    df[1][j] = combine(groupby(df[1][j], [:CUSTOM_CUID, :REF_DATE]), :PRINAMTX=>sum)
                catch e
                    df[1][j] = combine(groupby(df[1][j], [:CUSTOM_CUID, :REF_DATE]), :TOTOWED=>sum)
                end
            elseif k == "ovb"
                df[1][j][!, :veh_debt] = coalesce.(df[1][j][!, :QBALNM3X], 0) # coalesce.(df[1][j][!, :QBALNM3X], df[1][j][!, :QBALNM2X], df[1][j][!, :QBALNM1X])
                df[1][j] = combine(groupby(df[1][j], [:CUSTOM_CUID, :REF_DATE]), :veh_debt=>sum)

                # Convert the zeros to missing
                df[1][j][!, :veh_debt_sum] = [x == 0 ? missing : x for x in df[1][j][!, :veh_debt_sum]]
            elseif k == "hel"
                df[1][j][!, :heloc] = coalesce.(df[1][j][!, :QBLNCM3G], 0) #coalesce.(df[1][j][!, :QBLNCM3G], df[1][j][!, :QBLNCM2G], df[1][j][!, :QBLNCM1G])
                df[1][j] = combine(groupby(df[1][j], [:CUSTOM_CUID, :REF_DATE]), :heloc=>sum)

                # Convert the zeros to missing
                df[1][j][!, :heloc_sum] = [x == 0 ? missing : x for x in df[1][j][!, :heloc_sum]]
            end 
        end
    
        # Append the dataframes together in the dictionary to create a large df 
        final_df = DataFrame()
        for (i, w) in enumerate(collect(keys(df[1])))
            if i == 1
                final_df = df[1][w]
            else
                append!(final_df, df[1][w], promote=true)
            end
        end

        dfs[k] = unique(final_df, ["CUSTOM_CUID", "REF_DATE"]) # thing is: IDs in 1995/1996 were recycled. Understanding the gravity of the situation and the fact that there aren't many, I will just drop them.
    end

    return dfs
end



function clean_cex_all(IS_prefixes, years, key_selector, fmli_cols, mtbi_cols, itbi_cols, fmli_names_dict, mtbi_names_dict, itbi_names_dict, path)
    """
    This function cleans the Consumer Expenditure Survey data from the BLS.
    """

    # Pre-allocate panels to append to 
    mtbi_panel = DataFrame()
    fmli_panel = DataFrame()
    itbi_panel = DataFrame()
    
    for y in years 
        sleep(30)
        k    = key_selector(y)
        df   = retrieve_data(IS_prefixes, true, y, y) 
        if y == 1980 df = correct_month!(df) end
        if y == 1981 delete!(df[2], "fmli_20811") end

        # For the MTBI, the reference date refers to the date the actual consumption took place 
        if y ∉ [1984, 1985, 1986, 1987, 1988, 1989]
            df[1] = aggregate_to_hh_level(df[1], is_mtbi=true, UCC_selection=[mtbi_cols...], quarterly_aggregation=true, annual_aggregation=false)
            # Clean MTBI data 
            df[1] = renaming_columns!(df[1], mtbi_names_dict)
            # println(names(df[1]))
            df[1] = generate_veh_repairs!(df[1])
        else
            println("This data does not have MTBI UCCs to extract")
            df[1] = DataFrame()
        end

        # ITBI
        if y ∉ [1980, 1981, 1984, 1985, 1986, 1987, 1988, 1989]
            df[3] = aggregate_to_hh_level(df[3], is_itbi=true, UCC_selection=[itbi_cols...], quarterly_aggregation=true, annual_aggregation=false)
            
            df[3] = renaming_columns!(df[3], itbi_names_dict)
            
        else
            println("This data does not have ITBI UCCs to extract")
            df[3] = DataFrame()
        end 

        # Clean FMLI data
        if y == 1994
            cols = filter(x -> x ∉ ["RENTEQVX"], fmli_cols[k])
            # remove rental eq. variable 
            df[2] = subset_data(df[2], cols)
            df[2] = merge_fmli_files(df[2], cols)
        else
            df[2] = subset_data(df[2], fmli_cols[k])
            df[2] = merge_fmli_files(df[2], fmli_cols[k])
        end

        if y ∈ [1984, 1985, 1986, 1987, 1988, 1989]
            renaming_columns!(df[2], fmli_names_dict)
        end

        if y ∈ [1980, 1981]
            try 
                rename!(df[2], :NUM_AUTO => :VEHQ)
            catch ee
                println("No NUM_AUTO column")
            end
        end

        # df[2] = set_income_correctly(df[2]) # TODO: This needs to be corrected for perhaps Q2,Q3,Q4 

        # Take the income value from the last quarter of the SURVEY (each quarter reports the income of the previous 12 months ... hmmm)
        # “The Effects of Population Aging on the Relationship among Aggregate Consumption, Saving, and Income” by Karen Dynan, Wendy Edelberg, and Michael Palumbo

        # Append FMLI, MTBI files 
        append!(itbi_panel, df[3], cols=:union)
        append!(fmli_panel, df[2], cols=:union)
        append!(mtbi_panel, df[1], cols=:union)
    end

    # Clean files
    clean_fmli_files!(fmli_panel)
    # clean_mtbi_files!(mtbi_panel)

    # aggregate_to_annually_fmil!(fmli_panel)  # TODO: here, I need to use MO_SCOPE

    # Merge files together on :CUSTOM_CUID and :REF_DATE
    # data = outerjoin(fmli_panel, mtbi_panel, on=[:CUSTOM_CUID, :REF_DATE], makeunique=true)

    # # Clean data 
    # data = clean_final_df(data)
    # data[!, "INTNUM"]       = [x % 10 for x in data[:, :NEWID]]

    for obj in [fmli_panel, mtbi_panel, itbi_panel]
        obj[!, "REF_DATE"] = QuarterlyDate.(obj[!, "REF_DATE"])
        unique!(obj)
    end

    CSV.write(data_path * "/mtbi_processed.csv", unique(mtbi_panel))
    CSV.write(data_path * "/fmli_processed.csv", unique(fmli_panel))
    CSV.write(data_path * "/itbi_processed.csv", unique(itbi_panel))

    # Create liquid column in itbi 
    # itbi_panel[!, "liquid"] = itbi_panel[!, "liquid11"] .+ itbi_panel[!, "liquid12"] .+ itbi_panel[!, "liquid13"] .+ itbi_panel[!, "liquid14"] .+ itbi_panel[!, "liquid21"] .+ itbi_panel[!, "liquid22"] # since they should never overlap 
    # select!(itbi_panel, Not([:liquid11, :liquid12, :liquid13, :liquid14, :liquid21, :liquid22]))


    return mtbi_panel, fmli_panel, itbi_panel
end

function further_processing!(df, cat_in_str)
    # Fill the data with zeros if missing 
    # From CEX 2013 Users’ Documentation: the MTBI has no missings, so when I make a wide dataset, I can set everything else to 0. 
    # Same holds for the ITBI 
    for c in setdiff(names(df), [:CUSTOM_CUID, :QINTRVYR, :QINTRVMO, :NEWID, :REF_DATE])
        df[!, c] = coalesce.(df[!, c], 0)
    end

    # Aggregate columns with same stub
    df_names  = names(df)
    for c in cat_in_str
        df[!, c] .= 0
        cat_names = df_names[startswith.(df_names, c)]
        for n in cat_names
            df[!, c] = df[!, c] .+ df[!, n]
        end

        select!(df, Not(Symbol.(cat_names)))
    end

    # combine and groupby data to custom_cuid and ref_date and take the max of the columns
    df = combine(groupby(df, [:CUSTOM_CUID, :REF_DATE]), names(df, Not([:REF_DATE, :CUSTOM_CUID])) .=> maximum)  # TODO: only works with non-missing data

    # rename column to remove the "_maximum"
    for c in names(df)
        if endswith(c, "_maximum")
            rename!(df, c => replace(c, "_maximum" => ""))
        end
    end
    return df

end


function nan_max(itr) 
    a = [x for x in itr if !isnan(x)]
    if length(a) != 0 
        return maximum(a)
    else
        return NaN
    end 
end



function clean_cex(IS_prefixes, years, key_selector, fmli_cols, mtbi_cols, fmli_names_dict, mtbi_names_dict, path)
    """
    This function cleans the Consumer Expenditure Survey data from the BLS.
    """

    # Pre-allocate panels to append to 
    mtbi_panel = DataFrame()
    fmli_panel = DataFrame()
    
    for y in years 
        sleep(30)
        k    = key_selector(y)
        df   = retrieve_data(IS_prefixes, true, y, y) 
        if y == 1980 df = correct_month!(df) end
        if y == 1981 delete!(df[2], "fmli_20811") end

        # For the MTBI, the reference date refers to the date the actual consumption took place 
        if y ∉ [1984, 1985, 1986, 1987, 1988, 1989]
            df[1] = aggregate_to_hh_level(df[1], is_mtbi=true, UCC_selection=[mtbi_cols[k]...], quarterly_aggregation=true, annual_aggregation=false)
            # Clean MTBI data 
            df[1] = renaming_columns!(df[1], mtbi_names_dict)
            # println(names(df[1]))
            df[1] = generate_veh_repairs!(df[1])
        else
            println("This data does not have MTBI UCCs to extract")
            df[1] = DataFrame()
        end

        # Clean FMLI data
        if y == 1994
            cols = filter(x -> x ∉ ["RENTEQVX"], fmli_cols[k])
            # remove rental eq. variable 
            df[2] = subset_data(df[2], cols)
            df[2] = merge_fmli_files(df[2], cols)
        else
            df[2] = subset_data(df[2], fmli_cols[k])
            df[2] = merge_fmli_files(df[2], fmli_cols[k])
        end

        if y ∈ [1984, 1985, 1986, 1987, 1988, 1989]
            renaming_columns!(df[2], fmli_names_dict)
        end

        if y ∈ [1980, 1981]
            rename!(df[2], :NUM_AUTO => :VEHQ)
        end

        # df[2] = set_income_correctly(df[2]) # TODO: This needs to be corrected for perhaps Q2,Q3,Q4 

        # Take the income value from the last quarter of the SURVEY (each quarter reports the income of the previous 12 months ... hmmm)
        # “The Effects of Population Aging on the Relationship among Aggregate Consumption, Saving, and Income” by Karen Dynan, Wendy Edelberg, and Michael Palumbo

        # Append FMLI, MTBI files 
        append!(fmli_panel, df[2], cols=:union)
        append!(mtbi_panel, df[1], cols=:union)
    end

    # Clean files
    clean_fmli_files!(fmli_panel)
    # clean_mtbi_files!(mtbi_panel)

    # aggregate_to_annually_fmil!(fmli_panel)  # TODO: here, I need to use MO_SCOPE

    # Merge files together on :CUSTOM_CUID and :REF_DATE
    # data = outerjoin(fmli_panel, mtbi_panel, on=[:CUSTOM_CUID, :REF_DATE], makeunique=true)

    # # Clean data 
    # data = clean_final_df(data)
    # data[!, "INTNUM"]       = [x % 10 for x in data[:, :NEWID]]

    # CSV.write(path * "/CEX_processed.csv", select(data, :REF_DATE, :))
    return mtbi_panel, fmli_panel
end

function set_income_correctly(df)
    df[!, "FINCBTAX"][df[!, "FINCBTAX"] .!= last(df[:, "REF_DATE"])] .= 0
    return df
end

# Issue: when we import the data by year, it's from q1-q5. We need to keep q5 income here only. 

function clean_final_df(data)
    # Fill in FMLI columns with MTBI data as planned 
    left_cols = names(data)[endswith.(names(data), "_1")]
    for c in left_cols 
        old_c = c[1:end-2]
        try 
            data[!, old_c] = coalesce.(data[:, old_c], data[:, c])
        catch e 
            println("Error: ", e)
        end
    end

    # Subset to necessary columns 
    select!(data, Not(left_cols))

    # Convert missings to zero 
    for c in names(data)
        if c ∉ [:CUSTOM_CUID, :REF_DATE]
            data[!, c] = coalesce.(data[:, c], 0)
        end
    end

    # Drop if Age is less than 25 and greater than 64 
    # data = data[data[:, :AGE_REF] .>= 25, :]
    # data = data[data[:, :AGE_REF] .<= 64, :]

    # Correcting for inflation, perhaps per product category (but maybe not because PSID) # TODO: do it in Stata 

    return data
end


function renaming_columns!(df, names_dict)
    new_names = [endswith(s, "_sum") ? replace(s, "_sum" => "") : s for s in names(df)]
    rename!(df, new_names)
    # println(names(df))
    # Rename columns based on dictionary
    for (old_col, new_col) in names_dict
        if old_col in names(df)
            rename!(df, old_col => new_col)
        end
    end
    return df
end

function generate_veh_repairs!(mtbi_df)

    mtbi_df[!, :MAINRPCQ] .= 0
    container_exp         = []
    # Add up all columns beginning with "VEH_EXP"
    for col_name in names(mtbi_df)
        if startswith(col_name, "VEH_EXP")
            push!(container_exp, col_name)
            mtbi_df[!, :MAINRPCQ] .+= mtbi_df[:, col_name]
        end
    end

    # Drop all columns beginning with "VEH_EXP"
    veh_names = names(mtbi_df)[startswith.(names(mtbi_df), "VEH_EXP")]
    select!(mtbi_df, Not(Symbol.(veh_names)))
    # println(sort(container_exp))
    return mtbi_df
end


function correct_month!(df)
    can_be_parsed                   = tryparse.(Int, df[1]["mtbi_20804"][:, :REF_MO]) .!== nothing
    df[1]["mtbi_20804"]             = df[1]["mtbi_20804"][can_be_parsed, :]
    df[1]["mtbi_20804"][!, :REF_MO] = parse.(Int64, df[1]["mtbi_20804"][!, :REF_MO])
    return df
end

# function vehicle_rental_equivalence(data)
# """
# For vehicle rental equivalent following Cutler, Katz 1991:
# To find the imputed rental value, we took consumer units that reported spending on new and used vehicles regressed the amount of that 
#     - on total expenditures (less vehicle expenditures)
#     - expenditures squared
#     - income before taxes
#     - the age of the reference person 
#     - dummy variables for the sex and education of the reference person, 
#     - the size of the consumer unit
# """

#     foreach i of numlist 98 2000(2)2018 {
	
# 	gen tot_prices_of_veh`i' = 0
		
# 		foreach v of numlist 1(1)1 {
# 			foreach var in yr_veh`v'_acq_98 yr_veh`v'_acq_2000 yr_veh`v'_acq_2002 ///
# 			yr_veh`v'_acq_2004 yr_veh`v'_acq_2006 yr_veh`v'_acq_2008 yr_veh`v'_acq_2010 ///
# 			yr_veh`v'_acq_2012 yr_veh`v'_acq_2014 yr_veh`v'_acq_2016 yr_veh`v'_acq_2018 {
				
# 				if `i' == 98 {
# 					replace tot_prices_of_veh`i' = tot_prices_of_veh`i' + veh`v'_price`i' if `var' == 19`i'
# 				}
# 				else {
# 					replace tot_prices_of_veh`i' = tot_prices_of_veh`i' + veh`v'_price`i' if `var' == `i'
# 				}
# 			}
# 	}
# }

# * Generate total consumption THUS FAR. Vehicle rental eq. is added after regression 
# foreach i of numlist 98 2000(2)2018 {
# 	gen consumption`i' = food`i' + rent`i' + utilities`i' + prop_taxes`i' + ///
# 	homeinsurance`i' + health`i' + pubtrans`i' + eduexp`i' + childcare`i' + house_renteq`i'
	
# 	gen consumption_sq`i' =  consumption`i' *  consumption`i' 
# }

# * Run year by year regressions of rental value 
# foreach i of numlist 98 2000(2)2018 {
# 	disp in red `i'
# 	reg tot_prices_of_veh`i' consumption`i' consumption_sq`i'  /// 
# 	i.sex`i' i.edu`i' income`i' i.famsize`i' /// 
# 	ageh_`i' [aw=wgt`i'] if tot_prices_of_veh`i' > 0 & !missing(tot_prices_of_veh`i'), r
# 	predict tot_prices_of_veh`i'hat
# 	replace tot_prices_of_veh`i'hat = 0 if tot_prices_of_veh`i'hat < 0 & !missing(tot_prices_of_veh`i'hat)
# }

# end

    
function clean_fmli_files!(fmli_panel)
    # Aggregate fmli_panel to annual #TODO: does fmli have the CUSTOM ID?
    fmli_panel[!, "QINTRVYR"]    = year.(Date.(Int.(fmli_panel[!, "QINTRVYR"]), 1))
    fmli_panel[!, "QINTRVMO"]    = month.(Date.(fmli_panel[!, "QINTRVYR"], Int.(fmli_panel[!, "QINTRVMO"])))
    # fmli_panel[!, "QINTRVQTR"]   = quarterofyear.(Date.(fmli_panel[!, "QINTRVYR"], fmli_panel[!, :QINTRVMO]))
    transform!(fmli_panel, ["QINTRVYR", "QINTRVMO"] => ByRow((year, month) -> Dates.lastdayofquarter(Date(year, month))) => :REF_DATE);

    # # Fixing ID 
    # fmli_panel[!, "CUSTOM_CUID"] = floor.(fmli_panel[!, :NEWID])

    # Shift dates 1 quarter back since that is when consumption is observed
    # fmli_panel[!, :REF_DATE]    = fmli_panel[!, :REF_DATE] #.- Quarter(1)
    fmli_panel[!, :CUSTOM_CUID] = [parse(Int64, string(id)[1:end-1]) for id in fmli_panel[!, :NEWID]];
    
    # aggregate_to_annually_fmil!(fmli_panel)

    # # Weigh the data  
    # for col in ["FINCBTAX", "FDHOMECQ", "FDAWAYCQ", "RNTXRPCQ", "VEHINSCQ", "UTILCQ", "HEALTHCQ", "MAINRPCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "BBYDAYCQ"]
    #     fmli_panel[!, col] = fmli_panel[:, col] .* fmli_panel[:, :FINLWT21]  
    # end

    return fmli_panel
end


# Getting number of vehicles from DIARY	FMLD	VEHQ 
function clean_diary()
    df    = retrieve_data(["fml"], false, 1980, 1981) 
    for k in keys(df[1])
        select!(df[1][k], [:NEWID, :STRT_M_Y, :VEHQ])
    end

    # the cross-sections 
    diary = append!(df[1]["fml_20d80"], df[1]["fml_20d81"]) 
    # diary[!, "YEAR"]       = [x % 100 for x in diary[:, :STRT_M_Y]]
    # use the split_month_year function to split integers into month and year columns
    dates             = DataFrame([split_month_year(x) for x in diary[:, "STRT_M_Y"]])
    diary[!, "MONTH"] = dates[:, "MONTH"]
    diary[!, "YEAR"]  = dates[:, "YEAR"] .+ 1900 # DataFrame([split_month_year(x) for x in diary[:, "STRT_M_Y"]])

    diary[!, :CUSTOM_CUID] = [parse(Int64, string(id)[1:end-1]) for id in diary[!, :NEWID]];

    # Create a new column with only the first two digits of each observation
    # diary[!, "MONTH"]      = parse.(Int, [substring(x, 1, 2) for x in diary[:, "MONTH"]])
    transform!(diary, ["YEAR", "MONTH"] => ByRow((year, month) -> Dates.lastdayofquarter(Date(year, month))) => :REF_DATE);

    return select!(diary, [:CUSTOM_CUID, :REF_DATE, :VEHQ])
end

function split_month_year(x::Int)
    if length(string(x)) == 4
        month = parse(Int, string(x)[1:2])
        year = parse(Int, string(x)[3:4])
    elseif length(string(x)) == 3
        month = parse(Int, string(x)[1])
        year = parse(Int, string(x)[2:3])
    else
        error("Invalid integer length: $(x)")
    end
    return (MONTH = month, YEAR = year)
end



function aggregate_to_hh_level(input_dict; is_itbi::Bool=false, is_mtbi::Bool=false, UCC_selection::Union{Nothing, Vector{String}}=nothing, quarterly_aggregation::Bool=false, annual_aggregation::Bool=false)
    
    if (is_itbi && is_mtbi) || (!is_itbi && !is_mtbi)
        error("`is_itbi` or `is_mtbi` must be true.");
    end

    local ref_year, ref_month;
    if is_itbi
        ref_year  = :REFYR;
        ref_month = :REFMO;
        exp_col   = :VALUE;
    else
        ref_year = :REF_YR;
        ref_month = :REF_MO;
        exp_col   = :COST;
    end

    # Memory pre-allocation for output
    output = DataFrame();

    # Loop over monthly tables
    for (k, v) in input_dict

        # Copy original data
        v_copy         = copy(v); # this line slows done the code, but allows to compute the hh level data without changing the input monthly table
        v_copy[!,:UCC] = string.(v_copy[!, :UCC]);

        # Fill data with 0 if missing 
        v_copy[!,exp_col] = coalesce(v_copy[!,exp_col], 0)

        # Convert year to YYYY format
        for row in eachrow(v_copy)
            if row[ref_year] < 20 # YY rather than YYYY and referring to 20YY
                row[ref_year] += 2000;
            elseif 20 < row[ref_year] < 100 # YY rather than YYYY and referring to 19YY
                row[ref_year] += 1900;
            end
        end

        if !isnothing(UCC_selection)
            # The uccs from this years df 
            uccs         = unique(v_copy[!, :UCC])

            # The intersection of the uccs from this years df and the uccs from the selection
            intersection = intersect(UCC_selection, uccs)

            # Tell me the uccs that were in the ucc_selection, but not in the uccs from this years df
            survey_name = is_itbi ? "ITBI" : "MTBI"
            # println("These are the uccs that were not in the $survey_name:", setdiff(UCC_selection, uccs))
            
            @transform! v_copy @byrow :include_UCC = :UCC ∈ intersection;
            v_copy = v_copy[findall(v_copy[!,:include_UCC]), :];
        end

        # Aggregate at monthly frequency to remove duplicates
        transform!(v_copy, [ref_year, ref_month] => ByRow((year, month) -> Dates.lastdayofmonth(Date(year, month))) => :REF_DATE);
        
        v_grouped = combine(groupby(v_copy, [:CUSTOM_CUID, :REF_DATE, :UCC]), exp_col=>sum);
        # v_grouped = combine(groupby(v_copy, [:NEWID, :REF_DATE, :UCC]), exp_col=>sum);
        rename!(v_grouped, Dict(string.(exp_col) * "_sum" => "COST"));

        # Update output
        if k == 1
            output = copy(v_grouped);
        else
            append!(output, v_grouped);
        end
    end

    # Return output
    if quarterly_aggregation
        output = aggregate_to_quarterly!(output, is_itbi ? "itbi" : "mtbi");
    elseif annual_aggregation
        output = aggregate_to_annually!(output);
    end
    
    return output;
end

function aggregate_to_quarterly!(output, type)

    group_cols    = ["CUSTOM_CUID", "REF_DATE"]
    # group_cols    = ["NEWID", "REF_DATE"]


    # Ensure unqiueness 
    unique!(output, [:CUSTOM_CUID, :REF_DATE, :UCC]);
    # unique!(output, [:NEWID, :REF_DATE, :UCC]);

    # split output based on certain UCCs 
    local debt_df, wealth_cols
    if type == "mtbi"
        wealth_cols = ["6001", "6002"] # 6001 is second interview, 6002 is fifth interview #TODO: issue is a mode will be chosen, which will make 6001 and 6002 overlap on date 

        debt_df = filter(x -> (x.UCC ∈ wealth_cols), output)

        # drop wealth_cols from output
        @transform! output @byrow :do_not_include_UCC = :UCC ∉ wealth_cols;
        output = output[findall(output[!,:do_not_include_UCC]), :];

        filter!(x -> (x.UCC != "6001" || x.UCC != "6002"), output)
    elseif type == "itbi"
        wealth_cols = ["920010", "920020", "920030", "5100", "5800", "920040", "5400", "5500", "5600"] # 9200XX are only in the fifth interview, should be divided by 4 if used in the micro level 
                                                                                                       # 5100, 5800, 5400, 5500, 5600 are also only in the fifth int., should be multiplied by 4 if used in the macro level 
        debt_df = filter(x -> (x.UCC ∈ wealth_cols), output)

        # drop wealth_cols from output
        # filter!(x -> !(x.UCC ∈ wealth_cols), output)
        @transform! output @byrow :do_not_include_UCC = :UCC ∉ wealth_cols;
        output = output[findall(output[!,:do_not_include_UCC]), :];
    end

    # try 
    #     println("Wealth UCCs: ", wealth_cols)
    #     debt_df = filter(x -> (x.UCC ∈ wealth_cols), output)

    #     # drop wealth_cols from output
    #     filter!(x -> !(x.UCC ∈ wealth_cols), output)
    # catch ee
    #     println(ee)
    #     println("No debt UCCs")
    # end

    # Convert to wide format 
    quarterly_df       = unstack(output, group_cols, :UCC, :COST);
    cols               = setdiff(names(quarterly_df), group_cols)
    cols_expr          = [Symbol(col) =>sum for col in cols]
    
    #TODO: for some odd reason, the monthly numbers (MTBI, ITBI) are obtained by dividing the submitted values by 3. This is problematic if doing monthly analysis ... which we luckily dont do 
    #TODO: this means for the monthly numbers, we should actually sum. EVEN IF IT'S A STOCK VARIABLE LIKE DEBT. So weird 

    # Construct :REFMO from :REF_DATE
    transform!(quarterly_df, :REF_DATE => ByRow(x -> Dates.month(x)) => :REFMO);

    # Convert monthly reference periods to end of quarters
    transform!(quarterly_df, :REF_DATE => ByRow(x -> Dates.lastdayofquarter(x)), renamecols=false); #TODO: has a bug in what the last day is 

    quarterly_df[!, :REF_DATE] .= QuarterlyDate.(quarterly_df[!, :REF_DATE])

    # # Print the first five rows of the df
    # println(first(quarterly_df, 5))
    
    for c in cols 
        quarterly_df[!, c] = coalesce.(quarterly_df[:, c], 0)
    end
    # if type == "itbi"
    #     CSV.write("test0.csv", quarterly_df)
    # end

    # if type == "mtbi"
    #     CSV.write("test1.csv", quarterly_df)
    # end


    quarterly_df = combine(groupby(quarterly_df, [:CUSTOM_CUID, :REF_DATE]), cols_expr..., :REFMO=>(x -> length(unique(x))));
    # quarterly_df = combine(groupby(quarterly_df, [:NEWID]), cols_expr..., :REFMO=>(x -> length(unique(x)))); #TODO: for the sum to run smoothly, we need to zero things out, but the check later of 3 months prevents underestimated observations
    rename!(quarterly_df, Dict(:REFMO_function => "MONTHS_PER_REF_DATE"));

    # if type == "mtbi"
    #     CSV.write("test2.csv", quarterly_df)
    # end

    # Filter out incomplete quarters
    filter!(row -> (row.MONTHS_PER_REF_DATE == 3), quarterly_df); 
    select!(quarterly_df, Not(:MONTHS_PER_REF_DATE));

    # for debt_df, do the same process and then just merge outer 
    debt_df      = clean_debt_df(debt_df, group_cols, wealth_cols, type)

    if debt_df != DataFrame() 
        quarterly_df = outerjoin(quarterly_df, debt_df, on=["CUSTOM_CUID", "REF_DATE"], makeunique=true)
    end

    # if type == "mtbi"
    #     CSV.write("test3.csv", quarterly_df)
    # end

    return quarterly_df;
end


function clean_debt_df(debt_df, group_cols, wealth_cols, type)
    # Convert to wide format 
    quarterly_df       = unstack(debt_df, group_cols, :UCC, :COST);
    cols               = setdiff(names(quarterly_df), group_cols)
    wealth_cols_sum    = wealth_cols .* "_sum"
    
    # Construct :REFMO from :REF_DATE
    transform!(quarterly_df, :REF_DATE => ByRow(x -> Dates.month(x)) => :REFMO);

    # Convert monthly reference periods to end of quarters
    transform!(quarterly_df, :REF_DATE => ByRow(x -> Dates.lastdayofquarter(x)), renamecols=false);

    quarterly_df[!, :REF_DATE] .= QuarterlyDate.(quarterly_df[!, :REF_DATE])


    # Aggregate at quarterly frequency
    #TODO: the whole issue with use the custom_cuid, ref_date is with the ITBI file.
    # The ITBI file will have, for example, debt reported in February, but split that amount evenly over the past 3 months.
    # this will generate an amount for december, jan, and feb. Issue? This is over 2 ref-dates.
    # solution? Since the actual amount is reported in feb, we should change the reference date to that quarter containing february 

    # We take the mode. So if we have 3 months of data and 2 of those 3 are in Q4, we set ref date to Q4 

    # For the MTBI wealth, since they are from 2 separate interviews, the mode does not make sense. So we have to split them and then put them together 
    if type == "itbi"
        cols_expr          = [Symbol(col) =>sum for col in cols]

        for c in cols 
            quarterly_df[!, c] = coalesce.(quarterly_df[:, c], 0)
        end

        df             = select(quarterly_df, [:CUSTOM_CUID, :REF_DATE])
        latest_periods = combine(groupby(df, :CUSTOM_CUID), :REF_DATE => mode)  # Issue with this WAS: for some UCCs, you have different reference dates .e.g, debt was reported later vs. food 
        quarterly_df   = innerjoin(quarterly_df, latest_periods, on=[:CUSTOM_CUID])
    
        select!(quarterly_df, Not(:REF_DATE))
        rename!(quarterly_df, Dict(:REF_DATE_mode => :REF_DATE))
    
        quarterly_df = combine(groupby(quarterly_df, [:CUSTOM_CUID, :REF_DATE]), cols_expr..., :REFMO=>(x -> length(unique(x))));
        # quarterly_df = combine(groupby(quarterly_df, [:NEWID]), cols_expr..., :REFMO=>(x -> length(unique(x)))); #TODO: for the sum to run smoothly, we need to zero things out, but the check later of 3 months prevents underestimated observations
        rename!(quarterly_df, Dict(:REFMO_function => "MONTHS_PER_REF_DATE"));
        select!(quarterly_df, Not(:MONTHS_PER_REF_DATE));

    elseif type == "mtbi"
        # Split quarterly_df by 6001 and 6002
        df_container = []

        for (i,c) in enumerate(wealth_cols)

            if c ∈ names(quarterly_df)
                println(c)
                cols_expr    = [Symbol(c) =>sum]

                df = select(quarterly_df, [:CUSTOM_CUID, :REF_DATE, :REFMO, Symbol(c)])
                # Drop missing values (necessary because otherwise, we still have the same problem of overlapping dates)
                dropmissing!(df, [c])

                # Drop NaN 
                df = df[.!isnan.(df[!, c]), :]

                # Extract the mode now 
                latest_periods = combine(groupby(df, :CUSTOM_CUID), :REF_DATE => mode)  # Issue with this WAS: for some UCCs, you have different reference dates .e.g, debt was reported later vs. food
                df             = innerjoin(df, latest_periods, on=[:CUSTOM_CUID])
                
                select!(df, Not(:REF_DATE))
                rename!(df, Dict(:REF_DATE_mode => :REF_DATE))

                df = combine(groupby(df, [:CUSTOM_CUID, :REF_DATE]), cols_expr..., :REFMO=>(x -> length(unique(x))));
                # quarterly_df = combine(groupby(quarterly_df, [:NEWID]), cols_expr..., :REFMO=>(x -> length(unique(x)))); #TODO: for the sum to run smoothly, we need to zero things out, but the check later of 3 months prevents underestimated observations
                rename!(df, Dict(:REFMO_function => "MONTHS_PER_REF_DATE"));
                select!(df, Not(:MONTHS_PER_REF_DATE));
                select!(df, ["CUSTOM_CUID", "REF_DATE", c * "_sum"])
                
                push!(df_container, df)
            end
        end
        # append the two dataframes together
        quarterly_df = length(df_container) > 1 ? append!(df_container..., cols=:union) : length(df_container) == 0 ? DataFrame() : df_container[1]
        
        for c in setdiff(names(quarterly_df), ["CUSTOM_CUID", "REF_DATE"])
            quarterly_df[!, c] = coalesce.(quarterly_df[:, c], 0)
        end
    end

    return quarterly_df 
end


function aggregate_to_annually!(output)

    group_cols    = ["CUSTOM_CUID", "REF_DATE"]

    # Ensure unqiueness 
    unique!(output, [:CUSTOM_CUID, :REF_DATE, :UCC]);

    # Convert to wide format 
    annual_df     = unstack(output, group_cols, :UCC, :COST);
    sum_cols      = setdiff(names(annual_df), group_cols)
    sum_cols_expr = [Symbol(col) =>sum for col in sum_cols]


    # Construct :REFQ from :REF_DATE
    transform!(annual_df, :REF_DATE => ByRow(x -> Dates.quarter(x)) => :REFQ);

    # Convert quarterly reference periods to end of years
    transform!(annual_df, :REF_DATE => ByRow(x -> Dates.lastdayofyear(x)), renamecols=false); # => :REF_YEAR);

    # Aggregate at annual frequency
    annual_df = combine(groupby(annual_df, group_cols), sum_cols_expr..., :REFQ=>(x -> length(unique(x))));
    rename!(annual_df, Dict(:REFQ_function => "QUARTERS_PER_REF_DATE"));

    # Filter out incomplete years
    filter!(row -> row.QUARTERS_PER_REF_DATE == 4, annual_df);
    select!(annual_df, Not(:QUARTERS_PER_REF_DATE));
    
    # Return output
    return annual_df;
end


function aggregate_to_annually_all!(test, y)

    # Column groups 
    group_cols    = ["CUSTOM_CUID"]
    last_cols     = ["REF_DATE"]
    sum_cols      = setdiff(names(test), vcat(group_cols, last_cols))

    # Expressions 
    last_cols_expr = [Symbol(col) =>last for col in last_cols]
    sum_cols_expr  = [Symbol(col) =>sum for col in sum_cols]

    # Construct :REFQ from :REF_DATE
    transform!(test, :REF_DATE => ByRow(x -> Dates.quarter(x)) => :REFQ);

    # Convert quarterly reference periods to end of years, # Dates.lastdayofyear(x)
    transform!(test, :REF_DATE => ByRow(x -> Dates.lastdayofyear(Date(y))), renamecols=false); # => :REF_YEAR);

    # Aggregate at annual frequency
    annual_df = combine(groupby(test, group_cols), hcat(sum_cols_expr..., last_cols_expr...), :REFQ=>(x -> length(unique(x))));
    # rename!(annual_df, Dict(:REFQ_function => "QUARTERS_PER_REF_DATE"));

    # # Filter out incomplete years
    # a = filter(row -> row.QUARTERS_PER_REF_DATE == 4, annual_df);
    # b = filter(row -> row.QUARTERS_PER_REF_DATE != 4, annual_df);
    select!(annual_df, Not(:REFQ_function));
    rename!(annual_df, Dict(:REF_DATE_last => "REF_DATE"))
    
    new_names = [endswith(s, "_sum") ? replace(s, "_sum" => "") : s for s in names(annual_df)]
    rename!(annual_df, new_names)

    # Return output
    return annual_df;
end


# Extract columns from data 
function subset_data(data, cols)
    for k in keys(data)
        cols_to_keep = []
        for c in cols
            if c in names(data[k])
                push!(cols_to_keep, c)
            end
        end
        try 
            select!(data[k], cols_to_keep)
        catch e
            # for income 
            if k ∈ ["fmli_20042", "fmli_20043", "fmli_20044", "fmli_20051", "fmli_20052", "fmli_20053", "fmli_20054"]
                new_cols = filter(s -> s != "FINCBTAX", copy(cols))
                push!(new_cols, "FINCBTXM")

                # Double check that columns are there 
                new_cols = filter(s -> s ∈ names(data[k]), new_cols) 
                select!(data[k], new_cols)
                rename!(data[k], "FINCBTXM" => "FINCBTAX")  # for uniformity
                try 
                    data[k][!, "FINCBTAX"] = Float64.(data[k][!, "FINCBTAX"])
                catch e
                    data[k][!, "FINCBTAX"] = coalesce.(data[k][!, "FINCBTAX"], NaN)
                end
            else
                @info(e)
            end
        end

        # Convert columns to consistent types. Needed for merging across files 
        cons_cols = filter(col -> Symbol(col) ∉ [:NEWID, :QINTRVYR, :QINTRVMO], names(data[k]))

        # convert each column to Float64
        for c in cons_cols
            try 
                data[k][!, c] = coalesce.(Float64.(data[k][:, c]), NaN)
            catch e 
                data[k][!, c] = coalesce.(data[k][:, c], NaN)
            end
            # if eltype(data[k][!, c]) != Float64
        end
    end
    return data
end

function merge_fmli_files(fmli_files, mnemonics::Vector{String})

    # Convenient conversion
    mnemonics_sym = Symbol.(unique(vcat("QINTRVYR", "QINTRVMO", mnemonics)));
    
    # Memory pre-allocation for output
    output = DataFrame();

    # Loop over monthly tables
    for (k, v) in fmli_files
        println(k)

        # Select target variables
        selected_cols = filter(x -> x !== nothing, [col in names(v) ? col : nothing for col in mnemonics])
        v_selection   = copy(v[!, selected_cols]);
    
        for row in eachrow(v_selection)
            if row[:QINTRVYR] < 20 # YY rather than YYYY and referring to 20YY
                row[:QINTRVYR] += 2000;
            elseif 20 < row[:QINTRVYR] < 100 # YY rather than YYYY and referring to 19YY
                row[:QINTRVYR] += 1900;
            end
        end

        # Add :REF_DATE
        @transform! v_selection @byrow :REF_DATE = Dates.lastdayofmonth(Date(:QINTRVYR, :QINTRVMO));

        # Update output
        if size(output, 1) == 0
            output = v_selection;
        else
            append!(output, v_selection; cols=:union);
        end
    end

    # output[:, :MO_SCOPE] .= ifelse.(fmli_panel.QINTRVMO .== 1, 0,
    #                                ifelse.(fmli_panel.QINTRVMO .== 2, 1,
    #                                        ifelse.(fmli_panel.QINTRVMO .== 3, 2, 3)))

    return output;
end

#TODO: maybe shift one quarter back, and add the mo_scope? then aggregate? 
 

function aggregate_to_annually_fmil!(output)

    group_cols     = ["CUSTOM_CUID", "REF_DATE"]
    demo_cols      = ["FINLWT21", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE"]
    sum_cols       = setdiff(names(output), vcat(group_cols, demo_cols))
    sum_cols_expr  = [Symbol(col) => sum for col in sum_cols] #TODO: what about age? demographics? family? Take first I guess...
    demo_cols_expr = [Symbol(col) => last for col in demo_cols]
    expressions    = vcat(sum_cols_expr, demo_cols_expr)

    # Ensure unqiueness 
    unique!(output, [:CUSTOM_CUID, :REF_DATE]);

    # # Construct :REFQ from :REF_DATE
    transform!(annual_df, :REF_DATE => ByRow(x -> Dates.quarter(x)) => :REFQ);

    # # Reweight each column by MO_SCOPE
    # for col in sum_cols
    #     @transform! annual_df @byrow begin
    #         :$(Symbol(col)) = :$(Symbol(col)) * :MO_SCOPE
    #     end
    # end

    # Convert quarterly reference periods to end of years
    transform!(annual_df, :REF_DATE => ByRow(x -> Dates.lastdayofyear(x)), renamecols=false); # => :REF_YEAR);

    # Aggregate at annual frequency
    annual_df = combine(groupby(annual_df, group_cols), expressions..., :REFQ=>(x -> length(unique(x))));
    rename!(annual_df, Dict(:REFQ_function => "QUARTERS_PER_REF_DATE"));

    # Filter out incomplete years
    filter!(row -> row.QUARTERS_PER_REF_DATE == 4, annual_df);
    select!(annual_df, Not(:QUARTERS_PER_REF_DATE));
    
    # Return output
    return annual_df;
end


function retrieve_data(prefixes::Vector{String}, is_interview_survey::Bool, from_year::Int64, to_year::Int64; verbose::Bool=true)
    
    # Memory pre-allocation: output
    n_prefixes = length(prefixes);
    output     = Vector{Any}(undef, n_prefixes);    

    for t=from_year:to_year
        if verbose
            @info("Downloading survey referring to year $(t)");
        end
        download_folder = "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/CEX" #mktempdir(prefix="ce_pumd_", cleanup=true);
        survey_id       = get_csv_files(string(t), is_interview_survey, download_folder);
        new_entries     = csv_files_to_dataframes(survey_id, download_folder, prefixes);
        for i=1:n_prefixes
            if isassigned(new_entries, i)
                if isassigned(output, i)
                    merge!(output[i], new_entries[i])
                else
                    output[i] = new_entries[i];
                end
            end
        end
    end

    return output;
end

function get_csv_files(ref_year::String, is_interview_survey::Bool, download_folder::String)
    survey_id = ifelse(is_interview_survey, "intrvw$(ref_year[end-1:end])", "diary$(ref_year[end-1:end])");
    # Downloads.download() # ZipFile.download("https://www.bls.gov/cex/pumd/data/comma/$(survey_id).zip", "$(download_folder)/$(survey_id).zip");
    # run(`unzip -qq $(download_folder)/$(survey_id).zip -d $(download_folder)/`);
    return survey_id;
end

function csv_files_to_dataframes(survey_id::String, download_folder::String, prefixes::Vector{String}, additional_file=false)
    
    # Memory pre-allocation: sorting problem
    last = "";
    buffer = SortedDict{String, DataFrame}();

    # Memory pre-allocation: output
    output = Vector{SortedDict{String, DataFrame}}(undef, length(prefixes));    

    # Accounts for naming inconsistencies in the folders
    survey_path    = "$(download_folder)/$(survey_id)";
    local readdir_output
    try 
        readdir_output = sort(readdir(survey_path));

        if "$(survey_id)" ∈ readdir_output
            survey_path    = "$(download_folder)/$(survey_id)/$(survey_id)";
            readdir_output = sort(readdir(survey_path));
        end

        # Loop over the content in `readdir_output` and focus on the csv files
        for file_name_ext in readdir_output
            file_name   = split(file_name_ext, ".")[1];
            file_prefix = additional_file == true ? file_name[1:end-2] : file_name[1:end-3];

            # Proceed if `file_prefix` is in the target prefixes
            if !isnothing(findfirst(".", file_name_ext)) && (file_prefix ∈ prefixes) # this implicitly skips the tables ending with 'x'

                reduction = additional_file == true ? 1 : 2;
                if file_name[end-reduction] == '9'
                    new_key = "$(file_prefix)_19$(file_name[end-reduction:end])" 
                else
                    new_key = "$(file_prefix)_20$(file_name[end-reduction:end])"
                end

                # Store current csv file into a DataFrame
                new_SortedDict_item = CSV.read("$(survey_path)/$(file_name_ext)", missingstring=["", "."], DataFrame);
                
                # Include custom identifier for CUs
                if "NEWID" ∈ names(new_SortedDict_item)
                    new_SortedDict_item[!, :CUSTOM_CUID] = [parse(Int64, string(id)[1:end-1]) for id in new_SortedDict_item[!, :NEWID]];
                end
                
                # Generate `new_SortedDict_entry`
                new_SortedDict_entry = SortedDict(new_key => new_SortedDict_item);

                # Populate `buffer`
                if file_prefix == last
                    merge!(buffer, new_SortedDict_entry);
                
                # New iteration
                else
                    # Populate `output`
                    if length(buffer) > 0
                        coord_current_file = findfirst(last .== prefixes);
                        output[coord_current_file] = copy(buffer);
                        empty!(buffer);
                    end

                    # Re-initialise
                    merge!(buffer, new_SortedDict_entry);
                    last = String(file_prefix);
                end
            end
        

            if length(buffer) > 0
                coord_current_file         = findfirst(last .== prefixes);
                output[coord_current_file] = copy(buffer);
            end
        end

    catch ee
        println("No files found for survey $(survey_id)")
        @info(ee)
    end

    return output;
end


# Reading the mortgage data 
function import_specific_file(years, prefixes, verbose=true, additional_file=false)
    # Memory pre-allocation: output
    n_prefixes = length(prefixes);
    output     = Vector{Any}(undef, n_prefixes);    

    for t in years
        if verbose
            @info("Downloading additional file, referring to year $(t)");
        end
        download_folder = "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/CEX" #mktempdir(prefix="ce_pumd_", cleanup=true);
        ref_year        = string(t)
        survey_id       = "intrvw$(ref_year[end-1:end])" * "/expn$(ref_year[end-1:end])"
        new_entries     = csv_files_to_dataframes(survey_id, download_folder, prefixes, additional_file);

        # 
        for i=1:n_prefixes
            if isassigned(new_entries, i)
                if isassigned(output, i)
                    merge!(output[i], new_entries[i])
                else
                    output[i] = new_entries[i];
                end
            end
        end
    end

    return output;
end


function convert_year(year::String)
    if length(year) == 2
        return "19" * year
    else
        return year
    end
end

# Take this data and create a series of new dataframes 
# one dataframe for every two years 
# see how many CUSTOM_CUID are in there and drop the rest. 
function subset_to_fully_observed(data)
    new_data     = DataFrame()
    unique_years = unique(data.QINTRVYR)
    local data_y
    for (i,y) in enumerate(unique_years)
        if y <= 1981 || (y >= 1984 && y < 2022)
            data_y               = filter(row -> row.QINTRVYR == y || (row.QINTRVYR == unique_years[i+1] && row.QINTRVMO <= 3), data)
            count_by_id          = combine(groupby(data_y, :CUSTOM_CUID), :CUSTOM_CUID => length)
            count_by_id_filtered = filter(row -> row.CUSTOM_CUID_length >= 4, count_by_id)
            ids_to_include       = count_by_id_filtered.CUSTOM_CUID
            data_subset          = filter(row -> row.CUSTOM_CUID in ids_to_include, data_y)
            
            # For the years 1980, 1981 
            if y == 1980 || y == 1981
                data_subset[:, :MO_SCOPE]  .= ifelse.((data_subset.QINTRVMO .== 1) .&& (data_subset.INTNUM .< 5), 0,
                                                ifelse.((data_subset.QINTRVMO .== 2) .&& (data_subset.INTNUM .< 5), 1,
                                                    ifelse.((data_subset.QINTRVMO .== 3) .&& (data_subset.INTNUM .< 5), 2,
                                                        ifelse.((data_subset.QINTRVMO .> 3) .&& (data_subset.INTNUM .< 5), 3, 
                                                            ifelse.((data_subset.QINTRVMO .== 1) .&& (data_subset.INTNUM .== 5), 3,
                                                                ifelse.((data_subset.QINTRVMO .== 2) .&& (data_subset.INTNUM .== 5), 2,
                                                                    ifelse.((data_subset.QINTRVMO .== 3) .&& (data_subset.INTNUM .== 5), 1,0)))))))

                # Multiply all consumption columns by MO_SCOPE and drop MO_SCOPE 
                cons_cols =  ["FDHOMECQ", "FDAWAYCQ", "RENTEQVX", "UTILCQ", "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "RNTXRPCQ", "VEHINSCQ", "MAINRPCQ", "BBYDAYCQ", "ZCARTRKN", "ZCARTRKU", "ZCARTRKU1", "PARKING", "ZCARTRKN1"]
                for c in cons_cols
                    data_subset[!, c] = data_subset[!, c] .* data_subset[!, :MO_SCOPE] ./ 3 
                end

                # drop MO_SCOPE 
                select!(data_subset, Not(:MO_SCOPE))
            end

            # Separate out income, merge back later 
            income_df = select(data_subset, "CUSTOM_CUID", "REF_DATE", "FINCBTAX", "FINLWT21", "PERSLT18", "AGE_REF", "EDUC_REF", "FAM_SIZE", "VEHQ", "SEX_REF")    

            # Aggregate to annually here 
            select!(data_subset, Not(["QINTRVYR", "QINTRVMO", "NEWID", "INTNUM", "FINCBTAX", "FINLWT21", "PERSLT18", "AGE_REF", "EDUC_REF", "FAM_SIZE", "VEHQ", "SEX_REF"]))

            #TODO: for 1980,1981, correct for the fact that the dates cross 2 years 
            annual_df = aggregate_to_annually_all!(data_subset, y)

            # Merge back to income 
            last_data = leftjoin(income_df, annual_df, on=[:CUSTOM_CUID, :REF_DATE], makeunique=true)
            append!(new_data, last_data, promote=true)
        elseif y == 1982 || y == 2022
            nothing 
        end
    end

    # Finishing touches  
    new_data  = unique(new_data)
    select!(new_data, :REF_DATE, :CUSTOM_CUID,:)
    sort!(new_data, ["CUSTOM_CUID", "REF_DATE"])

    return new_data
end


function reduce_to_measures(final_df, path)
    """Reduce columns of final_df to just income and consumption."""
    
        # Replace missings with 0 
        cols_to_change = [:FINCBTAX, :FDHOMECQ, :FDAWAYCQ, :RENTEQVX, :UTILCQ, :HEALTHCQ, :GASMOCQ, :PUBTRACQ, :EDUCACQ, :RNTXRPCQ, :VEHINSCQ, :MAINRPCQ, :BBYDAYCQ, :ZCARTRKN, :ZCARTRKU, :PARKING, :TAXI_LIMO, :ZCARTRKU2, :ZCARTRKN2, :HOUSE_VAL, :PARKING_HOME, :PARKING_OUT]
        final_df[!, cols_to_change] = coalesce.(final_df[:, cols_to_change], 0)
    
        # Compute food 
        final_df[!, "food"]          = final_df[:, "FDHOMECQ"] + final_df[:, "FDAWAYCQ"]
        final_df[!, "tot_veh_price"] = final_df[:, "ZCARTRKU1"] + final_df[:, "ZCARTRKN1"] + final_df[:, "ZCARTRKU2"] + final_df[:, "ZCARTRKN2"] + final_df[:, "ZCARTRKU"] + final_df[:, "ZCARTRKN"]
        final_df[!, "parking"]       = final_df[!, "PARKING"] + final_df[!, "PARKING_HOME"] + final_df[!, "PARKING_OUT"] 
    
        name_dict       = Dict(
            "UTILCQ"   => "utilities",
            "HEALTHCQ" => "health",
            "FINCBTAX" => "income",
            "EDUCACQ"  => "eduexp",
            "RNTXRPCQ" => "rent",
            "VEHINSCQ" => "vehicleinsurance",
            "MAINRPCQ" => "vehiclerepairs",
            "BBYDAYCQ" => "childcare",
            "FINLWT21" => "weight",
            "AGE_REF"  => "age",
            "SEX_REF"  => "sex",
            "EDUC_REF" => "edu",
            "PERSLT18" => "children",
            "FAM_SIZE" => "famsize",
            "VEHQ"     => "vehicles_owned",
            "TAXI_LIMO" => "other_trans",
            "PUBTRACQ" => "pubtrans",
            "GASMOCQ"  => "gas",
            "RENTEQVX" => "house_renteq"
        ) 
        rename!(final_df, name_dict)
    
        # Define HH equivalence
        final_df[!, :adults]                = final_df[!, :famsize] - final_df[!, :children] 
        final_df[!, :adult_contribution]    = ifelse.(final_df.adults .<= 0, 0, ifelse.(final_df.adults .== 1, 1, (final_df.adults .- 1) .* 0.7 .+ 1))
        final_df[!, :children_contribution] = ifelse.(final_df.children .<= 0, 0, final_df.children .* 0.5)
        final_df[!, :hhequiv]               = final_df[!, :children_contribution] + final_df[!, :adult_contribution]
        final_df[!, :year]                  = Dates.year.(final_df[:, :REF_DATE])
    
        # Define consumption 
        cons_cols                           = [:food, :rent, :utilities, :health, :pubtrans, :eduexp, :childcare, :house_renteq]
        final_df[!, :consumption]           = sum(final_df[:, c] for c in cons_cols)
        final_df[!, :consumption_sq]        = final_df[!, :consumption].^2
    
        # Run year by year regressions for vehicle rental values 
        cons_cons2_sex_edu_income_famsize_age = sum(term.([:consumption, :consumption_sq, :sex, :edu, :income, :famsize, :age]))
        final_df[!, :veh_renteq]             .= 0 
    
        for y in unique(final_df[:, :year])
            data_y                                 = filter(x -> x.year == y, final_df)
            data_y                                 = data_y[.!ismissing.(data_y.tot_veh_price), :]  
            filter!(x -> x.tot_veh_price > 0, data_y)
            model                                  = lm(@formula(tot_veh_price ~ cons_cons2_sex_edu_income_famsize_age), data_y, wts=data_y[:, :weight]) 
            data_y[!, :veh_renteq]                 = predict(model)
    
            # Fill predictions into original df 
            final_df[final_df.year .== y, :veh_renteq]                         .= data_y[:, :veh_renteq]
            final_df[final_df.year .== y && final_df.veh_renteq .< 0, :veh_renteq] .= 0
        end
        annual_dep = 1/8  # 1/32 for quarterly 
        final_df[!, :consumption] = final_df[!, :consumption] + (final_df[!, :veh_renteq] * final_df[!, :vehicles_owned] * annual_dep) + final_df[!, :vehicleinsurance] + final_df[!, :vehiclerepairs] + final_df[!, :gas] + final_df[!, :parking]
        CSV.write(path * "/CEX.csv", select(data, :REF_DATE, :))

        return select(final_df, "consumption", "income", "hhequiv")
    end


# Take this data and create a series of new dataframes 
# one dataframe for every two years 
# see how many CUSTOM_CUID are in there and drop the rest. 
function subset_to_fully_observed(data)
    new_data     = DataFrame()
    unique_years = unique(data.QINTRVYR)
    local data_y
    for (i,y) in enumerate(unique_years)
        if y <= 1981 || (y >= 1984 && y < 2022)
            data_y               = filter(row -> row.QINTRVYR == y || (row.QINTRVYR == unique_years[i+1] && row.QINTRVMO <= 3), data)
            count_by_id          = combine(groupby(data_y, :CUSTOM_CUID), :CUSTOM_CUID => length)
            count_by_id_filtered = filter(row -> row.CUSTOM_CUID_length >= 4, count_by_id)
            ids_to_include       = count_by_id_filtered.CUSTOM_CUID
            data_subset          = filter(row -> row.CUSTOM_CUID in ids_to_include, data_y)
            
            # For the years 1980, 1981 
            if y == 1980 || y == 1981
                data_subset[:, :MO_SCOPE]  .= ifelse.((data_subset.QINTRVMO .== 1) .&& (data_subset.INTNUM .< 5), 0,
                                                ifelse.((data_subset.QINTRVMO .== 2) .&& (data_subset.INTNUM .< 5), 1,
                                                    ifelse.((data_subset.QINTRVMO .== 3) .&& (data_subset.INTNUM .< 5), 2,
                                                        ifelse.((data_subset.QINTRVMO .> 3) .&& (data_subset.INTNUM .< 5), 3, 
                                                            ifelse.((data_subset.QINTRVMO .== 1) .&& (data_subset.INTNUM .== 5), 3,
                                                                ifelse.((data_subset.QINTRVMO .== 2) .&& (data_subset.INTNUM .== 5), 2,
                                                                    ifelse.((data_subset.QINTRVMO .== 3) .&& (data_subset.INTNUM .== 5), 1,0)))))))

                # Multiply all consumption columns by MO_SCOPE and drop MO_SCOPE 
                cons_cols =  ["FDHOMECQ", "FDAWAYCQ", "RENTEQVX", "UTILCQ", "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "RNTXRPCQ", "VEHINSCQ", "MAINRPCQ", "BBYDAYCQ", "ZCARTRKN", "ZCARTRKU", "ZCARTRKU1", "PARKING", "ZCARTRKN1"]
                for c in cons_cols
                    data_subset[!, c] = data_subset[!, c] .* data_subset[!, :MO_SCOPE] ./ 3 
                end

                # drop MO_SCOPE 
                select!(data_subset, Not(:MO_SCOPE))
            end

            # Separate out income, merge back later 
            income_df = select(data_subset, "CUSTOM_CUID", "REF_DATE", "FINCBTAX", "FINLWT21", "PERSLT18", "AGE_REF", "EDUC_REF", "FAM_SIZE", "VEHQ", "SEX_REF")    

            # Aggregate to annually here 
            select!(data_subset, Not(["QINTRVYR", "QINTRVMO", "NEWID", "INTNUM", "FINCBTAX", "FINLWT21", "PERSLT18", "AGE_REF", "EDUC_REF", "FAM_SIZE", "VEHQ", "SEX_REF"]))

            #TODO: for 1980,1981, correct for the fact that the dates cross 2 years 
            annual_df = aggregate_to_annually_all!(data_subset, y)

            # Merge back to income 
            last_data = leftjoin(income_df, annual_df, on=[:CUSTOM_CUID, :REF_DATE], makeunique=true)
            append!(new_data, last_data, promote=true)
        elseif y == 1982 || y == 2022
            nothing 
        end
    end

    # Finishing touches  
    new_data  = unique(new_data)
    select!(new_data, :REF_DATE, :CUSTOM_CUID,:)
    sort!(new_data, ["CUSTOM_CUID", "REF_DATE"])

    return new_data
end


function reduce_to_measures(final_df, data_path)
    """Reduce columns of final_df to just income and consumption."""
    
    # Replace missings with 0 
    cols_to_change = [:FINCBTAX, :FDHOMECQ, :FDAWAYCQ, :RENTEQVX, :UTILCQ, :HEALTHCQ, :GASMOCQ, :PUBTRACQ, :EDUCACQ, :RNTXRPCQ, :VEHINSCQ, :MAINRPCQ, :BBYDAYCQ, :ZCARTRKN, :ZCARTRKU, :PARKING, :TAXI_LIMO, :ZCARTRKU2, :ZCARTRKN2, :HOUSE_VAL, :PARKING_HOME, :PARKING_OUT]
    final_df[!, cols_to_change] = coalesce.(final_df[:, cols_to_change], 0)

    # Compute food 
    final_df[!, "food"]          = final_df[:, "FDHOMECQ"] + final_df[:, "FDAWAYCQ"]
    final_df[!, "tot_veh_price"] = final_df[:, "ZCARTRKU1"] + final_df[:, "ZCARTRKN1"] + final_df[:, "ZCARTRKU2"] + final_df[:, "ZCARTRKN2"] + final_df[:, "ZCARTRKU"] + final_df[:, "ZCARTRKN"]
    final_df[!, "parking"]       = final_df[!, "PARKING"] + final_df[!, "PARKING_HOME"] + final_df[!, "PARKING_OUT"] 

    name_dict       = Dict(
        "UTILCQ"   => "utilities",
        "HEALTHCQ" => "health",
        "FINCBTAX" => "income",
        "EDUCACQ"  => "eduexp",
        "RNTXRPCQ" => "rent",
        "VEHINSCQ" => "vehicleinsurance",
        "MAINRPCQ" => "vehiclerepairs",
        "BBYDAYCQ" => "childcare",
        "FINLWT21" => "weight",
        "AGE_REF"  => "age",
        "SEX_REF"  => "sex",
        "EDUC_REF" => "edu",
        "PERSLT18" => "children",
        "FAM_SIZE" => "famsize",
        "VEHQ"     => "vehicles_owned",
        "TAXI_LIMO" => "other_trans",
        "PUBTRACQ" => "pubtrans",
        "GASMOCQ"  => "gas",
        "RENTEQVX" => "house_renteq"
    ) 
    rename!(final_df, name_dict)

    # Define HH equivalence
    final_df[!, :adults]                = final_df[!, :famsize] - final_df[!, :children] 
    final_df[!, :adult_contribution]    = ifelse.(final_df.adults .<= 0, 0, ifelse.(final_df.adults .== 1, 1, (final_df.adults .- 1) .* 0.7 .+ 1))
    final_df[!, :children_contribution] = ifelse.(final_df.children .<= 0, 0, final_df.children .* 0.5)
    final_df[!, :hhequiv]               = final_df[!, :children_contribution] + final_df[!, :adult_contribution]
    final_df[!, :year]                  = Dates.year.(final_df[:, :REF_DATE])

    # Define consumption 
    cons_cols                           = [:food, :rent, :utilities, :health, :pubtrans, :eduexp, :childcare, :house_renteq]
    final_df[!, :consumption]           = sum(final_df[:, c] for c in cons_cols)
    final_df[!, :consumption_sq]        = final_df[!, :consumption].^2

    # Run year by year regressions for vehicle rental values 
    cons_cons2_sex_edu_income_famsize_age = sum(term.([:consumption, :consumption_sq, :sex, :edu, :income, :famsize, :age]))
    final_df[!, :veh_renteq]             .= 0 

    for y in unique(final_df[:, :year])
        data_y                                 = filter(x -> x.year == y, final_df)
        data_y                                 = data_y[.!ismissing.(data_y.tot_veh_price), :]  
        filter!(x -> x.tot_veh_price > 0, data_y)
        model                                  = lm(@formula(tot_veh_price ~ cons_cons2_sex_edu_income_famsize_age), data_y, wts=data_y[:, :weight]) 
        data_y[!, :veh_renteq]                 = predict(model)

        # Fill predictions into original df 
        final_df[final_df.year .== y, :veh_renteq]                         .= data_y[:, :veh_renteq]
        final_df[final_df.year .== y && final_df.veh_renteq .< 0, :veh_renteq] .= 0
    end
    annual_dep = 1/8  # 1/32 for quarterly 
    final_df[!, :consumption] = final_df[!, :consumption] + (final_df[!, :veh_renteq] * final_df[!, :vehicles_owned] * annual_dep) + final_df[!, :vehicleinsurance] + final_df[!, :vehiclerepairs] + final_df[!, :gas] + final_df[!, :parking]
    CSV.write(data_path * "/CEX.csv", select(data, :REF_DATE, :))

    return select(final_df, "consumption", "income", "hhequiv")
end



function get_id_df(sep_dfs, k, id)
    return filter(x -> x.CUSTOM_CUID == id, sep_dfs[k])
end

function check_duplicality(sep_dfs)
    for (k,v) in sep_dfs
        println(k)
        println("Number of duplicates: ", sum(nonunique(v[:, ["CUSTOM_CUID", "REF_DATE"]])))
        println("Number of unique: ", nrow(unique(v[:, ["CUSTOM_CUID", "REF_DATE"]])))
        println("Number of rows: ", size(v, 1))
        println("Number of columns: ", size(v, 2))
    end 
end

function get_duplicates(sep_dfs, k)
    return sep_dfs[k][findall(nonunique(sep_dfs[k][:, ["CUSTOM_CUID", "REF_DATE"]])), :]
end
