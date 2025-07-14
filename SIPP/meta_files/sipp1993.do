log using sip93fp, text replace
set mem 1000m

/*------------------------------------------------

  This program reads the 1993 SIPP Full Panel Data File 

****************************************************************
*
* NOTE: This complete dataset has over more than 2,047 variables,
* the maximum number of variables for Intercooled Stata 8.0. 
* So, variables at the end are commented out.  The commenting 
* can be removed in an editor by replacing '' with ''.
* Stata/SE can handle up to 32,766 variables, default=5000.
*
****************************************************************

  Note:  This program is distributed under the GNU GPL. See end of
  this file and http://www.gnu.org/licenses/ for details.
  by Jean Roth Tue Dec 15 13:13:45 EST 2009
  Please report errors to jroth@nber.org
  run with do sip93fp

----------------------------------------------- */

/* The following line should contain
   the complete path and name of the raw data file.
   On a PC, use backslashes in paths as in C:\  */
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP

local dat_name "sipp93fp.dat"

/* The following line should contain the path to your output '.dta' file */

local dta_name "sipp93fp.dta"

/* The following line should contain the path to the data dictionary file */

local dct_name "sip93fp.dct"

/* The line below does NOT need to be changed */

quietly infile using "`dct_name'", using("`dat_name'") clear

/*------------------------------------------------

  Decimal places have been made explict in the dictionary file.
  Stata resolves a missing value of -1 / # of decimal places as a missing value.

 -----------------------------------------------*/

*Everything below this point, aside from the final save, are value labels

#delimit ;

;
label values pp_intv1 pp_intv;
label values pp_intv2 pp_intv;
label values pp_intv3 pp_intv;
label values pp_intv4 pp_intv;
label values pp_intv5 pp_intv;
label values pp_intv6 pp_intv;
label values pp_intv7 pp_intv;
label values pp_intv8 pp_intv;
label values pp_intv9 pp_intv;
label define pp_intv 
	0           "Not applicable (children under"
	1           "Interview (self)"              
	2           "Interview (proxy)"             
	3           "Noninterview - Type Z refusal" 
	4           "Noninterview - Type Z other"   
;
label values pp_mis01 pp_mis; 
label values pp_mis02 pp_mis; 
label values pp_mis03 pp_mis; 
label values pp_mis04 pp_mis; 
label values pp_mis05 pp_mis; 
label values pp_mis06 pp_mis; 
label values pp_mis07 pp_mis; 
label values pp_mis08 pp_mis; 
label values pp_mis09 pp_mis; 
label values pp_mis10 pp_mis; 
label values pp_mis11 pp_mis; 
label values pp_mis12 pp_mis; 
label values pp_mis13 pp_mis; 
label values pp_mis14 pp_mis; 
label values pp_mis15 pp_mis; 
label values pp_mis16 pp_mis; 
label values pp_mis17 pp_mis; 
label values pp_mis18 pp_mis; 
label values pp_mis19 pp_mis; 
label values pp_mis20 pp_mis; 
label values pp_mis21 pp_mis; 
label values pp_mis22 pp_mis; 
label values pp_mis23 pp_mis; 
label values pp_mis24 pp_mis; 
label values pp_mis25 pp_mis; 
label values pp_mis26 pp_mis; 
label values pp_mis27 pp_mis; 
label values pp_mis28 pp_mis; 
label values pp_mis29 pp_mis; 
label values pp_mis30 pp_mis; 
label values pp_mis31 pp_mis; 
label values pp_mis32 pp_mis; 
label values pp_mis33 pp_mis; 
label values pp_mis34 pp_mis; 
label values pp_mis35 pp_mis; 
label values pp_mis36 pp_mis; 
label define pp_mis  
	0           "Not matched or not in sample"  
	1           "Interview"                     
	2           "Non-interview"                 
;
label values reaslef1 reaslef;
label values reaslef2 reaslef;
label values reaslef3 reaslef;
label values reaslef4 reaslef;
label values reaslef5 reaslef;
label values reaslef6 reaslef;
label values reaslef7 reaslef;
label values reaslef8 reaslef;
label values reaslef9 reaslef;
label define reaslef 
	0           "Not applicable or not answered"
	1           "Left - deceased"               
	2           "Left - institutionalized"      
	3           "Left - living in armed forces" 
	4           "Left - moved outside of country"
	5           "Left - separation or divorce"  
	6           "Left - person #201 or greater" 
	7           "Left - other"                  
	8           "Entered merged household"      
	9           "Interviewed in previous wave"  
;
label values hhinst01 hhinst; 
label values hhinst02 hhinst; 
label values hhinst03 hhinst; 
label values hhinst04 hhinst; 
label values hhinst05 hhinst; 
label values hhinst06 hhinst; 
label values hhinst07 hhinst; 
label values hhinst08 hhinst; 
label values hhinst09 hhinst; 
label values hhinst10 hhinst; 
label values hhinst11 hhinst; 
label values hhinst12 hhinst; 
label values hhinst13 hhinst; 
label values hhinst14 hhinst; 
label values hhinst15 hhinst; 
label values hhinst16 hhinst; 
label values hhinst17 hhinst; 
label values hhinst18 hhinst; 
label values hhinst19 hhinst; 
label values hhinst20 hhinst; 
label values hhinst21 hhinst; 
label values hhinst22 hhinst; 
label values hhinst23 hhinst; 
label values hhinst24 hhinst; 
label values hhinst25 hhinst; 
label values hhinst26 hhinst; 
label values hhinst27 hhinst; 
label values hhinst28 hhinst; 
label values hhinst29 hhinst; 
label values hhinst30 hhinst; 
label values hhinst31 hhinst; 
label values hhinst32 hhinst; 
label values hhinst33 hhinst; 
label values hhinst34 hhinst; 
label values hhinst35 hhinst; 
label values hhinst36 hhinst; 
label define hhinst  
	0           "Not defined for this wave"     
	1           "Interviewed"                   
	2           "No one home"                   
	3           "Temporarily absent"            
	4           "Refused"                       
	5           "Unable to locate"              
	6           "Other"                         
	9           "Vacant"                        
	10          "Occupied by persons with URE"  
	11          "Unfit or to be demolished"     
	12          "Under construction, not ready" 
	13          "Converted to temporary business"
	14          "Unoccupied site for mobile"    
	15          "Permit granted, construction"  
	16          "Other Type B"                  
	17          "Demolished"                    
	18          "House or trailer moved"        
	19          "Converted to permanent business"
	20          "Merged"                        
	21          "Condemned"                     
	22          "Other Type C"                  
	23          "Entire household out-of-scope" 
	24          "Moved, address unknown"        
	25          "Moved within country beyond"   
	26          "All sample persons relisted on"
;
label values mst_rgc  mst_rgc;
label define mst_rgc 
	0           "Not applicable for coverage"   
;
label values lgthht01 lgthht; 
label values lgthht02 lgthht; 
label values lgthht03 lgthht; 
label values lgthht04 lgthht; 
label values lgthht05 lgthht; 
label values lgthht06 lgthht; 
label values lgthht07 lgthht; 
label values lgthht08 lgthht; 
label values lgthht09 lgthht; 
label values lgthht10 lgthht; 
label values lgthht11 lgthht; 
label values lgthht12 lgthht; 
label values lgthht13 lgthht; 
label values lgthht14 lgthht; 
label values lgthht15 lgthht; 
label values lgthht16 lgthht; 
label values lgthht17 lgthht; 
label values lgthht18 lgthht; 
label values lgthht19 lgthht; 
label values lgthht20 lgthht; 
label values lgthht21 lgthht; 
label values lgthht22 lgthht; 
label values lgthht23 lgthht; 
label values lgthht24 lgthht; 
label values lgthht25 lgthht; 
label values lgthht26 lgthht; 
label values lgthht27 lgthht; 
label values lgthht28 lgthht; 
label values lgthht29 lgthht; 
label values lgthht30 lgthht; 
label values lgthht31 lgthht; 
label values lgthht32 lgthht; 
label values lgthht33 lgthht; 
label values lgthht34 lgthht; 
label values lgthht35 lgthht; 
label values lgthht36 lgthht; 
label define lgthht  
	0           "NA, not in a household"        
	1           "Married couple household"      
	2           "Other family household, male"  
	3           "Other family household, female"
	4           "Nonfamily household, male"     
	5           "Nonfamily household, female"   
;
label values lgtkey01 lgtkey; 
label values lgtkey02 lgtkey; 
label values lgtkey03 lgtkey; 
label values lgtkey04 lgtkey; 
label values lgtkey05 lgtkey; 
label values lgtkey06 lgtkey; 
label values lgtkey07 lgtkey; 
label values lgtkey08 lgtkey; 
label values lgtkey09 lgtkey; 
label values lgtkey10 lgtkey; 
label values lgtkey11 lgtkey; 
label values lgtkey12 lgtkey; 
label values lgtkey13 lgtkey; 
label values lgtkey14 lgtkey; 
label values lgtkey15 lgtkey; 
label values lgtkey16 lgtkey; 
label values lgtkey17 lgtkey; 
label values lgtkey18 lgtkey; 
label values lgtkey19 lgtkey; 
label values lgtkey20 lgtkey; 
label values lgtkey21 lgtkey; 
label values lgtkey22 lgtkey; 
label values lgtkey23 lgtkey; 
label values lgtkey24 lgtkey; 
label values lgtkey25 lgtkey; 
label values lgtkey26 lgtkey; 
label values lgtkey27 lgtkey; 
label values lgtkey28 lgtkey; 
label values lgtkey29 lgtkey; 
label values lgtkey30 lgtkey; 
label values lgtkey31 lgtkey; 
label values lgtkey32 lgtkey; 
label values lgtkey33 lgtkey; 
label values lgtkey34 lgtkey; 
label values lgtkey35 lgtkey; 
label values lgtkey36 lgtkey; 
label define lgtkey  
	0           "This is not a key person"      
	1           "1 or greater indicates"        
;
label values lgtoth01 lgtoth; 
label values lgtoth02 lgtoth; 
label values lgtoth03 lgtoth; 
label values lgtoth04 lgtoth; 
label values lgtoth05 lgtoth; 
label values lgtoth06 lgtoth; 
label values lgtoth07 lgtoth; 
label values lgtoth08 lgtoth; 
label values lgtoth09 lgtoth; 
label values lgtoth10 lgtoth; 
label values lgtoth11 lgtoth; 
label values lgtoth12 lgtoth; 
label values lgtoth13 lgtoth; 
label values lgtoth14 lgtoth; 
label values lgtoth15 lgtoth; 
label values lgtoth16 lgtoth; 
label values lgtoth17 lgtoth; 
label values lgtoth18 lgtoth; 
label values lgtoth19 lgtoth; 
label values lgtoth20 lgtoth; 
label values lgtoth21 lgtoth; 
label values lgtoth22 lgtoth; 
label values lgtoth23 lgtoth; 
label values lgtoth24 lgtoth; 
label values lgtoth25 lgtoth; 
label values lgtoth26 lgtoth; 
label values lgtoth27 lgtoth; 
label values lgtoth28 lgtoth; 
label values lgtoth29 lgtoth; 
label values lgtoth30 lgtoth; 
label values lgtoth31 lgtoth; 
label values lgtoth32 lgtoth; 
label values lgtoth33 lgtoth; 
label values lgtoth34 lgtoth; 
label values lgtoth35 lgtoth; 
label values lgtoth36 lgtoth; 
label define lgtoth  
	0           "This is not an 'other' person" 
	1           "1 or greater indicates that"   
;
label values sex      sex;    
label define sex     
	1           "Male"                          
	2           "Female"                        
;
label values race     race;   
label define race    
	1           "White"                         
	2           "Black"                         
	3           "American Indian, Eskimo or"    
	4           "Asian or Pacific Islander"     
;
label values ethnicty ethnicty;
label define ethnicty
	1           "German"                        
	2           "English"                       
	3           "Irish"                         
	4           "French"                        
	5           "Italian"                       
	6           "Scotish"                       
	7           "Polish"                        
	8           "Dutch"                         
	9           "Swedish"                       
	10          "Norwegian"                     
	11          "Russian"                       
	12          "Ukranian"                      
	13          "Welsh"                         
	14          "Mexican-American"              
	15          "Chicano"                       
	16          "Mexican"                       
	17          "Puerto Rican"                  
	18          "Cuban"                         
	19          "Central or South American"     
	20          "Other Spanish"                 
	21          "Afro-American (Black or Negro)"
	30          "Another group not listed"      
	39          "Don't know"                    
;
label values rrp_01   rrp;    
label values rrp_02   rrp;    
label values rrp_03   rrp;    
label values rrp_04   rrp;    
label values rrp_05   rrp;    
label values rrp_06   rrp;    
label values rrp_07   rrp;    
label values rrp_08   rrp;    
label values rrp_09   rrp;    
label values rrp_10   rrp;    
label values rrp_11   rrp;    
label values rrp_12   rrp;    
label values rrp_13   rrp;    
label values rrp_14   rrp;    
label values rrp_15   rrp;    
label values rrp_16   rrp;    
label values rrp_17   rrp;    
label values rrp_18   rrp;    
label values rrp_19   rrp;    
label values rrp_20   rrp;    
label values rrp_21   rrp;    
label values rrp_22   rrp;    
label values rrp_23   rrp;    
label values rrp_24   rrp;    
label values rrp_25   rrp;    
label values rrp_26   rrp;    
label values rrp_27   rrp;    
label values rrp_28   rrp;    
label values rrp_29   rrp;    
label values rrp_30   rrp;    
label values rrp_31   rrp;    
label values rrp_32   rrp;    
label values rrp_33   rrp;    
label values rrp_34   rrp;    
label values rrp_35   rrp;    
label values rrp_36   rrp;    
label define rrp     
	0           "Not a sample person in this"   
	1           "Household reference person,"   
	2           "Household reference person"    
	3           "Spouse of household reference" 
	4           "Child of household reference"  
	5           "Other relative of household"   
	6           "Non-relative of household"     
	7           "Non-relative of household"     
;
label values age_01   age;    
label values age_02   age;    
label values age_03   age;    
label values age_04   age;    
label values age_05   age;    
label values age_06   age;    
label values age_07   age;    
label values age_08   age;    
label values age_09   age;    
label values age_10   age;    
label values age_11   age;    
label values age_12   age;    
label values age_13   age;    
label values age_14   age;    
label values age_15   age;    
label values age_16   age;    
label values age_17   age;    
label values age_18   age;    
label values age_19   age;    
label values age_20   age;    
label values age_21   age;    
label values age_22   age;    
label values age_23   age;    
label values age_24   age;    
label values age_25   age;    
label values age_26   age;    
label values age_27   age;    
label values age_28   age;    
label values age_29   age;    
label values age_30   age;    
label values age_31   age;    
label values age_32   age;    
label values age_33   age;    
label values age_34   age;    
label values age_35   age;    
label values age_36   age;    
label define age     
	0           "Less than 1 full year or not a"
	1           "1 year etc."                   
;
label values ms_01    ms;     
label values ms_02    ms;     
label values ms_03    ms;     
label values ms_04    ms;     
label values ms_05    ms;     
label values ms_06    ms;     
label values ms_07    ms;     
label values ms_08    ms;     
label values ms_09    ms;     
label values ms_10    ms;     
label values ms_11    ms;     
label values ms_12    ms;     
label values ms_13    ms;     
label values ms_14    ms;     
label values ms_15    ms;     
label values ms_16    ms;     
label values ms_17    ms;     
label values ms_18    ms;     
label values ms_19    ms;     
label values ms_20    ms;     
label values ms_21    ms;     
label values ms_22    ms;     
label values ms_23    ms;     
label values ms_24    ms;     
label values ms_25    ms;     
label values ms_26    ms;     
label values ms_27    ms;     
label values ms_28    ms;     
label values ms_29    ms;     
label values ms_30    ms;     
label values ms_31    ms;     
label values ms_32    ms;     
label values ms_33    ms;     
label values ms_34    ms;     
label values ms_35    ms;     
label values ms_36    ms;     
label define ms      
	0           "Not a sample person in this"   
	1           "Married, spouse present"       
	2           "Married, spouse absent"        
	3           "Widowed"                       
	4           "Divorced"                      
	5           "Separated"                     
	6           "Never married"                 
;
label values famtyp01 famtyp; 
label values famtyp02 famtyp; 
label values famtyp03 famtyp; 
label values famtyp04 famtyp; 
label values famtyp05 famtyp; 
label values famtyp06 famtyp; 
label values famtyp07 famtyp; 
label values famtyp08 famtyp; 
label values famtyp09 famtyp; 
label values famtyp10 famtyp; 
label values famtyp11 famtyp; 
label values famtyp12 famtyp; 
label values famtyp13 famtyp; 
label values famtyp14 famtyp; 
label values famtyp15 famtyp; 
label values famtyp16 famtyp; 
label values famtyp17 famtyp; 
label values famtyp18 famtyp; 
label values famtyp19 famtyp; 
label values famtyp20 famtyp; 
label values famtyp21 famtyp; 
label values famtyp22 famtyp; 
label values famtyp23 famtyp; 
label values famtyp24 famtyp; 
label values famtyp25 famtyp; 
label values famtyp26 famtyp; 
label values famtyp27 famtyp; 
label values famtyp28 famtyp; 
label values famtyp29 famtyp; 
label values famtyp30 famtyp; 
label values famtyp31 famtyp; 
label values famtyp32 famtyp; 
label values famtyp33 famtyp; 
label values famtyp34 famtyp; 
label values famtyp35 famtyp; 
label values famtyp36 famtyp; 
label define famtyp  
	0           "Primary family or not a sample"
	1           "Secondary individual (not a"   
	2           "Unrelated sub (secondary)"     
	3           "Related subfamily"             
	4           "Primary individual"            
