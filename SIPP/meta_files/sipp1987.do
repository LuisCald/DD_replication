log using sip87fp, text replace
set mem 1000m
*This program reads the 1987 SIPP Full Panel Data File 

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
*by Jean Roth Wed Jun  9 16:22:13 EDT 2004
*Please report errors to jroth@nber.org
*run with do sip87fp
*Change output file name/location as desired in the first line of the .dct file
*If you are using a PC, you may need to change the direction of the slashes, as in C:\
*  or "\\Nber\home\data\sipp\1987\sip87fp.dat"
* The following changes in variable names have been made, if necessary:
*      '$' to 'd';            '-' to '_';              '%' to 'p';
*For compatibility with other software, variable label definitions are the
*variable name unless the variable name ends in a digit. 
*'1' -> 'a', '2' -> 'b', '3' -> 'c', ... , '0' -> 'j'
* Note:  Variable names in Stata are case-sensitive
clear
cd /Users/lc/Dropbox/Distributional_Dynamics/1_Data/SIPP
quietly infile using sip87fp

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
	0           "Not applicable, children"      
	1           "Interview, self"               
	2           "Interview, proxy"              
	3           "Noninterview - type Z refusal" 
	4           "Noninterview - type Z other"   
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
	0           "Not applicable or not"         
	1           "Left - deceased"               
	2           "Left - institutionalized"      
	3           "Left - living in armed forces" 
	4           "Left - moved outside of"       
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
label define hhinst  
	0           "Not defined for this wave"     
	1           "Interviewed"                   
	2           "No one home"                   
	3           "Temporarily absent"            
	4           "Refused"                       
	5           "Unable to locate"              
	6           "Other"                         
	23          "Entire household out-of-scope" 
	24          "Moved, address unknown"        
	25          "Moved within country beyond"   
	26          "All sample persons relisted"   
;
label values su_rgc   su_rgc; 
label define su_rgc  
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
label define lgthht  
	0           "NA, not in a household"        
	1           "Married couple household"      
	2           "Other family household, male"  
	3           "Other family household,"       
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
	0           "Not a key person"              
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
	0           "Not an 'other' person in an"   
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
	21          "Afro-American, Black or Negro" 
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
	0           "Not a sample person, nonmatch" 
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
label define age     
	0           "Less than 1 year or not a"     
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
	0           "Not a sample person, nonmatch" 
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
	0           "Primary family or not a"       
	1           "Secondary individual, not a"   
	2           "Unrelated sub, secondary"      
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
	0           "Not applicable, not in"        
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
label define famnum  
	0           "Not applicable, not in"        
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
	0           "Not a sample person, nonmatch" 
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
	0           "Not in sample or nonmatch"     
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
	0           "Not a sample person, nonmatch" 
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
	0           "Not in sample or nonmatch"     
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
	0           "Not applicable, not in"        
	1           "Yes"                           
	2           "No"                            
;
label values u_vet_1  u_vet;  
label values u_vet_2  u_vet;  
label values u_vet_3  u_vet;  
label values u_vet_4  u_vet;  
label values u_vet_5  u_vet;  
label values u_vet_6  u_vet;  
label values u_vet_7  u_vet;  
label values u_vet_8  u_vet;  
label define u_vet   
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
label define in_af   
	0           "Not applicable if under 15,"   
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
label define usrv1l  
	0           "Not applicable, not in"        
	1           "Vietnam era, Aug'64-Apr'75"    
	2           "Korean conflict"               
	3           "World War II, Sept'40-July'47" 
	5           "May 1975 to August 1980"       
	6           "September 1980 or later"       
	7           "Other service"                 
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
label define usrv2l  
	0           "Not applicable, not in"        
	1           "Vietnam era, Aug'64-Apr'75"    
	2           "Korean conflict"               
	3           "World War II, Sept'40-July'47" 
	5           "May 1975 to August 1980"       
	6           "September 1980 or later"       
	7           "Other service"                 
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
label define usrv3l  
	0           "Not applicable, not in"        
	1           "Vietnam era, Aug'64-Apr'75"    
	2           "Korean conflict"               
	3           "World War II, Sept'40-July'47" 
	5           "May 1975 to August 1980"       
	6           "September 1980 or later"       
	7           "Other service"                 
	9           "Not answered"                  
