log using sip84fp, text replace
set mem 1000m
*This program reads the 1984 SIPP Full Panel Data File 

****************************************************************
*
* NOTE: This complete dataset has over more than 2,047 variables,
* the maximum number of variables for Intercooled Stata 8.0. 
* So, variables at the end are commented out.  The commenting 
* can be removed in an editor by replacing '' with ''.
* Stata/SE can handle up to 32,766 variables, default=5000.
*
****************************************************************

*Note:  This program is distributed under the GNU GPL. See end of
*this file and http://www.gnu.org/licenses/ for details.
*by Jean Roth Wed Jun  9 16:58:40 EDT 2004
*Please report errors to jroth@nber.org
*run with do sip84fp
*Change output file name/location as desired in the first line of the .dct file
*If you are using a PC, you may need to change the direction of the slashes, as in C:\
*  or "\\Nber\home\data\sipp\1984\sip84fp.dat"
* The following changes in variable names have been made, if necessary:
*      '$' to 'd';            '-' to '_';              '%' to 'p';
*For compatibility with other software, variable label definitions are the
*variable name unless the variable name ends in a digit. 
*'1' -> 'a', '2' -> 'b', '3' -> 'c', ... , '0' -> 'j'
* Note:  Variable names in Stata are case-sensitive
clear
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP
quietly infile using sipp84fp

*Everything below this point are value labels

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
label define pp_intv 
	0           "Not applicable (children"      
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
label define pp_mis  
	0           "Not matched or not in sample"  
	1           "Interview"                     
	2           "Noninterview"                  
;
label values reaslef1 reaslef;
label values reaslef2 reaslef;
label values reaslef3 reaslef;
label values reaslef4 reaslef;
label values reaslef5 reaslef;
label values reaslef6 reaslef;
label values reaslef7 reaslef;
label values reaslef8 reaslef;
label define reaslef 
	0           "Not applicable or not answered or"
	1           "Left - Deceased"               
	2           "Left - Institutionalized"      
	3           "Left - Living in Armed Forces barracks"
	4           "Left - Moved outside of country"
	5           "Left - Separation or divorce"  
	6           "Left - Person #201 or greater no"
	7           "Left - Other"                  
	8           "Entered merged household"      
	9           "Interviewed in previous Wave but"
;
label values su_rgc   su_rgc; 
label define su_rgc  
	0           "Not applicable for coverage"   
	101         "Applicable for coverage"       
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
label define lgthht  
	0           "Not available or not in a"     
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
label define lgtkey  
	0           "This is not a key person"      
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
label define lgtoth  
	0           "This is not an 'other' person" 
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
label define rrp     
	0           "Not a sample person in this"   
	1           "Household reference person,"   
	2           "Household reference person living"
	3           "Spouse of household reference" 
	4           "Child of household reference"  
	5           "Other relative of household"   
	6           "Nonrelative of household reference"
	7           "Nonrelative of household reference"
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
label define age     
	0           "Less than 1 full year or not a"
	1           "1 year"                        
	2           "2 years"                       
	85          "85 years or more"              
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
label define famtyp  
	0           "Primary family or not a sample"
	1           "Secondary individual (not a family"
	2           "Unrelated sub (secondary) family"
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
label define famrel  
	0           "Not applicable, not in sample,"
	1           "Reference person of family"    
	2           "Spouse of family reference person"
	3           "Child of family reference person"
	4           "Other relative of family reference"
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
label define pnsp    
	0           "Not a sample person in this"   
	999         "Not applicable"                
;
label values ent_sp01 ent_sp; 
label values ent_sp02 ent_sp; 
label values ent_sp03 ent_sp; 
label values ent_sp04 ent_sp; 
label values ent_sp05 ent_sp; 
label values ent_sp06 ent_sp; 
label values ent_sp07 ent_sp; 
label values ent_sp08 ent_sp; 
label values ent_sp09 ent_sp; 
label values ent_sp10 ent_sp; 
label values ent_sp11 ent_sp; 
label values ent_sp12 ent_sp; 
label values ent_sp13 ent_sp; 
label values ent_sp14 ent_sp; 
label values ent_sp15 ent_sp; 
label values ent_sp16 ent_sp; 
label values ent_sp17 ent_sp; 
label values ent_sp18 ent_sp; 
label values ent_sp19 ent_sp; 
label values ent_sp20 ent_sp; 
label values ent_sp21 ent_sp; 
label values ent_sp22 ent_sp; 
label values ent_sp23 ent_sp; 
label values ent_sp24 ent_sp; 
label values ent_sp25 ent_sp; 
label values ent_sp26 ent_sp; 
label values ent_sp27 ent_sp; 
label values ent_sp28 ent_sp; 
label values ent_sp29 ent_sp; 
label values ent_sp30 ent_sp; 
label values ent_sp31 ent_sp; 
label values ent_sp32 ent_sp; 
label define ent_sp  
	0           "Not a sample person in this"   
	99          "Not applicable"                
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
label define pnpt    
	0           "Not a sample person in this"   
	999         "Not applicable"                
