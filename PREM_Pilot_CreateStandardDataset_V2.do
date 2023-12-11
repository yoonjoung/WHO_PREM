clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
global mydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/"
cd $mydir

*** Directory for downloaded CSV data (can be same or different from the main directory)
global downloadcsvdir "$mydir/PilotExportedCSV_FromLimeSurvey/"

*** Define a directory for the chartbook (can be same or different from the main directory)
global chartbookdir "$mydir"

*** Define a directory for processed data files (can be same or different from the main directory)
global datadir "$mydir/PilotDataProduced/"

*** Define a directory for stata log files (can be same or different from the main directory)
global datanotedir "$mydir/PilotDataNote/"

*** Define local macro for the survey 

local country	 		 EXAMPLE /*country name*/	
local round 			 P /*round*/		
local year 			 	 2023 /*year of the mid point in data collection*/	
local month 			 12 /*month of the mid point in data collection*/	

local surveyid_EN 		 221751 /*LimeSurvey survey ID for ENGLISH form*/
local surveyid_CL 		 636743 /*LimeSurvey survey ID for COUNTRY LANGUAGE form*/

*** local macro for analysis (no change needed)  
local today		= c(current_date)
local c_today	= "`today'"
global date		= subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import raw data from LimeSurvey 
import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid_EN'&language=en&function=createExport", case(preserve) clear
	
	d, short	
	save temp.dta, replace

import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid_CL'&language=en&function=createExport", case(preserve) clear
	
	d, short
	
	append using temp.dta, force

**************************************************************
* D.A Expand and scramble the mock data <= DELETE THIS SECTION WHEN WORKING WITH REAL DATA
**************************************************************

	expand 50 if Q403a=="A1" | Q403b=="A1" 
	expand 10	
	
	* SCRAMBLE
	set seed 410	
	foreach var of varlist Q100a Q100b Q101 - Q137 Q2* Q302 Q303{
	generate random = runiform()
		replace `var' = "A1" if `var'=="A2" & random>0.80
		replace `var' = "A2" if `var'=="A1" & random<0.20
		drop random 
	}
	
	foreach var of varlist Q303{
	generate random = runiform()
		replace `var' = "A4" if `var'=="A1" & random>0.70
		replace `var' = "A5" if `var'=="A2" & random<0.30
		drop random 
	}	
		
	* ASSIGN NEW FACILITY ID
	set seed 443	
	generate random = runiform()
		replace A005 =	111	if 					  random<=	0.01
		replace A005 =	112	if random>	0.01	& random<=	0.037
		replace A005 =	113	if random>	0.037	& random<=	0.064
		replace A005 =	121	if random>	0.064	& random<=	0.091
		replace A005 =	122	if random>	0.091	& random<=	0.118
		replace A005 =	123	if random>	0.118	& random<=	0.145
		replace A005 =	131	if random>	0.145	& random<=	0.172
		replace A005 =	132	if random>	0.172	& random<=	0.199
		replace A005 =	133	if random>	0.199	& random<=	0.226
		replace A005 =	211	if random>	0.226	& random<=	0.253
		replace A005 =	212	if random>	0.253	& random<=	0.28
		replace A005 =	213	if random>	0.28	& random<=	0.307
		replace A005 =	221	if random>	0.307	& random<=	0.334
		replace A005 =	222	if random>	0.334	& random<=	0.361
		replace A005 =	223	if random>	0.361	& random<=	0.388
		replace A005 =	231	if random>	0.388	& random<=	0.415
		replace A005 =	232	if random>	0.415	& random<=	0.442
		replace A005 =	233	if random>	0.442	& random<=	0.469
		replace A005 =	311	if random>	0.469	& random<=	0.496
		replace A005 =	312	if random>	0.496	& random<=	0.523
		replace A005 =	313	if random>	0.523	& random<=	0.55
		replace A005 =	321	if random>	0.55	& random<=	0.577
		replace A005 =	322	if random>	0.577	& random<=	0.604
		replace A005 =	323	if random>	0.604	& random<=	0.631
		replace A005 =	331	if random>	0.631	& random<=	0.658
		replace A005 =	332	if random>	0.658	& random<=	0.685
		replace A005 =	333	if random>	0.685	& random<=	0.712
		replace A005 =	411	if random>	0.712	& random<=	0.739
		replace A005 =	412	if random>	0.739	& random<=	0.766
		replace A005 =	413	if random>	0.766	& random<=	0.793
		replace A005 =	421	if random>	0.793	& random<=	0.82
		replace A005 =	422	if random>	0.82	& random<=	0.847
		replace A005 =	423	if random>	0.847	& random<=	0.874
		replace A005 =	431	if random>	0.874	& random<=	0.901
		replace A005 =	432	if random>	0.901	
		*replace A005 =	433	if random>	0.928	
		drop random 
	
	* REPLACE DISTRICT ACCORDING TO FACILITY ID	
		replace A004 = 1 if A005>100 & A005<=199
		replace A004 = 2 if A005>200 & A005<=299
		replace A004 = 3 if A005>300 & A005<=399
		replace A004 = 4 if A005>400 & A005<=499
				
	* REPLACE Q001 ACCORDING TO THE DISTRICT
		replace A001 = "A1" if A004==1 | A004==3 /*Phone*/ 
		replace A001 = "A2" if A004==2 | A004==4 /*FTF*/
		
	* REPLACE Q402 ACCORDING TO THE DISTRICT
		replace Q402 = "A1" if A004==1 | A004==2 /*ENGLISH*/ 
		replace Q402 = "A2" if A004==3 | A004==4 /*COUNTRY LANGUAGE*/		
	
	* ASSIGN NEW SAMPLE ID
		set seed 123	
		generate random = runiformint(0, 999)
		replace A007 = random
		drop random
	
	* Create duplicates 
		foreach var of varlist A004 A005 A007{
			replace `var' = `var'[_n-1] in 2	
		}
	
save "$downloadcsvdir/LimeSurvey_PREM_EXAMPLE_20231207.dta", replace

d, short
bysort A004: tab A001 Q402, m
THE END 