;
label values brthmn   brthmn; 
label define brthmn  
	-9          "Not answered"                  
;
label values brthyr   brthyr; 
label define brthyr  
	-9          "Not answered"                  
	1902        "1902 or earlier"               
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
	-9          "Not answered"                  
	0           "Not in universe, not in"       
	999         "Not applicable"                
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
	0           "Not in universe, not in"       
	99          "Not applicable"                
;
label values u_lvqt01 u_lvqt; 
label values u_lvqt02 u_lvqt; 
label values u_lvqt03 u_lvqt; 
label values u_lvqt04 u_lvqt; 
label values u_lvqt05 u_lvqt; 
label values u_lvqt06 u_lvqt; 
label values u_lvqt07 u_lvqt; 
label values u_lvqt08 u_lvqt; 
label values u_lvqt09 u_lvqt; 
label values u_lvqt10 u_lvqt; 
label values u_lvqt11 u_lvqt; 
label values u_lvqt12 u_lvqt; 
label values u_lvqt13 u_lvqt; 
label values u_lvqt14 u_lvqt; 
label values u_lvqt15 u_lvqt; 
label values u_lvqt16 u_lvqt; 
label values u_lvqt17 u_lvqt; 
label values u_lvqt18 u_lvqt; 
label values u_lvqt19 u_lvqt; 
label values u_lvqt20 u_lvqt; 
label values u_lvqt21 u_lvqt; 
label values u_lvqt22 u_lvqt; 
label values u_lvqt23 u_lvqt; 
label values u_lvqt24 u_lvqt; 
label values u_lvqt25 u_lvqt; 
label values u_lvqt26 u_lvqt; 
label values u_lvqt27 u_lvqt; 
label values u_lvqt28 u_lvqt; 
label values u_lvqt29 u_lvqt; 
label values u_lvqt30 u_lvqt; 
label values u_lvqt31 u_lvqt; 
label values u_lvqt32 u_lvqt; 
label define u_lvqt  
	0           "Not applicable, not in"        
	1           "House, apartment, flat"        
	2           "HU in nontransient hotel,"     
	3           "HU, permanent in transient"    
	4           "HU in rooming house"           
	5           "Mobile home or trailer with"   
	6           "Mobile home or trailer with"   
	7           "HU not specified above"        
	8           "Quarters not hu in rooming or" 
	9           "Unit not permanent in"         
	10          "Unoccupied tent or trailer"    
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
label define tenure  
	0           "Not in sample, nonmatch"       
	1           "Owned or being bought by"      
	2           "Rented for cash"               
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
	0           "Not applicable, not in"        
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
label define low_re  
	0           "Not applicable, not in"        
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
	0           "Not in universe, not in"       
	1           "Yes"                           
	2           "No"                            
;
label values h_enrgy1 h_enrgy;
label values h_enrgy2 h_enrgy;
label values h_enrgy3 h_enrgy;
label values h_enrgy4 h_enrgy;
label values h_enrgy5 h_enrgy;
label values h_enrgy6 h_enrgy;
label values h_enrgy7 h_enrgy;
label values h_enrgy8 h_enrgy;
label define h_enrgy 
	0           "Not applicable, not in sample" 
	1           "Checks sent to household"      
	2           "Coupons or vouchers sent to"   
	3           "Payments sent elsewhere"       
	4           "Checks and coupons or"         
	5           "Checks sent to household and"  
	6           "Coupons or voucher sent to"    
	7           "All three types of assistance" 
;
label values h_48241  h_4824l;
label values h_48242  h_4824l;
label values h_48243  h_4824l;
label values h_48244  h_4824l;
label values h_48245  h_4824l;
label values h_48246  h_4824l;
label values h_48247  h_4824l;
label values h_48248  h_4824l;
label define h_4824l 
	0           "Not in universe, not in"       
;
label values h_lunch1 h_lunch;
label values h_lunch2 h_lunch;
label values h_lunch3 h_lunch;
label values h_lunch4 h_lunch;
label values h_lunch5 h_lunch;
label values h_lunch6 h_lunch;
label values h_lunch7 h_lunch;
label values h_lunch8 h_lunch;
label define h_lunch 
	0           "Not applicable, not in sample" 
	1           "Free"                          
	2           "Reduced-price"                 
	3           "Both"                          