;
label values ent_pt01 ent_pt; 
label values ent_pt02 ent_pt; 
label values ent_pt03 ent_pt; 
label values ent_pt04 ent_pt; 
label values ent_pt05 ent_pt; 
label values ent_pt06 ent_pt; 
label values ent_pt07 ent_pt; 
label values ent_pt08 ent_pt; 
label values ent_pt09 ent_pt; 
label values ent_pt10 ent_pt; 
label values ent_pt11 ent_pt; 
label values ent_pt12 ent_pt; 
label values ent_pt13 ent_pt; 
label values ent_pt14 ent_pt; 
label values ent_pt15 ent_pt; 
label values ent_pt16 ent_pt; 
label values ent_pt17 ent_pt; 
label values ent_pt18 ent_pt; 
label values ent_pt19 ent_pt; 
label values ent_pt20 ent_pt; 
label values ent_pt21 ent_pt; 
label values ent_pt22 ent_pt; 
label values ent_pt23 ent_pt; 
label values ent_pt24 ent_pt; 
label values ent_pt25 ent_pt; 
label values ent_pt26 ent_pt; 
label values ent_pt27 ent_pt; 
label values ent_pt28 ent_pt; 
label values ent_pt29 ent_pt; 
label values ent_pt30 ent_pt; 
label values ent_pt31 ent_pt; 
label values ent_pt32 ent_pt; 
label define ent_pt  
	0           "Not a sample person in this"   
	99          "Not applicable"                
;
label values higrade1 higrade;
label values higrade2 higrade;
label values higrade3 higrade;
label values higrade4 higrade;
label values higrade5 higrade;
label values higrade6 higrade;
label values higrade7 higrade;
label values higrade8 higrade;
label define higrade 
	0           "Not applicable if under 15,"   
;
label values grd_cmp1 grd_cmp;
label values grd_cmp2 grd_cmp;
label values grd_cmp3 grd_cmp;
label values grd_cmp4 grd_cmp;
label values grd_cmp5 grd_cmp;
label values grd_cmp6 grd_cmp;
label values grd_cmp7 grd_cmp;
label values grd_cmp8 grd_cmp;
label define grd_cmp 
	0           "Not applicable, not in sample,"
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
label define in_af   
	0           "Not applicable if under 15,"   
	1           "Yes"                           
	2           "No"                            
;
label values usrve_1  usrve;  
label values usrve_2  usrve;  
label values usrve_3  usrve;  
label values usrve_4  usrve;  
label values usrve_5  usrve;  
label values usrve_6  usrve;  
label values usrve_7  usrve;  
label values usrve_8  usrve;  
label define usrve   
	0           "Not applicable, not in sample,"
	1           "Vietnam Era (August 1964-"     
	2           "Korean Conflict (June 1950-"   
	3           "World War II (September 1940-" 
	4           "World War I (April 1917-"      
	5           "May 1975 or later"             
	6           "Other service"                 
	9           "Not answered"                  
;
label values u_brthmn u_brthmn;
label define u_brthmn
	-9          "Not answered"                  
	1           "January"                       
	2           "February"                      
	12          "December"                      
;
label values u_brthyr u_brthyr;
label define u_brthyr
	-009        "Not answered"                  
	1901        "1901 or earlier"               
;
label values u_pngd1  u_pngd; 
label values u_pngd2  u_pngd; 
label values u_pngd3  u_pngd; 
label values u_pngd4  u_pngd; 
label values u_pngd5  u_pngd; 
label values u_pngd6  u_pngd; 
label values u_pngd7  u_pngd; 
label values u_pngd8  u_pngd; 
label define u_pngd  
	0           "Not in universe, not in"       
	999         "Not applicable"                
	-09         "Not answered"                  
;
label values entid_g1 entid_g;
label values entid_g2 entid_g;
label values entid_g3 entid_g;
label values entid_g4 entid_g;
label values entid_g5 entid_g;
label values entid_g6 entid_g;
label values entid_g7 entid_g;
label values entid_g8 entid_g;
label define entid_g 
	0           "Not in universe, not in sample,"
	99          "Not applicable or not answered"
;
label values lvqtr_01 lvqtr;  
label values lvqtr_02 lvqtr;  
label values lvqtr_03 lvqtr;  
label values lvqtr_04 lvqtr;  
label values lvqtr_05 lvqtr;  
label values lvqtr_06 lvqtr;  
label values lvqtr_07 lvqtr;  
label values lvqtr_08 lvqtr;  
label values lvqtr_09 lvqtr;  
label values lvqtr_10 lvqtr;  
label values lvqtr_11 lvqtr;  
label values lvqtr_12 lvqtr;  
label values lvqtr_13 lvqtr;  
label values lvqtr_14 lvqtr;  
label values lvqtr_15 lvqtr;  
label values lvqtr_16 lvqtr;  
label values lvqtr_17 lvqtr;  
label values lvqtr_18 lvqtr;  
label values lvqtr_19 lvqtr;  
label values lvqtr_20 lvqtr;  
label values lvqtr_21 lvqtr;  
label values lvqtr_22 lvqtr;  
label values lvqtr_23 lvqtr;  
label values lvqtr_24 lvqtr;  
label values lvqtr_25 lvqtr;  
label values lvqtr_26 lvqtr;  
label values lvqtr_27 lvqtr;  
label values lvqtr_28 lvqtr;  
label values lvqtr_29 lvqtr;  
label values lvqtr_30 lvqtr;  
label values lvqtr_31 lvqtr;  
label values lvqtr_32 lvqtr;  
label define lvqtr   
	0           "Not applicable, not in sample,"
	1           "House, apartment, flat"        
	2           "Housing unit in nontransient hotel,"
	3           "Housing unit, permanent in"    
	4           "Housing unit in rooming house" 
	5           "Mobile home or trailer with no"
	6           "Mobile home or trailer with one"
	7           "Housing unit not specified above"
	8           "Quarters not housing unit in"  
	9           "Housing unit not permanent in" 
	10          "Unoccupied tent or trailer site"
	11          "Other unit not specified above"
