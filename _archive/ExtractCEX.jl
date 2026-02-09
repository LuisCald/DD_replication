cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
# include("import_CEX.jl")
using Pkg 
Pkg.activate("CEX")
# using CeMicrodata 
using GLM
using CSV
using Dates
using DataFrames
using PeriodicalDates
using Statistics
using StatsBase 
using DataFramesMeta
using DataStructures, DelimitedFiles, Downloads, Logging, Statistics;
include("CEXFunctions.jl")

# TODO: fix this columns thing 

# These refer to certain variables, see here: https://www.bls.gov/cex/pumd-getting-started-guide.htm
IS_prefixes = ["mtbi", "fmli", "itbi"];  # interview, good for everything # DS_prefixes =["expd", "fmld"];  # diary, for 2-week sequence, good for frequent purchases 

# FINCBTAX = last 12 months (current)
# RENTEQVX = current 
# "SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX" = last month 
# STOCKX = current 
# OTHLONX = current 
# OTHASTX = current 

# The 44 replicate weights 
weight_variables1 = ["WTREP0" * "$i" for i in 1:9] # 1990Q1 on 
weight_variables2 = ["WTREP" * "$i" for i in 10:44]

weight_variables3 = ["FINLWT0" * "$i" for i in 1:9] # 1984Q1 - 1989Q4 + 1980Q1 - 1981Q4
weight_variables4 = ["FINLWT" * "$i" for i in 10:44]

# Combine 1 and 2
weight_variables_rest   = vcat(weight_variables1, weight_variables2)
weight_variables80s     = vcat(weight_variables3, weight_variables4)

# From the last set, remove FINLWT21, which is the final weight
weight_variables80s = filter(x -> x != "FINLWT21", weight_variables80s)

# FMLI 
fmli_cols   = Dict(
    "IS_80s"       => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "RENTEQVX", "SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX", weight_variables80s...], # "FDHOMECQ", "FDAWAYCQ", "UTILCQ",   "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "NUM_AUTO"], # RNTXRPCQ, VEHINSCQ, MAINRPCQ, BBYDAYCQ given by  MTBI, , 
    "IS_90s_early" => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "RENTEQVX", "SIMHOUSX", "SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX", weight_variables_rest...], # "FDHOMECQ", "FDAWAYCQ", "UTILCQ",   "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "VEHQ"], # RNTXRPCQ, VEHINSCQ, MAINRPCQ, BBYDAYCQ given by MTBI --- rental eq. ends in 93q4, , "SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX"
    "IS_rest"      => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "RENTEQVX", "SAVACCTX", "CKBKACTX", "SECESTX", "STOCKX", "USBNDX", "CREDITX", "STUDNTX", "OTHLONX", "OTHASTX", "LIQUIDX", weight_variables_rest...], #"FDHOMECQ", "FDAWAYCQ", "UTILCQ",   "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "RNTXRPCQ", "VEHINSCQ" , "MAINRPCQ", "BBYDAYCQ", "VEHQ"], # RENTEQVX starts in 1995q1, , 
    "IS_80s_late"  => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "SIMHOUSX", "ZFOODHOM", "ZFOODAWY", "RENTEQVX", "ZUTILSPS", "ZHEALTH", "ZGASMOTO", "ZPUBTRAN", "ZEDUCATN", "ZRENTXRP", "ZRENTRAP", "ZVEHCINS", "ZMAINREP", "ZBABYDAY", "ZCARTRKN", "ZCARTRKU", "VEHQ", "SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX", weight_variables80s...], # has everything , 
)

fmli_names_dict = Dict(
    "ZFOODHOM" => "FDHOMECQ",
    "ZFOODAWY" => "FDAWAYCQ", 
    "ZUTILSPS" => "UTILCQ",
    "ZHEALTH" => "HEALTHCQ",  
    "ZGASMOTO" => "GASMOCQ", 
    "ZPUBTRAN" => "PUBTRACQ",
    "ZEDUCATN" => "EDUCACQ",
    "ZRENTXRP" => "RNTXRPCQ",
    "ZRENTRAP" => "RNTXRPCQ_1",
    "ZVEHCINS" => "VEHINSCQ", 
    "ZBABYDAY" => "BBYDAYCQ", 
    "ZMAINREP" => "MAINRPCQ"
)

