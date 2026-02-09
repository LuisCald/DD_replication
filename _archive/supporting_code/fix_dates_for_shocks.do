**# Import shocks data 
cd "/Users/lc/Dropbox/Distributional_Dynamics/1_Data/shocks"
import excel "all_shocks.xlsx", clear firstrow

* clean
gen qdate = quarterly(quarter, "YQ")
format qdate %tq
order qdate 
drop quarter 
rename qdate quarter 

export excel "all_shocks.xlsx", firstrow(var) replace


**# Importing the aggregates 
cd "/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing"
import excel "aggregates_HHs_NPs.xlsx", clear firstrow

* clean
tostring time, gen(str_time)
gen qdate = qofd(time)

format qdate %tq
order qdate 
drop time 
rename qdate quarter 

save "aggregates_HHs_NPs", replace