;
label values tenur_01 tenur;  
label values tenur_02 tenur;  
label values tenur_03 tenur;  
label values tenur_04 tenur;  
label values tenur_05 tenur;  
label values tenur_06 tenur;  
label values tenur_07 tenur;  
label values tenur_08 tenur;  
label values tenur_09 tenur;  
label values tenur_10 tenur;  
label values tenur_11 tenur;  
label values tenur_12 tenur;  
label values tenur_13 tenur;  
label values tenur_14 tenur;  
label values tenur_15 tenur;  
label values tenur_16 tenur;  
label values tenur_17 tenur;  
label values tenur_18 tenur;  
label values tenur_19 tenur;  
label values tenur_20 tenur;  
label values tenur_21 tenur;  
label values tenur_22 tenur;  
label values tenur_23 tenur;  
label values tenur_24 tenur;  
label values tenur_25 tenur;  
label values tenur_26 tenur;  
label values tenur_27 tenur;  
label values tenur_28 tenur;  
label values tenur_29 tenur;  
label values tenur_30 tenur;  
label values tenur_31 tenur;  
label values tenur_32 tenur;  
label define tenur   
	0           "Not in sample or nonmatch?"    
	1           "Owned or being bought by someone"
	2           "Rented for cash?"              
	3           "Occupied without payment of"   
;
label values pubhs_01 pubhs;  
label values pubhs_02 pubhs;  
label values pubhs_03 pubhs;  
label values pubhs_04 pubhs;  
label values pubhs_05 pubhs;  
label values pubhs_06 pubhs;  
label values pubhs_07 pubhs;  
label values pubhs_08 pubhs;  
label values pubhs_09 pubhs;  
label values pubhs_10 pubhs;  
label values pubhs_11 pubhs;  
label values pubhs_12 pubhs;  
label values pubhs_13 pubhs;  
label values pubhs_14 pubhs;  
label values pubhs_15 pubhs;  
label values pubhs_16 pubhs;  
label values pubhs_17 pubhs;  
label values pubhs_18 pubhs;  
label values pubhs_19 pubhs;  
label values pubhs_20 pubhs;  
label values pubhs_21 pubhs;  
label values pubhs_22 pubhs;  
label values pubhs_23 pubhs;  
label values pubhs_24 pubhs;  
label values pubhs_25 pubhs;  
label values pubhs_26 pubhs;  
label values pubhs_27 pubhs;  
label values pubhs_28 pubhs;  
label values pubhs_29 pubhs;  
label values pubhs_30 pubhs;  
label values pubhs_31 pubhs;  
label values pubhs_32 pubhs;  
label define pubhs   
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values lornt_01 lornt;  
label values lornt_02 lornt;  
label values lornt_03 lornt;  
label values lornt_04 lornt;  
label values lornt_05 lornt;  
label values lornt_06 lornt;  
label values lornt_07 lornt;  
label values lornt_08 lornt;  
label values lornt_09 lornt;  
label values lornt_10 lornt;  
label values lornt_11 lornt;  
label values lornt_12 lornt;  
label values lornt_13 lornt;  
label values lornt_14 lornt;  
label values lornt_15 lornt;  
label values lornt_16 lornt;  
label values lornt_17 lornt;  
label values lornt_18 lornt;  
label values lornt_19 lornt;  
label values lornt_20 lornt;  
label values lornt_21 lornt;  
label values lornt_22 lornt;  
label values lornt_23 lornt;  
label values lornt_24 lornt;  
label values lornt_25 lornt;  
label values lornt_26 lornt;  
label values lornt_27 lornt;  
label values lornt_28 lornt;  
label values lornt_29 lornt;  
label values lornt_30 lornt;  
label values lornt_31 lornt;  
label values lornt_32 lornt;  
label define lornt   
	0           "Not applicable, not"           
	1           "Yes"                           
	2           "No"                            
;
label values enrgy_y1 enrgy_y;
label values enrgy_y2 enrgy_y;
label values enrgy_y3 enrgy_y;
label values enrgy_y4 enrgy_y;
label values enrgy_y5 enrgy_y;
label values enrgy_y6 enrgy_y;
label values enrgy_y7 enrgy_y;
label values enrgy_y8 enrgy_y;
label define enrgy_y 
	0           "Not in universe, not in a sample"
	1           "Yes"                           
	2           "No"                            
;
label values hs_enrg1 hs_enrg;
label values hs_enrg2 hs_enrg;
label values hs_enrg3 hs_enrg;
label values hs_enrg4 hs_enrg;
label values hs_enrg5 hs_enrg;
label values hs_enrg6 hs_enrg;
label values hs_enrg7 hs_enrg;
label values hs_enrg8 hs_enrg;
label define hs_enrg 
	0           "Not applicable, not in a sample"
	1           "Checks sent to household"      
	2           "Coupons or vouchers sent to household"
	3           "Payments sent elsewhere"       
	4           "Checks and coupons or vouchers sent to"
	5           "Checks sent to household and payments"
	6           "Coupons or voucher sent to household"
	7           "All three types of assistance" 