;
label values famrel01 famrel; 
label values famrel02 famrel; 
label values famrel03 famrel; 
label values famrel04 famrel; 
label values famrel05 famrel; 
label values famrel06 famrel; 
label values famrel07 famrel; 
label values famrel08 famrel; 
label values famrel09 famrel; 
label values famrel10 famrel; 
label values famrel11 famrel; 
label values famrel12 famrel; 
label values famrel13 famrel; 
label values famrel14 famrel; 
label values famrel15 famrel; 
label values famrel16 famrel; 
label values famrel17 famrel; 
label values famrel18 famrel; 
label values famrel19 famrel; 
label values famrel20 famrel; 
label values famrel21 famrel; 
label values famrel22 famrel; 
label values famrel23 famrel; 
label values famrel24 famrel; 
label values famrel25 famrel; 
label values famrel26 famrel; 
label values famrel27 famrel; 
label values famrel28 famrel; 
label values famrel29 famrel; 
label values famrel30 famrel; 
label values famrel31 famrel; 
label values famrel32 famrel; 
label values famrel33 famrel; 
label values famrel34 famrel; 
label values famrel35 famrel; 
label values famrel36 famrel; 
label define famrel  
	0           "Not applicable, not in sample,"
	1           "Reference person of family"    
	2           "Spouse of family reference"    
	3           "Child of family reference"     
;
label values famnum01 famnum; 
label values famnum02 famnum; 
label values famnum03 famnum; 
label values famnum04 famnum; 
label values famnum05 famnum; 
label values famnum06 famnum; 
label values famnum07 famnum; 
label values famnum08 famnum; 
label values famnum09 famnum; 
label values famnum10 famnum; 
label values famnum11 famnum; 
label values famnum12 famnum; 
label values famnum13 famnum; 
label values famnum14 famnum; 
label values famnum15 famnum; 
label values famnum16 famnum; 
label values famnum17 famnum; 
label values famnum18 famnum; 
label values famnum19 famnum; 
label values famnum20 famnum; 
label values famnum21 famnum; 
label values famnum22 famnum; 
label values famnum23 famnum; 
label values famnum24 famnum; 
label values famnum25 famnum; 
label values famnum26 famnum; 
label values famnum27 famnum; 
label values famnum28 famnum; 
label values famnum29 famnum; 
label values famnum30 famnum; 
label values famnum31 famnum; 
label values famnum32 famnum; 
label values famnum33 famnum; 
label values famnum34 famnum; 
label values famnum35 famnum; 
label values famnum36 famnum; 
label define famnum  
	0           "Not applicable, not in sample,"
;
label values pnsp_01  pnsp;   
label values pnsp_02  pnsp;   
label values pnsp_03  pnsp;   
label values pnsp_04  pnsp;   
label values pnsp_05  pnsp;   
label values pnsp_06  pnsp;   
label values pnsp_07  pnsp;   
label values pnsp_08  pnsp;   
label values pnsp_09  pnsp;   
label values pnsp_10  pnsp;   
label values pnsp_11  pnsp;   
label values pnsp_12  pnsp;   
label values pnsp_13  pnsp;   
label values pnsp_14  pnsp;   
label values pnsp_15  pnsp;   
label values pnsp_16  pnsp;   
label values pnsp_17  pnsp;   
label values pnsp_18  pnsp;   
label values pnsp_19  pnsp;   
label values pnsp_20  pnsp;   
label values pnsp_21  pnsp;   
label values pnsp_22  pnsp;   
label values pnsp_23  pnsp;   
label values pnsp_24  pnsp;   
label values pnsp_25  pnsp;   
label values pnsp_26  pnsp;   
label values pnsp_27  pnsp;   
label values pnsp_28  pnsp;   
label values pnsp_29  pnsp;   
label values pnsp_30  pnsp;   
label values pnsp_31  pnsp;   
label values pnsp_32  pnsp;   
label values pnsp_33  pnsp;   
label values pnsp_34  pnsp;   
label values pnsp_35  pnsp;   
label values pnsp_36  pnsp;   
label define pnsp    
	0           "Not a sample person in this"   
	999         "Not applicable"                
;
label values pnpt_01  pnpt;   
label values pnpt_02  pnpt;   
label values pnpt_03  pnpt;   
label values pnpt_04  pnpt;   
label values pnpt_05  pnpt;   
label values pnpt_06  pnpt;   
label values pnpt_07  pnpt;   
label values pnpt_08  pnpt;   
label values pnpt_09  pnpt;   
label values pnpt_10  pnpt;   
label values pnpt_11  pnpt;   
label values pnpt_12  pnpt;   
label values pnpt_13  pnpt;   
label values pnpt_14  pnpt;   
label values pnpt_15  pnpt;   
label values pnpt_16  pnpt;   
label values pnpt_17  pnpt;   
label values pnpt_18  pnpt;   
label values pnpt_19  pnpt;   
label values pnpt_20  pnpt;   
label values pnpt_21  pnpt;   
label values pnpt_22  pnpt;   
label values pnpt_23  pnpt;   
label values pnpt_24  pnpt;   
label values pnpt_25  pnpt;   
label values pnpt_26  pnpt;   
label values pnpt_27  pnpt;   
label values pnpt_28  pnpt;   
label values pnpt_29  pnpt;   
label values pnpt_30  pnpt;   
label values pnpt_31  pnpt;   
label values pnpt_32  pnpt;   
label values pnpt_33  pnpt;   
label values pnpt_34  pnpt;   
label values pnpt_35  pnpt;   
label values pnpt_36  pnpt;   
label define pnpt    
	0           "Not a sample person in this"   
	999         "Not applicable"                
;
label values higrade1 higrade;
label values higrade2 higrade;
label values higrade3 higrade;
label values higrade4 higrade;
label values higrade5 higrade;
label values higrade6 higrade;
label values higrade7 higrade;
label values higrade8 higrade;
label values higrade9 higrade;
label define higrade 
	0           "Not applicable if under 15, not"
;
label values grd_cmp1 grd_cmp;
label values grd_cmp2 grd_cmp;
label values grd_cmp3 grd_cmp;
label values grd_cmp4 grd_cmp;
label values grd_cmp5 grd_cmp;
label values grd_cmp6 grd_cmp;
label values grd_cmp7 grd_cmp;
label values grd_cmp8 grd_cmp;
label values grd_cmp9 grd_cmp;
label define grd_cmp 
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values vetstat1 vetstat;
label values vetstat2 vetstat;
label values vetstat3 vetstat;
label values vetstat4 vetstat;
label values vetstat5 vetstat;
label values vetstat6 vetstat;
label values vetstat7 vetstat;
label values vetstat8 vetstat;
label values vetstat9 vetstat;
label define vetstat 
	0           "Not applicable"                
	1           "Yes"                           
	2           "No"                            
;
label values in_af_1  in_af;  
label values in_af_2  in_af;  
label values in_af_3  in_af;  
label values in_af_4  in_af;  
label values in_af_5  in_af;  
label values in_af_6  in_af;  
label values in_af_7  in_af;  
label values in_af_8  in_af;  
label values in_af_9  in_af;  
label define in_af   
	0           "Not applicable if under 15, not"
	1           "Yes"                           
	2           "No"                            
;
label values usrv1_1  usrv1l; 
label values usrv1_2  usrv1l; 
label values usrv1_3  usrv1l; 
label values usrv1_4  usrv1l; 
label values usrv1_5  usrv1l; 
label values usrv1_6  usrv1l; 
label values usrv1_7  usrv1l; 
label values usrv1_8  usrv1l; 
label values usrv1_9  usrv1l; 
label define usrv1l  
	0           "Not applicable, not in sample,"
	1           "Vietnam Era (Aug'64-Apr'75)"   
	2           "Korean conflict (June'50-"     
	3           "World War II (Sept'36-July'47)"
	5           "May 1975 to August 1980"       
	6           "September 1980 or later"       
	7           "Other service (all other"      
	9           "Not answered"                  
;
label values usrv2_1  usrv2l; 
label values usrv2_2  usrv2l; 
label values usrv2_3  usrv2l; 
label values usrv2_4  usrv2l; 
label values usrv2_5  usrv2l; 
label values usrv2_6  usrv2l; 
label values usrv2_7  usrv2l; 
label values usrv2_8  usrv2l; 
label values usrv2_9  usrv2l; 
label define usrv2l  
	0           "Not applicable, not in sample,"
	1           "Vietnam Era (Aug'64-Apr'75)"   
	2           "Korean conflict (June'50-"     
	3           "World War II (Sept'36-July'47)"
	5           "May 1975 to August 1980"       
	6           "September 1980 or later"       
	7           "Other service (all other"      
	9           "Not answered"                  
;
label values usrv3_1  usrv3l; 
label values usrv3_2  usrv3l; 
label values usrv3_3  usrv3l; 
label values usrv3_4  usrv3l; 
label values usrv3_5  usrv3l; 
label values usrv3_6  usrv3l; 
label values usrv3_7  usrv3l; 
label values usrv3_8  usrv3l; 
label values usrv3_9  usrv3l; 
label define usrv3l  
	0           "Not applicable, not in sample,"
	1           "Vietnam Era (Aug'64-Apr'75)"   
	2           "Korean conflict (June'50-"     
	3           "World War II (Sept'36-July'47)"
	5           "May 1975 to August 1980"       
	6           "September 1980 or later"       
	7           "Other service (all other"      
	9           "Not answered"                  
;
label values u_brthmn u_brthmn;
label define u_brthmn
	-9          "Not answered"                  
;
label values u_brthyr u_brthyr;
label define u_brthyr
	-9          "Not answered"                  
;
label values u_pngd1  u_pngd; 
label values u_pngd2  u_pngd; 
label values u_pngd3  u_pngd; 
label values u_pngd4  u_pngd; 
label values u_pngd5  u_pngd; 
label values u_pngd6  u_pngd; 
label values u_pngd7  u_pngd; 
label values u_pngd8  u_pngd; 
label values u_pngd9  u_pngd; 
label define u_pngd  
	0           "Not in universe, not in sample,"
	999         "Not applicable"                
	-09         "Not answered"                  
;
label values livqtr01 livqtr; 
label values livqtr02 livqtr; 
label values livqtr03 livqtr; 
label values livqtr04 livqtr; 
label values livqtr05 livqtr; 
label values livqtr06 livqtr; 
label values livqtr07 livqtr; 
label values livqtr08 livqtr; 
label values livqtr09 livqtr; 
label values livqtr10 livqtr; 
label values livqtr11 livqtr; 
label values livqtr12 livqtr; 
label values livqtr13 livqtr; 
label values livqtr14 livqtr; 
label values livqtr15 livqtr; 
label values livqtr16 livqtr; 
label values livqtr17 livqtr; 
label values livqtr18 livqtr; 
label values livqtr19 livqtr; 
label values livqtr20 livqtr; 
label values livqtr21 livqtr; 
label values livqtr22 livqtr; 
label values livqtr23 livqtr; 
label values livqtr24 livqtr; 
label values livqtr25 livqtr; 
label values livqtr26 livqtr; 
label values livqtr27 livqtr; 
label values livqtr28 livqtr; 
label values livqtr29 livqtr; 
label values livqtr30 livqtr; 
label values livqtr31 livqtr; 
label values livqtr32 livqtr; 
label values livqtr33 livqtr; 
label values livqtr34 livqtr; 
label values livqtr35 livqtr; 
label values livqtr36 livqtr; 
label define livqtr  
	0           "Not applicable, not in sample,"
	1           "House, apartment, flat"        
	2           "HU in nontransient hotel, motel"
	3           "HU, permanent in transient"    
	4           "HU in rooming house"           
	5           "Mobile home or trailer with no"
	6           "Mobile home or trailer with one"
	7           "HU not specified above"        
	8           "Quarters not HU in rooming or" 
	9           "Unit not permanent in transient"
	10          "Unoccupied tent or trailer site"
	11          "Other unit not specified above"
;
label values tenure01 tenure; 
label values tenure02 tenure; 
label values tenure03 tenure; 
label values tenure04 tenure; 
label values tenure05 tenure; 
label values tenure06 tenure; 
label values tenure07 tenure; 
label values tenure08 tenure; 
label values tenure09 tenure; 
label values tenure10 tenure; 
label values tenure11 tenure; 
label values tenure12 tenure; 
label values tenure13 tenure; 
label values tenure14 tenure; 
label values tenure15 tenure; 
label values tenure16 tenure; 
label values tenure17 tenure; 
label values tenure18 tenure; 
label values tenure19 tenure; 
label values tenure20 tenure; 
label values tenure21 tenure; 
label values tenure22 tenure; 
label values tenure23 tenure; 
label values tenure24 tenure; 
label values tenure25 tenure; 
label values tenure26 tenure; 
label values tenure27 tenure; 
label values tenure28 tenure; 
label values tenure29 tenure; 
label values tenure30 tenure; 
label values tenure31 tenure; 
label values tenure32 tenure; 
label values tenure33 tenure; 
label values tenure34 tenure; 
label values tenure35 tenure; 
label values tenure36 tenure; 
label define tenure  
	0           "Not in sample, nonmatch"       
	1           "Owned or being bought by"      
	2           "Rented for cash"               
	3           "Occupied without payment of"   
;
label values pubhou01 pubhou; 
label values pubhou02 pubhou; 
label values pubhou03 pubhou; 
label values pubhou04 pubhou; 
label values pubhou05 pubhou; 
label values pubhou06 pubhou; 
label values pubhou07 pubhou; 
label values pubhou08 pubhou; 
label values pubhou09 pubhou; 
label values pubhou10 pubhou; 
label values pubhou11 pubhou; 
label values pubhou12 pubhou; 
label values pubhou13 pubhou; 
label values pubhou14 pubhou; 
label values pubhou15 pubhou; 
label values pubhou16 pubhou; 
label values pubhou17 pubhou; 
label values pubhou18 pubhou; 
label values pubhou19 pubhou; 
label values pubhou20 pubhou; 
label values pubhou21 pubhou; 
label values pubhou22 pubhou; 
label values pubhou23 pubhou; 
label values pubhou24 pubhou; 
label values pubhou25 pubhou; 
label values pubhou26 pubhou; 
label values pubhou27 pubhou; 
label values pubhou28 pubhou; 
label values pubhou29 pubhou; 
label values pubhou30 pubhou; 
label values pubhou31 pubhou; 
label values pubhou32 pubhou; 
label values pubhou33 pubhou; 
label values pubhou34 pubhou; 
label values pubhou35 pubhou; 
label values pubhou36 pubhou; 
label define pubhou  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values low_re01 low_re; 
label values low_re02 low_re; 
label values low_re03 low_re; 
label values low_re04 low_re; 
label values low_re05 low_re; 
label values low_re06 low_re; 
label values low_re07 low_re; 
label values low_re08 low_re; 
label values low_re09 low_re; 
label values low_re10 low_re; 
label values low_re11 low_re; 
label values low_re12 low_re; 
label values low_re13 low_re; 
label values low_re14 low_re; 
label values low_re15 low_re; 
label values low_re16 low_re; 
label values low_re17 low_re; 
label values low_re18 low_re; 
label values low_re19 low_re; 
label values low_re20 low_re; 
label values low_re21 low_re; 
label values low_re22 low_re; 
label values low_re23 low_re; 
label values low_re24 low_re; 
label values low_re25 low_re; 
label values low_re26 low_re; 
label values low_re27 low_re; 
label values low_re28 low_re; 
label values low_re29 low_re; 
label values low_re30 low_re; 
label values low_re31 low_re; 
label values low_re32 low_re; 
label values low_re33 low_re; 
label values low_re34 low_re; 
label values low_re35 low_re; 
label values low_re36 low_re; 
label define low_re  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values engry_y1 engry_y;
label values engry_y2 engry_y;
label values engry_y3 engry_y;
label values engry_y4 engry_y;
label values engry_y5 engry_y;
label values engry_y6 engry_y;
label values engry_y7 engry_y;
label values engry_y8 engry_y;
label values engry_y9 engry_y;
label define engry_y 
	0           "Not in universe, not in sample"
	1           "Yes"                           
	2           "No"                            
;
label values engryty1 engryty;
label values engryty2 engryty;
label values engryty3 engryty;
label values engryty4 engryty;
label values engryty5 engryty;
label values engryty6 engryty;
label values engryty7 engryty;
label values engryty8 engryty;
label values engryty9 engryty;
label define engryty 
	0           "Not applicable, not in sample" 
	1           "Checks sent to household"      
	2           "Coupons or vouchers sent to"   
	3           "Payments sent elsewhere"       
	4           "Checks and coupons or vouchers"
	5           "Checks sent to household and"  
	6           "Coupons or voucher sent to"    
	7           "All three types of assistance" 
;
label values engryam1 engryam;
label values engryam2 engryam;
label values engryam3 engryam;
label values engryam4 engryam;
label values engryam5 engryam;
label values engryam6 engryam;
label values engryam7 engryam;
label values engryam8 engryam;
label values engryam9 engryam;
label define engryam 
	0           "Not in universe, not in sample"
	999999      "Total amount"                  
;
label values typelun1 typelun;
label values typelun2 typelun;
label values typelun3 typelun;
label values typelun4 typelun;
label values typelun5 typelun;
label values typelun6 typelun;
label values typelun7 typelun;
label values typelun8 typelun;
label values typelun9 typelun;
label define typelun 
	0           "Not applicable, not in sample" 
	1           "Free"                          
	2           "Reduced-price"                 
	3           "Both"                          
;
label values num_lun1 num_lun;
label values num_lun2 num_lun;
label values num_lun3 num_lun;
label values num_lun4 num_lun;
label values num_lun5 num_lun;
label values num_lun6 num_lun;
label values num_lun7 num_lun;
label values num_lun8 num_lun;
label values num_lun9 num_lun;
label define num_lun 
	0           "Not in universe, not in sample"
;
label values typebrk1 typebrk;
label values typebrk2 typebrk;
label values typebrk3 typebrk;
label values typebrk4 typebrk;
label values typebrk5 typebrk;
label values typebrk6 typebrk;
label values typebrk7 typebrk;
label values typebrk8 typebrk;
label values typebrk9 typebrk;
label define typebrk 
	0           "Not applicable, not in sample" 
	1           "Free"                          
	2           "Reduced-price"                 
	3           "Both"                          