;
label values h_48341  h_4834l;
label values h_48342  h_4834l;
label values h_48343  h_4834l;
label values h_48344  h_4834l;
label values h_48345  h_4834l;
label values h_48346  h_4834l;
label values h_48347  h_4834l;
label values h_48348  h_4834l;
label define h_4834l 
	0           "Not in universe, not in"       
;
label values h_break1 h_break;
label values h_break2 h_break;
label values h_break3 h_break;
label values h_break4 h_break;
label values h_break5 h_break;
label values h_break6 h_break;
label values h_break7 h_break;
label values h_break8 h_break;
label define h_break 
	0           "Not applicable, not in sample" 
	1           "Free"                          
	2           "Reduced-price"                 
	3           "Both"                          
;
label values h_48301  h_4830l;
label values h_48302  h_4830l;
label values h_48303  h_4830l;
label values h_48304  h_4830l;
label values h_48305  h_4830l;
label values h_48306  h_4830l;
label values h_48307  h_4830l;
label values h_48308  h_4830l;
label define h_4830l 
	0           "Not in universe, not in"       
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
;
label values utlpayyn utlpayyn;
label define utlpayyn
	0           "Not applicable"                
	1           "Yes"                           
	2           "No"                            
;
label values fullrent fullrent;
label define fullrent
	0           "Not applicable"                
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
	62          "Iowa, North Dakota, South"     
	63          "Alaska, Idaho, Montana,"       
;
label values sc1332   sc1332l;
label define sc1332l 
	-1          "Don't know"                    
	0           "Not in universe, not in"       
	1           "Less than 6 months"            
	2           "6 to 23 months"                
	3           "2 to 19 years"                 
	4           "20 or more years"              
;
label values sc1334   sc1334l;
label define sc1334l 
	-1          "Don't know"                    
	0           "Not in universe, not in"       
	1           "Yes"                           
	2           "No"                            
;
label values sc1336   sc1336l;
label define sc1336l 
	-2          "Refused"                       
	-1          "Don't know"                    
	0           "Not in universe, not in"       
	1           "1-10%"                         
	2           "11-29%"                        
	3           "30-49%"                        
	4           "50%"                           
	5           "51-89%"                        
	6           "90-99%"                        
	7           "100%"                          
	101         "No rating"                     
;
label values sc1346   sc1346l;
label define sc1346l 
	-1          "Don't know"                    
	0           "Not in universe, not in"       
	1           "Retired"                       
	2           "Disabled"                      
	3           "Widowed or surviving child"    
	4           "Spouse or dependent child"     
	5           "Some other reason"             
;
label values sc1348   sc1348l;
label define sc1348l 
	-1          "Don't know"                    
	0           "Not in universe, not in"       
	1           "Retired"                       
	2           "Disabled"                      
	3           "Widow,ed or surviving child"   
	4           "Spouse or dependent child"     
	5           "No other reason"               
;
label values sc1360   sc1360l;
label define sc1360l 
	0           "Not in universe, not in"       
	1           "Yes"                           
	2           "No"                            
;
label values sc1418   sc1418l;
label define sc1418l 
	0           "Not in universe, not in"       
	1           "Widowed"                       
	2           "Divorced"                      
	3           "Both widowed and divorced"     
	4           "No"                            
;
label values sc1456   sc1456l;
label define sc1456l 
	0           "Not in universe, not in"       
	1           "Yes, in the service"           
	2           "Yes, from service-related"     
	3           "No"                            
;
label values medcode  medcode;
label define medcode 
	0           "Not in universe"               
	1           "Retired or disabled worker"    
	2           "Spouse of retired or disabled" 
	3           "Widow of retired or"           
	4           "Adult disabled as a child"     
	5           "Uninsured"                     
	7           "Other or invalid code"         
	8           "Missing code"                  
;
label values sc1468   sc1468l;
label define sc1468l 
	0           "Not in universe or"            
	1           "Hospital only, Type A"         
	2           "Medical only, Type B"          
	3           "Both hospital and medical"     
	4           "Card not available"            
;
label values sc1472   sc1472l;
label define sc1472l 
	-1          "Don't know"                    
	0           "Not in universe"               
	1           "Yes"                           
	2           "No"                            
