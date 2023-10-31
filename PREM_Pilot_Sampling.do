clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of last code update: 10/31/2023
*   See Github for history of changes: 
*	https://github.com/yoonjoung/WHO_PREM
*	https://github.com/yoonjoung/WHO_PREM/blob/main/PREM_Pilot_Sampling.do

*This code is only for PHONE interviews
*1) imports listing data from the server 
*2) randomly sample the target number of sample size in each facility 
*3) creates three output files 

*  DATA IN:	
*		1. MOCK client-level listing files from each facility AND service area
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
***** B.1. Import raw data from LimeSurvey 
***** B.2. Export/save the data daily in CSV form with date 
***** B.3. Check and drop odd rows
***** B.4. Drop duplicate cases 

* C. Cleaning - variables
***** C.1. Change var names to lowercase
***** C.2. Clean and create analysis var
***** C.3. Create one language variable <<<<<<<<<<== MUST BE ADAPTED: MAKE IT CONSISTENT WITH THE LIME SURVEY FORM
***** C.4. Assign facilityid <<<<<<<<<<== MUST BE ADAPTED: MAKE IT CONSISTENT WITH THE LIME SURVEY FORM
***** C.5. Sort by facilityid

* D. Merge with facility information 
***** D.1. Merge with facility information 
***** D.2. More cleaning 

* D.A Expand and scramble the mock data <<<<<<<<<<== DELETE THIS SECTION WHEN WORKING WITH REAL DATA

* E. Export datafile with all listing process information

* F. Assessment of the listing progress
***** F.1 gen listing progress check variables
***** F.2 collapse by district 

* G. Sampling 
***** G.1 Keep only those who are "listed" with phone numbers
***** G.2 Sample by facility
***** G.3 Append all sample by facility
***** G.4 Export datafile with sampled clients

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
global mydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/"
cd $mydir

*** Define a directory for the chartbook (can be same or different from the main directory)
global chartbookdir "$mydir"

*** Define a directory for downloaded lime survey data
global downloadcsvdir "$mydir/ListingFilesDownloaded/"

*** Define a directory for COMBINED LISTING data files
global listingdatadir "$mydir/ListingData/"

*** Define a directory for stata log and any other outout note files
global listingnotedir "$mydir/ListingNote/"

*** Define local macro for the survey 
local country	 		 EXAMPLE /*country name*/	
local round 			 P /*round*/		
local year 			 	 2023 /*year of the mid point in data collection*/	
local month 			 6 /*month of the mid point in data collection*/	

local surveyid 			 885938 /*LimeSurvey survey ID*/

*** Define local macro for response options specific to the country 

local countrylanguage1	 Spanish /*Country language 1*/

/*Study district names: must match with district code in ORANGE tab*/
local geoname1	 		 Mfantseman 
local geoname2	 		 Suhum
local geoname3	 		 West Gonja
local geoname4	 		 South Dayi

/*Facility type: must match with facility_type numeric code in ORANGE tab*/
local type1 			 District Hospital 
local type2 			 Health Center 
local type3 			 CHPS
		
*** local macro for analysis (no change needed)  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

***** B.1. Import raw data from LimeSurvey 
import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid'&language=en&function=createExport", case(preserve) clear
	
		d, short

***** B.2. Export/save the data daily in CSV form with date 	

export delimited using "$downloadcsvdir/LimeSurvey_PREM_Listing_`country'_$date.csv", replace
*We need the next line until there are more data entry in the mock link....
*import delimited "$downloadcsvdir/LimeSurvey_PREM_CT_EXAMPLE_16Oct2023.csv", case(preserve) clear 

***** B.3. Check and drop odd rows

drop if submitdate==""
		