# MTBI 
food            = ["190904", "790220", "190901", "190902", "190903", "790410", "790430", "200900", "790330", "790420", "800700", "790230", "790240"]
rent            = ["210110", "800710"]
utilities       = ["250111", "250112", "250113", "250114", "250211", "250212", "250213", "250214", "250221", "250222", "250223",  "250224", "250901", "250902", "250903", "250904", "250911", "250912", "250913", "250914", "260111", "260112", "260113", "260114", "260211", "260212",  "260213", "260214", "270211", "270212", "270213", "270214", "270310", "270411", "270412", "270413", "270414","270101", "270102", "270104", "270105", "270310", "270311", "690116", "270901", "270902", "270903", "270904"]
health          = ["570110", "570111", "570210", "570220", "570230", "560110", "560210", "560310", "560330", "560400", "340906", "540000", "550110", "550320", "550330", "550340", "570901", "570903", "570240", "580110", "580111",  "580112", "580113", "580114", "580311", "580312", "580901", "580903", "580904", "580905", "580906", "580400", "580907"] # 550110 - non PSID 
pubtrans        = ["520531", "520532", "530311", "530312", "530501", "530902", "530210", "530411", "530412", "520511", "520512", "520521", "520522", "520542", "520902", "520903", "520904", "520905", "520906", "520907", "530110", "530901", "520110", "520310"]
eduexp          = ["210310", "370903", "390901", "660110", "660210", "660310", "660900", "670110", "670210", "670901", "670902", "800802", "800804", "690111", "690112", "660410", "660902", "670410", "670903", "690114", "690310"]
childcare       = ["340210", "340211", "340212", "670310", "660901"]
house_rental_eq = ["910050"] # estimated monthly rental equivalence of owned home
mv_home         = ["800721"] # value is divided by 3
gas_repairs     = ["470111", "470112", "470113", "470220", "470211", "470212", "480110", "480212", "480213", "480214", "490110", "490211", "490212", "490221", "490231", "490232", "490311", "490312", "490313", "490314", "490318", "490319", "490411", "490412", "490413", "490501", "490502", "490900", "520410", "480215", "620113"]
undebt1         = ["6001", "6002"] # from MTBI: debt to creditors (1990-2013), 6001 and 6002 never overlap 

cat_in_str_mtbi = ["food", "rent", "utilities", "health", "pubtrans", "eduexp", "childcare", "house_rental_eq", "mv_home", "gas_repairs", "undebt1"]
mtbi_labels     = [food, rent, utilities, health, pubtrans, eduexp, childcare, house_rental_eq, mv_home, gas_repairs, undebt1]
mtbi_cols       = vcat(mtbi_labels...)
mtbi_names_dict = Dict("500110" => "VEHINSCQ1", "450110" => "ZCARTRKN1", "450210" => "ZCARTRKN2", "460110" => "ZCARTRKU1", "460901" => "ZCARTRKU2",)

# ITBI  
liquid          = ["920010", "920020", "920030", "5100"] # from ITBI: savings, checkings, bonds (before 2013), checkings - savings - money market - CDs (2013 -)
finassets       = ["5800", "920040"] # From itbi: Value of stocks - bonds - mutual funds (post 2013), value of all securities (before 2013)
undebt2         = ["5400", "5500", "5600"] # from ITBI: cc debt, student loans, other loans (2013-)

cat_in_str_itbi = ["liquid", "finassets", "undebt2"]
itbi_labels     = [liquid, finassets, undebt2]
itbi_cols       = vcat(itbi_labels...)
itbi_names_dict = Dict()


# Adding remaining entries to the dictionary 
for (j,c) in enumerate(mtbi_labels)
    for (i,n) in enumerate(c)
        mtbi_names_dict[n] = cat_in_str_mtbi[j] * string(i)
    end
end

# Adding remaining entries to the dictionary 
for (j,c) in enumerate(itbi_labels)
    for (i,n) in enumerate(c)
        itbi_names_dict[n] = cat_in_str_itbi[j] * string(i)
    end
end

