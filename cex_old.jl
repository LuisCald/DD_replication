cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
# include("import_CEX.jl")
using Pkg 
Pkg.activate("CEX")
# using CeMicrodata 
using GLM
using CSV
using Dates
using PeriodicalDates
using DataFrames
using Statistics
using DataFramesMeta
using DataStructures, DelimitedFiles, Downloads, Logging, Statistics;
include("CEXConsumption.jl")

# These refer to certain variables, see here: https://www.bls.gov/cex/pumd-getting-started-guide.htm
IS_prefixes = ["mtbi", "fmli"];  # interview, good for everything # DS_prefixes =["expd", "fmld"];  # diary, for 2-week sequence, good for frequent purchases 

fmli_cols   = Dict(
    "IS_80s"       => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "FDHOMECQ", "FDAWAYCQ", "RENTEQVX", "UTILCQ",   "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "NUM_AUTO", "SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX"], # RNTXRPCQ, VEHINSCQ, MAINRPCQ, BBYDAYCQ given by  MTBI
    "IS_90s_early" => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "FDHOMECQ", "FDAWAYCQ", "RENTEQVX", "UTILCQ", "SIMHOUSX",  "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "VEHQ", "SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX"], # RNTXRPCQ, VEHINSCQ, MAINRPCQ, BBYDAYCQ given by MTBI --- rental eq. ends in 93q4,
    "IS_rest"      => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "FDHOMECQ", "FDAWAYCQ", "RENTEQVX", "UTILCQ",   "HEALTHCQ", "GASMOCQ", "PUBTRACQ", "EDUCACQ", "RNTXRPCQ", "VEHINSCQ" , "MAINRPCQ", "BBYDAYCQ", "VEHQ", "SAVACCTX", "CKBKACTX", "SECESTX", "STOCKX", "USBNDX"], # RENTEQVX starts in 1995q1 
    "IS_80s_late"  => ["NEWID", "FINLWT21", "QINTRVYR", "QINTRVMO", "AGE_REF", "SEX_REF", "EDUC_REF", "FINCBTAX", "PERSLT18", "FAM_SIZE", "ZFOODHOM", "ZFOODAWY", "RENTEQVX", "SIMHOUSX", "ZUTILSPS", "ZHEALTH", "ZGASMOTO", "ZPUBTRAN", "ZEDUCATN", "ZRENTXRP", "ZVEHCINS", "ZMAINREP", "ZBABYDAY", "ZCARTRKN", "ZCARTRKU", "VEHQ", "SAVACCTX", "CKBKACTX", "SECESTX", "USBNDX"], # has everything 
)

mtbi_cols   = Dict(
    "IS_80s"       => ["210110", "500110", "490110", "490211", "490212", "490220", "490231", "490232", "490311", "490312", "490313", "490314", "490315", "490411", "490412", "490413", "490900", "490318", "490319", "470220", "480110", "480211", "490500", "520530", "530411", "340210", "800721", "450110", "450210", "460110", "460901"],
    "IS_80s_late"  => [],
    "IS_90s_early" => ["800721", "210110", "500110", "490110", "490211", "490212", "490220", "490231", "490232", "490311", "490312", "490313", "490314", "490315", "490411", "490412", "490413", "490900", "490318", "490319", "470220", "480110", "480211", "490500", "520530", "520531", "520532", "530411", "340210", "450110", "450210", "460110", "460901"],
    "IS_rest"      => ["800721", "520530", "520531", "520532", "530411", "530411", "450110", "450210", "460110", "460901"],
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
    "ZVEHCINS" => "VEHINSCQ", 
    "ZBABYDAY" => "BBYDAYCQ", 
    "ZMAINREP" => "MAINRPCQ"
)

mtbi_names_dict   = Dict(
    # "210110" => "RNTXRPCQ",
    "500110" => "VEHINSCQ",
    # "220121" => "ZMREPINS", # TODO: ZMREPINS includes Maintenance, repairs, insurance, and other expense. We just need home insurance ... 
    # "220211" => "PROPTXCQ", # property taxes
    # "220212" => "PROPTXCQ2", # property taxes
    # "490110" => "VEH_EXP1", 
    # "490211" => "VEH_EXP2",
    # "490212" => "VEH_EXP3",
    # "490220" => "VEH_EXP4",
    # "490231" => "VEH_EXP5",
    # "490232" => "VEH_EXP6",
    # "490311" => "VEH_EXP7",
    # "490312" => "VEH_EXP8",
    # "490313" => "VEH_EXP9",
    # "490314" => "VEH_EXP10",
    # "490315" => "VEH_EXP11",
    # "490411" => "VEH_EXP12",
    # "490412" => "VEH_EXP13",
    # "490413" => "VEH_EXP14",
    # "490900" => "VEH_EXP15",
    # "490318" => "VEH_EXP16",
    # "490319" => "VEH_EXP17",
    # "470220" => "VEH_EXP18",
    # "480110" => "VEH_EXP19",
    # "480211" => "VEH_EXP20",
    # "490500" => "VEH_EXP21",
    # "520530" => "PARKING", # not in 1984-1989, 220901 for 1980-1981 and 1990q1 -
    # "530411" => "TAXI_LIMO", # not in 1984-1989
    # "340210" => "BBYDAYCQ", # child care
    # "800721" => "HOUSE_VAL", #(1980-1981q4, 1990q2-) --- in reality, we only need it for 1994 
    # "520531" => "PARKING_HOME",
    # "520532" => "PARKING_OUT",
    "450110" => "ZCARTRKN1", 
    "450210" => "ZCARTRKN2", 
    "460110" => "ZCARTRKU1", 
    "460901" => "ZCARTRKU2",

)

