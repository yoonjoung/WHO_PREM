clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of last code update: 5/30/2023
*   See Github for history of changes: 
*	https://github.com/yoonjoung/WHO_PREM
*	https://github.com/yoonjoung/WHO_PREM/blob/main/PREM_Pilot_Sampling.do

*This code is only for PHONE interviews
*1) imports and appends all listing files from each facility AND service area 
*2) randomly sample the target number of sample size in each facility 
*3) creates three output files 

*  DATA IN:	
*		1. MOCK client-level listing files from each facility AND service area
*			USING FULL DIGITAL VERSION AS AN EXAMPLE
*		2. facility sampling design info (ORANGE TAB from the chartbook) 
 
*  DATA OUT: 
*		1. Listing process monitoring log: 
*			"ListingCheck_PREM_`country'_R`round'_$date.log"
*		2. Listing process data: 
*			List of all clients attempted for recruitment/listing 
*		3. Final sample data: List of sampled clients with their phone numbers 
*			and study design information

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: directories and local macro

* B. Prepare listing data for sampling 
***** B.1 Import, create source file name, and append
***** B.2 Change var names to lowercase
***** B.3 Rename questions to variable names 
***** B.4 More data cleaning 
***** B.5 Identify and drop duplicate cases
***** B.6 Sort by facility id

* C. Merge with facility information 
***** C.1. Merge with facility information 
***** C.2. More cleaning 

* D. Export datafile with all listing process information

* E. Assessment of the listing progress
***** E.1 gen listing progress check variables
***** E.2 collapse by district 

* F. Sampling 
***** F.1 Keep only those who are "listed" with phone numbers
***** F.2 Sample by facility
***** F.3 Append all sample by facility
***** F.4 Export datafile with sampled clients

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
cd "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/"

*** Define a directory for the chartbook (can be same or different from the main directory)
global chartbookdir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/"

*** Define a directory for LISTING data files
global listingfilesdir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/ListingFilesDownloaded/"

*** Define a directory for COMBINED LISTING data files
global listingdatadir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/ListingDataCombined/"

*** Define a directory for stata log files
global statalog "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/StataLog/"

*** Define local macro for the survey 
local country	 		 EXAMPLE /*country name*/	
local round 			 1 /*round*/		
local year 			 	 2023 /*year of the mid point in data collection*/	
local month 			 6 /*month of the mid point in data collection*/	

local surveyid 			 259237 /*LimeSurvey survey ID*/

*** Define local macro for response options specific to the country 

local countrylanguage1	 Spanish /*Country language 1*/

local geoname1	 		 Anne Arundel /*Study district names*/
local geoname2	 		 Baltimore 
local geoname3	 		 Harford
local geoname4	 		 Somerset

local type1 			 District Hospital /*Facility type*/
local type2 			 Health Center 
local type3 			 Health Post

local service1 			 Service A /*ServiceArea*/		
local service2 			 Service B
local service3 			 Service C 
		
*** local macro for analysis (no change needed)  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Prepare listing data for sampling 
**************************************************************

***** B.1 Import, create source file name, and append
clear
tempfile building
save `building', emptyok

local filenames: dir "$listingfilesdir" files "*.xlsx"

	foreach file of local filenames {
		import excel using `"$listingfilesdir/`file'"', firstrow allstring clear 
		gen sourcefile = `"`file'"' /*source file name*/
			
		append using `building', force
		save `"`building'"', replace
	}
	
	*drop any variable that is completely missing. Why do we have these?
	foreach var of varlist _all {
		capture assert mi(`var')
		if !_rc {
			drop `var'
		}
	}	
			
	tab source, m
	
***** B.2 Change var names to lowercase
	
	rename *, lower

***** B.3 Rename questions to variable names 
	
	rename timestamp timestamp_listing
	
	rename pleaseprovideclientsinitial initial
	rename istheclientinterestedinthe interest
	rename doestheclienthaveaccesstop phone
	rename doestheclientspeakinstudy language
	rename pleaseenterclientsfullname name
	rename pleaseenterclientsphonenumb number1
	rename pleasereenterclientsphonen number2