;
label values enrgy_1  enrgy;  
label values enrgy_2  enrgy;  
label values enrgy_3  enrgy;  
label values enrgy_4  enrgy;  
label values enrgy_5  enrgy;  
label values enrgy_6  enrgy;  
label values enrgy_7  enrgy;  
label values enrgy_8  enrgy;  
label define enrgy   
	0           "Not in universe, not in"       
;
label values hs_lunc1 hs_lunc;
label values hs_lunc2 hs_lunc;
label values hs_lunc3 hs_lunc;
label values hs_lunc4 hs_lunc;
label values hs_lunc5 hs_lunc;
label values hs_lunc6 hs_lunc;
label values hs_lunc7 hs_lunc;
label values hs_lunc8 hs_lunc;
label define hs_lunc 
	0           "Not applicable, not in sample" 
	1           "Free"                          
	2           "Reduced-price"                 
	3           "Both"                          
;
label values lunch_1  lunch;  
label values lunch_2  lunch;  
label values lunch_3  lunch;  
label values lunch_4  lunch;  
label values lunch_5  lunch;  
label values lunch_6  lunch;  
label values lunch_7  lunch;  
label values lunch_8  lunch;  
label define lunch   
	0           "Not in universe, not in"       
;
label values break_1  break;  
label values break_2  break;  
label values break_3  break;  
label values break_4  break;  
label values break_5  break;  
label values break_6  break;  
label values break_7  break;  
label values break_8  break;  
label define break   
	0           "Not applicable, not in sample" 
	1           "Free"                          
	2           "Reduced-price"                 
	3           "Both"                          
;
label values h8_48301 h8_4830l;
label values h8_48302 h8_4830l;
label values h8_48303 h8_4830l;
label values h8_48304 h8_4830l;
label values h8_48305 h8_4830l;
label values h8_48306 h8_4830l;
label values h8_48307 h8_4830l;
label values h8_48308 h8_4830l;
label define h8_4830l
	0           "Not in universe, not in"       
;
label values hs_pubhs hs_pubhs;
label define hs_pubhs
	0           "Not in sample in Wave 1"       
	1           "Yes"                           
	2           "No"                            
;
label values pubrnamt pubrnamt;
label define pubrnamt
	0           "Not applicable"                
;
label values utlpayyn utlpayyn;
label define utlpayyn
	0           "Not applicable"                
	1           "Yes"                           
	2           "No"                            
;
label values fullrent fullrent;
label define fullrent
	0           "Not in universe"               
;
label values state_1  state;  
label values state_2  state;  
label values state_3  state;  
label values state_4  state;  
label values state_5  state;  
label values state_6  state;  
label values state_7  state;  
label values state_8  state;  
label define state   
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
	19          "Iowa"                          
	20          "Kansas"                        
	21          "Kentucky"                      
	22          "Louisiana"                     
	23          "Maine"                         
	24          "Maryland"                      
	25          "Massachusetts"                 
	26          "Michigan"                      
	27          "Minnesota"                     
	29          "Missouri"                      
	30          "Montana"                       
	31          "Nebraska"                      
	32          "Nevada"                        
	33          "New Hampshire"                 
	34          "New Jersey"                    
	36          "New York"                      
	37          "North Carolina"                
	38          "North Dakota"                  
	39          "Ohio"                          
	40          "Oklahoma"                      
	41          "Oregon"                        
	42          "Pennsylvania"                  
	44          "Rhode Island"                  
	45          "South Carolina"                
	47          "Tennessee"                     
	48          "Texas"                         
	49          "Utah"                          
	50          "Vermont"                       
	51          "Virginia"                      
	53          "Washington"                    
	55          "Wisconsin"                     
	57          "Mississippi and West Virginia" 
	58          "Idaho, New Mexico, South Dakota,"
;
label values metro_1  metro;  
label values metro_2  metro;  
label values metro_3  metro;  
label values metro_4  metro;  
label values metro_5  metro;  
label values metro_6  metro;  
label values metro_7  metro;  
label values metro_8  metro;  
label define metro   
	0           "Not in sample or nonmatch"     
	1           "Central city of an MSA or PMSA"
	2           "In an MSA or PMSA but not"     
	3           "Not in an MSA or PMSA"         
;
label values sc1332   sc1332l;
label define sc1332l 
	0           "Not in universe, not in"       
	1           "Less than 6 months"            
	2           "6 to 23 months"                
	3           "2 to 19 years"                 
	4           "20 or more years"              
	-1          "Don't know"                    
;
label values sc1334   sc1334l;
label define sc1334l 
	0           "Not in universe, not in"       
	1           "Yes"                           
	2           "No"                            
	-1          "Don't know"                    
;
label values sc1336   sc1336l;
label define sc1336l 
	0           "Not in universe, not in"       
	1           "1 percent to 10 percent"       
	2           "11 percent to 29 percent"      
	3           "30 percent to 49 percent"      
	4           "50 percent"                    
	5           "51 percent to 89 percent"      
	6           "90 percent to 99 percent"      
	7           "100 percent"                   
	101         "No rating"                     
	-1          "Don't know"                    
	-2          "Refused"                       
	-3          "0 percent"                     
;
label values sc1346   sc1346l;
label define sc1346l 
	0           "Not in universe, not in sample,"
	1           "Retired?"                      
	2           "Disabled?"                     
	3           "Widow(ed) or surviving child?" 
	4           "Spouse or dependent child?"    
	5           "Some other reason"             
	-1          "Don't know"                    