# Import the main data
data_path    = "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing"  
mtbi_data, fmli_data, itbi_data    = clean_cex_all(IS_prefixes, [1980, 1981, 1984:1989..., 1990:2021...], key_selector, fmli_cols, mtbi_cols, itbi_cols, fmli_names_dict, mtbi_names_dict, itbi_names_dict, data_path)  #1980 is retrieved in the code

# fmli_data = CSV.read(data_path * "/fmli_processed.csv", DataFrame)
# mtbi_data = CSV.read(data_path * "/mtbi_processed.csv", DataFrame)
# itbi_data = CSV.read(data_path * "/itbi_processed.csv", DataFrame)

# for obj in [fmli_data, mtbi_data, itbi_data]
#     obj[!, "REF_DATE"] = QuarterlyDate.(obj[!, "REF_DATE"])
#     unique!(obj)
# end

# From the FMLI, extract wealth columns
# wealth_df = fmli_data[:, ["CUSTOM_CUID", "REF_DATE", "QINTRVMO", "SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX"]]
# select!(fmli_data, Not(["SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX"]))

# # shift the ref date 1 quarter if the qintrvmo == 1, 4, 7, 10
# condition = (wealth_df[!, "QINTRVMO"] .== 1) .| (wealth_df[!, "QINTRVMO"] .== 4) .| (wealth_df[!, "QINTRVMO"] .== 7) .| (wealth_df[!, "QINTRVMO"] .== 10)
# wealth_df[!, "REF_DATE"] .= ifelse.(condition, wealth_df[!, "REF_DATE"] .- Quarter(1), wealth_df[!, "REF_DATE"])
# select!(wealth_df, Not(["QINTRVMO"]))

# # Drop rows where all wealth columns are missing
# wealth_df = dropmissing(wealth_df, ["SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX"])

# # Merge the wealth columns to the main data
# fmli_data = outerjoin(fmli_data, wealth_df, on=[:CUSTOM_CUID, :REF_DATE], makeunique=true)
# fmli_data = combine(groupby(fmli_data, [:REF_DATE, :CUSTOM_CUID]), names(fmli_data, Not([:REF_DATE, :CUSTOM_CUID])) .=> sum)

# # For each column that ends in "_sum", remove the "_sum" 
# for c in names(fmli_data)
#     if occursin(r"_sum$", c)
#         rename!(fmli_data, c => replace(c, r"_sum$" => ""))
#     end
# end



mtbi_data = further_processing!(mtbi_data, cat_in_str_mtbi)
itbi_data = further_processing!(itbi_data, cat_in_str_itbi)


# Import separate files 
sep_files_cols = Dict(
    "mor" => ["QYEAR", "CUSTOM_CUID", "NEWID", "QBLNCM1X", "QBLNCM2X", "QBLNCM3X", "REC_ORIG"], 
    "fn2" => ["CREDITX1", "QYEAR", "CUSTOM_CUID", "NEWID", "REC_ORIG"],
    "fna" => ["CREDITX5", "QYEAR", "CUSTOM_CUID", "NEWID", "REC_ORIG"],
    "oph" => ["QYEAR", "CUSTOM_CUID", "NEWID", "PRINAMTX", "REC_ORIG"],
    "ovb" => ["QYEAR", "CUSTOM_CUID", "NEWID", "QBALNM1X", "QBALNM2X", "QBALNM3X", "REC_ORIG"],
    "hel" => ["QYEAR", "CUSTOM_CUID", "NEWID", "QBLNCM1G", "QBLNCM2G", "QBLNCM3G", "REC_ORIG"],
    # "veq" => ["QYEAR", "CUSTOM_CUID", "NEWID", "VOPEXPX", "VOPMOA"],
    # "vlr" => ["QYEAR", "CUSTOM_CUID", "NEWID", "VOPREGX", "VOPMO_C"],
    )

sep_files_yrs = Dict(
    "mor" => [1994:2021...], 
    "fn2" => [1994:2013...],
    "fna" => [1994:2013...],
    "oph" => [1994:2005...],
    "ovb" => [1994:2021...],
    "hel" => [1994:2021...],
    )

sep_dfs = import_additional_files(sep_files_cols, sep_files_yrs)
# check_duplicality(sep_dfs)
# get_duplicates(sep_dfs, "mor")
# get_id_df(sep_dfs, "mor", 65891)