***** B.4. Check and drop duplicate cases 
*
	* B.4.1 check variables with "id" in their names
		lookfor id
		
		*****CHECK HERE: 
		codebook *id 	
		*	this is an ID variable generated by LimeSurvey, not client ID
		*	do not use it for analysis 
		*	still there should be no missing and it is used for data check	
		rename ïid formid
		
	* B.4.2 check rows with all missing values
		ds
		egen nvarmiss = rowmiss(`r(varlist)')
		d, short	
		
		gen allmissing = nvarmiss==`r(k)'
		*****CHECK HERE: 
		tab allmissing, m
		*	there should be 0, but
		*	drop if any rows that are completely missing 
		drop if allmissing==1
		drop nvarmiss allmissing
	
	* B.4.3 check duplicates, based on unique ID variables for clients
		duplicates tag Q100a Q100c formid, gen(duplicate) 

		*****CHECK HERE: 	
		tab duplicate, m
		*	there should be no 1 or higher 
		* 	if there is any, 
		*	the following will identify the latest entry for the duplicates
		*	In the mock dataset, 
		*	there are two clients that have three data entries for practice purpose. 
			
			/* 
			* must check string value "mask" in the "clock" line for submitdate, 
			*		depending on the format/structure of the string var submitdate 
			*		use the correct specification
			* REFERENCE: https://www.stata.com/manuals13/u24.pdf
			* REFERENCE: https://www.stata.com/manuals13/ddatetime.pdf#ddatetime
			*/
			
			*** 1. check specification
			rename submitdate submitdate_string	/*rename to str*/		
			codebook submitdate_string /*identify format/structure of the string*/
			
			*** 2. clock
			gen double submitdate 	= clock(submitdate_string, "YMD hms") 
			*gen double submitdate 	= clock(submitdate_string, "MD20Y hms") /*if 2-digit year*/ 
			*gen double submitdate 	= clock(submitdate_string, "MDY hm") /*if no second*/ 
			
			*** 3. format
			format submitdate %tc 
			*list submitdate* in 1/2		
				
		sort Q100a Q100c formid submitdate
		list Q100a Q100c formid submitdate if duplicate!=0  
		*****CHECK HERE: 
		*	check submitdate within each repeated client, 
		*	Again, in the mock dataset, 
		*	there are two clients that have three data entries for practice purpose. 

		*****drop duplicates before the latest submission 
		egen double submitdatelatest = max(submitdate) if duplicate!=0, ///
			by(Q100a Q100c formid) /*LATEST TIME WITHIN EACH DUPLICATE*/					
						
			*format %tcnn/dd/ccYY_hh:MM submitdatelatest /*"format line without seconds*/
			format %tcnn/dd/ccYY_hh:MM:SS submitdatelatest /*"format line with seconds*/
			
			sort Q100a Q100c formid submitdate
			list Q100a Q100c formid submitdate* if duplicate!=0  
			
	* B.4.4 drop duplicates
	
		drop if duplicate!=0  & submitdate!=submitdatelatest 
		
		*****confirm there's no duplicate cases, based on facility code
		duplicates report Q100a Q100c formid,
		*****CHECK HERE: 
		*	Now there should be no duplicate, yay!!   

		drop duplicate submitdatelatest

**************************************************************
* C. Data cleaning - variables 
**************************************************************

***** C.1. Change var names to lowercase
 
	rename *, lower

***** C.2. Clean and create analysis var

	lab var q100a "district"
	lab var q100c "listing area"
	lab var q101 "initial" 
	lab var q102 "interest"	
	lab var q103 "phone"
	lab var q105a "agree"
	lab var q105 "name"
	lab var q106 "phone number"
	lab var q106 "phone number, repeated"
	
	rename q100c listingarea
	rename q102 interest	
	rename q103 phone
	rename q105a agree
	rename q105 name
	rename q106 number
	rename q107 number2
	
	rename submitdate listingdate
	
	tostring number, replace
	tostring number2, replace
	
	gen byte listinginfocomplete = name!="" & number!="" /*those who provided name and number*/
		
***** C.3. Create one language variable <<<<<<<<<<== MUST BE ADAPTED: MAKE IT CONSISTENT WITH THE LIME SURVEY FORM
	
	gen language=.
		replace language = q104a if q100a==1 
		replace language = q104b if q100a==2

***** C.4. Assign facility id <<<<<<<<<<== MUST BE ADAPTED: MAKE IT CONSISTENT WITH THE LIME SURVEY FORM
		
	gen facilityid=.
		replace facilityid = 1101 if q100bsq001==1
		replace facilityid = 1202 if q100bsq002==1
		replace facilityid = 1203 if q100bsq003==1
		replace facilityid = 1304 if q100bsq004==1
		replace facilityid = 1305 if q100bsq005==1
		replace facilityid = 1306 if q100bsq006==1
		replace facilityid = 4101 if q100bsq007==1
		replace facilityid = 4202 if q100bsq008==1
		replace facilityid = 4203 if q100bsq009==1
		replace facilityid = 4304 if q100bsq010==1
		replace facilityid = 4305 if q100bsq011==1
		replace facilityid = 4306 if q100bsq012==1
	
***** C.5 sort by facility id
		
	sort facilityid /*ready for merging with the sampling design info*/
	
save temp.dta, replace	

**************************************************************
* D. Merge with facility information 
**************************************************************
  
***** D.1. Merge with facility information 

import excel "$chartbookdir/PREM_Pilot_Chartbook_WORKING.xlsx", sheet("Facility_sample") firstrow clear 
		
	rename *, lower
		
		d

		/* 
		this worksheet aka ORANGE TAB has background characteristics of the sentinel facilites.
		PREMs team in the country will provide this information
		
		Contains data
		  obs:            25                          
		 vars:             8                          
		 size:           625                          
		--------------------------------------------------------------------------------------------------
					  storage   display    value
		variable name   type    format     label      variable label
		--------------------------------------------------------------------------------------------------
		facilityid      int     %10.0g                facilityid
		district        byte    %10.0g                district
		facility_type   byte    %10.0g                facility_type
		managing_auth~y byte    %10.0g                managing_authority
		target_sample~e int     %10.0g                target_sample_size
		mode_design     str9    %9s                   mode_design
		language_design str7    %9s                   language_design
		--------------------------------------------------------------------------------------------------
		Sorted by: 

	*/ 
	
		codebook facilityid /*this is assigned for the study, same with A005 in PREMs*/ 
	
	keep if mode_design=="Telephone"
	
	sort facilityid	
	merge facilityid using temp.dta, 
	
		tab _merge
			
		*****CHECK HERE: 
		
		/*
			
			.                 tab _merge

			 _merge |      Freq.     Percent        Cum.
		------------+-----------------------------------
				  1 |         14        1.96        1.96
				  3 |        700       98.04      100.00
		------------+-----------------------------------
			  Total |        714      100.00


		*/
		
		*		all should be 3 (i.e., match) by the end of the listing*/
		*		until then there will be 1 (facilities with no listing) and 3*/
		
		keep if _merge==3 /*for practice purposes*/
		
		drop _merge*

***** D.2. More cleaning 
	
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
	
	#delimit cr

**************************************************************
* D.A Expand and scramble the mock data <= DELETE THIS SECTION WHEN WORKING WITH REAL DATA
**************************************************************

	expand 300 

	* RECODE 
	foreach var of varlist interest phone language{
		recode `var' .=0
	}	
	
	* SCRAMBLE
	set seed 410	
	generate random = runiform()
		recode interest	(1=0) (0=1) if random>0.90
		recode phone 	(1=0) (0=1) if random>0.70 
		recode language	(1=0) (0=1) if random>0.50
		recode agree	(1=0) (0=1) if random>0.45
		drop random 
	
	* MAKE IT INTERNALLY CONSISTENT
		replace phone=0 if interest==0
		replace language=0 if phone==0
		replace agree=0 if language==0
		
		foreach var of varlist name number number2{
		replace `var'="" if agree==0
		}
	
	replace formid = _n
	
	drop listinginfocomplete 
	gen byte listinginfocomplete = name!="" & number!="" /*those who provided name and number*/
	
**************************************************************
* E. Export 
**************************************************************

	*date and time when the listing files were combined
	gen updatedate = "$date" 

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"
	
export excel using "$listingdatadir/PREM_`country'_R`round'_LIST.xlsx", firstrow(variables) replace
save "$listingdatadir/PREM_`country'_R`round'_LIST.dta", replace

**************************************************************
* F. Assessment of the listing progress
**************************************************************
use "$listingdatadir/PREM_`country'_R`round'_LIST.dta", clear

***** F.1 gen listing progress check variables

	gen num_total = 1
	
	gen num_interest = 1 if interest==1 /*interested in the study*/
	gen num_phone = 1 if phone==1 /*PLUS have access to phone numbers*/
	gen num_language = 1 if language==1 /*PLUS speak in the language*/
	
	gen num_listed = 1 if listinginfocomplete==1 /*gave both name and number*/
		
	gen numfacilities = 1
	
	save temp.dta, replace 
	
***** F.2 collapse by district 
capture log close
log using "$listingnotedir/ListingCheck_PREM_`country'_R`round'_$date.log", replace

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

putdocx save "$listingnotedir/ListingProgress_$date.docx", replace
*/
**************************************************************
* G. Sampling 
**************************************************************

***** have the temp file ready for step G.3 below....
clear
tempfile building
save `building', emptyok	

***** G.1 Keep only those who are "listed" with phone numbers

use "$listingdatadir/PREM_`country'_R`round'_LIST.dta", clear

	sum interest phone language agree listinginfocomplete
			
keep if listinginfocomplete==1
	
	egen num_listed_facility = count(name), by (facilityid) /*number listed by facility*/
	
***** G.2 Sample by each facility

    levelsof facilityid, local(levels)
	
    foreach level of local levels {
		preserve
		keep if facilityid ==`level' 
			
			set seed 38 /*MUST SET SEED for reproducibility*/
			
			sum target_sample_size /*target SS in each facility*/ 
			return list /*save the target SS as a scalar*/ 
			sample `r(mean)', count by(facilityid) /*sample the numer of target clients*/
			list facilityid name number*
		
		save "$listingdatadir/sample_`level'.dta", replace
		restore
	}

***** G.3 Append all sample by facility
	    
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
		collapse (mean) target* num_*, by (district type facilityid) 
		list
		* 	Each type of facility has different target sample size
		* 	Also each facility will have different number of clients who are listed 
		*	they can be similar within a same type, but unlikely identical... 
		* 	Also, it is possible the number of listed is less than the target sample size...
		*	
	restore
		
***** G.4 Export 		

	*** Keep only variables essential to call/interview	
	keep  name number district facility_name listingdate facilityid formid
	
	*** Sort and create a serial number
	sort district listingdate facility_name formid
	
	gen sample_number = _n
	
	*** Order 
	order sample_number name number district facility_name listingdate facilityid formid
	
export excel using "$listingdatadir/PREM_`country'_R`round'_SAMPLE.xlsx", firstrow(variables) replace
save "$listingdatadir/PREM_`country'_R`round'_SAMPLE.dta", replace	
	

END OF DATA CLEANING AND MANAGEMENT AND SAMPLING 