;
label values disab    disab;  
label define disab   
	0           "Not in universe, under 15"     
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
label define enrl_m  
	0           "Not enrolled, not in"          
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
label define ed_leve 
	0           "Not in universe, not in"       
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
label define ed_fina 
	0           "Not in universe"               
	1           "Yes"                           
	2           "No"                            
;
label values sc16721  sc1672l;
label values sc16722  sc1672l;
label values sc16723  sc1672l;
label values sc16724  sc1672l;
label values sc16725  sc1672l;
label values sc16726  sc1672l;
label values sc16727  sc1672l;
label values sc16728  sc1672l;
label define sc1672l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16741  sc1674l;
label values sc16742  sc1674l;
label values sc16743  sc1674l;
label values sc16744  sc1674l;
label values sc16745  sc1674l;
label values sc16746  sc1674l;
label values sc16747  sc1674l;
label values sc16748  sc1674l;
label define sc1674l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16761  sc1676l;
label values sc16762  sc1676l;
label values sc16763  sc1676l;
label values sc16764  sc1676l;
label values sc16765  sc1676l;
label values sc16766  sc1676l;
label values sc16767  sc1676l;
label values sc16768  sc1676l;
label define sc1676l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16781  sc1678l;
label values sc16782  sc1678l;
label values sc16783  sc1678l;
label values sc16784  sc1678l;
label values sc16785  sc1678l;
label values sc16786  sc1678l;
label values sc16787  sc1678l;
label values sc16788  sc1678l;
label define sc1678l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16801  sc1680l;
label values sc16802  sc1680l;
label values sc16803  sc1680l;
label values sc16804  sc1680l;
label values sc16805  sc1680l;
label values sc16806  sc1680l;
label values sc16807  sc1680l;
label values sc16808  sc1680l;
label define sc1680l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16821  sc1682l;
label values sc16822  sc1682l;
label values sc16823  sc1682l;
label values sc16824  sc1682l;
label values sc16825  sc1682l;
label values sc16826  sc1682l;
label values sc16827  sc1682l;
label values sc16828  sc1682l;
label define sc1682l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16841  sc1684l;
label values sc16842  sc1684l;
label values sc16843  sc1684l;
label values sc16844  sc1684l;
label values sc16845  sc1684l;
label values sc16846  sc1684l;
label values sc16847  sc1684l;
label values sc16848  sc1684l;
label define sc1684l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16861  sc1686l;
label values sc16862  sc1686l;
label values sc16863  sc1686l;
label values sc16864  sc1686l;
label values sc16865  sc1686l;
label values sc16866  sc1686l;
label values sc16867  sc1686l;
label values sc16868  sc1686l;
label define sc1686l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16881  sc1688l;
label values sc16882  sc1688l;
label values sc16883  sc1688l;
label values sc16884  sc1688l;
label values sc16885  sc1688l;
label values sc16886  sc1688l;
label values sc16887  sc1688l;
label values sc16888  sc1688l;
label define sc1688l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16901  sc1690l;
label values sc16902  sc1690l;
label values sc16903  sc1690l;
label values sc16904  sc1690l;
label values sc16905  sc1690l;
label values sc16906  sc1690l;
label values sc16907  sc1690l;
label values sc16908  sc1690l;
label define sc1690l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16921  sc1692l;
label values sc16922  sc1692l;
label values sc16923  sc1692l;
label values sc16924  sc1692l;
label values sc16925  sc1692l;
label values sc16926  sc1692l;
label values sc16927  sc1692l;
label values sc16928  sc1692l;
label define sc1692l 
	0           "Not marked as a kind of"       
	1           "Marked as a kind of"           