;
label values num_brk1 num_brk;
label values num_brk2 num_brk;
label values num_brk3 num_brk;
label values num_brk4 num_brk;
label values num_brk5 num_brk;
label values num_brk6 num_brk;
label values num_brk7 num_brk;
label values num_brk8 num_brk;
label values num_brk9 num_brk;
label define num_brk 
	0           "Not in universe, not in sample"
;
label values pubrntyn pubrntyn;
label define pubrntyn
	0           "Not in sample in wave 1"       
	1           "Yes"                           
	2           "No"                            
;
label values pubrnamt pubrnamt;
label define pubrnamt
	0           "Not applicable"                
	999999      "Total rent"                    
;
label values utlpayyn utlpayyn;
label define utlpayyn
	0           "Not applicable"                
	1           "Yes"                           
	2           "No"                            
;
label values geo_ste1 geo_ste;
label values geo_ste2 geo_ste;
label values geo_ste3 geo_ste;
label values geo_ste4 geo_ste;
label values geo_ste5 geo_ste;
label values geo_ste6 geo_ste;
label values geo_ste7 geo_ste;
label values geo_ste8 geo_ste;
label values geo_ste9 geo_ste;
label define geo_ste 
	0           "Nonmatch"                      
	1           "Alabama"                       
	4           "Arizona"                       
	5           "Arkansas"                      
	6           "California"                    
	8           "Colorado"                      
	9           "Connecticut"                   
	10          "Delaware"                      
	11          "District of Columbia"          
	12          "Florida"                       
	13          "Georgia"                       
	15          "Hawaii"                        
	17          "Illinois"                      
	18          "Indiana"                       
	20          "Kansas"                        
	21          "Kentucky"                      
	22          "Louisiana"                     
	24          "Maryland"                      
	25          "Massachusetts"                 
	26          "Michigan"                      
	27          "Minnesota"                     
	28          "Mississippi"                   
	29          "Missouri"                      
	31          "Nebraska"                      
	32          "Nevada"                        
	33          "New Hampshire"                 
	34          "New Jersey"                    
	35          "New Mexico"                    
	36          "New York"                      
	37          "North Carolina"                
	39          "Ohio"                          
	40          "Oklahoma"                      
	41          "Oregon"                        
	42          "Pennsylvania"                  
	44          "Rhode Island"                  
	45          "South Carolina"                
	47          "Tennessee"                     
	48          "Texas"                         
	49          "Utah"                          
	51          "Virginia"                      
	53          "Washington"                    
	54          "West Virginia"                 
	55          "Wisconsin"                     
	61          "Maine, Vermont"                
	62          "Iowa,North Dakota,South Dakota"
	63          "Alaska,Idaho,Montana,Wyoming"  
;
label values sc1332   sc1332l;
label define sc1332l 
	0           "Not in universe, not in sample,"
	1           "Less than 6 months"            
	2           "6 to 23 months"                
	3           "2 to 19 years"                 
	4           "20 or more years"              
	-1          "DK"                            
;
label values sc1334   sc1334l;
label define sc1334l 
	0           "Not in universe, not in sample,"
	1           "Yes"                           
	2           "No"                            
	-1          "Dk"                            
;
label values sc1336   sc1336l;
label define sc1336l 
	0           "Not in universe, not in sample,"
	1           "1-10%"                         
	2           "11-29%"                        
	3           "30-49%"                        
	4           "50%"                           
	5           "51-89%"                        
	6           "90-99%"                        
	7           "100%"                          
	101         "No rating"                     
	-1          "Dk"                            
	-2          "Ref"                           
	-3          "0%"                            
;
label values sc1344   sc1344l;
label define sc1344l 
	0           "Not in universe, not in sample,"
	1           "Retired"                       
	2           "Disabled"                      
	3           "Widow(ed) or surviving child"  
	4           "Spouse or dependent child"     
	5           "Some other reason"             
	-1          "Dk"                            
;
label values sc1346   sc1346l;
label define sc1346l 
	0           "Not in universe, not in sample,"
	1           "Retired"                       
	2           "Disabled"                      
	3           "Widow(ed) or surviving child"  
	4           "Spouse or dependent child"     
	5           "No other reason"               
	-1          "Dk"                            
;
label values sc1360   sc1360l;
label define sc1360l 
	0           "Not in universe, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values sc1418   sc1418l;
label define sc1418l 
	0           "Not in universe, not in sample,"
	1           "Widowed"                       
	2           "Divorced"                      
	3           "Both widowed and divorced"     
	4           "No"                            
;
label values sc1456   sc1456l;
label define sc1456l 
	0           "Not in universe, not in sample,"
	1           "Yes, in the service"           
	2           "Yes, from service-related"     
	3           "No"                            
;
label values medcode  medcode;
label define medcode 
	0           "Not in universe"               
	1           "Retired or disabled worker"    
	2           "Spouse of retired or disabled" 
	3           "Widow of retired or disabled"  
	4           "Adult disabled as a child"     
	5           "Uninsured"                     
	7           "Other or invalid code"         
	9           "Missing code"                  
;
label values sc1468   sc1468l;
label define sc1468l 
	0           "Not in universe, card not"     
	1           "Hospital only (Type A)"        
	2           "Medical only (Type B)"         
	3           "Both hospital and medical"     
	4           "Card not available"            
;
label values sc1472   sc1472l;
label define sc1472l 
	0           "Not in universe"               
	1           "Yes"                           
	2           "No"                            
	-1          "Dk"                            
;
label values disab    disab;  
label define disab   
	0           "Not in universe (under 15 years"
	1           "Ever disabled marked on the"   
;
label values att_sch1 att_sch;
label values att_sch2 att_sch;
label values att_sch3 att_sch;
label values att_sch4 att_sch;
label values att_sch5 att_sch;
label values att_sch6 att_sch;
label values att_sch7 att_sch;
label values att_sch8 att_sch;
label values att_sch9 att_sch;
label define att_sch 
	0           "Not in universe"               
	1           "Yes, full-time"                
	2           "Yes, part-time"                
	3           "No - skip to SC1694"           
;
label values enrl_m01 enrl_m; 
label values enrl_m02 enrl_m; 
label values enrl_m03 enrl_m; 
label values enrl_m04 enrl_m; 
label values enrl_m05 enrl_m; 
label values enrl_m06 enrl_m; 
label values enrl_m07 enrl_m; 
label values enrl_m08 enrl_m; 
label values enrl_m09 enrl_m; 
label values enrl_m10 enrl_m; 
label values enrl_m11 enrl_m; 
label values enrl_m12 enrl_m; 
label values enrl_m13 enrl_m; 
label values enrl_m14 enrl_m; 
label values enrl_m15 enrl_m; 
label values enrl_m16 enrl_m; 
label values enrl_m17 enrl_m; 
label values enrl_m18 enrl_m; 
label values enrl_m19 enrl_m; 
label values enrl_m20 enrl_m; 
label values enrl_m21 enrl_m; 
label values enrl_m22 enrl_m; 
label values enrl_m23 enrl_m; 
label values enrl_m24 enrl_m; 
label values enrl_m25 enrl_m; 
label values enrl_m26 enrl_m; 
label values enrl_m27 enrl_m; 
label values enrl_m28 enrl_m; 
label values enrl_m29 enrl_m; 
label values enrl_m30 enrl_m; 
label values enrl_m31 enrl_m; 
label values enrl_m32 enrl_m; 
label values enrl_m33 enrl_m; 
label values enrl_m34 enrl_m; 
label values enrl_m35 enrl_m; 
label values enrl_m36 enrl_m; 
label define enrl_m  
	0           "Not enrolled, not in universe,"
	1           "Enrolled during that month"    
;
label values ed_leve1 ed_leve;
label values ed_leve2 ed_leve;
label values ed_leve3 ed_leve;
label values ed_leve4 ed_leve;
label values ed_leve5 ed_leve;
label values ed_leve6 ed_leve;
label values ed_leve7 ed_leve;
label values ed_leve8 ed_leve;
label values ed_leve9 ed_leve;
label define ed_leve 
	0           "Not in universe, not in sample,"
	1           "Elementary grades 1-8"         
	2           "High school grades 9-12"       
	3           "College year 1"                
	4           "College year 2"                
	5           "College year 3"                
	6           "College year 4"                
	7           "College year 5"                
	8           "College year 6"                
	9           "Vocational school"             
	10          "Technical school"              
	11          "Business school"               
;
label values ed_fina1 ed_fina;
label values ed_fina2 ed_fina;
label values ed_fina3 ed_fina;
label values ed_fina4 ed_fina;
label values ed_fina5 ed_fina;
label values ed_fina6 ed_fina;
label values ed_fina7 ed_fina;
label values ed_fina8 ed_fina;
label values ed_fina9 ed_fina;
label define ed_fina 
	0           "Not in universe"               
	1           "Yes"                           
	2           "No"                            
;
label values sc16961  sc1696l;
label values sc16962  sc1696l;
label values sc16963  sc1696l;
label values sc16964  sc1696l;
label values sc16965  sc1696l;
label values sc16966  sc1696l;
label values sc16967  sc1696l;
label values sc16968  sc1696l;
label values sc16969  sc1696l;
label define sc1696l 
	0           "Not in universe"               
	1           "Yes"                           
	2           "No"                            
;
label values telephon telephon;
label define telephon
	0           "Not applicable in panel 93"    
;
label values wavflg01 wavflg; 
label values wavflg02 wavflg; 
label values wavflg03 wavflg; 
label values wavflg04 wavflg; 
label values wavflg05 wavflg; 
label values wavflg06 wavflg; 
label values wavflg07 wavflg; 
label values wavflg08 wavflg; 
label values wavflg09 wavflg; 
label values wavflg10 wavflg; 
label values wavflg11 wavflg; 
label values wavflg12 wavflg; 
label values wavflg13 wavflg; 
label values wavflg14 wavflg; 
label values wavflg15 wavflg; 
label values wavflg16 wavflg; 
label values wavflg17 wavflg; 
label values wavflg18 wavflg; 
label values wavflg19 wavflg; 
label values wavflg20 wavflg; 
label values wavflg21 wavflg; 
label values wavflg22 wavflg; 
label values wavflg23 wavflg; 
label values wavflg24 wavflg; 
label values wavflg25 wavflg; 
label values wavflg26 wavflg; 
label values wavflg27 wavflg; 
label values wavflg28 wavflg; 
label values wavflg29 wavflg; 
label values wavflg30 wavflg; 
label values wavflg31 wavflg; 
label values wavflg32 wavflg; 
label values wavflg33 wavflg; 
label values wavflg34 wavflg; 
label values wavflg35 wavflg; 
label values wavflg36 wavflg; 
label define wavflg  
	0           "Not imputed"                   
	1           "Adult Type A/D imputed"        
	2           "Adult Type Z imputed"          
	3           "Child Type A/D imputed"        
	4           "Adult A/D present at start of" 
	5           "Child A/D present at start of" 
	6           "Adult A/D present at end of"   
	7           "Child A/D present at end of"   
	8           "A/D adult bounded by a Type Z" 
	9           "Type Z adult bounded by a Type Z"
;
label values esr_01   esr;    
label values esr_02   esr;    
label values esr_03   esr;    
label values esr_04   esr;    
label values esr_05   esr;    
label values esr_06   esr;    
label values esr_07   esr;    
label values esr_08   esr;    
label values esr_09   esr;    
label values esr_10   esr;    
label values esr_11   esr;    
label values esr_12   esr;    
label values esr_13   esr;    
label values esr_14   esr;    
label values esr_15   esr;    
label values esr_16   esr;    
label values esr_17   esr;    
label values esr_18   esr;    
label values esr_19   esr;    
label values esr_20   esr;    
label values esr_21   esr;    
label values esr_22   esr;    
label values esr_23   esr;    
label values esr_24   esr;    
label values esr_25   esr;    
label values esr_26   esr;    
label values esr_27   esr;    
label values esr_28   esr;    
label values esr_29   esr;    
label values esr_30   esr;    
label values esr_31   esr;    
label values esr_32   esr;    
label values esr_33   esr;    
label values esr_34   esr;    
label values esr_35   esr;    
label values esr_36   esr;    
label define esr     
	0           "Not applicable, not in sample,"
	1           "With a job entire month, worked"
	2           "With a job entire month, missed"
	3           "With a job entire month, missed"
	4           "With job one or more weeks, no"
	5           "With job one or more weeks,"   
	6           "No job during month, spent"    
	7           "No job during month, spent one"
	8           "No job during month, no time"  
;
label values wksper01 wksper; 
label values wksper02 wksper; 
label values wksper03 wksper; 
label values wksper04 wksper; 
label values wksper05 wksper; 
label values wksper06 wksper; 
label values wksper07 wksper; 
label values wksper08 wksper; 
label values wksper09 wksper; 
label values wksper10 wksper; 
label values wksper11 wksper; 
label values wksper12 wksper; 
label values wksper13 wksper; 
label values wksper14 wksper; 
label values wksper15 wksper; 
label values wksper16 wksper; 
label values wksper17 wksper; 
label values wksper18 wksper; 
label values wksper19 wksper; 
label values wksper20 wksper; 
label values wksper21 wksper; 
label values wksper22 wksper; 
label values wksper23 wksper; 
label values wksper24 wksper; 
label values wksper25 wksper; 
label values wksper26 wksper; 
label values wksper27 wksper; 
label values wksper28 wksper; 
label values wksper29 wksper; 
label values wksper30 wksper; 
label values wksper31 wksper; 
label values wksper32 wksper; 
label values wksper33 wksper; 
label values wksper34 wksper; 
label values wksper35 wksper; 
label values wksper36 wksper; 
label define wksper  
	0           "Not applicable, not in sample,"
	4           "Four weeks"                    
	5           "Five weeks"                    