sep_files_cols = Dict(
    "oph" => ["QYEAR", "CUSTOM_CUID", "NEWID", "TOTOWED", "REC_ORIG"]
    )

sep_files_yrs = Dict(
    "oph" => [2006:2021...],
    )

sep_dfs2 = import_additional_files(sep_files_cols, sep_files_yrs)


for dict_obj in [sep_dfs, sep_dfs2]
    for k in collect(keys(dict_obj))
        dict_obj[k][!, "REF_DATE"] = QuarterlyDate.(dict_obj[k][!, "REF_DATE"])
        unique!(dict_obj[k])
    end
end


# Merge MTBI to FMLI. Outer because they eat contain information that can be used separately 
outer_data = outerjoin(fmli_data, mtbi_data, on=[:CUSTOM_CUID, :REF_DATE], makeunique=true, indicator=:source)  # the outer join was so that for dates that didnt merge, we can still use them, but with the weights of the previous quarter
outer_data[!, "REF_DATE"] = QuarterlyDate.(outer_data[!, "REF_DATE"])

# Merge the ITBI file   
outer_data2   = outerjoin(outer_data, itbi_data, on=[:CUSTOM_CUID, :REF_DATE], makeunique=true, indicator=:source2)
outer_data2[!, "REF_DATE"] = QuarterlyDate.(outer_data2[!, "REF_DATE"])

# Merge the other files
for dict_obj in [sep_dfs, sep_dfs2]
    for k in collect(keys(dict_obj))
        outer_data2 = outerjoin(outer_data2, dict_obj[k], on=[:CUSTOM_CUID, :REF_DATE], makeunique=true, indicator="source_$k")
        outer_data2[!, "REF_DATE"] = QuarterlyDate.(outer_data2[!, "REF_DATE"])
    end
end

# Drop all source columns
for c in names(outer_data2)
    if occursin(r"source", c)
        select!(outer_data2, Not([c]))
    end
end

# For some reason, in the outer join, the merge is not clean although it should be. The following fixes this 
# First, coalesce 
for c in names(outer_data2)
    outer_data2[!, c] = coalesce.(outer_data2[!, c], NaN)
end
outer_data2 = combine(groupby(outer_data2, [:CUSTOM_CUID, :REF_DATE]), names(outer_data2, Not([:REF_DATE, :CUSTOM_CUID])) .=> nan_max)  # TODO: only works with non-missing data

# Rename columns that have nan_max
for c in names(outer_data2)
    if occursin(r"nan_max", c)
        rename!(outer_data2, c => replace(c, r"_nan_max$" => ""))
    end
end


# Export the clean df 
CSV.write(data_path * "/CEX_processed.csv", outer_data2)
















# Aggregate to annual 
# How is the weight aggregated? Multiply before? I guess if they are frequency weights, the weights must sum to the US population at the time 

# Explanation for dates between Interview and MTBI  
## so I merge on ref_date. What does this mean?
## for the MTBI columns, they refer to the date of the transaction and since it's monthly, we just aggregate to the quarter. Done. 
## For the IS columns, the REF_DATE refers to when the interview took place. 
## However, the interview is on the past 3 months, excluding the interview month 
## this implies that the MTBI data is ahead of the interview data, even tho they may coincide on the same date 
## e.g., Q4 transactions from MTBI are in Q4, while for IS, it can be completely in Q3, assuming the interview was in october 
## How do we deal with this? 
## First, we should definitely export 2 separate datasets for now.
## Second, how much do we depend on the MTBI in terms of totals? We should aggregate across columns to see 
## What are the date0 bounds for the interviews?
    ## I can interview in January 2020, April, July, October -> Data reflects October 2019 - September 2020
    ## I can interview in March 2020, June, September, December -> Data reflects December 2019 - November 2020
    ## Bounds = 2020Q3?
    ## Since I would detrend and what not, seasonality would not be an issue and I can just shift this up a quarter ... 
# In terms of dealing with income, I think we should extract it, deal with it separately because it gives us annual income on 
# a quarterly basis, so this is what we do (the income is from the FMLI btw):
## (1) we separate them. make the dataset quarterly 
## (2) we merge it with the other dataset, which is q4 data. Everything else is missing 
## (3) In the model code, it must reflect this somehow

# Issue: NEWID seems to repeat down the line. This means we have treat each year separately, 
# but each family goes into the next year as well. So we gotta aggregate one year every two years .... 