# Collect data from IS files 
path    = "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing"  
data    = clean_cex(IS_prefixes, [1980, 1981, 1984:1989..., 1990:2021...], key_selector, fmli_cols, mtbi_cols, fmli_names_dict, mtbi_names_dict, path)  #1980 is retrieved in the code

# Merge the dataframes in data 
final_df = outerjoin(data[1], data[2], on=[:CUSTOM_CUID, :REF_DATE], makeunique=true, indicator=:source)
filter!(x -> x.source != "left_only", final_df)
final_df = coalesce.(final_df, 0)
select!(final_df, Not(:source))

CSV.write(path * "/CEX_processed.csv", select(unique(final_df), :REF_DATE, :))


data    = CSV.read(path * "/CEX_processed.csv", DataFrame)
cols     = ["QBLNCM1X", "QBLNCM2X", "QBLNCM3X", "QYEAR", "CUSTOM_CUID", "NEWID"]
mortg_df = import_additional_files(1990, 2021, ["mor"], true, true)
for k in collect(keys(mortg_df[1]))
    select!(mortg_df[1][k], cols)
end

# Creating date columns, we move everything one period back 
for k in collect(keys(mortg_df[1]))
    mortg_df[1][k][!, :year]           = parse.(Int, [convert_year(string(x)[1:end-1]) for x in mortg_df[1][k][!, "QYEAR"]])
    mortg_df[1][k][!, :quarter]        = mortg_df[1][k][!, :QYEAR] .% 10
    cond                               = mortg_df[1][k][!, :quarter] .== 5
    mortg_df[1][k][!, :quarter][cond] .= 1
    mortg_df[1][k][!, :date]           = QuarterlyDate.(mortg_df[1][k][!, :year], mortg_df[1][k][!, :quarter]) # TODO: we shift the quarter back in the stata code

    # If QBLNCM1X is missing, fill with QBLNCM2X. If both missing, fill with QBLNCM3X
    mortg_df[1][k][!, :mortgage] = coalesce.(mortg_df[1][k][!, :QBLNCM1X], mortg_df[1][k][!, :QBLNCM2X], mortg_df[1][k][!, :QBLNCM3X])

    # Aggregate by CU and date 
    mortg_df[1][k] = combine(groupby(mortg_df[1][k], [:CUSTOM_CUID, :date]), :mortgage=>sum)
end

# Append the dataframes together in the dictionary to create a large df 
final_mortg_df = DataFrame()
for k in collect(keys(mortg_df[1]))
    if k == 1
        final_mortg_df = mortg_df[1][k]
    else
        append!(final_mortg_df, mortg_df[1][k])
    end
end

# QBLNCM1X	Principal balance outstanding at the beginning of month M1
# QBLNCM2X	Principal balance outstanding at the beginning of month M2
# QBLNCM3X	Principal balance outstanding at the beginning of month M3
# QYEAR	Year and quarter of interview
# NEWID
# CUSTOM_CUID
# Merge the mortgage data with the processed data on two keys: CUSTOM_CUID and date
data[!, "date"] = QuarterlyDate.(data[!, "REF_DATE"])
final_df        = leftjoin(data, final_mortg_df, on = [:CUSTOM_CUID, :date], indicator=:source)
final_df[!, "mortgage_sum"] = coalesce.(final_df[!, "mortgage_sum"], 0) #TODO: double check that indeed those that have 0 mortgage have rent 

CSV.write(path * "/CEX.csv", select(unique(final_df), ["CUSTOM_CUID", "date"], :))




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
# house rent eq.    = RENTEQVX (1980-1981, 1984-1993, 1995-) (self reported) -> This is monthly rental eq.: 910050
# house rent eq. #2 = SIMHOUSX (1984-1993) 
# house rent eq. #3 = 910050 (1993-) MTBI + ITBI 
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



# Building financial income / earnings / transfer income / business (i think these are  all based on the last 12 months)
    # Earnings: FSALARYX,
    # Business: FNONFRMX (business income), FFRMINCX (farm income)
    # Transfer: FRRETIRX (social security, railroad), FSSIX (last 12 months tho), UNEMPLX, COMPENSX (workers comp), WELFAREX (public assistance/job training), PENSIONX (pension income), CHDOTHX (child support), OTHRINCX (scholarships), ALIOTHX (alimony from last 12 months)
    # Financial: INTEARNX (interest income), FININCX (dividends, royalties, estates and trusts, )
