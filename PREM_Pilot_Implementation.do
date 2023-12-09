clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of last code update: 12/07/2023
*   See Github for history of changes: 
*	https://github.com/yoonjoung/WHO_PREM
*	https://github.com/yoonjoung/WHO_PREM/blob/main/PREM_Pilot_DataManagement_WORKING.do

*This code 
*1) runs the data management do file **BOTH FILES MUST BE IN THE SAME DIRECTORY**
*2) calculates process metrics for evaluation of the PREMs pilot implementation 
*3) produces outputs 
*		=====> Second PURPLE TAB in Chartbook: "Pilot_Implementation"

*  DATA IN:	
*		1. cleaned client-level data CSV file (AKA BLUE TAB in Chartbook)

*  DATA OUT: 
*		1. Metrics data 
*			=> CSV, dta, and the second PURPLE TAB in Chartbook 

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: directories and local macro

* B. Run the data management do file 

* C. Implementation results 
***** C.1. Open/import the clean client-level data  
***** C.2. Create process metrics at the client level
***** C.3. Calculate rate process metrics by analysis domain 
***** C.4. Export data to chartbook AND in CSV for dashboard

* D. Data viz and output

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
global mydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/"
cd $mydir

*** Define a directory for the chartbook (can be same or different from the main directory)
global chartbookdir "$mydir"

*** Define a directory for PROCESSED data files 
global datadir "$mydir/PilotDataProduced/"

*** Define local macro for the survey 
local country	 		 EXAMPLE /*country name*/	
local round 			 P /*round*/		
local year 			 	 2023 /*year of the mid point in data collection*/	
local month 			 12 /*month of the mid point in data collection*/	

*** Define local macro for response options specific to the country 

local countrylanguage1	 Spanish /*Country language 1*/

/*Study district names: must match with district code in ORANGE tab*/
local geoname1	 		 Anne Arundel 
local geoname2	 		 Baltimore 
local geoname3	 		 Harford
local geoname4	 		 Somerset

/*Facility type: must match with facility_type numeric code in ORANGE tab*/
local type1 			 District Hospital /*Facility type*/
local type2 			 Health Center 
local type3 			 Health Post
		
*** local macro for analysis (no change needed)  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Run the data management do file 
**************************************************************

do PREM_Pilot_DataManagement_WORKING.do

**************************************************************
* C. Implementation results 
**************************************************************

***** C.1. Open/import the clean client-level data  

use "$datadir/PREM_`country'_R`round'.dta", clear 

***** C.2. Create process metrics at the client level
		
	*count number of missing responses 

		foreach var of varlist q101 - q303 {
			gen byte m`var' = `var'==.
		}
		
		local varlist mq`i'* 
			preserve
			keep `varlist'
			d, short
			restore
		gen nq_total = `r(k)' /*total number of questions q101-q303*/
		egen nq_missing =rowtotal(`varlist') /*total number of questions with missing*/				
		gen pq_missing = nq_missing / nq_total	/*percent questions with missing*/
		
		/*
		foreach i in 1 2 3 {
			local varlist mq`i'* 
				preserve
				keep `varlist'
				d, short
				restore
				*return list
			gen n_section`i' = `r(k)'
			egen n_missing_section`i'=rowtotal(`varlist')				
		}
		*/

	*Number of clients/respondents
	
		*Number of sampled clients - i.e., everyone in the dataset
		gen num_samp = 1
				
		*Number of sampled clients with invalid/wrong phone numbers  
		gen num_invwronum = 1 if a011==5 | a011==6		

		*Number of sampled clients with no answer 
		gen num_nocnt = 1 if a011==2 | a011==3	
		
		*Number of sampled clients who are contacted 
		gen num_cntsoelse = 1 if a011==4
		
		*Number of sampled clients who are contacted successfully 
		gen num_cntsuccess = 1 if a011==1
		
		*Number of respondents
		gen num_resp = 1 if q001==1 
		
		*Number of respondents who completed more than 50% of the interview*
		gen num_comp50 = 1 if xcomplete==1 | (q403==3 & pq_missing>0.5)
		
		*Number of respondents who completed the interview**
		gen num_comp = 1 if xcomplete==1 
		
		*Number of phone calls made
		gen num_call = a008	
		
			bysort a001: sum num_*
			bysort zdistrict: sum num_*

	*And, finally language... 
	
		tab language mode, m		
		* language is not given if the interview did not start! 
		* assign language of the district in that case
		
		gsort district -language 
		
		replace language = language[_n-1] if district == district[_n-1] & language=="" 
		tab language mode, m
		
	save temp.dta, replace	
	