# TODO: ok, so we will need to do scope actually ... since by simply backtracking the quarter will eliminate the expenses entirely. 
# TODO: before merging to MTBI, we must make scope adjustments for the fmli data. 
# TODO: new idea: I only take observations that appear in 5 interviews 

# with UCC names attached, for reference  
# cols_80s_MTBI = [rent 210110,  veh ins 500110, home ins 220121, veh rep 490110, 490211, 490212, 490220, 490231, 490232, 490311, 490312, 490313, 490314, 490315, 490411, 490412, 490413, 490900, 490318, 490319, 
# 470220, 480110, 480211, 490500, parking 520530, taxi 530411, child 340210, home value 800721]
# cols_90s_early_MTBI = [house value 800721, rent 210110, veh ins 500110, home ins 220121, repairs "490110", "490211", "490212", "490220", "490231", "490232", "490311", "490312", "490313", "490314", "490315", "490411", "490412", "490413", "490900", "490318", "490319", "470220", "480110", "480211", "490500",
# parking 520530, 520531, 520532, taxi 530411, 530411, child 340210]
# cols_90s_late_MTBI  = [house value 800721, home ins 220121, parking 520530, 520531, 520532, taxi 530411, 530411]









# fmli_panel[:, :MO_SCOPE] .= ifelse.(fmli_panel.QINTRVMO .== 1, 0,
#                                    ifelse.(fmli_panel.QINTRVMO .== 2, 1,
#                                            ifelse.(fmli_panel.QINTRVMO .== 3, 2, 3)))



# fmli_panel[!, "food"] = fmli_panel[:, "FDHOMECQ"] + fmli_panel[:, "FDAWAYCQ"]

# sum_values = sum(ifelse.(year.(fmli_panel[!, "Q_DATE"]) .== 2001 .&& quarterofyear.(fmli_panel[!, "Q_DATE"]) .== 4, fmli_panel[!, "food"], 0))
# pop_sum_values = sum(ifelse.(year.(fmli_panel[!, "Q_DATE"]) .== 2001, fmli_panel[!, "denom"], 0))
# fmli_panel[!, "denom"] = (fmli_panel[!, "FINLWT21"] ./ 4) .* fmli_panel[:, :MO_SCOPE] ./ 3



#TODO: Compute the vehicle rental equivalence by fitting a simple linear regression model
# model = lm(@formula(y ~ x), fmli_panel)
# fit OLS model
# model = lm(@formula(y ~ x1 + x2 + x3 + x4), df)

# # predict values
# predicted = predict(model)

# # add predicted values as a new column to the data frame
# df[!, :VEH_CONS] = predicted


#TODO: Define total consumption by renaming columns, merge FMLI and MTBI on year date 
#TODO: in the MTBI, the data is designed so weird. It's family-UCC level. I'd like to convert this to family-time level and UCC as columns
#TODO: there is some concern that not all households finish the surveys unfortunately. Lets see how much we get 


# By now, we should have 6 groups, with 2 things in them, the mtbi stuff and the fmli stuff 
# 'QINTRVYR' identifies the year of interview 
# 'QINTRVMO' identifies the month of interview 
# THIS DIFERS from the REFERENCE month/year 
# Due to this conceptual difference, we have the concept of scope, which tells us how many months of the quarter refer to the year of the interview
# For March, it would be 2, since December falls outside, in the previous year --- it is outside the scope 
# Anyway 

# In the FMLI, besides perhaps 'income', everything else is on a quarterly level 
# We can then put them together, mergingin on 'NEWID'
# We also get population weights, 'FINLWT21', for the data. 
# They are at the quarterly level, since each quarter is treated independently.
# I'm not sure if I Divide the weights by 4 to get quarterly weights 

###################################################################################################

