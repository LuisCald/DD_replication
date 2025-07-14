# Things to run 
# cd("/Users/lc/Dropbox/Distributional_Dynamics/5_Code")
include("DistributionalDynamics.jl")

# Beginning of file 
init_path = dirname(pwd())[end-7:end] == "Dynamics" ? dirname(pwd()) : pwd()
@unpack measures, data_cutoffs, tag = model_options
label = "3D_A non-diag"

kind_of_plots = :mcmc # :mcmc
par_final     = get_param_vector(measures, kind_of_plots, label, data_cutoffs, tag)

# Importing posterior params 
# counterfactuals_dict = Dict(
#     "UN"             => ["UNEMPLOYMENT_RATE", "AVG_DURATION_UNEMP", "AVG_WEEKLY_HOURS", "NON_FARM_EMP"], 
#     "AP"             => ["SHILLER_PRICE_INDEX", "SP500", "SP_DIV_YIELD", "HNOREMV", "HOOREVLMHMV", "BOGZ1LM154022005Q", "BOGZ1LM153061105Q", "BOGZ1LM153062005Q", "BOGZ1LM153063005Q", "HNOCEA", "HNOMFSA", "BOGZ1LM152090205Q", "BOGZ1LM152010005Q", "TABSHNO"], #TODO: add more rates 
#     "MP"             => ["TB3MS", "GS5", "GS1", "CORP_BOND_PREMIA", "CPI_INFLATION"],
#     "RE"             => ["BOGZ1LM155111005Q", "GOV_STATE_LOCAL", "GOV_DEFENSE", "GOV_NONDEFENSE", "GDP", "PRIVATE_INVESTMENT", "NONRESIDENTIAL_INVESTMENT", "RESIDENTIAL_INVESTMENT", "DURABLE_CONSUMPTION", "NONDURABLE_CONSUMPTION", "SERVICES_CONSUMPTION", "REAL_PERSONAL_INCOME", "IND_PROD"],
#     # "AL"             => ["TLBSHNO", "CDCABSHNO", "TSDABSHNO", "TFAABSHNO", "HNOLA", "MABSHNO", "LIRABSHNO", "HNOPFAQ027S", "MAABSHNO", "HNOLL", "HMLBSHNO", "CCLBSHNO", "BLNECLBSHNO", "OLALBSHNO", "MVLOAS"],
#     # "HE"             => ["PERSONALFINANCECURRENT", "PERSONALFINANCEEXPECTED", "BUSINESSCONDITION12MONTHS", "BUSINESSCONDITION5YEARS", "BUYINGCONDITIONS" , "CURRENTINDEX", "EXPECTEDINDEX"],
#     "Nothing"             => [] # no aggregate shocks
#     ) 

counterfactuals_dict = Dict(
    "UN" => ["PAYEMS", "USPRIV", "MANEMP", "SRVPRD", "USGOOD", "DMANEMP", "NDMANEMP", 
        "USCONS", "USEHS", "USFIRE", "USINFO", "USPBS", "USLAH", "USSERV", 
        "USMINE", "USTPU", "USGOVT", "USTRADE", "USWTRADE", "CES9091000001", 
        "CES9092000001", "CES9093000001", "CE16OV", "CIVPART", "UNRATE", 
        "UNRATESTx", "UNRATE5Tx", "UNRATELTx", "LNS14000012", "LNS14000025", 
        "LNS14000026", "UEMPLT5", "UEMP5TO14", "UEMP15T26", "UEMP27OV", 
        "LNS13023621", "LNS13023557", "LNS13023705", "LNS13023569", 
        "LNS12032194", "HOABS", "HOAMS", "HOANBS", "AWHMAN", 
        "AWHNONAG", "AWOTMAN", "WIX", "EMPMEAN", "CES0600000007", 
        "WIURATIOx", "CLAIMSx"],
    
    "AP" => ["VXOCLSx", "NIKKEI225", "NASDAQCOM", "S&P 500", "S&P: indust", "S&P: div yield", "S&P PE ratio", "SPCS10RSA", "SPCS20RSA"],
    
    "MP" => ["FEDFUNDS", "TB3MS", "TB6MS", "GS1", "GS10", "MORTGAGE30US", "AAA", "BAA", "BAA10YM", "MORTG10YRx", "TB6M3Mx", "GS1TB3Mx", "GS10TB3Mx", 
        "CPF3MTB3Mx", "GS5", "TB3SMFFM", "T5YFFM", "AAAFFM", "CP3M", "COMPAPFF"],

    # "PR" => ["CUSR0000SAD", "CUSR0000SAS", "CPIULFSL", "CUSR0000SA0L2", "CUSR0000SA0L5", "CUSR0000SEHC",
    #     "DRCARG3Q086SBEA", "DFSARG3Q086SBEA", "DIFSRG3Q086SBEA", "DOTSRG3Q086SBEA", "CPIAUCSL", "CPILFESL", "WPSFD49207", 
    #     "PPIACO", "WPSFD49502", "WPSFD4111", "PPIIDC", "WPSID61", "WPU0531", "WPU0561", "OILPRICEx", "WPSID62", "PPICMM", 
    #     "CPIAPPSL", "CPITRNSL", "CPI MEDSL", "CUSROOOOSAC", "PCETPI", "PCEPILFE", "GDPCTPI", "GPDICTPI", "IPDBS", 
    #     "DGDSRG3Q086SBEA", "DDURRG3Q086SBEA", "DSERRG3Q086SBEA", "DNDGRG3Q086SBEA", "DHCECRG3Q086SBEA", "DMOTRG3Q086SBEA", 
    #     "DFDHRG3Q086SBEA", "DREQRG3Q086SBEA", "DODGRG3Q086SBEA", "DFXARG3Q086SBEA", "DCLORG3Q086SBEA", "DGOERG3Q086SBEA", 
    #     "DONGRG3Q086SBEA", "DHUTRG3Q086SBEA", "DHLCRG3Q086SBEA", "DTRSRG3Q086SBEA"],

    # "HS" = [
    #     "HOUST", "HOUST5F", "PERMIT", "HOUSTMW", "HOUSTNE", 
    #     "HOUSTS", "HOUSTW", "USSTHPI", "SPCS10RSA", "SPCS20RSA", 
    #     "PERMITNE", "PERMITMW", "PERMITS", "PERMITW"],
)


# Create the different 'blinds'/scenarios, each one corresponding to a key 
# blind_to_dict                  = Dict()
# blind_to_dict["Wealth"]        = Dict("PSID" => ["wealth"])  #TEST CASE
# blind_to_dict["Income"]        = Dict("PSID" => ["income"])
# blind_to_dict["Both"]          = Dict("PSID" => ["income", "wealth"])

func_data, time_params, model_elements                  = estimation_prep(obs_data, model_options);
param_vector, param_sizes, priors, meas_ind, Σ_ids      = set_params(model_elements, time_params, model_options)

run_counterfactual_aggregates(counterfactuals_dict, model_options, par_final, func_data, time_params, model_elements, param_sizes, priors, meas_ind, Σ_ids)  #TODO: if you run twice, things will go wrong 

# run_counterfactual_distributions(blind_to_dict, final_params, obs_data, method_options)

# final_params
# A = reshape(final_params[1:19*19], (19,19))
# B = reshape(final_params[19*19+1:19*19+19*36], (19,36))
# Ω = Diagonal(final_params[19*19+19*36+1:19*19+19*36+19])
# Σ = Diagonal(final_params[19*19+19*36+19+1:end])