;
label values sc16961  sc1696l;
label values sc16962  sc1696l;
label values sc16963  sc1696l;
label values sc16964  sc1696l;
label values sc16965  sc1696l;
label values sc16966  sc1696l;
label values sc16967  sc1696l;
label values sc16968  sc1696l;
label define sc1696l 
	0           "Not in universe"               
	1           "Yes"                           
	2           "No"                            
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
	0           "Not applicable, not in"        
	1           "With a job entire month,"      
	2           "With a job entire month,"      
	3           "With a job entire month,"      
	4           "With job one or more weeks,"   
	5           "With job one or more weeks,"   
	6           "No job during month, spent"    
	7           "No job during month, spent"    
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
label define wksper  
	0           "Not applicable, not in"        
	4           "Four weeks"                    
	5           "Five weeks"                    
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
	0           "0 weeks or not applicable,"    
	1           "1 weeks"                       
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks, only applicable for"  
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
	5           "5 weeks, only applicable for"  
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
	0           "None or not applicable, not"   
	1           "1 week"                        
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks, only applicable for"  
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
;
label values ws1_ei01 ws1_ei; 
label values ws1_ei02 ws1_ei; 
label values ws1_ei03 ws1_ei; 
label values ws1_ei04 ws1_ei; 
label values ws1_ei05 ws1_ei; 
label values ws1_ei06 ws1_ei; 
label values ws1_ei07 ws1_ei; 
label values ws1_ei08 ws1_ei; 
label values ws1_ei09 ws1_ei; 
label values ws1_ei10 ws1_ei; 
label values ws1_ei11 ws1_ei; 
label values ws1_ei12 ws1_ei; 
label values ws1_ei13 ws1_ei; 
label values ws1_ei14 ws1_ei; 
label values ws1_ei15 ws1_ei; 
label values ws1_ei16 ws1_ei; 
label values ws1_ei17 ws1_ei; 
label values ws1_ei18 ws1_ei; 
label values ws1_ei19 ws1_ei; 
label values ws1_ei20 ws1_ei; 
label values ws1_ei21 ws1_ei; 
label values ws1_ei22 ws1_ei; 
label values ws1_ei23 ws1_ei; 
label values ws1_ei24 ws1_ei; 
label values ws1_ei25 ws1_ei; 
label values ws1_ei26 ws1_ei; 
label values ws1_ei27 ws1_ei; 
label values ws1_ei28 ws1_ei; 
label values ws1_ei29 ws1_ei; 
label values ws1_ei30 ws1_ei; 
label values ws1_ei31 ws1_ei; 
label values ws1_ei32 ws1_ei; 
label define ws1_ei  
	0           "Not in universe, not in"       
;
label values ws2_ei01 ws2_ei; 
label values ws2_ei02 ws2_ei; 
label values ws2_ei03 ws2_ei; 
label values ws2_ei04 ws2_ei; 
label values ws2_ei05 ws2_ei; 
label values ws2_ei06 ws2_ei; 
label values ws2_ei07 ws2_ei; 
label values ws2_ei08 ws2_ei; 
label values ws2_ei09 ws2_ei; 
label values ws2_ei10 ws2_ei; 
label values ws2_ei11 ws2_ei; 
label values ws2_ei12 ws2_ei; 
label values ws2_ei13 ws2_ei; 
label values ws2_ei14 ws2_ei; 
label values ws2_ei15 ws2_ei; 
label values ws2_ei16 ws2_ei; 
label values ws2_ei17 ws2_ei; 
label values ws2_ei18 ws2_ei; 
label values ws2_ei19 ws2_ei; 
label values ws2_ei20 ws2_ei; 
label values ws2_ei21 ws2_ei; 
label values ws2_ei22 ws2_ei; 
label values ws2_ei23 ws2_ei; 
label values ws2_ei24 ws2_ei; 
label values ws2_ei25 ws2_ei; 
label values ws2_ei26 ws2_ei; 
label values ws2_ei27 ws2_ei; 
label values ws2_ei28 ws2_ei; 
label values ws2_ei29 ws2_ei; 
label values ws2_ei30 ws2_ei; 
label values ws2_ei31 ws2_ei; 
label values ws2_ei32 ws2_ei; 
label define ws2_ei  
	0           "Not in universe, not in"       
