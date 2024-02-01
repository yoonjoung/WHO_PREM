clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of the PREM questionniare version: Questionnaire_8SEPT2023_WORKING
*	https://worldhealthorg-my.sharepoint.com/:w:/r/personal/banicag_who_int/_layouts/15/Doc.aspx?sourcedoc=%7BA1DE21BB-2BD1-4F22-B36B-4B4EBC0AE145%7D&file=Questionnaire_8SEPT2023_WORKING.docx&wdLOR=c2F996D4A-4A15-9D4B-A8F6-4242767CAB35&action=default&mobileredirect=true
* Date of last code update: 12/07/2023
*	https://github.com/yoonjoung/WHO_PREM
*	https://github.com/yoonjoung/WHO_PREM/blob/main/PREM_Pilot_DataManagement_WORKING.do

*This code 
*1) creates random sample of respondents for reliability test - merged with their phone numbers

*  DATA IN:	
*		1. PREM person-level clean data	
*		2. SAMPLE with phone number

*  DATA OUT: 
*		1. random sample of respondents who agreed completed the interview and 
*			agreed to have a follow-up call 

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: directories and local macro
* B. Random sample of completed interviews by langague 
* C. Merge with sample data with phone numbers

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
global mydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/Workshop/PREM_DM_Pilot_Workshop_Ghana/"
cd $mydir

*** Define a directory for processed pilot data files 
global pilotdata "$mydir/PilotDataProduced/"

*** Define a directory for listing/sample data files
*global listingdata "$mydir/ListingData/"
global listingdata "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/Workshop/PREM_DM_Sampling_Workshop_Ghana/ListingData/"

*** Define a directory for repeat sample 
global repeatsample "$mydir/RepeatSample/"

*** Define local macro for the survey 
local country	 		 Ghana /*country name*/	
local round 			 P /*round*/		

*** Define local macro for response options specific to the country 

local countrylanguage1	 Twi /*Country language 1*/
		
*** local macro for analysis (no change needed)  
local today		= c(current_date)
local c_today	= "`today'"
global date		= subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Random sample of completed interviews by langague 
**************************************************************

*****B.1. Open pilot data and check data
use "$pilotdata/PREM_`country'_R`round'.dta", clear

	tab mode, m
	tab interviewdate xcomplete, m /*interview date vs. interview result*/
	tab q401 xcomplete, m /*agree for a follow up interview*/
	tab a008 xcomplete, m /*call number vs. interview result*/	
	tab q402 language, m /*Reported language of interview vs. language by design*/
	
*****B.2. Keep only the following interviews 

keep if mode=="Phone" & xcomplete==1 & q401==1
/*those who completed a phone interview and agreed for a follow up interview*/
	
*keep if a008<=3 /* NOT APPLYING THIS IN GHANA because of duplicated sample number... */ 
/*interviews that were successfully completed within 3 attempts*/
	
keep if (q402==1 & language=="English") | (q402==2 & language =="`countrylanguage1'")
/*interviews that have consistent reported vs. study design language*/

		duplicates tag district facilityid samplenumber, gen(duplicate)
		tab duplicate, m
				
		capture drop duplicate 
		duplicates tag samplenumber, gen(duplicate)
		tab duplicate , m
		tab duplicate language, m
		
		/*
		.                 duplicates tag district facilityid samplenumber, gen(duplicate)

		Duplicates in terms of district facilityid samplenumber

		.                 tab duplicate, m

		  duplicate |      Freq.     Percent        Cum.
		------------+-----------------------------------
				  0 |        157       75.48       75.48
				  1 |         24       11.54       87.02
				  2 |          6        2.88       89.90
				  3 |         16        7.69       97.60
				  4 |          5        2.40      100.00
		------------+-----------------------------------
			  Total |        208      100.00

		.                 drop duplicate

		.                 
		.                 capture drop duplicate 

		.                 duplicates tag samplenumber, gen(duplicate)

		Duplicates in terms of samplenumber

		.                 tab duplicate , m

		  duplicate |      Freq.     Percent        Cum.
		------------+-----------------------------------
				  0 |        134       40.12       40.12
				  1 |         26        7.78       47.90
				  2 |         15        4.49       52.40
				  3 |         16        4.79       57.19
				  4 |         10        2.99       60.18
				  5 |         12        3.59       63.77
				  6 |         14        4.19       67.96
				  7 |         24        7.19       75.15
				  8 |         27        8.08       83.23
				 10 |         44       13.17       96.41
				 11 |         12        3.59      100.00
		------------+-----------------------------------
			  Total |        334      100.00

		.                 tab duplicate language, m

				   |       language
		 duplicate |   English        Twi |     Total
		-----------+----------------------+----------
				 0 |        43         91 |       134 
				 1 |        13         13 |        26 
				 2 |         9          6 |        15 
				 3 |        11          5 |        16 
				 4 |         8          2 |        10 
				 5 |         8          4 |        12 
				 6 |        12          2 |        14 
				 7 |        17          7 |        24 
				 8 |        19          8 |        27 
				10 |        33         11 |        44 
				11 |        10          2 |        12 
		-----------+----------------------+----------
			 Total |       183        151 |       334  	  

		*/		
keep if duplicate==0
/*to ensure unique sample_number*/

*****B.3. Keep only ID variables 
	
keep q402 district facility_name facilityid samplenumber interviewdate
* Note: why do we used q402 instead of "language"? 
* language is based on district that interviewer entered in the form
* If there is data error in "district", "language" is CAN be in correct - especially in Zambia
	
*****B.4. Random sample of 100 by language 

	set seed 38 /*MUST SET SEED for reproducibility*/
		
	sample 100, count by(q402) 
	/*sample extra, considering response rate & data entry errors - see below 
	+ any merge issues (which is high in Ghana)*/
	
		tab q402, m
	
	*getting ready for merge
	rename samplenumber sample_number	
	rename district district_interview
		
	*sort district_interview facilityid sample_number
	sort sample_number
		
save "$repeatsample/repeatsample_PREM_Pilot_`country'_R`round'.dta", replace

	capture drop temp
	egen temp=group(district facilityid sample_number)
	codebook temp
	
**************************************************************
* C. Merge with phone numbers
**************************************************************

*****C.1. Determine sample files to merge with 
use "$listingdata/PREM_`country'_R`round'_SAMPLE_ALL.dta", clear /*initial listing*/

	d, short
	
*****C.2. Merge 
	
	capture drop formid
	*sort district facilityid sample_number
	sort sample_number
	
	merge sample_number using "$repeatsample/repeatsample_PREM_Pilot_`country'_R`round'.dta"
		tab _merge, m
		
		list district facilityid sample_number interviewdate if _merge==2

	keep if _merge==3	
		drop _merge
		
*****C.3. Tidy 
	
		tab language q402, m
	
	keep if (q402==1 & language=="English") | (q402==2 & language =="`countrylanguage1'")	

		tab language q402, m
		
	*** Reduce the sample size to 60
	set seed 410 /*MUST SET SEED for reproducibility*/		
	sample 60, count by(language) 
	/*sample extra, considering contact and response rate*/
	
		tab language q402, m
		
	*** Date 
	gen updatedate = "$date"
	
	*** Order 
	order language listingdate district_name district facility_name facilityid sample_number name phonenumber interviewdate

	*** Sort
	sort language interviewdate
	
save "$repeatsample/repeatsample_PREM_Pilot_`country'_R`round'_$date.dta", replace	

	drop district_interview q402 updatedate
	
export excel using "$repeatsample/repeatsample_PREM_Pilot_`country'_R`round'_$date.xlsx", firstrow(variables) nolabel replace
	