***** C.3. Calculate rate process metrics by analysis domain 

	use temp.dta, clear
	collapse (sum) num_*, ///
		by(country round month year  )
				
		gen language="All languages"
		gen mode="All modes" 
		gen group ="All"
		gen grouplabel ="All"
		
		save "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", replace 
		
	use temp.dta, clear
	collapse (sum) num_*, ///
		by(country round month year language mode)

		gen group ="Study arm"
		gen grouplabel ="All"
			
		append using "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", force				
		save "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", replace 
		
	use temp.dta, clear
	collapse (sum) num_*, ///
		by(country round month year language mode zdistrict)
		
		gen group ="Study arm_District"
		gen grouplabel =""
			replace grouplabel="`geoname1'" if zdistrict==1
			replace grouplabel="`geoname2'" if zdistrict==2
			replace grouplabel="`geoname3'" if zdistrict==3
			replace grouplabel="`geoname4'" if zdistrict==4		
		
		append using "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", force
		save "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", replace 	
		
	use temp.dta, clear
	
		tab submitdate
				
		gen submit_date = day(dofc(submitdate))
		gen submit_month = month(dofc(submitdate))
			tostring(submit_date), replace
			tostring(submit_month), replace
			tab submit_date submit_month, m
			
		drop submitdate
		gen submitdate = submit_month + "/" + submit_date
		tab submitdate
			
	collapse (sum) num_*, ///
		by(country round month year language mode submitdate)
		
		gen group ="Study arm_Date"
		gen grouplabel =submitdate
		
		append using "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", force
		save "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", replace 			
		
	***** gen axis - for figure axis purposes...
		
			tab group, m
			bysort group: tab mode language, m
			bysort group: list grouplabel language mode 
		
		gen axis =""			
			replace axis = language + "_" + mode if group=="Study arm" /*study arm*/
			replace axis = "Pooled" if mode=="All modes" & language=="All languages" /*pooled*/
			replace axis = grouplabel if group=="Study arm_District" /*district*/
			replace axis = submitdate if group=="Study arm_Date" /*date*/

	***** replace grouplabel 
			replace grouplabel = language + "_" + mode + "_" + grouplabel
			
			***** CHECK HERE:
			duplicates report grouplabel
			*	check grouplabel is unique in every row
						
			drop zdistrict* submitdate
		
	***** order columns	
	order country round year month language mode group grouplabel axis num*
	
	***** sort rows
	sort country round year month group grouplabel axis, 
	
	***** calculate rate/pct distribution metrics 

		*Pct distribution for contact for PHONE interviews
		gen pct_ph_invwronum = num_invwronum / num_samp
		gen pct_ph_nocnt = num_nocnt / num_samp
		gen pct_ph_cntsoelse = num_cntsoelse / num_samp
		gen pct_ph_cntsuccess = num_cntsuccess / num_samp
		
		gen pct_ph_cntnocoop = (num_cntsuccess - num_resp) / num_samp
		gen pct_ph_cntcoop = num_resp / num_samp
		
		*Contact rate, correct phone number 
		gen rate_cnt = (num_cntsoelse + num_cntsuccess) / num_samp
		
		*Contact rate, correct person
		gen rate_cntsuccess = num_cntsuccess / num_samp
		
		*Cooperation rate for PHONE interview
		gen rate_coop = num_resp / num_samp
		
		*Partial response rate
		gen rate_resp_partial = num_comp50 / num_resp
		
		*Response rate
		gen rate_resp = num_comp / num_resp
		
		foreach var of varlist pct_ph_* rate_* {
			replace `var'=round(100 * `var', 1)	
			format `var' %2.1f
			}	

	***** replace with missing for phone specific indicators 
	
		#delimit; 
		foreach var of varlist 
			num_invwronum	num_nocnt	num_cntsoelse	num_cntsuccess
			pct_ph_invwronum	pct_ph_nocnt	pct_ph_cntsoelse	pct_ph_cntsuccess	
			rate_cnt	rate_cntsuccess{
			;
			#delimit cr
			replace `var'=. if mode!="Phone"
			}
			
save "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", replace	

***** C.4. Export data to chartbook AND in CSV for dashboard

use "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"

export delimited using "$datadir/PREM_Pilot_Process_`country'_R`round'.csv", replace 	
export excel using "$chartbookdir/PREM_Pilot_Chartbook_WORKING.xlsx", sheet("Pilot_Implementation") sheetreplace firstrow(variables) nolabel keepcellfmt

erase temp.dta		

*END OF DATA CLEANING AND MANAGEMENT - Yay!!! 