;
label values ws1_cl01 ws1_cl; 
label values ws1_cl02 ws1_cl; 
label values ws1_cl03 ws1_cl; 
label values ws1_cl04 ws1_cl; 
label values ws1_cl05 ws1_cl; 
label values ws1_cl06 ws1_cl; 
label values ws1_cl07 ws1_cl; 
label values ws1_cl08 ws1_cl; 
label values ws1_cl09 ws1_cl; 
label values ws1_cl10 ws1_cl; 
label values ws1_cl11 ws1_cl; 
label values ws1_cl12 ws1_cl; 
label values ws1_cl13 ws1_cl; 
label values ws1_cl14 ws1_cl; 
label values ws1_cl15 ws1_cl; 
label values ws1_cl16 ws1_cl; 
label values ws1_cl17 ws1_cl; 
label values ws1_cl18 ws1_cl; 
label values ws1_cl19 ws1_cl; 
label values ws1_cl20 ws1_cl; 
label values ws1_cl21 ws1_cl; 
label values ws1_cl22 ws1_cl; 
label values ws1_cl23 ws1_cl; 
label values ws1_cl24 ws1_cl; 
label values ws1_cl25 ws1_cl; 
label values ws1_cl26 ws1_cl; 
label values ws1_cl27 ws1_cl; 
label values ws1_cl28 ws1_cl; 
label values ws1_cl29 ws1_cl; 
label values ws1_cl30 ws1_cl; 
label values ws1_cl31 ws1_cl; 
label values ws1_cl32 ws1_cl; 
label define ws1_cl  
	0           "Not in universe, not in"       
	1           "A private company or"          
	2           "Federal government, exclude"   
	3           "State government"              
	4           "Local government"              
	5           "Armed Forces"                  
	6           "Unpaid in family business or"  
;
label values ws2_cl01 ws2_cl; 
label values ws2_cl02 ws2_cl; 
label values ws2_cl03 ws2_cl; 
label values ws2_cl04 ws2_cl; 
label values ws2_cl05 ws2_cl; 
label values ws2_cl06 ws2_cl; 
label values ws2_cl07 ws2_cl; 
label values ws2_cl08 ws2_cl; 
label values ws2_cl09 ws2_cl; 
label values ws2_cl10 ws2_cl; 
label values ws2_cl11 ws2_cl; 
label values ws2_cl12 ws2_cl; 
label values ws2_cl13 ws2_cl; 
label values ws2_cl14 ws2_cl; 
label values ws2_cl15 ws2_cl; 
label values ws2_cl16 ws2_cl; 
label values ws2_cl17 ws2_cl; 
label values ws2_cl18 ws2_cl; 
label values ws2_cl19 ws2_cl; 
label values ws2_cl20 ws2_cl; 
label values ws2_cl21 ws2_cl; 
label values ws2_cl22 ws2_cl; 
label values ws2_cl23 ws2_cl; 
label values ws2_cl24 ws2_cl; 
label values ws2_cl25 ws2_cl; 
label values ws2_cl26 ws2_cl; 
label values ws2_cl27 ws2_cl; 
label values ws2_cl28 ws2_cl; 
label values ws2_cl29 ws2_cl; 
label values ws2_cl30 ws2_cl; 
label values ws2_cl31 ws2_cl; 
label values ws2_cl32 ws2_cl; 
label define ws2_cl  
	0           "Not in universe, not in"       
	1           "A private company or"          
	2           "Federal government, exclude"   
	3           "State government"              
	4           "Local government"              
	5           "Armed Forces"                  
	6           "Unpaid in family business or"  