# Creating large dictionary, broken into segments based on whether measures are missing or not 
# CEX_dict    = Dict(
#     "IS_80s"       => retrieve_data(IS_prefixes, true, 1980, 1981), 
    # "IS_80s_late"  => retrieve_data(IS_prefixes, true, 1984, 1989), 
    # "IS_90s_early" => retrieve_data(IS_prefixes, true, 1990, 1993), 
    # "IS_90s_late"  => retrieve_data(IS_prefixes, true, 1994, 1999), 
    # "IS_00s"       => retrieve_data(IS_prefixes, true, 2000, 2009), 
    # "IS_10s"       => retrieve_data(IS_prefixes, true, 2010, 2021)
    # )

    # fmli_cols   = Dict(
    #     "IS_80s"       => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "FDHOMECQ", "FDAWAYCQ", "RENTEQVX", "UTILCQ", "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ"],
    #     "IS_80s_late"  => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "ZFOODHOM", "ZFOODAWY", "RENTEQVX", "ZRENTXRP", "ZMREPINS", "ZVEHCINS", "ZUTILSPS", "ZHEALTH", "ZMAINREP", "ZGASMOTO", "ZPUBTRAN", "ZEDUCATN", "ZBABYDAY"],
    #     "IS_90s_early" => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "FDHOMECQ", "FDAWAYCQ", "UTILCQ", "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ"],
    #     "IS_rest"      => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "FDHOMECQ", "FDAWAYCQ", "RNTXRPCQ", "VEHINSCQ", "UTILCQ", "HEALTHCQ", "MAINRPCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "BBYDAYCQ"],
    # )
    
    # mtbi_cols   = Dict(
    #     "IS_80s"       => ["210110", "500110", "220121", "490110", "490211", "490212", "490220", "490231", "490232", "490311", "490312", "490313", "490314", "490315", "490411", "490412", "490413", "490900", "490318", "490319", "470220", "480110", "480211", "490500", "520530", "530411", "340210", "800721"],
    #     "IS_80s_late"  => [],
    #     "IS_90s_early" => ["800721", "210110", "500110", "220121", "490110", "490211", "490212", "490220", "490231", "490232", "490311", "490312", "490313", "490314", "490315", "490411", "490412", "490413", "490900", "490318", "490319", "470220", "480110", "480211", "490500", "520530", "520531", "520532", "530411", "530411", "340210"],
    #     "IS_rest"      => ["800721", "220121", "520530", "520531", "520532", "530411", "530411"],
    # )

# First thing to know is that the CEX consists of 2 surveys: The IS and DS 
# The IS is a quarterly interview, covers questions on infrequently bought things 
# The DS is a bi-weekly interview, covers questions on frequently bought things  
# Their samples are independent 

# Data users need data from two subsequent years to calculate calendar year estimates because in the Interview Survey, 
# users report expenditures for the three months prior to the interview.

# However, they may include overlapping information. The DS data can be aggregated, and since 
# it is independent of the IS, they can be merged. 

### IS 
# itbi = Income  
# mtbi = Monthly expenditures
# fmli = CU level income, assets, and liabilities

## Expenditures
# total existing vehicles = owned + leased 
    # owned  = VEHQ (1984 on), VEHQ (1980, 1981 from Diary)
    # leased = 
# purchase price of vehicle = ?   # other file: OVB file, NETPURX (1980, 1994 on) (net purchase price)
# spending on new and used cars = (ZCARTRKN, ZCARTRKU 1984-1989)
    # 450110	New cars (1980, 1981, 1990q2-)   MTBI
    # 450210	New trucks (1980, 1981, 1990q2-)   MTBI
    # 450220	New motorcycles (1980, 1981, 1990q2-)   MTBI
    # 460110	Used cars
    # 460901	Used trucks
    # 460902	Used motorcycles
    
# age = AGE_REF (1980, 1981, 1984 on)
# sex = SEX_REF (1980, 1981, 1984 on)
# edu = EDUC_REF (1980, 1981, 1984 on)
# income = FINCBTAX (1980, 1981, 1984 on)
# children = PERSLT18 (1980, 1981, 1984 on)
# family size = FAM_SIZE (1980, 1981, 1984 on)

# for child and repairs, check 1993

