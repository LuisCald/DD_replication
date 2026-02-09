//
// bysort hh_id year month: egen maxage_male=max(age) if sex==1
// gen hh_head=0
// replace hh_head=1 if age==maxage_male 
// bysort hh_id year month: egen maxage_female=max(age) if sex==2
// gen hh_spouse=0
// replace hh_spouse=1 if age==maxage_female 
//
// keep if hh_head==1 | hh_spouse==1
//
// bysort hh_id year month: egen a1=sum(hh_head)
// bysort hh_id year month: egen a2=sum(hh_spouse)
// gen full_hh=(a1+a2)/2
// keep if full_hh==1
// keep if ms==1 /*keep only married*/


gen labor_inc = ws1_am+ ws2_am
// bysort hh_id year month: egen wife_inc  = sum(labor_inc)
// replace wife_inc=wife_inc-labor_inc
// gen hours = ws1_hr*ws1_wk+ ws2_hr*ws2_wk
// bysort hh_id year month: egen HH_hr  = sum(hours)
//
// bysort hh_id year month: replace maxage_female = maxage_female[_n - 1] if maxage_female[_n - 1] !=. & hh_spouse[_n - 1]==1 
// bysort hh_id year month: replace maxage_female = maxage_female[_n + 1] if maxage_female[_n + 1] !=. & hh_spouse[_n + 1]==1 


// keep if hh_head==1
drop if labor_inc<0
// drop if wife_inc<0


gen hh_tot_tran= h_tran +h_socsec+ h_unemp+ h_vets+h_noncsh  // already includes ssi
replace hh_tot_tran = hh_tot_tran - h_vets if h_vets == h_tran & h_tran!=0  // data check

*!!!Top coding may be an issue!!!!

*****CREATE CALENDAR MONTH/YEAR*****************************
gen     quarter=1 if month>=1 & month<=3
replace quarter=2 if month>=4 & month<=6
replace quarter=3 if month>=7 & month<=9
replace quarter=4 if month>=10 & month<=12


bysort hh_id year quarter: gen check_month = _N

keep if check_month == 3

*******Aggregate to quarter *******
// bysort hh_id year quarter: replace wife_inc  = sum(wife_inc)
bysort hh_id year quarter: replace labor_inc  = sum(labor_inc)
// bysort hh_id year quarter: replace h_prop  = sum(h_prop)
// bysort hh_id year quarter: replace h_tran  = sum(h_tran)
// bysort hh_id year quarter: replace h_ssi  = sum(h_ssi)
// bysort hh_id year quarter: replace h_unemp  = sum(h_unemp)
bysort hh_id year quarter: replace hh_tot_tran = sum(hh_tot_tran)
// bysort hh_id year quarter: replace HH_hr = sum(HH_hr)

keep if month==3 |month==6 | month==9| month==12

// keep if HH_hr>260