;
label values ws1_wk01 ws1_wk; 
label values ws1_wk02 ws1_wk; 
label values ws1_wk03 ws1_wk; 
label values ws1_wk04 ws1_wk; 
label values ws1_wk05 ws1_wk; 
label values ws1_wk06 ws1_wk; 
label values ws1_wk07 ws1_wk; 
label values ws1_wk08 ws1_wk; 
label values ws1_wk09 ws1_wk; 
label values ws1_wk10 ws1_wk; 
label values ws1_wk11 ws1_wk; 
label values ws1_wk12 ws1_wk; 
label values ws1_wk13 ws1_wk; 
label values ws1_wk14 ws1_wk; 
label values ws1_wk15 ws1_wk; 
label values ws1_wk16 ws1_wk; 
label values ws1_wk17 ws1_wk; 
label values ws1_wk18 ws1_wk; 
label values ws1_wk19 ws1_wk; 
label values ws1_wk20 ws1_wk; 
label values ws1_wk21 ws1_wk; 
label values ws1_wk22 ws1_wk; 
label values ws1_wk23 ws1_wk; 
label values ws1_wk24 ws1_wk; 
label values ws1_wk25 ws1_wk; 
label values ws1_wk26 ws1_wk; 
label values ws1_wk27 ws1_wk; 
label values ws1_wk28 ws1_wk; 
label values ws1_wk29 ws1_wk; 
label values ws1_wk30 ws1_wk; 
label values ws1_wk31 ws1_wk; 
label values ws1_wk32 ws1_wk; 
label define ws1_wk  
	0           "None or not in universe if"    
	1           "1 week"                        
	2           "2 weeks"                       
	3           "3 weeks"                       
	4           "4 weeks"                       
	5           "5 weeks"                       
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
label values w2024_01 w2024l; 
label values w2024_02 w2024l; 
label values w2024_03 w2024l; 
label values w2024_04 w2024l; 
label values w2024_05 w2024l; 
label values w2024_06 w2024l; 
label values w2024_07 w2024l; 
label values w2024_08 w2024l; 
label values w2024_09 w2024l; 
label values w2024_10 w2024l; 
label values w2024_11 w2024l; 
label values w2024_12 w2024l; 
label values w2024_13 w2024l; 
label values w2024_14 w2024l; 
label values w2024_15 w2024l; 
label values w2024_16 w2024l; 
label values w2024_17 w2024l; 
label values w2024_18 w2024l; 
label values w2024_19 w2024l; 
label values w2024_20 w2024l; 
label values w2024_21 w2024l; 
label values w2024_22 w2024l; 
label values w2024_23 w2024l; 
label values w2024_24 w2024l; 
label values w2024_25 w2024l; 
label values w2024_26 w2024l; 
label values w2024_27 w2024l; 
label values w2024_28 w2024l; 
label values w2024_29 w2024l; 
label values w2024_30 w2024l; 
label values w2024_31 w2024l; 
label values w2024_32 w2024l; 
label define w2024l  
	-3          "None"                          
	0           "Not in universe, not in"       
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
	0           "Not in universe, not in"       
;
label values w2028_01 w2028l; 
label values w2028_02 w2028l; 
label values w2028_03 w2028l; 
label values w2028_04 w2028l; 
label values w2028_05 w2028l; 
label values w2028_06 w2028l; 
label values w2028_07 w2028l; 
label values w2028_08 w2028l; 
label values w2028_09 w2028l; 
label values w2028_10 w2028l; 
label values w2028_11 w2028l; 
label values w2028_12 w2028l; 
label values w2028_13 w2028l; 
label values w2028_14 w2028l; 
label values w2028_15 w2028l; 
label values w2028_16 w2028l; 
label values w2028_17 w2028l; 
label values w2028_18 w2028l; 
label values w2028_19 w2028l; 
label values w2028_20 w2028l; 
label values w2028_21 w2028l; 
label values w2028_22 w2028l; 
label values w2028_23 w2028l; 
label values w2028_24 w2028l; 
label values w2028_25 w2028l; 
label values w2028_26 w2028l; 
label values w2028_27 w2028l; 
label values w2028_28 w2028l; 
label values w2028_29 w2028l; 
label values w2028_30 w2028l; 
label values w2028_31 w2028l; 
label values w2028_32 w2028l; 
label define w2028l  
	0           "Not in universe, not in"       
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
	0           "Not in universe, not in"       
;
label values s2202_01 s2202l; 
label values s2202_02 s2202l; 
label values s2202_03 s2202l; 
label values s2202_04 s2202l; 
label values s2202_05 s2202l; 
label values s2202_06 s2202l; 
label values s2202_07 s2202l; 
label values s2202_08 s2202l; 
label values s2202_09 s2202l; 
label values s2202_10 s2202l; 
label values s2202_11 s2202l; 
label values s2202_12 s2202l; 
label values s2202_13 s2202l; 
label values s2202_14 s2202l; 
label values s2202_15 s2202l; 
label values s2202_16 s2202l; 
label values s2202_17 s2202l; 
label values s2202_18 s2202l; 
label values s2202_19 s2202l; 
label values s2202_20 s2202l; 
label values s2202_21 s2202l; 
label values s2202_22 s2202l; 
label values s2202_23 s2202l; 
label values s2202_24 s2202l; 
label values s2202_25 s2202l; 
label values s2202_26 s2202l; 
label values s2202_27 s2202l; 
label values s2202_28 s2202l; 
label values s2202_29 s2202l; 
label values s2202_30 s2202l; 
label values s2202_31 s2202l; 
label values s2202_32 s2202l; 
label define s2202l  
	0           "Not in universe, not in"       
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
	0           "Not in universe, not in"       