# food at home      = ZFOODHOM (1984-1989), FDHOMECQ (1980-1981, 1990-)
# food away         = ZFOODAWY (1984-1989), FDAWAYCQ (1980-1981, 1990-)
# house rent eq.    = RENTEQVX (1980-1981, 1984-1993, 1995-) (self reported) 
# house rent eq. #2 = SIMHOUSX (1984-1993) 
# house rent eq. #3 = 910050 (1980-1981, 1990-) MTBI + ITBI 
# rent as pay       = ZRENTRAP (1984-1989), RNTAPYCQ (1994-) --- MTBI 800710 
# actual rent       = ZRENTXRP (1984-1989), RNTXRPCQ (1994-) --- MTBI 210110 (1980,1981,1990q2-)
# rent + other rent = ZRENTDWL (1984-1989)
# utilities         = UTILCQ (1980-1981, 1990-), ZUTILSPS (1984-1989)
# vehicle insurance = ZVEHCINS (1984-1989), VEHINSCQ (1994-) 
    # 500110 (1980, 1981, 1990q2-)   MTBI 
    # insurance + maintenance on lease (1991, 2013) for cars, for vans 450311

# home market value = 800721 (1980-1981q4, 1990q2-) MTBI 
# home insurance    = ZMREPINS (1984-1989) (this measure however is maintenance, repairs, insurance and other so I have to subtract maintenance), 
                       # 220121, 220122 (1980, 1981, 1990q2-)
# health exp. = HEALTHCQ (1980-1981, 1990-), ZHEALTH (1984-1989)  (insurance, services, drugs, supplements)
# vehicles 
    # repairs and maintenance
        # ZMAINREP (1984-1989), MAINRPCQ (1994-)
        # For 1980-1981, 1990-1993
            ## 490110: Body work and painting (1980-1981, 1990q2-) --- MTBI
            ## 490211: Clutch, transmission repair (1980-1981, 1990q2-2013q1) --- MTBI
            ## 490212: Drive shaft and rear-end repair (1980-1981, 1990q2-2013q1) --- MTBI
            ## 490220: Brake work (old) (1980-1981, 1990q1-1995q4) --- MTBI
            ## 490231: Repair to steering or front-end (1980-1981, 1990q2-2013q1) --- MTBI
            ## 490232: Repair to engine cooling system (1980-1981, 1990q2-2013q1) --- MTBI
            ## 490311: Motor tune-up (1980-1981, 1990q2-) --- MTBI
            ## 490312: Lube, oil change, and oil filters (1980-1981, 1990q2-) --- MTBI
            ## 490313: Front-end alignment, wheel balance and rotation (1980-1981, 1990q1-) --- MTBI
            ## 490314: Shock absorber replacement (1980-1981, 1990q2-) --- MTBI
            ## 490315: Brake adjustment (old) 
            ## 490411: Exhaust system repair (1980-1981, 1990q2-2013q1) --- MTBI
            ## 490412: Electrical system repair (1980-1981, 1990q2-) --- MTBI
            ## 490413: Motor repair, replacement (1980-1981, 1990q2-) --- MTBI
            ## 490900: Auto repair service policy (1980-1981, 1990q2-) --- MTBI
            ## 490318: Repair tires and other repair work (1980-1981, 1990q2-) --- MTBI
            ## 490319: Vehicle air conditioning repair (#TODO: only from 93!)
            ## 470220: Coolant, brake fluid, transmission fluid, and other additives (1980-1981, 1990q2-) --- MTBI
            ## 480110: Tires - purchased, replaced, installed (1980-1981, 1990q2-) --- MTBI
            ## 480211: PARTS/EQUIP/ACCESSORIES (1980-1981, 1990q1-1995q4) --- MTBI
            ## 490500, 490501: VEHICLE ACCESSORIES INCL. LABOR (audio equipment) (1980-1981, 1991q1-1994q4, 490501 for 1994q1-2005q1) --- MTBI
            # 470211, 470212: motor oil already included in gas 
            
    # gas                     = GASMOCQ (1980-1981, 1990-), ZGASMOTO (1984-1989)
    # public trans            = ZPUBTRAN (1984-1989), PUBTRACQ (1980-1981, 1990-)
    # parking                 = 520530 (1980-1981, 1990q1-1991q4, ), 520531 + 520532 (1991q4-) (missing for 1984-1989)
    # taxi                    = 530411 + 530411 (1980-1981, 1990q2-) (missing for 1984-1989)
# education         = ZEDUCATN (1984-1989), EDUCACQ (1980-1981, 1990-)
# child care        = ZBABYDAY (1984-1989), BBYDAYCQ (1994-), 340210 (1980-1981q4, 1990q1-1993q4)