***** B.4 More data cleaning 
	
	*facility and service area 
	gen facility_area = substr(sourcefile, strpos(sourcefile, "_") + 1, .) 
		replace facility_area = substr(facility_area, strpos(facility_area, "_") + 1, .) 
		replace facility_area = substr(facility_area, 1, strpos(facility_area, ".") -1) 
		
	gen facilityid = substr(facility_area, 1, strpos(facility_area, "_") - 1) 
		destring facilityid, replace
		
	gen servicearea = substr(facility_area, strpos(facility_area, "_") + 1, .)
		destring servicearea, replace

***** B.5 identify and drop duplicate cases

	*****identify duplicate cases, based on facility code
	duplicates tag facilityid servicearea name number1 , gen(duplicate) 	
		tab duplicate, m
		list duplicate facilityid servicearea name number1 timestamp if duplicate!=0 & name!=""	

		*CHECK HERE - assess and drop duplicate. 
		
***** B.6 sort by facility id
		
	sort facilityid /*ready for merging with the sampling design info*/
	
save temp.dta, replace

**************************************************************
* C. Merge with facility information 
**************************************************************
  
***** C.1. Merge with facility information 

import excel "$chartbookdir/PREM_Pilot_Chartbook_WORKING.xlsx", sheet("Facility_sample") firstrow clear 
		
	rename *, lower
		
		d

		/* this worksheet has background characteristics of the sentinel facilites.
		PREMs team in the country will provide this information
		
		Contains data
		  obs:            36                          
		 vars:             7                          
		 size:           648                          
		--------------------------------------------------------------------------------------------------------------------------------------
					  storage   display    value
		variable name   type    format     label      variable label
		--------------------------------------------------------------------------------------------------------------------------------------
		facilityid      int     %10.0g                facilityid
		district        byte    %10.0g                district
		facility_type   byte    %10.0g                facility_type
		managing_auth~y byte    %10.0g                managing_authority
		target_sample~e byte    %10.0g                target_sample_size
		mode_design     str5    %9s                   mode_design
		language_design str7    %9s                   language_design
		--------------------------------------------------------------------------------------------------------------------------------------

	*/ 
	
		codebook facilityid /*this is assigned for the study, same with A005 in PREMs*/ 
	
	sort facilityid	
	merge facilityid using temp.dta, 
	
		tab _merge
				
		*****CHECK HERE: 
		
		/*
			
			.                 tab _merge

		 _merge |      Freq.     Percent        Cum.
	------------+-----------------------------------
			  1 |         32        4.37        4.37
			  3 |        700       95.63      100.00
	------------+-----------------------------------
		  Total |        732      100.00

		*/
		
		*		all should be 3 (i.e., match) by the end of the listing*/
		*		until then there will be 1 (facilities with no listing) and 3*/
		
		keep if _merge==3 /*for practice purposes*/
		
		drop _merge*

***** C.2. More cleaning 
	
	rename facility_type type
	rename managing_authority sector
		
	#delimit;	
  
	lab define geoname
		1 "`geoname1'"
		2 "`geoname2'"
		3 "`geoname3'"
		4 "`geoname4'"
		;
	lab values district geoname;
	
	lab define type
		1 "`type1'"
		2 "`type2'"
		3 "`type3'"
		;
	lab values type type; 	
		
	replace servicearea = 0 if type==3;
	
	lab define service
		0 "All"
		1 "`service1'"
		2 "`service2'" 
		3 "`service3'"
		;
	lab values servicearea service; 	

	#delimit cr

**************************************************************
* D. Export 
**************************************************************

	*date and time when the listing files were combined
	gen updatedate = "$date" 

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"
	
export excel using "$listingdatadir/PREM_`country'_R`round'_LIST.xlsx", firstrow(variables) replace
save "$listingdatadir/PREM_`country'_R`round'_LIST.dta", replace