;
label values se1_ty01 se1_ty; 
label values se1_ty02 se1_ty; 
label values se1_ty03 se1_ty; 
label values se1_ty04 se1_ty; 
label values se1_ty05 se1_ty; 
label values se1_ty06 se1_ty; 
label values se1_ty07 se1_ty; 
label values se1_ty08 se1_ty; 
label values se1_ty09 se1_ty; 
label values se1_ty10 se1_ty; 
label values se1_ty11 se1_ty; 
label values se1_ty12 se1_ty; 
label values se1_ty13 se1_ty; 
label values se1_ty14 se1_ty; 
label values se1_ty15 se1_ty; 
label values se1_ty16 se1_ty; 
label values se1_ty17 se1_ty; 
label values se1_ty18 se1_ty; 
label values se1_ty19 se1_ty; 
label values se1_ty20 se1_ty; 
label values se1_ty21 se1_ty; 
label values se1_ty22 se1_ty; 
label values se1_ty23 se1_ty; 
label values se1_ty24 se1_ty; 
label values se1_ty25 se1_ty; 
label values se1_ty26 se1_ty; 
label values se1_ty27 se1_ty; 
label values se1_ty28 se1_ty; 
label values se1_ty29 se1_ty; 
label values se1_ty30 se1_ty; 
label values se1_ty31 se1_ty; 
label values se1_ty32 se1_ty; 
label define se1_ty  
	0           "Not in universe, not in"       
	1           "Sole proprietorship"           
	2           "Partnership"                   
	3           "Corporation"                   
;
label values se2_ty01 se2_ty; 
label values se2_ty02 se2_ty; 
label values se2_ty03 se2_ty; 
label values se2_ty04 se2_ty; 
label values se2_ty05 se2_ty; 
label values se2_ty06 se2_ty; 
label values se2_ty07 se2_ty; 
label values se2_ty08 se2_ty; 
label values se2_ty09 se2_ty; 
label values se2_ty10 se2_ty; 
label values se2_ty11 se2_ty; 
label values se2_ty12 se2_ty; 
label values se2_ty13 se2_ty; 
label values se2_ty14 se2_ty; 
label values se2_ty15 se2_ty; 
label values se2_ty16 se2_ty; 
label values se2_ty17 se2_ty; 
label values se2_ty18 se2_ty; 
label values se2_ty19 se2_ty; 
label values se2_ty20 se2_ty; 
label values se2_ty21 se2_ty; 
label values se2_ty22 se2_ty; 
label values se2_ty23 se2_ty; 
label values se2_ty24 se2_ty; 
label values se2_ty25 se2_ty; 
label values se2_ty26 se2_ty; 
label values se2_ty27 se2_ty; 
label values se2_ty28 se2_ty; 
label values se2_ty29 se2_ty; 
label values se2_ty30 se2_ty; 
label values se2_ty31 se2_ty; 
label values se2_ty32 se2_ty; 
label define se2_ty  
	0           "Not in universe, not in"       
	1           "Sole proprietorship"           
	2           "Partnership"                   
	3           "Corporation"                   
;
label values se1_in01 se1_in; 
label values se1_in02 se1_in; 
label values se1_in03 se1_in; 
label values se1_in04 se1_in; 
label values se1_in05 se1_in; 
label values se1_in06 se1_in; 
label values se1_in07 se1_in; 
label values se1_in08 se1_in; 
label values se1_in09 se1_in; 
label values se1_in10 se1_in; 
label values se1_in11 se1_in; 
label values se1_in12 se1_in; 
label values se1_in13 se1_in; 
label values se1_in14 se1_in; 
label values se1_in15 se1_in; 
label values se1_in16 se1_in; 
label values se1_in17 se1_in; 
label values se1_in18 se1_in; 
label values se1_in19 se1_in; 
label values se1_in20 se1_in; 
label values se1_in21 se1_in; 
label values se1_in22 se1_in; 
label values se1_in23 se1_in; 
label values se1_in24 se1_in; 
label values se1_in25 se1_in; 
label values se1_in26 se1_in; 
label values se1_in27 se1_in; 
label values se1_in28 se1_in; 
label values se1_in29 se1_in; 
label values se1_in30 se1_in; 
label values se1_in31 se1_in; 
label values se1_in32 se1_in; 
label define se1_in  
	1           "Agriculture, forestry,"        
	2           "Mining"                        
	3           "Construction"       