;
label values sc1348   sc1348l;
label define sc1348l 
	0           "Not in universe, not in sample,"
	1           "Retired"                       
	2           "Disabled"                      
	3           "Widow(ed) or surviving child"  
	4           "Spouse or dependent child"     
	5           "No other reason"               
	-1          "Don't know"                    
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
	2           "Yes, from service-related injury"
	3           "No"                            
;
label values sc1468   sc1468l;
label define sc1468l 
	0           "Not in universe or card not"   
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
	-1          "Don't know"                    
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
label define att_sch 
	0           "Not in universe, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values sc168201 sc1682l;
label values sc168202 sc1682l;
label values sc168203 sc1682l;
label values sc168204 sc1682l;
label values sc168205 sc1682l;
label values sc168206 sc1682l;
label values sc168207 sc1682l;
label values sc168208 sc1682l;
label values sc168209 sc1682l;
label values sc168210 sc1682l;
label values sc168211 sc1682l;
label values sc168212 sc1682l;
label values sc168213 sc1682l;
label values sc168214 sc1682l;
label values sc168215 sc1682l;
label values sc168216 sc1682l;
label values sc168217 sc1682l;
label values sc168218 sc1682l;
label values sc168219 sc1682l;
label values sc168220 sc1682l;
label values sc168221 sc1682l;
label values sc168222 sc1682l;
label values sc168223 sc1682l;
label values sc168224 sc1682l;
label values sc168225 sc1682l;
label values sc168226 sc1682l;
label values sc168227 sc1682l;
label values sc168228 sc1682l;
label values sc168229 sc1682l;
label values sc168230 sc1682l;
label values sc168231 sc1682l;
label values sc168232 sc1682l;
label define sc1682l 
	0           "Not in universe, not in sample,"
;
label values sc169001 sc1690l;
label values sc169002 sc1690l;
label values sc169003 sc1690l;
label values sc169004 sc1690l;
label values sc169005 sc1690l;
label values sc169006 sc1690l;
label values sc169007 sc1690l;
label values sc169008 sc1690l;
label values sc169009 sc1690l;
label values sc169010 sc1690l;
label values sc169011 sc1690l;
label values sc169012 sc1690l;
label values sc169013 sc1690l;
label values sc169014 sc1690l;
label values sc169015 sc1690l;
label values sc169016 sc1690l;
label values sc169017 sc1690l;
label values sc169018 sc1690l;
label values sc169019 sc1690l;
label values sc169020 sc1690l;
label values sc169021 sc1690l;
label values sc169022 sc1690l;
label values sc169023 sc1690l;
label values sc169024 sc1690l;
label values sc169025 sc1690l;
label values sc169026 sc1690l;
label values sc169027 sc1690l;
label values sc169028 sc1690l;
label values sc169029 sc1690l;
label values sc169030 sc1690l;
label values sc169031 sc1690l;
label values sc169032 sc1690l;
label define sc1690l 
	0           "Not in universe, not in sample,"
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
label define esr     
	0           "Not applicable, not in sample,"
	1           "With a job entire month, worked"
	2           "With a job entire month, missed"
	3           "With a job entire month, missed"
	4           "With job one or more weeks, no"
	5           "With job one or more weeks, spent"
	6           "No job during month, spent entire"
	7           "No job during month, spent one or"
	8           "No job during month, no time spent"
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
label define wksper  
	0           " Not applicable, not in sample,"
	4           "4 weeks"                       
	5           "5 weeks"                       