;
label values mthjbw01 mthjbw; 
label values mthjbw02 mthjbw; 
label values mthjbw03 mthjbw; 
label values mthjbw04 mthjbw; 
label values mthjbw05 mthjbw; 
label values mthjbw06 mthjbw; 
label values mthjbw07 mthjbw; 
label values mthjbw08 mthjbw; 
label values mthjbw09 mthjbw; 
label values mthjbw10 mthjbw; 
label values mthjbw11 mthjbw; 
label values mthjbw12 mthjbw; 
label values mthjbw13 mthjbw; 
label values mthjbw14 mthjbw; 
label values mthjbw15 mthjbw; 
label values mthjbw16 mthjbw; 
label values mthjbw17 mthjbw; 
label values mthjbw18 mthjbw; 
label values mthjbw19 mthjbw; 
label values mthjbw20 mthjbw; 
label values mthjbw21 mthjbw; 
label values mthjbw22 mthjbw; 
label values mthjbw23 mthjbw; 
label values mthjbw24 mthjbw; 
label values mthjbw25 mthjbw; 
label values mthjbw26 mthjbw; 
label values mthjbw27 mthjbw; 
label values mthjbw28 mthjbw; 
label values mthjbw29 mthjbw; 
label values mthjbw30 mthjbw; 
label values mthjbw31 mthjbw; 
label values mthjbw32 mthjbw; 
label values mthjbw33 mthjbw; 
label values mthjbw34 mthjbw; 
label values mthjbw35 mthjbw; 
label values mthjbw36 mthjbw; 
label define mthjbw  
	0           "0 weeks or not applicable, not"
	1           "1 week"                        
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks (only applicable for"  
;
label values mthwop01 mthwop; 
label values mthwop02 mthwop; 
label values mthwop03 mthwop; 
label values mthwop04 mthwop; 
label values mthwop05 mthwop; 
label values mthwop06 mthwop; 
label values mthwop07 mthwop; 
label values mthwop08 mthwop; 
label values mthwop09 mthwop; 
label values mthwop10 mthwop; 
label values mthwop11 mthwop; 
label values mthwop12 mthwop; 
label values mthwop13 mthwop; 
label values mthwop14 mthwop; 
label values mthwop15 mthwop; 
label values mthwop16 mthwop; 
label values mthwop17 mthwop; 
label values mthwop18 mthwop; 
label values mthwop19 mthwop; 
label values mthwop20 mthwop; 
label values mthwop21 mthwop; 
label values mthwop22 mthwop; 
label values mthwop23 mthwop; 
label values mthwop24 mthwop; 
label values mthwop25 mthwop; 
label values mthwop26 mthwop; 
label values mthwop27 mthwop; 
label values mthwop28 mthwop; 
label values mthwop29 mthwop; 
label values mthwop30 mthwop; 
label values mthwop31 mthwop; 
label values mthwop32 mthwop; 
label values mthwop33 mthwop; 
label values mthwop34 mthwop; 
label values mthwop35 mthwop; 
label values mthwop36 mthwop; 
label define mthwop  
	0           "0 weeks or not applicable, not"
	1           "1 week"                        
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks (only applicable for"  
;
label values mthwks01 mthwks; 
label values mthwks02 mthwks; 
label values mthwks03 mthwks; 
label values mthwks04 mthwks; 
label values mthwks05 mthwks; 
label values mthwks06 mthwks; 
label values mthwks07 mthwks; 
label values mthwks08 mthwks; 
label values mthwks09 mthwks; 
label values mthwks10 mthwks; 
label values mthwks11 mthwks; 
label values mthwks12 mthwks; 
label values mthwks13 mthwks; 
label values mthwks14 mthwks; 
label values mthwks15 mthwks; 
label values mthwks16 mthwks; 
label values mthwks17 mthwks; 
label values mthwks18 mthwks; 
label values mthwks19 mthwks; 
label values mthwks20 mthwks; 
label values mthwks21 mthwks; 
label values mthwks22 mthwks; 
label values mthwks23 mthwks; 
label values mthwks24 mthwks; 
label values mthwks25 mthwks; 
label values mthwks26 mthwks; 
label values mthwks27 mthwks; 
label values mthwks28 mthwks; 
label values mthwks29 mthwks; 
label values mthwks30 mthwks; 
label values mthwks31 mthwks; 
label values mthwks32 mthwks; 
label values mthwks33 mthwks; 
label values mthwks34 mthwks; 
label values mthwks35 mthwks; 
label values mthwks36 mthwks; 
label define mthwks  
	0           "None or not applicable, not in"
	1           "1 week"                        
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks (only applicable for"  
;
label values usualhr1 usualhr;
label values usualhr2 usualhr;
label values usualhr3 usualhr;
label values usualhr4 usualhr;
label values usualhr5 usualhr;
label values usualhr6 usualhr;
label values usualhr7 usualhr;
label values usualhr8 usualhr;
label values usualhr9 usualhr;
label define usualhr 
	0           "Not in universe"               
	-3          "None"                          
;
label values jobid101 jobid1l;
label values jobid102 jobid1l;
label values jobid103 jobid1l;
label values jobid104 jobid1l;
label values jobid105 jobid1l;
label values jobid106 jobid1l;
label values jobid107 jobid1l;
label values jobid108 jobid1l;
label values jobid109 jobid1l;
label values jobid110 jobid1l;
label values jobid111 jobid1l;
label values jobid112 jobid1l;
label values jobid113 jobid1l;
label values jobid114 jobid1l;
label values jobid115 jobid1l;
label values jobid116 jobid1l;
label values jobid117 jobid1l;
label values jobid118 jobid1l;
label values jobid119 jobid1l;
label values jobid120 jobid1l;
label values jobid121 jobid1l;
label values jobid122 jobid1l;
label values jobid123 jobid1l;
label values jobid124 jobid1l;
label values jobid125 jobid1l;
label values jobid126 jobid1l;
label values jobid127 jobid1l;
label values jobid128 jobid1l;
label values jobid129 jobid1l;
label values jobid130 jobid1l;
label values jobid131 jobid1l;
label values jobid132 jobid1l;
label values jobid133 jobid1l;
label values jobid134 jobid1l;
label values jobid135 jobid1l;
label values jobid136 jobid1l;
label define jobid1l 
	0           "Not in universe, not in sample,"
;
label values jobid201 jobid2l;
label values jobid202 jobid2l;
label values jobid203 jobid2l;
label values jobid204 jobid2l;
label values jobid205 jobid2l;
label values jobid206 jobid2l;
label values jobid207 jobid2l;
label values jobid208 jobid2l;
label values jobid209 jobid2l;
label values jobid210 jobid2l;
label values jobid211 jobid2l;
label values jobid212 jobid2l;
label values jobid213 jobid2l;
label values jobid214 jobid2l;
label values jobid215 jobid2l;
label values jobid216 jobid2l;
label values jobid217 jobid2l;
label values jobid218 jobid2l;
label values jobid219 jobid2l;
label values jobid220 jobid2l;
label values jobid221 jobid2l;
label values jobid222 jobid2l;
label values jobid223 jobid2l;
label values jobid224 jobid2l;
label values jobid225 jobid2l;
label values jobid226 jobid2l;
label values jobid227 jobid2l;
label values jobid228 jobid2l;
label values jobid229 jobid2l;
label values jobid230 jobid2l;
label values jobid231 jobid2l;
label values jobid232 jobid2l;
label values jobid233 jobid2l;
label values jobid234 jobid2l;
label values jobid235 jobid2l;
label values jobid236 jobid2l;
label define jobid2l 
	0           "Not in universe, not in sample,"
;
label values clswk201 clswk2l;
label values clswk202 clswk2l;
label values clswk203 clswk2l;
label values clswk204 clswk2l;
label values clswk205 clswk2l;
label values clswk206 clswk2l;
label values clswk207 clswk2l;
label values clswk208 clswk2l;
label values clswk209 clswk2l;
label values clswk210 clswk2l;
label values clswk211 clswk2l;
label values clswk212 clswk2l;
label values clswk213 clswk2l;
label values clswk214 clswk2l;
label values clswk215 clswk2l;
label values clswk216 clswk2l;
label values clswk217 clswk2l;
label values clswk218 clswk2l;
label values clswk219 clswk2l;
label values clswk220 clswk2l;
label values clswk221 clswk2l;
label values clswk222 clswk2l;
label values clswk223 clswk2l;
label values clswk224 clswk2l;
label values clswk225 clswk2l;
label values clswk226 clswk2l;
label values clswk227 clswk2l;
label values clswk228 clswk2l;
label values clswk229 clswk2l;
label values clswk230 clswk2l;
label values clswk231 clswk2l;
label values clswk232 clswk2l;
label values clswk233 clswk2l;
label values clswk234 clswk2l;
label values clswk235 clswk2l;
label values clswk236 clswk2l;
label define clswk2l 
	0           "Not in universe, not in sample,"
	1           "A private for-profit company or"
	2           "A private not-for-profit, tax" 
	3           "Federal government (exclude"   
	4           "State government"              
	5           "Local government"              
	6           "Armed forces"                  
	7           "Unpaid in family business or"  
;
label values wksem101 wksem1l;
label values wksem102 wksem1l;
label values wksem103 wksem1l;
label values wksem104 wksem1l;
label values wksem105 wksem1l;
label values wksem106 wksem1l;
label values wksem107 wksem1l;
label values wksem108 wksem1l;
label values wksem109 wksem1l;
label values wksem110 wksem1l;
label values wksem111 wksem1l;
label values wksem112 wksem1l;
label values wksem113 wksem1l;
label values wksem114 wksem1l;
label values wksem115 wksem1l;
label values wksem116 wksem1l;
label values wksem117 wksem1l;
label values wksem118 wksem1l;
label values wksem119 wksem1l;
label values wksem120 wksem1l;
label values wksem121 wksem1l;
label values wksem122 wksem1l;
label values wksem123 wksem1l;
label values wksem124 wksem1l;
label values wksem125 wksem1l;
label values wksem126 wksem1l;
label values wksem127 wksem1l;
label values wksem128 wksem1l;
label values wksem129 wksem1l;
label values wksem130 wksem1l;
label values wksem131 wksem1l;
label values wksem132 wksem1l;
label values wksem133 wksem1l;
label values wksem134 wksem1l;
label values wksem135 wksem1l;
label values wksem136 wksem1l;
label define wksem1l 
	0           "None"                          
	1           "1 week etc"                    
;
label values wksem201 wksem2l;
label values wksem202 wksem2l;
label values wksem203 wksem2l;
label values wksem204 wksem2l;
label values wksem205 wksem2l;
label values wksem206 wksem2l;
label values wksem207 wksem2l;
label values wksem208 wksem2l;
label values wksem209 wksem2l;
label values wksem210 wksem2l;
label values wksem211 wksem2l;
label values wksem212 wksem2l;
label values wksem213 wksem2l;
label values wksem214 wksem2l;
label values wksem215 wksem2l;
label values wksem216 wksem2l;
label values wksem217 wksem2l;
label values wksem218 wksem2l;
label values wksem219 wksem2l;
label values wksem220 wksem2l;
label values wksem221 wksem2l;
label values wksem222 wksem2l;
label values wksem223 wksem2l;
label values wksem224 wksem2l;
label values wksem225 wksem2l;
label values wksem226 wksem2l;
label values wksem227 wksem2l;
label values wksem228 wksem2l;
label values wksem229 wksem2l;
label values wksem230 wksem2l;
label values wksem231 wksem2l;
label values wksem232 wksem2l;
label values wksem233 wksem2l;
label values wksem234 wksem2l;
label values wksem235 wksem2l;
label values wksem236 wksem2l;
label define wksem2l 
	0           "None"                          
	1           "1 week etc"                    
;
label values wshrs101 wshrs1l;
label values wshrs102 wshrs1l;
label values wshrs103 wshrs1l;
label values wshrs104 wshrs1l;
label values wshrs105 wshrs1l;
label values wshrs106 wshrs1l;
label values wshrs107 wshrs1l;
label values wshrs108 wshrs1l;
label values wshrs109 wshrs1l;
label values wshrs110 wshrs1l;
label values wshrs111 wshrs1l;
label values wshrs112 wshrs1l;
label values wshrs113 wshrs1l;
label values wshrs114 wshrs1l;
label values wshrs115 wshrs1l;
label values wshrs116 wshrs1l;
label values wshrs117 wshrs1l;
label values wshrs118 wshrs1l;
label values wshrs119 wshrs1l;
label values wshrs120 wshrs1l;
label values wshrs121 wshrs1l;
label values wshrs122 wshrs1l;
label values wshrs123 wshrs1l;
label values wshrs124 wshrs1l;
label values wshrs125 wshrs1l;
label values wshrs126 wshrs1l;
label values wshrs127 wshrs1l;
label values wshrs128 wshrs1l;
label values wshrs129 wshrs1l;
label values wshrs130 wshrs1l;
label values wshrs131 wshrs1l;
label values wshrs132 wshrs1l;
label values wshrs133 wshrs1l;
label values wshrs134 wshrs1l;
label values wshrs135 wshrs1l;
label values wshrs136 wshrs1l;
label define wshrs1l 
	0           "Not in universe, not in"       
	-3          "None"                          
;
label values wshrs201 wshrs2l;
label values wshrs202 wshrs2l;
label values wshrs203 wshrs2l;
label values wshrs204 wshrs2l;
label values wshrs205 wshrs2l;
label values wshrs206 wshrs2l;
label values wshrs207 wshrs2l;
label values wshrs208 wshrs2l;
label values wshrs209 wshrs2l;
label values wshrs210 wshrs2l;
label values wshrs211 wshrs2l;
label values wshrs212 wshrs2l;
label values wshrs213 wshrs2l;
label values wshrs214 wshrs2l;
label values wshrs215 wshrs2l;
label values wshrs216 wshrs2l;
label values wshrs217 wshrs2l;
label values wshrs218 wshrs2l;
label values wshrs219 wshrs2l;
label values wshrs220 wshrs2l;
label values wshrs221 wshrs2l;
label values wshrs222 wshrs2l;
label values wshrs223 wshrs2l;
label values wshrs224 wshrs2l;
label values wshrs225 wshrs2l;
label values wshrs226 wshrs2l;
label values wshrs227 wshrs2l;
label values wshrs228 wshrs2l;
label values wshrs229 wshrs2l;
label values wshrs230 wshrs2l;
label values wshrs231 wshrs2l;
label values wshrs232 wshrs2l;
label values wshrs233 wshrs2l;
label values wshrs234 wshrs2l;
label values wshrs235 wshrs2l;
label values wshrs236 wshrs2l;
label define wshrs2l 
	0           "Not in universe, not in"       
	-3          "None"                          
;
label values hrrat101 hrrat1l;
label values hrrat102 hrrat1l;
label values hrrat103 hrrat1l;
label values hrrat104 hrrat1l;
label values hrrat105 hrrat1l;
label values hrrat106 hrrat1l;
label values hrrat107 hrrat1l;
label values hrrat108 hrrat1l;
label values hrrat109 hrrat1l;
label values hrrat110 hrrat1l;
label values hrrat111 hrrat1l;
label values hrrat112 hrrat1l;
label values hrrat113 hrrat1l;
label values hrrat114 hrrat1l;
label values hrrat115 hrrat1l;
label values hrrat116 hrrat1l;
label values hrrat117 hrrat1l;
label values hrrat118 hrrat1l;
label values hrrat119 hrrat1l;
label values hrrat120 hrrat1l;
label values hrrat121 hrrat1l;
label values hrrat122 hrrat1l;
label values hrrat123 hrrat1l;
label values hrrat124 hrrat1l;
label values hrrat125 hrrat1l;
label values hrrat126 hrrat1l;
label values hrrat127 hrrat1l;
label values hrrat128 hrrat1l;
label values hrrat129 hrrat1l;
label values hrrat130 hrrat1l;
label values hrrat131 hrrat1l;
label values hrrat132 hrrat1l;
label values hrrat133 hrrat1l;
label values hrrat134 hrrat1l;
label values hrrat135 hrrat1l;
label values hrrat136 hrrat1l;
label define hrrat1l 
	0           "Not in universe, not in"       
;
label values hrrat201 hrrat2l;
label values hrrat202 hrrat2l;
label values hrrat203 hrrat2l;
label values hrrat204 hrrat2l;
label values hrrat205 hrrat2l;
label values hrrat206 hrrat2l;
label values hrrat207 hrrat2l;
label values hrrat208 hrrat2l;
label values hrrat209 hrrat2l;
label values hrrat210 hrrat2l;
label values hrrat211 hrrat2l;
label values hrrat212 hrrat2l;
label values hrrat213 hrrat2l;
label values hrrat214 hrrat2l;
label values hrrat215 hrrat2l;
label values hrrat216 hrrat2l;
label values hrrat217 hrrat2l;
label values hrrat218 hrrat2l;
label values hrrat219 hrrat2l;
label values hrrat220 hrrat2l;
label values hrrat221 hrrat2l;
label values hrrat222 hrrat2l;
label values hrrat223 hrrat2l;
label values hrrat224 hrrat2l;
label values hrrat225 hrrat2l;
label values hrrat226 hrrat2l;
label values hrrat227 hrrat2l;
label values hrrat228 hrrat2l;
label values hrrat229 hrrat2l;
label values hrrat230 hrrat2l;
label values hrrat231 hrrat2l;
label values hrrat232 hrrat2l;
label values hrrat233 hrrat2l;
label values hrrat234 hrrat2l;
label values hrrat235 hrrat2l;
label values hrrat236 hrrat2l;
label define hrrat2l 
	0           "Not in universe, not in"       
;
label values busid101 busid1l;
label values busid102 busid1l;
label values busid103 busid1l;
label values busid104 busid1l;
label values busid105 busid1l;
label values busid106 busid1l;
label values busid107 busid1l;
label values busid108 busid1l;
label values busid109 busid1l;
label values busid110 busid1l;
label values busid111 busid1l;
label values busid112 busid1l;
label values busid113 busid1l;
label values busid114 busid1l;
label values busid115 busid1l;
label values busid116 busid1l;
label values busid117 busid1l;
label values busid118 busid1l;
label values busid119 busid1l;
label values busid120 busid1l;
label values busid121 busid1l;
label values busid122 busid1l;
label values busid123 busid1l;
label values busid124 busid1l;
label values busid125 busid1l;
label values busid126 busid1l;
label values busid127 busid1l;
label values busid128 busid1l;
label values busid129 busid1l;
label values busid130 busid1l;
label values busid131 busid1l;
label values busid132 busid1l;
label values busid133 busid1l;
label values busid134 busid1l;
label values busid135 busid1l;
label values busid136 busid1l;
label define busid1l 
	0           "Not in universe, not in"       
;
label values busid201 busid2l;
label values busid202 busid2l;
label values busid203 busid2l;
label values busid204 busid2l;
label values busid205 busid2l;
label values busid206 busid2l;
label values busid207 busid2l;
label values busid208 busid2l;
label values busid209 busid2l;
label values busid210 busid2l;
label values busid211 busid2l;
label values busid212 busid2l;
label values busid213 busid2l;
label values busid214 busid2l;
label values busid215 busid2l;
label values busid216 busid2l;
label values busid217 busid2l;
label values busid218 busid2l;
label values busid219 busid2l;
label values busid220 busid2l;
label values busid221 busid2l;
label values busid222 busid2l;
label values busid223 busid2l;
label values busid224 busid2l;
label values busid225 busid2l;
label values busid226 busid2l;
label values busid227 busid2l;
label values busid228 busid2l;
label values busid229 busid2l;
label values busid230 busid2l;
label values busid231 busid2l;
label values busid232 busid2l;
label values busid233 busid2l;
label values busid234 busid2l;
label values busid235 busid2l;
label values busid236 busid2l;
label define busid2l 
	0           "Not in universe, not in"       
;
label values typbs101 typbs1l;
label values typbs102 typbs1l;
label values typbs103 typbs1l;
label values typbs104 typbs1l;
label values typbs105 typbs1l;
label values typbs106 typbs1l;
label values typbs107 typbs1l;
label values typbs108 typbs1l;
label values typbs109 typbs1l;
label values typbs110 typbs1l;
label values typbs111 typbs1l;
label values typbs112 typbs1l;
label values typbs113 typbs1l;
label values typbs114 typbs1l;
label values typbs115 typbs1l;
label values typbs116 typbs1l;
label values typbs117 typbs1l;
label values typbs118 typbs1l;
label values typbs119 typbs1l;
label values typbs120 typbs1l;
label values typbs121 typbs1l;
label values typbs122 typbs1l;
label values typbs123 typbs1l;
label values typbs124 typbs1l;
label values typbs125 typbs1l;
label values typbs126 typbs1l;
label values typbs127 typbs1l;
label values typbs128 typbs1l;
label values typbs129 typbs1l;
label values typbs130 typbs1l;
label values typbs131 typbs1l;
label values typbs132 typbs1l;
label values typbs133 typbs1l;
label values typbs134 typbs1l;
label values typbs135 typbs1l;
label values typbs136 typbs1l;
label define typbs1l 
	0           "Not in universe, not in"       
	1           "Sole proprietorship"           
	2           "Partnership"                   
	3           "Corporation"                   
;
label values typbs201 typbs2l;
label values typbs202 typbs2l;
label values typbs203 typbs2l;
label values typbs204 typbs2l;
label values typbs205 typbs2l;
label values typbs206 typbs2l;
label values typbs207 typbs2l;
label values typbs208 typbs2l;
label values typbs209 typbs2l;
label values typbs210 typbs2l;
label values typbs211 typbs2l;
label values typbs212 typbs2l;
label values typbs213 typbs2l;
label values typbs214 typbs2l;
label values typbs215 typbs2l;
label values typbs216 typbs2l;
label values typbs217 typbs2l;
label values typbs218 typbs2l;
label values typbs219 typbs2l;
label values typbs220 typbs2l;
label values typbs221 typbs2l;
label values typbs222 typbs2l;
label values typbs223 typbs2l;
label values typbs224 typbs2l;
label values typbs225 typbs2l;
label values typbs226 typbs2l;
label values typbs227 typbs2l;
label values typbs228 typbs2l;
label values typbs229 typbs2l;
label values typbs230 typbs2l;
label values typbs231 typbs2l;
label values typbs232 typbs2l;
label values typbs233 typbs2l;
label values typbs234 typbs2l;
label values typbs235 typbs2l;
label values typbs236 typbs2l;
label define typbs2l 
	0           "Not in universe, not in"       
	1           "Sole proprietorship"           
	2           "Partnership"                   
	3           "Corporation"                   
;
label values se_wb201 se_wb2l;
label values se_wb202 se_wb2l;
label values se_wb203 se_wb2l;
label values se_wb204 se_wb2l;
label values se_wb205 se_wb2l;
label values se_wb206 se_wb2l;
label values se_wb207 se_wb2l;
label values se_wb208 se_wb2l;
label values se_wb209 se_wb2l;
label values se_wb210 se_wb2l;
label values se_wb211 se_wb2l;
label values se_wb212 se_wb2l;
label values se_wb213 se_wb2l;
label values se_wb214 se_wb2l;
label values se_wb215 se_wb2l;
label values se_wb216 se_wb2l;
label values se_wb217 se_wb2l;
label values se_wb218 se_wb2l;
label values se_wb219 se_wb2l;
label values se_wb220 se_wb2l;
label values se_wb221 se_wb2l;
label values se_wb222 se_wb2l;
label values se_wb223 se_wb2l;
label values se_wb224 se_wb2l;
label values se_wb225 se_wb2l;
label values se_wb226 se_wb2l;
label values se_wb227 se_wb2l;
label values se_wb228 se_wb2l;
label values se_wb229 se_wb2l;
label values se_wb230 se_wb2l;
label values se_wb231 se_wb2l;
label values se_wb232 se_wb2l;
label values se_wb233 se_wb2l;
label values se_wb234 se_wb2l;
label values se_wb235 se_wb2l;
label values se_wb236 se_wb2l;
label define se_wb2l 
	0           "None, not in universe, not in" 
	1           "1 week etc"                    
;
label values se_hr201 se_hr2l;
label values se_hr202 se_hr2l;
label values se_hr203 se_hr2l;
label values se_hr204 se_hr2l;
label values se_hr205 se_hr2l;
label values se_hr206 se_hr2l;
label values se_hr207 se_hr2l;
label values se_hr208 se_hr2l;
label values se_hr209 se_hr2l;
label values se_hr210 se_hr2l;
label values se_hr211 se_hr2l;
label values se_hr212 se_hr2l;
label values se_hr213 se_hr2l;
label values se_hr214 se_hr2l;
label values se_hr215 se_hr2l;
label values se_hr216 se_hr2l;
label values se_hr217 se_hr2l;
label values se_hr218 se_hr2l;
label values se_hr219 se_hr2l;
label values se_hr220 se_hr2l;
label values se_hr221 se_hr2l;
label values se_hr222 se_hr2l;
label values se_hr223 se_hr2l;
label values se_hr224 se_hr2l;
label values se_hr225 se_hr2l;
label values se_hr226 se_hr2l;
label values se_hr227 se_hr2l;
label values se_hr228 se_hr2l;
label values se_hr229 se_hr2l;
label values se_hr230 se_hr2l;
label values se_hr231 se_hr2l;
label values se_hr232 se_hr2l;
label values se_hr233 se_hr2l;
label values se_hr234 se_hr2l;
label values se_hr235 se_hr2l;
label values se_hr236 se_hr2l;
label define se_hr2l 
	0           "Not in universe, not in sample,"
	-3          "None"                          
;
label values g1src1   g1src1l;
label define g1src1l 
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values g1src2   g1src2l;
label define g1src2l 
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values g1src3   g1src3l;
label define g1src3l 
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values g1src4   g1src4l;
label define g1src4l 
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values g1src5   g1src5l;
label define g1src5l 
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values g1src6   g1src6l;
label define g1src6l 
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values g1src7   g1src7l;
label define g1src7l 
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values g1src8   g1src8l;
label define g1src8l 
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values g1src9   g1src9l;
label define g1src9l 
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values g1src10  g1src10l;
label define g1src10l
	0           "Not applicable, not in sample,"
	1           "Social security"               
	2           "Railroad retirement"           
	3           "Federal supplemental security" 
	5           "State unemployment compensation"
	6           "Supplemental unemployment"     
	7           "Other unemployment compensation"
	8           "Veterans compensation or"      
	10          "Workers compensation"          
	12          "Employer or union temporary"   
	13          "Payments from a sickness,"     
	20          "Aid to families with dependent"
	21          "General assistance or general" 
	23          "Foster child care payments"    
	24          "Other welfare"                 
	25          "WIC"                           
	27          "Food stamps"                   
	28          "Child support payments"        
	29          "Alimony payments"              
	30          "Pension from company or union" 
	31          "Federal civil service or other"
	32          "U.S. military retirement pay"  
	34          "State government pensions"     
	35          "Local government pensions"     
	36          "Income from paid up life"      
	37          "Estates and trusts"            
	38          "Other payments for retirement,"
	40          "GI bill education benefits"    
	41          "Other VA educational assistance"
	50          "Income assistance from a"      
	51          "Money from relatives or friends"
	52          "Lump sum payments"             
	53          "Income from roomers or boarders"
	54          "National guard or reserve pay" 
	55          "Incidental or casual earnings" 
	56          "Other cash income not included"
	75          "State SSI/black lung/state"    
;
label values ssrecin1 ssrecin;
label values ssrecin2 ssrecin;
label values ssrecin3 ssrecin;
label values ssrecin4 ssrecin;
label values ssrecin5 ssrecin;
label values ssrecin6 ssrecin;
label values ssrecin7 ssrecin;
label values ssrecin8 ssrecin;
label values ssrecin9 ssrecin;
label define ssrecin 
	0           "Not in universe"               
	1           "Adult benefits received in own"
	2           "Only adult benefits received"  
	3           "Only child benefits received"  
	4           "Adult benefits received in own"
	5           "Adult benefits received jointly"
;
label values rrrecin1 rrrecin;
label values rrrecin2 rrrecin;
label values rrrecin3 rrrecin;
label values rrrecin4 rrrecin;
label values rrrecin5 rrrecin;
label values rrrecin6 rrrecin;
label values rrrecin7 rrrecin;
label values rrrecin8 rrrecin;
label values rrrecin9 rrrecin;
label define rrrecin 
	0           "Not in universe"               
	1           "Adult benefits received in own"
	2           "Only adult benefits received"  
	3           "Only child benefits received"  
	4           "Adult benefits received in own"
	5           "Adult benefits received jointly"
;
label values sc3060   sc3060l;
label define sc3060l 
	0           "Not in universe or don't know" 
	1           "Yes"                           
	2           "No"                            
	-1          "Dk"                            
;
label values ast1501  ast150l;
label values ast1502  ast150l;
label values ast1503  ast150l;
label values ast1504  ast150l;
label values ast1505  ast150l;
label values ast1506  ast150l;
label values ast1507  ast150l;
label values ast1508  ast150l;
label values ast1509  ast150l;
label define ast150l 
	0           "Not applicable"                
	1           "Yes"                           
	2           "No"                            
;
label values g2src140 g2src14n;
label define g2src14n
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values careco01 careco; 
label values careco02 careco; 
label values careco03 careco; 
label values careco04 careco; 
label values careco05 careco; 
label values careco06 careco; 
label values careco07 careco; 
label values careco08 careco; 
label values careco09 careco; 
label values careco10 careco; 
label values careco11 careco; 
label values careco12 careco; 
label values careco13 careco; 
label values careco14 careco; 
label values careco15 careco; 
label values careco16 careco; 
label values careco17 careco; 
label values careco18 careco; 
label values careco19 careco; 
label values careco20 careco; 
label values careco21 careco; 
label values careco22 careco; 
label values careco23 careco; 
label values careco24 careco; 
label values careco25 careco; 
label values careco26 careco; 
label values careco27 careco; 
label values careco28 careco; 
label values careco29 careco; 
label values careco30 careco; 
label values careco31 careco; 
label values careco32 careco; 
label values careco33 careco; 
label values careco34 careco; 
label values careco35 careco; 
label values careco36 careco; 
label define careco  
	0           "Not applicable if age under 15,"
	1           "Yes"                           
	2           "No"                            
;
label values caidco01 caidco; 
label values caidco02 caidco; 
label values caidco03 caidco; 
label values caidco04 caidco; 
label values caidco05 caidco; 
label values caidco06 caidco; 
label values caidco07 caidco; 
label values caidco08 caidco; 
label values caidco09 caidco; 
label values caidco10 caidco; 
label values caidco11 caidco; 
label values caidco12 caidco; 
label values caidco13 caidco; 
label values caidco14 caidco; 
label values caidco15 caidco; 
label values caidco16 caidco; 
label values caidco17 caidco; 
label values caidco18 caidco; 
label values caidco19 caidco; 
label values caidco20 caidco; 
label values caidco21 caidco; 
label values caidco22 caidco; 
label values caidco23 caidco; 
label values caidco24 caidco; 
label values caidco25 caidco; 
label values caidco26 caidco; 
label values caidco27 caidco; 
label values caidco28 caidco; 
label values caidco29 caidco; 
label values caidco30 caidco; 
label values caidco31 caidco; 
label values caidco32 caidco; 
label values caidco33 caidco; 
label values caidco34 caidco; 
label values caidco35 caidco; 
label values caidco36 caidco; 
label define caidco  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values wiccov01 wiccov; 
label values wiccov02 wiccov; 
label values wiccov03 wiccov; 
label values wiccov04 wiccov; 
label values wiccov05 wiccov; 
label values wiccov06 wiccov; 
label values wiccov07 wiccov; 
label values wiccov08 wiccov; 
label values wiccov09 wiccov; 
label values wiccov10 wiccov; 
label values wiccov11 wiccov; 
label values wiccov12 wiccov; 
label values wiccov13 wiccov; 
label values wiccov14 wiccov; 
label values wiccov15 wiccov; 
label values wiccov16 wiccov; 
label values wiccov17 wiccov; 
label values wiccov18 wiccov; 
label values wiccov19 wiccov; 
label values wiccov20 wiccov; 
label values wiccov21 wiccov; 
label values wiccov22 wiccov; 
label values wiccov23 wiccov; 
label values wiccov24 wiccov; 
label values wiccov25 wiccov; 
label values wiccov26 wiccov; 
label values wiccov27 wiccov; 
label values wiccov28 wiccov; 
label values wiccov29 wiccov; 
label values wiccov30 wiccov; 
label values wiccov31 wiccov; 
label values wiccov32 wiccov; 
label values wiccov33 wiccov; 
label values wiccov34 wiccov; 
label values wiccov35 wiccov; 
label values wiccov36 wiccov; 
label define wiccov  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values afdc_01  afdc;   
label values afdc_02  afdc;   
label values afdc_03  afdc;   
label values afdc_04  afdc;   
label values afdc_05  afdc;   
label values afdc_06  afdc;   
label values afdc_07  afdc;   
label values afdc_08  afdc;   
label values afdc_09  afdc;   
label values afdc_10  afdc;   
label values afdc_11  afdc;   
label values afdc_12  afdc;   
label values afdc_13  afdc;   
label values afdc_14  afdc;   
label values afdc_15  afdc;   
label values afdc_16  afdc;   
label values afdc_17  afdc;   
label values afdc_18  afdc;   
label values afdc_19  afdc;   
label values afdc_20  afdc;   
label values afdc_21  afdc;   
label values afdc_22  afdc;   
label values afdc_23  afdc;   
label values afdc_24  afdc;   
label values afdc_25  afdc;   
label values afdc_26  afdc;   
label values afdc_27  afdc;   
label values afdc_28  afdc;   
label values afdc_29  afdc;   
label values afdc_30  afdc;   
label values afdc_31  afdc;   
label values afdc_32  afdc;   
label values afdc_33  afdc;   
label values afdc_34  afdc;   
label values afdc_35  afdc;   
label values afdc_36  afdc;   
label define afdc    
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values foodst01 foodst; 
label values foodst02 foodst; 
label values foodst03 foodst; 
label values foodst04 foodst; 
label values foodst05 foodst; 
label values foodst06 foodst; 
label values foodst07 foodst; 
label values foodst08 foodst; 
label values foodst09 foodst; 
label values foodst10 foodst; 
label values foodst11 foodst; 
label values foodst12 foodst; 
label values foodst13 foodst; 
label values foodst14 foodst; 
label values foodst15 foodst; 
label values foodst16 foodst; 
label values foodst17 foodst; 
label values foodst18 foodst; 
label values foodst19 foodst; 
label values foodst20 foodst; 
label values foodst21 foodst; 
label values foodst22 foodst; 
label values foodst23 foodst; 
label values foodst24 foodst; 
label values foodst25 foodst; 
label values foodst26 foodst; 
label values foodst27 foodst; 
label values foodst28 foodst; 
label values foodst29 foodst; 
label values foodst30 foodst; 
label values foodst31 foodst; 
label values foodst32 foodst; 
label values foodst33 foodst; 
label values foodst34 foodst; 
label values foodst35 foodst; 
label values foodst36 foodst; 
label define foodst  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values gen_as01 gen_as; 
label values gen_as02 gen_as; 
label values gen_as03 gen_as; 
label values gen_as04 gen_as; 
label values gen_as05 gen_as; 
label values gen_as06 gen_as; 
label values gen_as07 gen_as; 
label values gen_as08 gen_as; 
label values gen_as09 gen_as; 
label values gen_as10 gen_as; 
label values gen_as11 gen_as; 
label values gen_as12 gen_as; 
label values gen_as13 gen_as; 
label values gen_as14 gen_as; 
label values gen_as15 gen_as; 
label values gen_as16 gen_as; 
label values gen_as17 gen_as; 
label values gen_as18 gen_as; 
label values gen_as19 gen_as; 
label values gen_as20 gen_as; 
label values gen_as21 gen_as; 
label values gen_as22 gen_as; 
label values gen_as23 gen_as; 
label values gen_as24 gen_as; 
label values gen_as25 gen_as; 
label values gen_as26 gen_as; 
label values gen_as27 gen_as; 
label values gen_as28 gen_as; 
label values gen_as29 gen_as; 
label values gen_as30 gen_as; 
label values gen_as31 gen_as; 
label values gen_as32 gen_as; 
label values gen_as33 gen_as; 
label values gen_as34 gen_as; 
label values gen_as35 gen_as; 
label values gen_as36 gen_as; 
label define gen_as  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values fost_k01 fost_k; 
label values fost_k02 fost_k; 
label values fost_k03 fost_k; 
label values fost_k04 fost_k; 
label values fost_k05 fost_k; 
label values fost_k06 fost_k; 
label values fost_k07 fost_k; 
label values fost_k08 fost_k; 
label values fost_k09 fost_k; 
label values fost_k10 fost_k; 
label values fost_k11 fost_k; 
label values fost_k12 fost_k; 
label values fost_k13 fost_k; 
label values fost_k14 fost_k; 
label values fost_k15 fost_k; 
label values fost_k16 fost_k; 
label values fost_k17 fost_k; 
label values fost_k18 fost_k; 
label values fost_k19 fost_k; 
label values fost_k20 fost_k; 
label values fost_k21 fost_k; 
label values fost_k22 fost_k; 
label values fost_k23 fost_k; 
label values fost_k24 fost_k; 
label values fost_k25 fost_k; 
label values fost_k26 fost_k; 
label values fost_k27 fost_k; 
label values fost_k28 fost_k; 
label values fost_k29 fost_k; 
label values fost_k30 fost_k; 
label values fost_k31 fost_k; 
label values fost_k32 fost_k; 
label values fost_k33 fost_k; 
label values fost_k34 fost_k; 
label values fost_k35 fost_k; 
label values fost_k36 fost_k; 
label define fost_k  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values oth_we01 oth_we; 
label values oth_we02 oth_we; 
label values oth_we03 oth_we; 
label values oth_we04 oth_we; 
label values oth_we05 oth_we; 
label values oth_we06 oth_we; 
label values oth_we07 oth_we; 
label values oth_we08 oth_we; 
label values oth_we09 oth_we; 
label values oth_we10 oth_we; 
label values oth_we11 oth_we; 
label values oth_we12 oth_we; 
label values oth_we13 oth_we; 
label values oth_we14 oth_we; 
label values oth_we15 oth_we; 
label values oth_we16 oth_we; 
label values oth_we17 oth_we; 
label values oth_we18 oth_we; 
label values oth_we19 oth_we; 
label values oth_we20 oth_we; 
label values oth_we21 oth_we; 
label values oth_we22 oth_we; 
label values oth_we23 oth_we; 
label values oth_we24 oth_we; 
label values oth_we25 oth_we; 
label values oth_we26 oth_we; 
label values oth_we27 oth_we; 
label values oth_we28 oth_we; 
label values oth_we29 oth_we; 
label values oth_we30 oth_we; 
label values oth_we31 oth_we; 
label values oth_we32 oth_we; 
label values oth_we33 oth_we; 
label values oth_we34 oth_we; 
label values oth_we35 oth_we; 
label values oth_we36 oth_we; 
label define oth_we  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values soc_se01 soc_se; 
label values soc_se02 soc_se; 
label values soc_se03 soc_se; 
label values soc_se04 soc_se; 
label values soc_se05 soc_se; 
label values soc_se06 soc_se; 
label values soc_se07 soc_se; 
label values soc_se08 soc_se; 
label values soc_se09 soc_se; 
label values soc_se10 soc_se; 
label values soc_se11 soc_se; 
label values soc_se12 soc_se; 
label values soc_se13 soc_se; 
label values soc_se14 soc_se; 
label values soc_se15 soc_se; 
label values soc_se16 soc_se; 
label values soc_se17 soc_se; 
label values soc_se18 soc_se; 
label values soc_se19 soc_se; 
label values soc_se20 soc_se; 
label values soc_se21 soc_se; 
label values soc_se22 soc_se; 
label values soc_se23 soc_se; 
label values soc_se24 soc_se; 
label values soc_se25 soc_se; 
label values soc_se26 soc_se; 
label values soc_se27 soc_se; 
label values soc_se28 soc_se; 
label values soc_se29 soc_se; 
label values soc_se30 soc_se; 
label values soc_se31 soc_se; 
label values soc_se32 soc_se; 
label values soc_se33 soc_se; 
label values soc_se34 soc_se; 
label values soc_se35 soc_se; 
label values soc_se36 soc_se; 
label define soc_se  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values railro01 railro; 
label values railro02 railro; 
label values railro03 railro; 
label values railro04 railro; 
label values railro05 railro; 
label values railro06 railro; 
label values railro07 railro; 
label values railro08 railro; 
label values railro09 railro; 
label values railro10 railro; 
label values railro11 railro; 
label values railro12 railro; 
label values railro13 railro; 
label values railro14 railro; 
label values railro15 railro; 
label values railro16 railro; 
label values railro17 railro; 
label values railro18 railro; 
label values railro19 railro; 
label values railro20 railro; 
label values railro21 railro; 
label values railro22 railro; 
label values railro23 railro; 
label values railro24 railro; 
label values railro25 railro; 
label values railro26 railro; 
label values railro27 railro; 
label values railro28 railro; 
label values railro29 railro; 
label values railro30 railro; 
label values railro31 railro; 
label values railro32 railro; 
label values railro33 railro; 
label values railro34 railro; 
label values railro35 railro; 
label values railro36 railro; 
label define railro  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values vets_01  vets;   
label values vets_02  vets;   
label values vets_03  vets;   
label values vets_04  vets;   
label values vets_05  vets;   
label values vets_06  vets;   
label values vets_07  vets;   
label values vets_08  vets;   
label values vets_09  vets;   
label values vets_10  vets;   
label values vets_11  vets;   
label values vets_12  vets;   
label values vets_13  vets;   
label values vets_14  vets;   
label values vets_15  vets;   
label values vets_16  vets;   
label values vets_17  vets;   
label values vets_18  vets;   
label values vets_19  vets;   
label values vets_20  vets;   
label values vets_21  vets;   
label values vets_22  vets;   
label values vets_23  vets;   
label values vets_24  vets;   
label values vets_25  vets;   
label values vets_26  vets;   
label values vets_27  vets;   
label values vets_28  vets;   
label values vets_29  vets;   
label values vets_30  vets;   
label values vets_31  vets;   
label values vets_32  vets;   
label values vets_33  vets;   
label values vets_34  vets;   
label values vets_35  vets;   
label values vets_36  vets;   
label define vets    
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values champ_01 champ;  
label values champ_02 champ;  
label values champ_03 champ;  
label values champ_04 champ;  
label values champ_05 champ;  
label values champ_06 champ;  
label values champ_07 champ;  
label values champ_08 champ;  
label values champ_09 champ;  
label values champ_10 champ;  
label values champ_11 champ;  
label values champ_12 champ;  
label values champ_13 champ;  
label values champ_14 champ;  
label values champ_15 champ;  
label values champ_16 champ;  
label values champ_17 champ;  
label values champ_18 champ;  
label values champ_19 champ;  
label values champ_20 champ;  
label values champ_21 champ;  
label values champ_22 champ;  
label values champ_23 champ;  
label values champ_24 champ;  
label values champ_25 champ;  
label values champ_26 champ;  
label values champ_27 champ;  
label values champ_28 champ;  
label values champ_29 champ;  
label values champ_30 champ;  
label values champ_31 champ;  
label values champ_32 champ;  
label values champ_33 champ;  
label values champ_34 champ;  
label values champ_35 champ;  
label values champ_36 champ;  
label define champ   
	0           "Not applicable"                
	1           "Yes"                           
	2           "No"                            
;
label values hiownc01 hiownc; 
label values hiownc02 hiownc; 
label values hiownc03 hiownc; 
label values hiownc04 hiownc; 
label values hiownc05 hiownc; 
label values hiownc06 hiownc; 
label values hiownc07 hiownc; 
label values hiownc08 hiownc; 
label values hiownc09 hiownc; 
label values hiownc10 hiownc; 
label values hiownc11 hiownc; 
label values hiownc12 hiownc; 
label values hiownc13 hiownc; 
label values hiownc14 hiownc; 
label values hiownc15 hiownc; 
label values hiownc16 hiownc; 
label values hiownc17 hiownc; 
label values hiownc18 hiownc; 
label values hiownc19 hiownc; 
label values hiownc20 hiownc; 
label values hiownc21 hiownc; 
label values hiownc22 hiownc; 
label values hiownc23 hiownc; 
label values hiownc24 hiownc; 
label values hiownc25 hiownc; 
label values hiownc26 hiownc; 
label values hiownc27 hiownc; 
label values hiownc28 hiownc; 
label values hiownc29 hiownc; 
label values hiownc30 hiownc; 
label values hiownc31 hiownc; 
label values hiownc32 hiownc; 
label values hiownc33 hiownc; 
label values hiownc34 hiownc; 
label values hiownc35 hiownc; 
label values hiownc36 hiownc; 
label define hiownc  
	0           "Not in universe, not in sample,"
	1           "Had health insurance in own"   
	2           "Did not have health insurance" 
;
label values hi_otc01 hi_otc; 
label values hi_otc02 hi_otc; 
label values hi_otc03 hi_otc; 
label values hi_otc04 hi_otc; 
label values hi_otc05 hi_otc; 
label values hi_otc06 hi_otc; 
label values hi_otc07 hi_otc; 
label values hi_otc08 hi_otc; 
label values hi_otc09 hi_otc; 
label values hi_otc10 hi_otc; 
label values hi_otc11 hi_otc; 
label values hi_otc12 hi_otc; 
label values hi_otc13 hi_otc; 
label values hi_otc14 hi_otc; 
label values hi_otc15 hi_otc; 
label values hi_otc16 hi_otc; 
label values hi_otc17 hi_otc; 
label values hi_otc18 hi_otc; 
label values hi_otc19 hi_otc; 
label values hi_otc20 hi_otc; 
label values hi_otc21 hi_otc; 
label values hi_otc22 hi_otc; 
label values hi_otc23 hi_otc; 
label values hi_otc24 hi_otc; 
label values hi_otc25 hi_otc; 
label values hi_otc26 hi_otc; 
label values hi_otc27 hi_otc; 
label values hi_otc28 hi_otc; 
label values hi_otc29 hi_otc; 
label values hi_otc30 hi_otc; 
label values hi_otc31 hi_otc; 
label values hi_otc32 hi_otc; 
label values hi_otc33 hi_otc; 
label values hi_otc34 hi_otc; 
label values hi_otc35 hi_otc; 
label values hi_otc36 hi_otc; 
label define hi_otc  
	0           "Not in universe, not in sample,"
	1           "Had health insurance thru"     
	2           "Did not have health insurance" 
;
label values hiempl01 hiempl; 
label values hiempl02 hiempl; 
label values hiempl03 hiempl; 
label values hiempl04 hiempl; 
label values hiempl05 hiempl; 
label values hiempl06 hiempl; 
label values hiempl07 hiempl; 
label values hiempl08 hiempl; 
label values hiempl09 hiempl; 
label values hiempl10 hiempl; 
label values hiempl11 hiempl; 
label values hiempl12 hiempl; 
label values hiempl13 hiempl; 
label values hiempl14 hiempl; 
label values hiempl15 hiempl; 
label values hiempl16 hiempl; 
label values hiempl17 hiempl; 
label values hiempl18 hiempl; 
label values hiempl19 hiempl; 
label values hiempl20 hiempl; 
label values hiempl21 hiempl; 
label values hiempl22 hiempl; 
label values hiempl23 hiempl; 
label values hiempl24 hiempl; 
label values hiempl25 hiempl; 
label values hiempl26 hiempl; 
label values hiempl27 hiempl; 
label values hiempl28 hiempl; 
label values hiempl29 hiempl; 
label values hiempl30 hiempl; 
label values hiempl31 hiempl; 
label values hiempl32 hiempl; 
label values hiempl33 hiempl; 
label values hiempl34 hiempl; 
label values hiempl35 hiempl; 
label values hiempl36 hiempl; 
label define hiempl  
	0           "Not in universe, not in sample,"
	1           "Health insurance coverage"     
	2           "Health insurance coverage not" 
;
label values ss_pid01 ss_pid; 
label values ss_pid02 ss_pid; 
label values ss_pid03 ss_pid; 
label values ss_pid04 ss_pid; 
label values ss_pid05 ss_pid; 
label values ss_pid06 ss_pid; 
label values ss_pid07 ss_pid; 
label values ss_pid08 ss_pid; 
label values ss_pid09 ss_pid; 
label values ss_pid10 ss_pid; 
label values ss_pid11 ss_pid; 
label values ss_pid12 ss_pid; 
label values ss_pid13 ss_pid; 
label values ss_pid14 ss_pid; 
label values ss_pid15 ss_pid; 
label values ss_pid16 ss_pid; 
label values ss_pid17 ss_pid; 
label values ss_pid18 ss_pid; 
label values ss_pid19 ss_pid; 
label values ss_pid20 ss_pid; 
label values ss_pid21 ss_pid; 
label values ss_pid22 ss_pid; 
label values ss_pid23 ss_pid; 
label values ss_pid24 ss_pid; 
label values ss_pid25 ss_pid; 
label values ss_pid26 ss_pid; 
label values ss_pid27 ss_pid; 
label values ss_pid28 ss_pid; 
label values ss_pid29 ss_pid; 
label values ss_pid30 ss_pid; 
label values ss_pid31 ss_pid; 
label values ss_pid32 ss_pid; 
label values ss_pid33 ss_pid; 
label values ss_pid34 ss_pid; 
label values ss_pid35 ss_pid; 
label values ss_pid36 ss_pid; 
label define ss_pid  
	0           "Not in universe, not in sample,"
;
label values rr_pid01 rr_pid; 
label values rr_pid02 rr_pid; 
label values rr_pid03 rr_pid; 
label values rr_pid04 rr_pid; 
label values rr_pid05 rr_pid; 
label values rr_pid06 rr_pid; 
label values rr_pid07 rr_pid; 
label values rr_pid08 rr_pid; 
label values rr_pid09 rr_pid; 
label values rr_pid10 rr_pid; 
label values rr_pid11 rr_pid; 
label values rr_pid12 rr_pid; 
label values rr_pid13 rr_pid; 
label values rr_pid14 rr_pid; 
label values rr_pid15 rr_pid; 
label values rr_pid16 rr_pid; 
label values rr_pid17 rr_pid; 
label values rr_pid18 rr_pid; 
label values rr_pid19 rr_pid; 
label values rr_pid20 rr_pid; 
label values rr_pid21 rr_pid; 
label values rr_pid22 rr_pid; 
label values rr_pid23 rr_pid; 
label values rr_pid24 rr_pid; 
label values rr_pid25 rr_pid; 
label values rr_pid26 rr_pid; 
label values rr_pid27 rr_pid; 
label values rr_pid28 rr_pid; 
label values rr_pid29 rr_pid; 
label values rr_pid30 rr_pid; 
label values rr_pid31 rr_pid; 
label values rr_pid32 rr_pid; 
label values rr_pid33 rr_pid; 
label values rr_pid34 rr_pid; 
label values rr_pid35 rr_pid; 
label values rr_pid36 rr_pid; 
label define rr_pid  
	0           "Not in universe, not in sample,"
;
label values va_pid01 va_pid; 
label values va_pid02 va_pid; 
label values va_pid03 va_pid; 
label values va_pid04 va_pid; 
label values va_pid05 va_pid; 
label values va_pid06 va_pid; 
label values va_pid07 va_pid; 
label values va_pid08 va_pid; 
label values va_pid09 va_pid; 
label values va_pid10 va_pid; 
label values va_pid11 va_pid; 
label values va_pid12 va_pid; 
label values va_pid13 va_pid; 
label values va_pid14 va_pid; 
label values va_pid15 va_pid; 
label values va_pid16 va_pid; 
label values va_pid17 va_pid; 
label values va_pid18 va_pid; 
label values va_pid19 va_pid; 
label values va_pid20 va_pid; 
label values va_pid21 va_pid; 
label values va_pid22 va_pid; 
label values va_pid23 va_pid; 
label values va_pid24 va_pid; 
label values va_pid25 va_pid; 
label values va_pid26 va_pid; 
label values va_pid27 va_pid; 
label values va_pid28 va_pid; 
label values va_pid29 va_pid; 
label values va_pid30 va_pid; 
label values va_pid31 va_pid; 
label values va_pid32 va_pid; 
label values va_pid33 va_pid; 
label values va_pid34 va_pid; 
label values va_pid35 va_pid; 
label values va_pid36 va_pid; 
label define va_pid  
	0           "Not in universe, not in sample,"
;
label values afdcpi01 afdcpi; 
label values afdcpi02 afdcpi; 
label values afdcpi03 afdcpi; 
label values afdcpi04 afdcpi; 
label values afdcpi05 afdcpi; 
label values afdcpi06 afdcpi; 
label values afdcpi07 afdcpi; 
label values afdcpi08 afdcpi; 
label values afdcpi09 afdcpi; 
label values afdcpi10 afdcpi; 
label values afdcpi11 afdcpi; 
label values afdcpi12 afdcpi; 
label values afdcpi13 afdcpi; 
label values afdcpi14 afdcpi; 
label values afdcpi15 afdcpi; 
label values afdcpi16 afdcpi; 
label values afdcpi17 afdcpi; 
label values afdcpi18 afdcpi; 
label values afdcpi19 afdcpi; 
label values afdcpi20 afdcpi; 
label values afdcpi21 afdcpi; 
label values afdcpi22 afdcpi; 
label values afdcpi23 afdcpi; 
label values afdcpi24 afdcpi; 
label values afdcpi25 afdcpi; 
label values afdcpi26 afdcpi; 
label values afdcpi27 afdcpi; 
label values afdcpi28 afdcpi; 
label values afdcpi29 afdcpi; 
label values afdcpi30 afdcpi; 
label values afdcpi31 afdcpi; 
label values afdcpi32 afdcpi; 
label values afdcpi33 afdcpi; 
label values afdcpi34 afdcpi; 
label values afdcpi35 afdcpi; 
label values afdcpi36 afdcpi; 
label define afdcpi  
	0           "Not in universe, not in sample,"
;
label values ga_pid01 ga_pid; 
label values ga_pid02 ga_pid; 
label values ga_pid03 ga_pid; 
label values ga_pid04 ga_pid; 
label values ga_pid05 ga_pid; 
label values ga_pid06 ga_pid; 
label values ga_pid07 ga_pid; 
label values ga_pid08 ga_pid; 
label values ga_pid09 ga_pid; 
label values ga_pid10 ga_pid; 
label values ga_pid11 ga_pid; 
label values ga_pid12 ga_pid; 
label values ga_pid13 ga_pid; 
label values ga_pid14 ga_pid; 
label values ga_pid15 ga_pid; 
label values ga_pid16 ga_pid; 
label values ga_pid17 ga_pid; 
label values ga_pid18 ga_pid; 
label values ga_pid19 ga_pid; 
label values ga_pid20 ga_pid; 
label values ga_pid21 ga_pid; 
label values ga_pid22 ga_pid; 
label values ga_pid23 ga_pid; 
label values ga_pid24 ga_pid; 
label values ga_pid25 ga_pid; 
label values ga_pid26 ga_pid; 
label values ga_pid27 ga_pid; 
label values ga_pid28 ga_pid; 
label values ga_pid29 ga_pid; 
label values ga_pid30 ga_pid; 
label values ga_pid31 ga_pid; 
label values ga_pid32 ga_pid; 
label values ga_pid33 ga_pid; 
label values ga_pid34 ga_pid; 
label values ga_pid35 ga_pid; 
label values ga_pid36 ga_pid; 
label define ga_pid  
	0           "Not in universe, not in sample,"
;
label values fostpi01 fostpi; 
label values fostpi02 fostpi; 
label values fostpi03 fostpi; 
label values fostpi04 fostpi; 
label values fostpi05 fostpi; 
label values fostpi06 fostpi; 
label values fostpi07 fostpi; 
label values fostpi08 fostpi; 
label values fostpi09 fostpi; 
label values fostpi10 fostpi; 
label values fostpi11 fostpi; 
label values fostpi12 fostpi; 
label values fostpi13 fostpi; 
label values fostpi14 fostpi; 
label values fostpi15 fostpi; 
label values fostpi16 fostpi; 
label values fostpi17 fostpi; 
label values fostpi18 fostpi; 
label values fostpi19 fostpi; 
label values fostpi20 fostpi; 
label values fostpi21 fostpi; 
label values fostpi22 fostpi; 
label values fostpi23 fostpi; 
label values fostpi24 fostpi; 
label values fostpi25 fostpi; 
label values fostpi26 fostpi; 
label values fostpi27 fostpi; 
label values fostpi28 fostpi; 
label values fostpi29 fostpi; 
label values fostpi30 fostpi; 
label values fostpi31 fostpi; 
label values fostpi32 fostpi; 
label values fostpi33 fostpi; 
label values fostpi34 fostpi; 
label values fostpi35 fostpi; 
label values fostpi36 fostpi; 
label define fostpi  
	0           "Not in universe, not in sample,"
;
label values oth_pi01 oth_pi; 
label values oth_pi02 oth_pi; 
label values oth_pi03 oth_pi; 
label values oth_pi04 oth_pi; 
label values oth_pi05 oth_pi; 
label values oth_pi06 oth_pi; 
label values oth_pi07 oth_pi; 
label values oth_pi08 oth_pi; 
label values oth_pi09 oth_pi; 
label values oth_pi10 oth_pi; 
label values oth_pi11 oth_pi; 
label values oth_pi12 oth_pi; 
label values oth_pi13 oth_pi; 
label values oth_pi14 oth_pi; 
label values oth_pi15 oth_pi; 
label values oth_pi16 oth_pi; 
label values oth_pi17 oth_pi; 
label values oth_pi18 oth_pi; 
label values oth_pi19 oth_pi; 
label values oth_pi20 oth_pi; 
label values oth_pi21 oth_pi; 
label values oth_pi22 oth_pi; 
label values oth_pi23 oth_pi; 
label values oth_pi24 oth_pi; 
label values oth_pi25 oth_pi; 
label values oth_pi26 oth_pi; 
label values oth_pi27 oth_pi; 
label values oth_pi28 oth_pi; 
label values oth_pi29 oth_pi; 
label values oth_pi30 oth_pi; 
label values oth_pi31 oth_pi; 
label values oth_pi32 oth_pi; 
label values oth_pi33 oth_pi; 
label values oth_pi34 oth_pi; 
label values oth_pi35 oth_pi; 
label values oth_pi36 oth_pi; 
label define oth_pi  
	0           "Not in universe, not in sample,"
;
label values wic_pi01 wic_pi; 
label values wic_pi02 wic_pi; 
label values wic_pi03 wic_pi; 
label values wic_pi04 wic_pi; 
label values wic_pi05 wic_pi; 
label values wic_pi06 wic_pi; 
label values wic_pi07 wic_pi; 
label values wic_pi08 wic_pi; 
label values wic_pi09 wic_pi; 
label values wic_pi10 wic_pi; 
label values wic_pi11 wic_pi; 
label values wic_pi12 wic_pi; 
label values wic_pi13 wic_pi; 
label values wic_pi14 wic_pi; 
label values wic_pi15 wic_pi; 
label values wic_pi16 wic_pi; 
label values wic_pi17 wic_pi; 
label values wic_pi18 wic_pi; 
label values wic_pi19 wic_pi; 
label values wic_pi20 wic_pi; 
label values wic_pi21 wic_pi; 
label values wic_pi22 wic_pi; 
label values wic_pi23 wic_pi; 
label values wic_pi24 wic_pi; 
label values wic_pi25 wic_pi; 
label values wic_pi26 wic_pi; 
label values wic_pi27 wic_pi; 
label values wic_pi28 wic_pi; 
label values wic_pi29 wic_pi; 
label values wic_pi30 wic_pi; 
label values wic_pi31 wic_pi; 
label values wic_pi32 wic_pi; 
label values wic_pi33 wic_pi; 
label values wic_pi34 wic_pi; 
label values wic_pi35 wic_pi; 
label values wic_pi36 wic_pi; 
label define wic_pi  
	0           "Not in universe, not in sample,"
;
label values fs_pid01 fs_pid; 
label values fs_pid02 fs_pid; 
label values fs_pid03 fs_pid; 
label values fs_pid04 fs_pid; 
label values fs_pid05 fs_pid; 
label values fs_pid06 fs_pid; 
label values fs_pid07 fs_pid; 
label values fs_pid08 fs_pid; 
label values fs_pid09 fs_pid; 
label values fs_pid10 fs_pid; 
label values fs_pid11 fs_pid; 
label values fs_pid12 fs_pid; 
label values fs_pid13 fs_pid; 
label values fs_pid14 fs_pid; 
label values fs_pid15 fs_pid; 
label values fs_pid16 fs_pid; 
label values fs_pid17 fs_pid; 
label values fs_pid18 fs_pid; 
label values fs_pid19 fs_pid; 
label values fs_pid20 fs_pid; 
label values fs_pid21 fs_pid; 
label values fs_pid22 fs_pid; 
label values fs_pid23 fs_pid; 
label values fs_pid24 fs_pid; 
label values fs_pid25 fs_pid; 
label values fs_pid26 fs_pid; 
label values fs_pid27 fs_pid; 
label values fs_pid28 fs_pid; 
label values fs_pid29 fs_pid; 
label values fs_pid30 fs_pid; 
label values fs_pid31 fs_pid; 
label values fs_pid32 fs_pid; 
label values fs_pid33 fs_pid; 
label values fs_pid34 fs_pid; 
label values fs_pid35 fs_pid; 
label values fs_pid36 fs_pid; 
label define fs_pid  
	0           "Not in universe, not in sample,"
;
label values ws_i1_01 ws_i1l; 
label values ws_i1_02 ws_i1l; 
label values ws_i1_03 ws_i1l; 
label values ws_i1_04 ws_i1l; 
label values ws_i1_05 ws_i1l; 
label values ws_i1_06 ws_i1l; 
label values ws_i1_07 ws_i1l; 
label values ws_i1_08 ws_i1l; 
label values ws_i1_09 ws_i1l; 
label values ws_i1_10 ws_i1l; 
label values ws_i1_11 ws_i1l; 
label values ws_i1_12 ws_i1l; 
label values ws_i1_13 ws_i1l; 
label values ws_i1_14 ws_i1l; 
label values ws_i1_15 ws_i1l; 
label values ws_i1_16 ws_i1l; 
label values ws_i1_17 ws_i1l; 
label values ws_i1_18 ws_i1l; 
label values ws_i1_19 ws_i1l; 
label values ws_i1_20 ws_i1l; 
label values ws_i1_21 ws_i1l; 
label values ws_i1_22 ws_i1l; 
label values ws_i1_23 ws_i1l; 
label values ws_i1_24 ws_i1l; 
label values ws_i1_25 ws_i1l; 
label values ws_i1_26 ws_i1l; 
label values ws_i1_27 ws_i1l; 
label values ws_i1_28 ws_i1l; 
label values ws_i1_29 ws_i1l; 
label values ws_i1_30 ws_i1l; 
label values ws_i1_31 ws_i1l; 
label values ws_i1_32 ws_i1l; 
label values ws_i1_33 ws_i1l; 
label values ws_i1_34 ws_i1l; 
label values ws_i1_35 ws_i1l; 
label values ws_i1_36 ws_i1l; 
label define ws_i1l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values ws_i2_01 ws_i2l; 
label values ws_i2_02 ws_i2l; 
label values ws_i2_03 ws_i2l; 
label values ws_i2_04 ws_i2l; 
label values ws_i2_05 ws_i2l; 
label values ws_i2_06 ws_i2l; 
label values ws_i2_07 ws_i2l; 
label values ws_i2_08 ws_i2l; 
label values ws_i2_09 ws_i2l; 
label values ws_i2_10 ws_i2l; 
label values ws_i2_11 ws_i2l; 
label values ws_i2_12 ws_i2l; 
label values ws_i2_13 ws_i2l; 
label values ws_i2_14 ws_i2l; 
label values ws_i2_15 ws_i2l; 
label values ws_i2_16 ws_i2l; 
label values ws_i2_17 ws_i2l; 
label values ws_i2_18 ws_i2l; 
label values ws_i2_19 ws_i2l; 
label values ws_i2_20 ws_i2l; 
label values ws_i2_21 ws_i2l; 
label values ws_i2_22 ws_i2l; 
label values ws_i2_23 ws_i2l; 
label values ws_i2_24 ws_i2l; 
label values ws_i2_25 ws_i2l; 
label values ws_i2_26 ws_i2l; 
label values ws_i2_27 ws_i2l; 
label values ws_i2_28 ws_i2l; 
label values ws_i2_29 ws_i2l; 
label values ws_i2_30 ws_i2l; 
label values ws_i2_31 ws_i2l; 
label values ws_i2_32 ws_i2l; 
label values ws_i2_33 ws_i2l; 
label values ws_i2_34 ws_i2l; 
label values ws_i2_35 ws_i2l; 
label values ws_i2_36 ws_i2l; 
label define ws_i2l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values se_i1_01 se_i1l; 
label values se_i1_02 se_i1l; 
label values se_i1_03 se_i1l; 
label values se_i1_04 se_i1l; 
label values se_i1_05 se_i1l; 
label values se_i1_06 se_i1l; 
label values se_i1_07 se_i1l; 
label values se_i1_08 se_i1l; 
label values se_i1_09 se_i1l; 
label values se_i1_10 se_i1l; 
label values se_i1_11 se_i1l; 
label values se_i1_12 se_i1l; 
label values se_i1_13 se_i1l; 
label values se_i1_14 se_i1l; 
label values se_i1_15 se_i1l; 
label values se_i1_16 se_i1l; 
label values se_i1_17 se_i1l; 
label values se_i1_18 se_i1l; 
label values se_i1_19 se_i1l; 
label values se_i1_20 se_i1l; 
label values se_i1_21 se_i1l; 
label values se_i1_22 se_i1l; 
label values se_i1_23 se_i1l; 
label values se_i1_24 se_i1l; 
label values se_i1_25 se_i1l; 
label values se_i1_26 se_i1l; 
label values se_i1_27 se_i1l; 
label values se_i1_28 se_i1l; 
label values se_i1_29 se_i1l; 
label values se_i1_30 se_i1l; 
label values se_i1_31 se_i1l; 
label values se_i1_32 se_i1l; 
label values se_i1_33 se_i1l; 
label values se_i1_34 se_i1l; 
label values se_i1_35 se_i1l; 
label values se_i1_36 se_i1l; 
label define se_i1l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values se_i2_01 se_i2l; 
label values se_i2_02 se_i2l; 
label values se_i2_03 se_i2l; 
label values se_i2_04 se_i2l; 
label values se_i2_05 se_i2l; 
label values se_i2_06 se_i2l; 
label values se_i2_07 se_i2l; 
label values se_i2_08 se_i2l; 
label values se_i2_09 se_i2l; 
label values se_i2_10 se_i2l; 
label values se_i2_11 se_i2l; 
label values se_i2_12 se_i2l; 
label values se_i2_13 se_i2l; 
label values se_i2_14 se_i2l; 
label values se_i2_15 se_i2l; 
label values se_i2_16 se_i2l; 
label values se_i2_17 se_i2l; 
label values se_i2_18 se_i2l; 
label values se_i2_19 se_i2l; 
label values se_i2_20 se_i2l; 
label values se_i2_21 se_i2l; 
label values se_i2_22 se_i2l; 
label values se_i2_23 se_i2l; 
label values se_i2_24 se_i2l; 
label values se_i2_25 se_i2l; 
label values se_i2_26 se_i2l; 
label values se_i2_27 se_i2l; 
label values se_i2_28 se_i2l; 
label values se_i2_29 se_i2l; 
label values se_i2_30 se_i2l; 
label values se_i2_31 se_i2l; 
label values se_i2_32 se_i2l; 
label values se_i2_33 se_i2l; 
label values se_i2_34 se_i2l; 
label values se_i2_35 se_i2l; 
label values se_i2_36 se_i2l; 
label define se_i2l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i1_01 g1_i1l; 
label values g1_i1_02 g1_i1l; 
label values g1_i1_03 g1_i1l; 
label values g1_i1_04 g1_i1l; 
label values g1_i1_05 g1_i1l; 
label values g1_i1_06 g1_i1l; 
label values g1_i1_07 g1_i1l; 
label values g1_i1_08 g1_i1l; 
label values g1_i1_09 g1_i1l; 
label values g1_i1_10 g1_i1l; 
label values g1_i1_11 g1_i1l; 
label values g1_i1_12 g1_i1l; 
label values g1_i1_13 g1_i1l; 
label values g1_i1_14 g1_i1l; 
label values g1_i1_15 g1_i1l; 
label values g1_i1_16 g1_i1l; 
label values g1_i1_17 g1_i1l; 
label values g1_i1_18 g1_i1l; 
label values g1_i1_19 g1_i1l; 
label values g1_i1_20 g1_i1l; 
label values g1_i1_21 g1_i1l; 
label values g1_i1_22 g1_i1l; 
label values g1_i1_23 g1_i1l; 
label values g1_i1_24 g1_i1l; 
label values g1_i1_25 g1_i1l; 
label values g1_i1_26 g1_i1l; 
label values g1_i1_27 g1_i1l; 
label values g1_i1_28 g1_i1l; 
label values g1_i1_29 g1_i1l; 
label values g1_i1_30 g1_i1l; 
label values g1_i1_31 g1_i1l; 
label values g1_i1_32 g1_i1l; 
label values g1_i1_33 g1_i1l; 
label values g1_i1_34 g1_i1l; 
label values g1_i1_35 g1_i1l; 
label values g1_i1_36 g1_i1l; 
label define g1_i1l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i2_01 g1_i2l; 
label values g1_i2_02 g1_i2l; 
label values g1_i2_03 g1_i2l; 
label values g1_i2_04 g1_i2l; 
label values g1_i2_05 g1_i2l; 
label values g1_i2_06 g1_i2l; 
label values g1_i2_07 g1_i2l; 
label values g1_i2_08 g1_i2l; 
label values g1_i2_09 g1_i2l; 
label values g1_i2_10 g1_i2l; 
label values g1_i2_11 g1_i2l; 
label values g1_i2_12 g1_i2l; 
label values g1_i2_13 g1_i2l; 
label values g1_i2_14 g1_i2l; 
label values g1_i2_15 g1_i2l; 
label values g1_i2_16 g1_i2l; 
label values g1_i2_17 g1_i2l; 
label values g1_i2_18 g1_i2l; 
label values g1_i2_19 g1_i2l; 
label values g1_i2_20 g1_i2l; 
label values g1_i2_21 g1_i2l; 
label values g1_i2_22 g1_i2l; 
label values g1_i2_23 g1_i2l; 
label values g1_i2_24 g1_i2l; 
label values g1_i2_25 g1_i2l; 
label values g1_i2_26 g1_i2l; 
label values g1_i2_27 g1_i2l; 
label values g1_i2_28 g1_i2l; 
label values g1_i2_29 g1_i2l; 
label values g1_i2_30 g1_i2l; 
label values g1_i2_31 g1_i2l; 
label values g1_i2_32 g1_i2l; 
label values g1_i2_33 g1_i2l; 
label values g1_i2_34 g1_i2l; 
label values g1_i2_35 g1_i2l; 
label values g1_i2_36 g1_i2l; 
label define g1_i2l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i3_01 g1_i3l; 
label values g1_i3_02 g1_i3l; 
label values g1_i3_03 g1_i3l; 
label values g1_i3_04 g1_i3l; 
label values g1_i3_05 g1_i3l; 
label values g1_i3_06 g1_i3l; 
label values g1_i3_07 g1_i3l; 
label values g1_i3_08 g1_i3l; 
label values g1_i3_09 g1_i3l; 
label values g1_i3_10 g1_i3l; 
label values g1_i3_11 g1_i3l; 
label values g1_i3_12 g1_i3l; 
label values g1_i3_13 g1_i3l; 
label values g1_i3_14 g1_i3l; 
label values g1_i3_15 g1_i3l; 
label values g1_i3_16 g1_i3l; 
label values g1_i3_17 g1_i3l; 
label values g1_i3_18 g1_i3l; 
label values g1_i3_19 g1_i3l; 
label values g1_i3_20 g1_i3l; 
label values g1_i3_21 g1_i3l; 
label values g1_i3_22 g1_i3l; 
label values g1_i3_23 g1_i3l; 
label values g1_i3_24 g1_i3l; 
label values g1_i3_25 g1_i3l; 
label values g1_i3_26 g1_i3l; 
label values g1_i3_27 g1_i3l; 
label values g1_i3_28 g1_i3l; 
label values g1_i3_29 g1_i3l; 
label values g1_i3_30 g1_i3l; 
label values g1_i3_31 g1_i3l; 
label values g1_i3_32 g1_i3l; 
label values g1_i3_33 g1_i3l; 
label values g1_i3_34 g1_i3l; 
label values g1_i3_35 g1_i3l; 
label values g1_i3_36 g1_i3l; 
label define g1_i3l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i4_01 g1_i4l; 
label values g1_i4_02 g1_i4l; 
label values g1_i4_03 g1_i4l; 
label values g1_i4_04 g1_i4l; 
label values g1_i4_05 g1_i4l; 
label values g1_i4_06 g1_i4l; 
label values g1_i4_07 g1_i4l; 
label values g1_i4_08 g1_i4l; 
label values g1_i4_09 g1_i4l; 
label values g1_i4_10 g1_i4l; 
label values g1_i4_11 g1_i4l; 
label values g1_i4_12 g1_i4l; 
label values g1_i4_13 g1_i4l; 
label values g1_i4_14 g1_i4l; 
label values g1_i4_15 g1_i4l; 
label values g1_i4_16 g1_i4l; 
label values g1_i4_17 g1_i4l; 
label values g1_i4_18 g1_i4l; 
label values g1_i4_19 g1_i4l; 
label values g1_i4_20 g1_i4l; 
label values g1_i4_21 g1_i4l; 
label values g1_i4_22 g1_i4l; 
label values g1_i4_23 g1_i4l; 
label values g1_i4_24 g1_i4l; 
label values g1_i4_25 g1_i4l; 
label values g1_i4_26 g1_i4l; 
label values g1_i4_27 g1_i4l; 
label values g1_i4_28 g1_i4l; 
label values g1_i4_29 g1_i4l; 
label values g1_i4_30 g1_i4l; 
label values g1_i4_31 g1_i4l; 
label values g1_i4_32 g1_i4l; 
label values g1_i4_33 g1_i4l; 
label values g1_i4_34 g1_i4l; 
label values g1_i4_35 g1_i4l; 
label values g1_i4_36 g1_i4l; 
label define g1_i4l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i5_01 g1_i5l; 
label values g1_i5_02 g1_i5l; 
label values g1_i5_03 g1_i5l; 
label values g1_i5_04 g1_i5l; 
label values g1_i5_05 g1_i5l; 
label values g1_i5_06 g1_i5l; 
label values g1_i5_07 g1_i5l; 
label values g1_i5_08 g1_i5l; 
label values g1_i5_09 g1_i5l; 
label values g1_i5_10 g1_i5l; 
label values g1_i5_11 g1_i5l; 
label values g1_i5_12 g1_i5l; 
label values g1_i5_13 g1_i5l; 
label values g1_i5_14 g1_i5l; 
label values g1_i5_15 g1_i5l; 
label values g1_i5_16 g1_i5l; 
label values g1_i5_17 g1_i5l; 
label values g1_i5_18 g1_i5l; 
label values g1_i5_19 g1_i5l; 
label values g1_i5_20 g1_i5l; 
label values g1_i5_21 g1_i5l; 
label values g1_i5_22 g1_i5l; 
label values g1_i5_23 g1_i5l; 
label values g1_i5_24 g1_i5l; 
label values g1_i5_25 g1_i5l; 
label values g1_i5_26 g1_i5l; 
label values g1_i5_27 g1_i5l; 
label values g1_i5_28 g1_i5l; 
label values g1_i5_29 g1_i5l; 
label values g1_i5_30 g1_i5l; 
label values g1_i5_31 g1_i5l; 
label values g1_i5_32 g1_i5l; 
label values g1_i5_33 g1_i5l; 
label values g1_i5_34 g1_i5l; 
label values g1_i5_35 g1_i5l; 
label values g1_i5_36 g1_i5l; 
label define g1_i5l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i6_01 g1_i6l; 
label values g1_i6_02 g1_i6l; 
label values g1_i6_03 g1_i6l; 
label values g1_i6_04 g1_i6l; 
label values g1_i6_05 g1_i6l; 
label values g1_i6_06 g1_i6l; 
label values g1_i6_07 g1_i6l; 
label values g1_i6_08 g1_i6l; 
label values g1_i6_09 g1_i6l; 
label values g1_i6_10 g1_i6l; 
label values g1_i6_11 g1_i6l; 
label values g1_i6_12 g1_i6l; 
label values g1_i6_13 g1_i6l; 
label values g1_i6_14 g1_i6l; 
label values g1_i6_15 g1_i6l; 
label values g1_i6_16 g1_i6l; 
label values g1_i6_17 g1_i6l; 
label values g1_i6_18 g1_i6l; 
label values g1_i6_19 g1_i6l; 
label values g1_i6_20 g1_i6l; 
label values g1_i6_21 g1_i6l; 
label values g1_i6_22 g1_i6l; 
label values g1_i6_23 g1_i6l; 
label values g1_i6_24 g1_i6l; 
label values g1_i6_25 g1_i6l; 
label values g1_i6_26 g1_i6l; 
label values g1_i6_27 g1_i6l; 
label values g1_i6_28 g1_i6l; 
label values g1_i6_29 g1_i6l; 
label values g1_i6_30 g1_i6l; 
label values g1_i6_31 g1_i6l; 
label values g1_i6_32 g1_i6l; 
label values g1_i6_33 g1_i6l; 
label values g1_i6_34 g1_i6l; 
label values g1_i6_35 g1_i6l; 
label values g1_i6_36 g1_i6l; 
label define g1_i6l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i7_01 g1_i7l; 
label values g1_i7_02 g1_i7l; 
label values g1_i7_03 g1_i7l; 
label values g1_i7_04 g1_i7l; 
label values g1_i7_05 g1_i7l; 
label values g1_i7_06 g1_i7l; 
label values g1_i7_07 g1_i7l; 
label values g1_i7_08 g1_i7l; 
label values g1_i7_09 g1_i7l; 
label values g1_i7_10 g1_i7l; 
label values g1_i7_11 g1_i7l; 
label values g1_i7_12 g1_i7l; 
label values g1_i7_13 g1_i7l; 
label values g1_i7_14 g1_i7l; 
label values g1_i7_15 g1_i7l; 
label values g1_i7_16 g1_i7l; 
label values g1_i7_17 g1_i7l; 
label values g1_i7_18 g1_i7l; 
label values g1_i7_19 g1_i7l; 
label values g1_i7_20 g1_i7l; 
label values g1_i7_21 g1_i7l; 
label values g1_i7_22 g1_i7l; 
label values g1_i7_23 g1_i7l; 
label values g1_i7_24 g1_i7l; 
label values g1_i7_25 g1_i7l; 
label values g1_i7_26 g1_i7l; 
label values g1_i7_27 g1_i7l; 
label values g1_i7_28 g1_i7l; 
label values g1_i7_29 g1_i7l; 
label values g1_i7_30 g1_i7l; 
label values g1_i7_31 g1_i7l; 
label values g1_i7_32 g1_i7l; 
label values g1_i7_33 g1_i7l; 
label values g1_i7_34 g1_i7l; 
label values g1_i7_35 g1_i7l; 
label values g1_i7_36 g1_i7l; 
label define g1_i7l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i8_01 g1_i8l; 
label values g1_i8_02 g1_i8l; 
label values g1_i8_03 g1_i8l; 
label values g1_i8_04 g1_i8l; 
label values g1_i8_05 g1_i8l; 
label values g1_i8_06 g1_i8l; 
label values g1_i8_07 g1_i8l; 
label values g1_i8_08 g1_i8l; 
label values g1_i8_09 g1_i8l; 
label values g1_i8_10 g1_i8l; 
label values g1_i8_11 g1_i8l; 
label values g1_i8_12 g1_i8l; 
label values g1_i8_13 g1_i8l; 
label values g1_i8_14 g1_i8l; 
label values g1_i8_15 g1_i8l; 
label values g1_i8_16 g1_i8l; 
label values g1_i8_17 g1_i8l; 
label values g1_i8_18 g1_i8l; 
label values g1_i8_19 g1_i8l; 
label values g1_i8_20 g1_i8l; 
label values g1_i8_21 g1_i8l; 
label values g1_i8_22 g1_i8l; 
label values g1_i8_23 g1_i8l; 
label values g1_i8_24 g1_i8l; 
label values g1_i8_25 g1_i8l; 
label values g1_i8_26 g1_i8l; 
label values g1_i8_27 g1_i8l; 
label values g1_i8_28 g1_i8l; 
label values g1_i8_29 g1_i8l; 
label values g1_i8_30 g1_i8l; 
label values g1_i8_31 g1_i8l; 
label values g1_i8_32 g1_i8l; 
label values g1_i8_33 g1_i8l; 
label values g1_i8_34 g1_i8l; 
label values g1_i8_35 g1_i8l; 
label values g1_i8_36 g1_i8l; 
label define g1_i8l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i9_01 g1_i9l; 
label values g1_i9_02 g1_i9l; 
label values g1_i9_03 g1_i9l; 
label values g1_i9_04 g1_i9l; 
label values g1_i9_05 g1_i9l; 
label values g1_i9_06 g1_i9l; 
label values g1_i9_07 g1_i9l; 
label values g1_i9_08 g1_i9l; 
label values g1_i9_09 g1_i9l; 
label values g1_i9_10 g1_i9l; 
label values g1_i9_11 g1_i9l; 
label values g1_i9_12 g1_i9l; 
label values g1_i9_13 g1_i9l; 
label values g1_i9_14 g1_i9l; 
label values g1_i9_15 g1_i9l; 
label values g1_i9_16 g1_i9l; 
label values g1_i9_17 g1_i9l; 
label values g1_i9_18 g1_i9l; 
label values g1_i9_19 g1_i9l; 
label values g1_i9_20 g1_i9l; 
label values g1_i9_21 g1_i9l; 
label values g1_i9_22 g1_i9l; 
label values g1_i9_23 g1_i9l; 
label values g1_i9_24 g1_i9l; 
label values g1_i9_25 g1_i9l; 
label values g1_i9_26 g1_i9l; 
label values g1_i9_27 g1_i9l; 
label values g1_i9_28 g1_i9l; 
label values g1_i9_29 g1_i9l; 
label values g1_i9_30 g1_i9l; 
label values g1_i9_31 g1_i9l; 
label values g1_i9_32 g1_i9l; 
label values g1_i9_33 g1_i9l; 
label values g1_i9_34 g1_i9l; 
label values g1_i9_35 g1_i9l; 
label values g1_i9_36 g1_i9l; 
label define g1_i9l  
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g1_i1001 g1_i10l;
label values g1_i1002 g1_i10l;
label values g1_i1003 g1_i10l;
label values g1_i1004 g1_i10l;
label values g1_i1005 g1_i10l;
label values g1_i1006 g1_i10l;
label values g1_i1007 g1_i10l;
label values g1_i1008 g1_i10l;
label values g1_i1009 g1_i10l;
label values g1_i1010 g1_i10l;
label values g1_i1011 g1_i10l;
label values g1_i1012 g1_i10l;
label values g1_i1013 g1_i10l;
label values g1_i1014 g1_i10l;
label values g1_i1015 g1_i10l;
label values g1_i1016 g1_i10l;
label values g1_i1017 g1_i10l;
label values g1_i1018 g1_i10l;
label values g1_i1019 g1_i10l;
label values g1_i1020 g1_i10l;
label values g1_i1021 g1_i10l;
label values g1_i1022 g1_i10l;
label values g1_i1023 g1_i10l;
label values g1_i1024 g1_i10l;
label values g1_i1025 g1_i10l;
label values g1_i1026 g1_i10l;
label values g1_i1027 g1_i10l;
label values g1_i1028 g1_i10l;
label values g1_i1029 g1_i10l;
label values g1_i1030 g1_i10l;
label values g1_i1031 g1_i10l;
label values g1_i1032 g1_i10l;
label values g1_i1033 g1_i10l;
label values g1_i1034 g1_i10l;
label values g1_i1035 g1_i10l;
label values g1_i1036 g1_i10l;
label define g1_i10l 
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g2i10001 g2i100l;
label values g2i10002 g2i100l;
label values g2i10003 g2i100l;
label values g2i10004 g2i100l;
label values g2i10005 g2i100l;
label values g2i10006 g2i100l;
label values g2i10007 g2i100l;
label values g2i10008 g2i100l;
label values g2i10009 g2i100l;
label values g2i10010 g2i100l;
label values g2i10011 g2i100l;
label values g2i10012 g2i100l;
label values g2i10013 g2i100l;
label values g2i10014 g2i100l;
label values g2i10015 g2i100l;
label values g2i10016 g2i100l;
label values g2i10017 g2i100l;
label values g2i10018 g2i100l;
label values g2i10019 g2i100l;
label values g2i10020 g2i100l;
label values g2i10021 g2i100l;
label values g2i10022 g2i100l;
label values g2i10023 g2i100l;
label values g2i10024 g2i100l;
label values g2i10025 g2i100l;
label values g2i10026 g2i100l;
label values g2i10027 g2i100l;
label values g2i10028 g2i100l;
label values g2i10029 g2i100l;
label values g2i10030 g2i100l;
label values g2i10031 g2i100l;
label values g2i10032 g2i100l;
label values g2i10033 g2i100l;
label values g2i10034 g2i100l;
label values g2i10035 g2i100l;
label values g2i10036 g2i100l;
label define g2i100l 
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g2i10401 g2i104l;
label values g2i10402 g2i104l;
label values g2i10403 g2i104l;
label values g2i10404 g2i104l;
label values g2i10405 g2i104l;
label values g2i10406 g2i104l;
label values g2i10407 g2i104l;
label values g2i10408 g2i104l;
label values g2i10409 g2i104l;
label values g2i10410 g2i104l;
label values g2i10411 g2i104l;
label values g2i10412 g2i104l;
label values g2i10413 g2i104l;
label values g2i10414 g2i104l;
label values g2i10415 g2i104l;
label values g2i10416 g2i104l;
label values g2i10417 g2i104l;
label values g2i10418 g2i104l;
label values g2i10419 g2i104l;
label values g2i10420 g2i104l;
label values g2i10421 g2i104l;
label values g2i10422 g2i104l;
label values g2i10423 g2i104l;
label values g2i10424 g2i104l;
label values g2i10425 g2i104l;
label values g2i10426 g2i104l;
label values g2i10427 g2i104l;
label values g2i10428 g2i104l;
label values g2i10429 g2i104l;
label values g2i10430 g2i104l;
label values g2i10431 g2i104l;
label values g2i10432 g2i104l;
label values g2i10433 g2i104l;
label values g2i10434 g2i104l;
label values g2i10435 g2i104l;
label values g2i10436 g2i104l;
label define g2i104l 
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g2i11001 g2i110l;
label values g2i11002 g2i110l;
label values g2i11003 g2i110l;
label values g2i11004 g2i110l;
label values g2i11005 g2i110l;
label values g2i11006 g2i110l;
label values g2i11007 g2i110l;
label values g2i11008 g2i110l;
label values g2i11009 g2i110l;
label values g2i11010 g2i110l;
label values g2i11011 g2i110l;
label values g2i11012 g2i110l;
label values g2i11013 g2i110l;
label values g2i11014 g2i110l;
label values g2i11015 g2i110l;
label values g2i11016 g2i110l;
label values g2i11017 g2i110l;
label values g2i11018 g2i110l;
label values g2i11019 g2i110l;
label values g2i11020 g2i110l;
label values g2i11021 g2i110l;
label values g2i11022 g2i110l;
label values g2i11023 g2i110l;
label values g2i11024 g2i110l;
label values g2i11025 g2i110l;
label values g2i11026 g2i110l;
label values g2i11027 g2i110l;
label values g2i11028 g2i110l;
label values g2i11029 g2i110l;
label values g2i11030 g2i110l;
label values g2i11031 g2i110l;
label values g2i11032 g2i110l;
label values g2i11033 g2i110l;
label values g2i11034 g2i110l;
label values g2i11035 g2i110l;
label values g2i11036 g2i110l;
label define g2i110l 
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g2i12001 g2i120l;
label values g2i12002 g2i120l;
label values g2i12003 g2i120l;
label values g2i12004 g2i120l;
label values g2i12005 g2i120l;
label values g2i12006 g2i120l;
label values g2i12007 g2i120l;
label values g2i12008 g2i120l;
label values g2i12009 g2i120l;
label values g2i12010 g2i120l;
label values g2i12011 g2i120l;
label values g2i12012 g2i120l;
label values g2i12013 g2i120l;
label values g2i12014 g2i120l;
label values g2i12015 g2i120l;
label values g2i12016 g2i120l;
label values g2i12017 g2i120l;
label values g2i12018 g2i120l;
label values g2i12019 g2i120l;
label values g2i12020 g2i120l;
label values g2i12021 g2i120l;
label values g2i12022 g2i120l;
label values g2i12023 g2i120l;
label values g2i12024 g2i120l;
label values g2i12025 g2i120l;
label values g2i12026 g2i120l;
label values g2i12027 g2i120l;
label values g2i12028 g2i120l;
label values g2i12029 g2i120l;
label values g2i12030 g2i120l;
label values g2i12031 g2i120l;
label values g2i12032 g2i120l;
label values g2i12033 g2i120l;
label values g2i12034 g2i120l;
label values g2i12035 g2i120l;
label values g2i12036 g2i120l;
label define g2i120l 
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g2i13001 g2i130l;
label values g2i13002 g2i130l;
label values g2i13003 g2i130l;
label values g2i13004 g2i130l;
label values g2i13005 g2i130l;
label values g2i13006 g2i130l;
label values g2i13007 g2i130l;
label values g2i13008 g2i130l;
label values g2i13009 g2i130l;
label values g2i13010 g2i130l;
label values g2i13011 g2i130l;
label values g2i13012 g2i130l;
label values g2i13013 g2i130l;
label values g2i13014 g2i130l;
label values g2i13015 g2i130l;
label values g2i13016 g2i130l;
label values g2i13017 g2i130l;
label values g2i13018 g2i130l;
label values g2i13019 g2i130l;
label values g2i13020 g2i130l;
label values g2i13021 g2i130l;
label values g2i13022 g2i130l;
label values g2i13023 g2i130l;
label values g2i13024 g2i130l;
label values g2i13025 g2i130l;
label values g2i13026 g2i130l;
label values g2i13027 g2i130l;
label values g2i13028 g2i130l;
label values g2i13029 g2i130l;
label values g2i13030 g2i130l;
label values g2i13031 g2i130l;
label values g2i13032 g2i130l;
label values g2i13033 g2i130l;
label values g2i13034 g2i130l;
label values g2i13035 g2i130l;
label values g2i13036 g2i130l;
label define g2i130l 
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;
label values g2i14001 g2i140l;
label values g2i14002 g2i140l;
label values g2i14003 g2i140l;
label values g2i14004 g2i140l;
label values g2i14005 g2i140l;
label values g2i14006 g2i140l;
label values g2i14007 g2i140l;
label values g2i14008 g2i140l;
label values g2i14009 g2i140l;
label values g2i14010 g2i140l;
label values g2i14011 g2i140l;
label values g2i14012 g2i140l;
label values g2i14013 g2i140l;
label values g2i14014 g2i140l;
label values g2i14015 g2i140l;
label values g2i14016 g2i140l;
label values g2i14017 g2i140l;
label values g2i14018 g2i140l;
label values g2i14019 g2i140l;
label values g2i14020 g2i140l;
label values g2i14021 g2i140l;
label values g2i14022 g2i140l;
label values g2i14023 g2i140l;
label values g2i14024 g2i140l;
label values g2i14025 g2i140l;
label values g2i14026 g2i140l;
label values g2i14027 g2i140l;
label values g2i14028 g2i140l;
label values g2i14029 g2i140l;
label values g2i14030 g2i140l;
label values g2i14031 g2i140l;
label values g2i14032 g2i140l;
label values g2i14033 g2i140l;
label values g2i14034 g2i140l;
label values g2i14035 g2i140l;
label values g2i14036 g2i140l;
label define g2i140l 
	0           "No imputations, not"           
	1           "Monthly amount imputed"        
;

#delimit cr
save `dta_name' , replace

/*
Copyright 2009 shared by the National Bureau of Economic Research and Jean Roth

National Bureau of Economic Research.
1050 Massachusetts Avenue
Cambridge, MA 02138
jroth@nber.org

This program and all programs referenced in it are free software. You
can redistribute the program or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
USA.
*/
