**# Cleaning the new wave of the SCF
use "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SCF+/SCF_2022.dta", clear 

set maxvar 10000   // the full public file has more than 5,000 variables

* Generate ID variable 
rename y1 id 

* Generate income (tinc - total household income, excluding capital gains)
* total income as the sum of wages and salaries, income from profes- sional practice and self-employment, rental income, interest, dividends, transfer payments, as well as business and farm income.
// rename x5702 wages_salary 
// rename X5704 business_farm_income
// rename X5706 bond_interest_income
// rename X5708 other_interest_income
// rename X5710 dividend_income
// rename X5712 capital_gains
// rename X5714 other_business_income //annual income from other businesses or investments, net rent, trusts, or royalties in 2021, before deductions for taxes and anything else?

// rename X5716 unemployment_wrk_comp
// rename X5718 child_support_alimony
// rename X5722 social_security 
// rename X5720 food_stamps_ssi 
// rename X5724 other_income 

rename x5729 inc_w_gains
replace  inc_w_gains = . if  inc_w_gains == -9 
gen income = inc_w_gains - x5712 // minus losses/gains from capital 
keep income id 
save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SCF+/SCF_2022_income.dta", replace 

* Generate wealth 
// FIN=LIQ+CDS+NMMF+STOCKS+BOND+RETQLIQ+SAVBND+CASHLI+OTHMA+OTHFIN;
// NFIN=VEHIC+HOUSES+ORESRE+NNRESRE+BUS+OTHNFIN;
// Total debt: MRTHEL+RESDBT+OTHLOC+CCBAL+INSTALL+ODEBT;

use "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SCF+/SCF_2022_wealth.dta", replace
drop income
rename y1 id
gen wealth = nfin + fin - debt - retqliq   // pensions out, as in the SCF+ waves (wealth - pen); see issue #9

* DFA balance-sheet components (SCF summary-extract names) — match the SCF+ block.
* `stocks` is also a raw var (directly-held equities), so build into a temp and rename.
gen real_estate = houses + oresre + nnresre   // DFA "real estate" (= SCF+ house + oest)
gen business    = bus                         // DFA "unincorporated business" (= SCF+ ffabus)
gen pension     = retqliq                     // quasi-liquid retirement (~ SCF+ pen)
gen vehicles    = vehic                       // DFA "consumer durables" (vehicles only)
gen stocks_m    = stocks + nmmf               // DFA "corporate equities + mutual funds" (= SCF+ equity + mfun)
drop stocks
rename stocks_m stocks

merge 1:1 id using "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SCF+/SCF_2022_income.dta"

* Find weight variable 
rename wgt weight 

* generate impnum 
gen impnum = mod(id, 10)
gen year = "2022"
gen id_string = string(id)
drop id
gen id = year + id_string
drop year 
gen year = 2022 

* Put in 2019 dollars (CPI-U annual averages, FRED CPIAUCSL, as the other surveys' 2019 = 1 factors; issue #9).
* Balance-sheet values are at the 2022 survey date: CPI 2019 / CPI 2022 = 0.8737.
* Income refers to 2021:                         CPI 2019 / CPI 2021 = 0.9435.
* (Before Oct 2026 all were multiplied by .83.)
foreach var in wealth stocks real_estate business pension vehicles {
	replace `var' = `var' * 0.8737
}
replace income = income * 0.9435

keep id weight income wealth year stocks real_estate business pension vehicles

* Append to SCF we have 
save "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/SCF+/SCF_2022_cleaned.dta", replace 

	