;
label values wksjb_01 wksjb;  
label values wksjb_02 wksjb;  
label values wksjb_03 wksjb;  
label values wksjb_04 wksjb;  
label values wksjb_05 wksjb;  
label values wksjb_06 wksjb;  
label values wksjb_07 wksjb;  
label values wksjb_08 wksjb;  
label values wksjb_09 wksjb;  
label values wksjb_10 wksjb;  
label values wksjb_11 wksjb;  
label values wksjb_12 wksjb;  
label values wksjb_13 wksjb;  
label values wksjb_14 wksjb;  
label values wksjb_15 wksjb;  
label values wksjb_16 wksjb;  
label values wksjb_17 wksjb;  
label values wksjb_18 wksjb;  
label values wksjb_19 wksjb;  
label values wksjb_20 wksjb;  
label values wksjb_21 wksjb;  
label values wksjb_22 wksjb;  
label values wksjb_23 wksjb;  
label values wksjb_24 wksjb;  
label values wksjb_25 wksjb;  
label values wksjb_26 wksjb;  
label values wksjb_27 wksjb;  
label values wksjb_28 wksjb;  
label values wksjb_29 wksjb;  
label values wksjb_30 wksjb;  
label values wksjb_31 wksjb;  
label values wksjb_32 wksjb;  
label define wksjb   
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
label define mthwop  
	0           "0 weeks or not applicable,"    
	1           "1 week"                        
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks (only applicable for"  
;
label values weeksl01 weeksl; 
label values weeksl02 weeksl; 
label values weeksl03 weeksl; 
label values weeksl04 weeksl; 
label values weeksl05 weeksl; 
label values weeksl06 weeksl; 
label values weeksl07 weeksl; 
label values weeksl08 weeksl; 
label values weeksl09 weeksl; 
label values weeksl10 weeksl; 
label values weeksl11 weeksl; 
label values weeksl12 weeksl; 
label values weeksl13 weeksl; 
label values weeksl14 weeksl; 
label values weeksl15 weeksl; 
label values weeksl16 weeksl; 
label values weeksl17 weeksl; 
label values weeksl18 weeksl; 
label values weeksl19 weeksl; 
label values weeksl20 weeksl; 
label values weeksl21 weeksl; 
label values weeksl22 weeksl; 
label values weeksl23 weeksl; 
label values weeksl24 weeksl; 
label values weeksl25 weeksl; 
label values weeksl26 weeksl; 
label values weeksl27 weeksl; 
label values weeksl28 weeksl; 
label values weeksl29 weeksl; 
label values weeksl30 weeksl; 
label values weeksl31 weeksl; 
label values weeksl32 weeksl; 
label define weeksl  
	0           "None or not applicable, not in"
	1           "1 week"                        
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks (only applicable for"  
;
label values sc12301  sc1230l;
label values sc12302  sc1230l;
label values sc12303  sc1230l;
label values sc12304  sc1230l;
label values sc12305  sc1230l;
label values sc12306  sc1230l;
label values sc12307  sc1230l;
label values sc12308  sc1230l;
label define sc1230l 
	0           "Not in universe"               
	-3          "None"                          
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
label define clswk2l 
	0           "Not in universe, not in sample,"
	1           "A private company or individual"
	2           "Federal Government (exclude"   
	3           "State government"              
	4           "Local government"              
	5           "Armed Forces"                  
	6           "Unpaid in family business or farm"
;
label values ws2_wk01 ws2_wk; 
label values ws2_wk02 ws2_wk; 
label values ws2_wk03 ws2_wk; 
label values ws2_wk04 ws2_wk; 
label values ws2_wk05 ws2_wk; 
label values ws2_wk06 ws2_wk; 
label values ws2_wk07 ws2_wk; 
label values ws2_wk08 ws2_wk; 
label values ws2_wk09 ws2_wk; 
label values ws2_wk10 ws2_wk; 
label values ws2_wk11 ws2_wk; 
label values ws2_wk12 ws2_wk; 
label values ws2_wk13 ws2_wk; 
label values ws2_wk14 ws2_wk; 
label values ws2_wk15 ws2_wk; 
label values ws2_wk16 ws2_wk; 
label values ws2_wk17 ws2_wk; 
label values ws2_wk18 ws2_wk; 
label values ws2_wk19 ws2_wk; 
label values ws2_wk20 ws2_wk; 
label values ws2_wk21 ws2_wk; 
label values ws2_wk22 ws2_wk; 
label values ws2_wk23 ws2_wk; 
label values ws2_wk24 ws2_wk; 
label values ws2_wk25 ws2_wk; 
label values ws2_wk26 ws2_wk; 
label values ws2_wk27 ws2_wk; 
label values ws2_wk28 ws2_wk; 
label values ws2_wk29 ws2_wk; 
label values ws2_wk30 ws2_wk; 
label values ws2_wk31 ws2_wk; 
label values ws2_wk32 ws2_wk; 
label define ws2_wk  
	0           "None or not in universe if"    
	1           "1 week"                        
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks"                       
;
label values w2124_01 w2124l; 
label values w2124_02 w2124l; 
label values w2124_03 w2124l; 
label values w2124_04 w2124l; 
label values w2124_05 w2124l; 
label values w2124_06 w2124l; 
label values w2124_07 w2124l; 
label values w2124_08 w2124l; 
label values w2124_09 w2124l; 
label values w2124_10 w2124l; 
label values w2124_11 w2124l; 
label values w2124_12 w2124l; 
label values w2124_13 w2124l; 
label values w2124_14 w2124l; 
label values w2124_15 w2124l; 
label values w2124_16 w2124l; 
label values w2124_17 w2124l; 
label values w2124_18 w2124l; 
label values w2124_19 w2124l; 
label values w2124_20 w2124l; 
label values w2124_21 w2124l; 
label values w2124_22 w2124l; 
label values w2124_23 w2124l; 
label values w2124_24 w2124l; 
label values w2124_25 w2124l; 
label values w2124_26 w2124l; 
label values w2124_27 w2124l; 
label values w2124_28 w2124l; 
label values w2124_29 w2124l; 
label values w2124_30 w2124l; 
label values w2124_31 w2124l; 
label values w2124_32 w2124l; 
label define w2124l  
	0           "Not in universe, not in sample,"
	-3          "None"                          
;
label values w2128_01 w2128l; 
label values w2128_02 w2128l; 
label values w2128_03 w2128l; 
label values w2128_04 w2128l; 
label values w2128_05 w2128l; 
label values w2128_06 w2128l; 
label values w2128_07 w2128l; 
label values w2128_08 w2128l; 
label values w2128_09 w2128l; 
label values w2128_10 w2128l; 
label values w2128_11 w2128l; 
label values w2128_12 w2128l; 
label values w2128_13 w2128l; 
label values w2128_14 w2128l; 
label values w2128_15 w2128l; 
label values w2128_16 w2128l; 
label values w2128_17 w2128l; 
label values w2128_18 w2128l; 
label values w2128_19 w2128l; 
label values w2128_20 w2128l; 
label values w2128_21 w2128l; 
label values w2128_22 w2128l; 
label values w2128_23 w2128l; 
label values w2128_24 w2128l; 
label values w2128_25 w2128l; 
label values w2128_26 w2128l; 
label values w2128_27 w2128l; 
label values w2128_28 w2128l; 
label values w2128_29 w2128l; 
label values w2128_30 w2128l; 
label values w2128_31 w2128l; 
label values w2128_32 w2128l; 
label define w2128l  
	0           "Not in universe, not in sample,"
;
label values s2302_01 s2302l; 
label values s2302_02 s2302l; 
label values s2302_03 s2302l; 
label values s2302_04 s2302l; 
label values s2302_05 s2302l; 
label values s2302_06 s2302l; 
label values s2302_07 s2302l; 
label values s2302_08 s2302l; 
label values s2302_09 s2302l; 
label values s2302_10 s2302l; 
label values s2302_11 s2302l; 
label values s2302_12 s2302l; 
label values s2302_13 s2302l; 
label values s2302_14 s2302l; 
label values s2302_15 s2302l; 
label values s2302_16 s2302l; 
label values s2302_17 s2302l; 
label values s2302_18 s2302l; 
label values s2302_19 s2302l; 
label values s2302_20 s2302l; 
label values s2302_21 s2302l; 
label values s2302_22 s2302l; 
label values s2302_23 s2302l; 
label values s2302_24 s2302l; 
label values s2302_25 s2302l; 
label values s2302_26 s2302l; 
label values s2302_27 s2302l; 
label values s2302_28 s2302l; 
label values s2302_29 s2302l; 
label values s2302_30 s2302l; 
label values s2302_31 s2302l; 
label values s2302_32 s2302l; 
label define s2302l  
	0           "Not in universe, not in sample,"
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
label define typbs2l 
	0           "Not in universe, not in sample,"
	1           "Sole proprietorship"           
	2           "Partnership"                   
	3           "Corporation"                   
;
label values se2_wk01 se2_wk; 
label values se2_wk02 se2_wk; 
label values se2_wk03 se2_wk; 
label values se2_wk04 se2_wk; 
label values se2_wk05 se2_wk; 
label values se2_wk06 se2_wk; 
label values se2_wk07 se2_wk; 
label values se2_wk08 se2_wk; 
label values se2_wk09 se2_wk; 
label values se2_wk10 se2_wk; 
label values se2_wk11 se2_wk; 
label values se2_wk12 se2_wk; 
label values se2_wk13 se2_wk; 
label values se2_wk14 se2_wk; 
label values se2_wk15 se2_wk; 
label values se2_wk16 se2_wk; 
label values se2_wk17 se2_wk; 
label values se2_wk18 se2_wk; 
label values se2_wk19 se2_wk; 
label values se2_wk20 se2_wk; 
label values se2_wk21 se2_wk; 
label values se2_wk22 se2_wk; 
label values se2_wk23 se2_wk; 
label values se2_wk24 se2_wk; 
label values se2_wk25 se2_wk; 
label values se2_wk26 se2_wk; 
label values se2_wk27 se2_wk; 
label values se2_wk28 se2_wk; 
label values se2_wk29 se2_wk; 
label values se2_wk30 se2_wk; 
label values se2_wk31 se2_wk; 
label values se2_wk32 se2_wk; 
label define se2_wk  
	0           "None, not in universe, not in sample,"
	1           "1 week"                        
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks"                       
;
label values s2312_01 s2312l; 
label values s2312_02 s2312l; 
label values s2312_03 s2312l; 
label values s2312_04 s2312l; 
label values s2312_05 s2312l; 
label values s2312_06 s2312l; 
label values s2312_07 s2312l; 
label values s2312_08 s2312l; 
label values s2312_09 s2312l; 
label values s2312_10 s2312l; 
label values s2312_11 s2312l; 
label values s2312_12 s2312l; 
label values s2312_13 s2312l; 
label values s2312_14 s2312l; 
label values s2312_15 s2312l; 
label values s2312_16 s2312l; 
label values s2312_17 s2312l; 
label values s2312_18 s2312l; 
label values s2312_19 s2312l; 
label values s2312_20 s2312l; 
label values s2312_21 s2312l; 
label values s2312_22 s2312l; 
label values s2312_23 s2312l; 
label values s2312_24 s2312l; 
label values s2312_25 s2312l; 
label values s2312_26 s2312l; 
label values s2312_27 s2312l; 
label values s2312_28 s2312l; 
label values s2312_29 s2312l; 
label values s2312_30 s2312l; 
label values s2312_31 s2312l; 
label values s2312_32 s2312l; 
label define s2312l  
	0           "Not in universe, not in sample,"
	-3          "None"                          
;
label values g1src_01 g1src;  
label values g1src_02 g1src;  
label values g1src_03 g1src;  
label values g1src_04 g1src;  
label values g1src_05 g1src;  
label values g1src_06 g1src;  
label values g1src_07 g1src;  
label values g1src_08 g1src;  
label values g1src_09 g1src;  
label values g1src_10 g1src;  
label define g1src   
	0           "NOT APPLICABLE, NOT IN"        
	1           "SOCIAL SECURITY"               
	2           "RAILROAD RETIREMENT"           
	3           "FEDERAL SUPPLEMENTAL SECURITY" 
	5           "STATE UNEMPLOYMENT"            
	6           "SUPPLEMENTAL UNEMPLOYMENT"     
	7           "OTHER UNEMPLOYMENT"            
	8           "VETERANS COMPENSATION OR"      
	10          "WORKERS COMPENSATION"          
	12          "EMPLOYER OR UNION TEMPORARY"   
	13          "PAYMENTS FROM A SICKNESS,"     
	20          "AID TO FAMILIES WITH"          
	21          "GENERAL ASSISTANCE OR GENERAL" 
	23          "FOSTER CHILD CARE PAYMENTS"    
	24          "OTHER WELFARE"                 
	25          "WIC"                           
	27          "FOOD STAMPS"                   
	28          "CHILD SUPPORT PAYMENTS"        
	29          "ALIMONY PAYMENTS"              
	30          "PENSION FROM COMPANY OR UNION" 
	31          "FEDERAL CIVIL SERVICE OR"      
	32          "U.S. MILITARY RETIREMENT PAY"  
	34          "STATE GOVERNMENT PENSIONS"     
	35          "LOCAL GOVERNMENT PENSIONS"     
	36          "INCOME FROM PAID UP LIFE"      
	37          "ESTATES AND TRUSTS"            
	38          "OTHER PAYMENTS FOR"            
	40          "GI BILL EDUCATION BENEFITS"    
	41          "OTHER VA EDUCATIONAL"          
	50          "INCOME ASSISTANCE FROM A"      
	51          "MONEY FROM RELATIVES OR"       
	52          "LUMP SUM PAYMENTS"             
	53          "INCOME FROM ROOMERS OR"        
	54          "NATIONAL GUARD OR RESERVE PAY" 
	55          "INCIDENTAL OR CASUAL EARNINGS" 
	56          "OTHER CASH INCOME NOT"         
	75          "STATE SSI/BLACK LUNG/STATE"    
;
label values ssrecin1 ssrecin;
label values ssrecin2 ssrecin;
label values ssrecin3 ssrecin;
label values ssrecin4 ssrecin;
label values ssrecin5 ssrecin;
label values ssrecin6 ssrecin;
label values ssrecin7 ssrecin;
label values ssrecin8 ssrecin;
label define ssrecin 
	0           "Not in universe"               
	1           "Adult benefits received in own"
	2           "Only adult benefits received jointly"
	3           "Only child benefits received"  
	4           "Adult benefits received in own name"
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
label define rrrecin 
	0           "Not in universe"               
	1           "Adult benefits received in own"
	2           "Only adult benefits received jointly"
	3           "Only child benefits received"  
	4           "Adult benefits received in own name"
	5           "Adult benefits received jointly"
;
label values vet3060  vet3060l;
label define vet3060l
	0           "Not in universe or don't know" 
	1           "Yes"                           
	2           "No"                            
	-1          "Don't know"                    
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
label define soc_se  
	0           "Not applicable, not in sample,"
	1           "Yes"                           
	2           "No"                            
;
label values railrd01 railrd; 
label values railrd02 railrd; 
label values railrd03 railrd; 
label values railrd04 railrd; 
label values railrd05 railrd; 
label values railrd06 railrd; 
label values railrd07 railrd; 
label values railrd08 railrd; 
label values railrd09 railrd; 
label values railrd10 railrd; 
label values railrd11 railrd; 
label values railrd12 railrd; 
label values railrd13 railrd; 
label values railrd14 railrd; 
label values railrd15 railrd; 
label values railrd16 railrd; 
label values railrd17 railrd; 
label values railrd18 railrd; 
label values railrd19 railrd; 
label values railrd20 railrd; 
label values railrd21 railrd; 
label values railrd22 railrd; 
label values railrd23 railrd; 
label values railrd24 railrd; 
label values railrd25 railrd; 
label values railrd26 railrd; 
label values railrd27 railrd; 
label values railrd28 railrd; 
label values railrd29 railrd; 
label values railrd30 railrd; 
label values railrd31 railrd; 
label values railrd32 railrd; 
label define railrd  
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
label define vets    
	0           "Not applicable, not in sample,"
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
label define hiownc  
	1           "Had health insurance in own name"
	2           "Did not have health insurance in own name"
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
label define hi_otc  
	1           "Had health insurance thru someone"
	2           "Did not have health insurance coverage"
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
label define hiempl  
	0           "Not in universe, not in sample,"
	1           "Health insurance coverage obtained thru"
	2           "Health insurance coverage not obtained"
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
label define ws_i1l  
	0           "No imputations, not applicable,"
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
label define ws_i2l  
	0           "No imputations, not applicable,"
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
label define se_i1l  
	0           "No imputations, not applicable,"
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
label define se_i2l  
	0           "No imputations, not applicable,"
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
label define g1_i1l  
	0           "No imputations, not applicable,"
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
label define g1_i2l  
	0           "No imputations, not applicable,"
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
label define g1_i3l  
	0           "No imputations, not applicable,"
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
label define g1_i4l  
	0           "No imputations, not applicable,"
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
label define g1_i5l  
	0           "No imputations, not applicable,"
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
label define g1_i6l  
	0           "No imputations, not applicable,"
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
label define g1_i7l  
	0           "No imputations, not applicable,"
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
label define g1_i8l  
	0           "No imputations, not applicable,"
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
label define g1_i9l  
	0           "No imputations, not applicable,"
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
label define g1_i10l 
	0           "No imputations, not applicable,"
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
label define g2i100l 
	0           "No imputations, not applicable,"
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
label define g2i104l 
	0           "No imputations, not applicable,"
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
label define g2i110l 
	0           "No imputations, not applicable,"
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
label define g2i120l 
	0           "No imputations, not applicable,"
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
label define g2i130l 
	0           "No imputations, not applicable,"
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
label define g2i140l 
	0           "No imputations, not applicable,"
	1           "Monthly amount imputed"        
;

/*
Copyright 2004 shared by the National Bureau of Economic Research and Jean Roth

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
