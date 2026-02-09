use "F:\SIPP Files\2008\sipp08w1.dta", clear 
keep ssuid epppnum swave srefmon thtotinc whfnwgt thfdstp erace

foreach j in 2 3 4 { 
append using "F:\SIPP Files\2008\sipp08w`j'.dta" 
keep ssuid epppnum swave srefmon thtotinc whfnwgt thfdstp erace 
}