**************************************************************
* E. Assessment of the listing progress
**************************************************************
use "$listingdatadir/PREM_`country'_R`round'_LIST.dta", clear

***** E.1 gen listing progress check variables

	gen num_total = 1
	
	gen num_interest = 1 if interest=="Yes" /*interested in the study*/
	gen num_phone = 1 if phone=="Yes" /*PLUS have access to phone numbers*/
	gen num_language = 1 if language=="Yes" /*PLUS speak in the language*/
	
	gen num_listed = 1 if name!="" & number1!=""
	gen num_listed_twonumbers = 1 if name!="" & (number1==number2)
	
	gen numfacilities = 1
	
	save temp.dta, replace 
	
***** E.2 collapse by district 
capture log close
log using "$statalog/ListingCheck_PREM_`country'_R`round'_$date.log", replace

	*Date and total screened for listing
	tab updatedate
	
	*Number of facilities conducted listing by district
	use temp.dta, clear
		
		collapse (mean) numfacilities, by(district facilityid)
		tab district, m
	
	*By district, number of listing progress in detail
	use temp.dta, clear
		
		collapse (count) num_*, by(district)
		bysort district: list num_*
	
	*By district and facility, number of listing progress in detail
	use temp.dta, clear
		
		collapse (count) num_* (mean) target_sample_size, by(district facilityid type)
		bysort district type facilityid: list num_* target

log close

erase temp.dta

/*
capture putdocx clear 
putdocx begin
putdocx paragraph
putdocx text ("Listing progress: `today'"),  linebreak	

putdocx paragraph
putdocx table stable = (1,10), title("Listing by facility")  
putdocx table table = data(district type facilityid num_* target_sample_size ) 

putdocx save "$statalog/ListingProgress_$date.docx", replace
*/
**************************************************************
* F. Sampling 
**************************************************************

***** have the temp file ready for step F.3 below....
clear
tempfile building
save `building', emptyok	

***** F.1 Keep only those who are "listed" with phone numbers

use "$listingdatadir/PREM_`country'_R`round'_LIST.dta", clear

	tab duplicate, m

keep if name!="" & number1!=""

	tab duplicate, m

	egen num_listed_facility = count(name), by (facilityid) /*number listed by facility*/
	
***** F.2 Sample by each facility

    levelsof facilityid, local(levels)
	
    foreach level of local levels {
		preserve
		keep if facilityid ==`level' 
			
			set seed 38 /*MUST SET SEED for reproducibility*/
			
			sum target /*target SS in each facility*/ 
			return list /*save the target SS as a scalar*/ 
			sample `r(mean)', count by(facilityid) /*sample the numer of target clients*/
			list facilityid name number*
		
		save "$listingdatadir/sample_`level'.dta", replace
		restore
	}

***** F.3 Append all sample by facility
	    
    foreach level of local levels {
		use "$listingdatadir/sample_`level'.dta", replace
	
		append using `building', force
		save `"`building'"', replace
	}		

    foreach level of local levels {
		erase "$listingdatadir/sample_`level'.dta"
	}
	
	egen num_sampled_facility = count(name), by (facilityid) /*number sampled by facility*/
	
	preserve
		*****CHECK HERE:  
		collapse (mean) target num_*, by (district type facilityid) 
		list
		* 	Each type of facility has different target sample size
		* 	Also each facility will have different number of clients who are listed 
		*	they can be similar within a same type, but unlikely identical... 
		* 	Also, it is possible the number of listed is less than the target sample size...
		*	
	restore

***** F.4 Export 		
		
export excel using "$listingdatadir/PREM_`country'_R`round'_SAMPLE.xlsx", firstrow(variables) replace
save "$listingdatadir/PREM_`country'_R`round'_SAMPLE.dta", replace	
	

END OF DATA CLEANING AND MANAGEMENT AND SAMPLING 
