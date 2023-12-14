clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of last code update: 12/10/2023
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
***** E.1 Drop data that were entered for practice and test <<<<<<<<<<== ACTIVATE THIS SECTION
***** E.2 Export	

* F. Sampling 
***** F.1 Keep only those who are "listed" with phone numbers
***** F.2 Sample by facility
***** F.3 Append all sample by facility
***** F.4 Export datafile with sampled clients

* G. Report: Assessment of the listing progress
***** G.1 gen listing progress check variables
***** G.2 collapse by district 

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
global mydir "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/Workshop/PREM_DM_Zambia/"
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
local country	 		 Zambia /*country name*/	
local round 			 P /*round*/		
local year 			 	 2023 /*year of the mid point in data collection*/	
local month 			 12 /*month of the mid point in data collection*/	

local surveyid 			 194538 /*LimeSurvey survey ID*/

local startdate 	 	 20231207 /*First date of the actual listing - in YYYYMMDD */ 
local startdatetime      2023-12-07 14:30:00 /*Time when the actual listing started - SEE BELOW */ 
/*
* In Zambia, listing training was conducted on 12/7/2023, and actual listing started later in the day. 
* At around 02:30PM Zambia time, it was communicated that actual listing can start. 
* Therefore, there are mix of practice and real data on 12/7/2023. 
* We need to find the cutoff time...  
* The following file was downloaded at around 01:30PM 12/7/2023 Zambia time.
* It has 45 observations.  
import delimited "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/Workshop/PREM_DM_Zambia/ListingFilesDownloaded/LimeSurvey_PREM_Listing_EXAMPLE_7Dec2023.csv", clear
d, short
sort submitdate
list submitdate startdate q101 q105
		/*
		 41. | 2023-12-07 10:28:25   2023-12-07 10:26:00    C.H     Caroline  handima |
		 42. | 2023-12-07 10:30:17   2023-12-07 10:28:45    S.k         Sarah kalunga |
		 43. | 2023-12-07 10:43:45   2023-12-07 10:35:06     Js       Josephine sunga |
		 44. | 2023-12-07 10:49:31   2023-12-07 10:47:38     Mm       Michael  mubili |
		 45. | 2023-12-07 11:02:08   2023-12-07 11:00:21    L.k      Kicks in kamanga |
		*/

* The following file was downloaded at around 04:30PM 12/8/2023 Zambia time. 
* It has 280 observations. 
import excel "~/Dropbox/0iSquared/iSquared_WHO/PREM/Methods/4_DataAnalysis/Workshop/PREM_DM_Zambia/ListingFilesDownloaded/LimeSurvey_PREM_Listing_Zambia_8Dec2023.xlsx", sheet("Sheet1") firstrow clear
d, short
sort submitdate
list submitdate startdate Q101 Q105
		/*
		 41. | 2023-12-07 10:28:25   2023-12-07 10:26:00    C.H         Caroline  handima |
		 42. | 2023-12-07 10:30:17   2023-12-07 10:28:45    S.k             Sarah kalunga |
		 43. | 2023-12-07 10:43:45   2023-12-07 10:35:06     Js           Josephine sunga |
		 44. | 2023-12-07 10:49:31   2023-12-07 10:47:38     Mm           Michael  mubili |
		 45. | 2023-12-07 11:02:08   2023-12-07 11:00:21    L.k          Kicks in kamanga |
			 |----------------------------------------------------------------------------|
		 46. | 2023-12-07 13:49:03   2023-12-07 13:45:58     IB               IREEN BANDa |
		 47. | 2023-12-07 13:54:30   2023-12-07 13:49:52    IL                 0773821280 |
		 48. | 2023-12-07 15:57:26   2023-12-07 15:55:54    M.k           Maputo kapembwa |
		 49. | 2023-12-07 16:03:22   2023-12-07 15:58:34    I.u               Isaac utete |
		 50. | 2023-12-07 17:27:48   2023-12-07 17:25:36     Js       Josephine kasonteka |
		*/
*/

*** Define local macro for response options specific to the country 

local countrylanguage1	 Bemba /*Country language 1*/

/*Study district names: must match with district code in ORANGE tab*/
local geoname1	 		 Lusaka
local geoname2	 		 Chilanga
local geoname3	 		 Kapiri Mposhi
local geoname4	 		 Mkushi

/*Facility type: must match with facility_type numeric code in ORANGE tab*/
local type1 			 First-level Hospital 
local type2 			 Health Center 
local type3 			 Health Post

/*Target sample size*/ 
local districtss 		 177
local type1ss	 		 53
local type2ss	 		 44
local type3ss	 		 18

*** local macro for analysis (no change needed)  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

local currenttime=c(current_time)
local c_currenttime= "`currenttime'"
global time=subinstr("`c_currenttime'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

***** B.1. Import raw data from LimeSurvey 
import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid'&language=en&function=createExport", case(preserve) clear
	
		d, short

***** B.2. Export/save the data daily in Excel form with date 	

export excel using "$downloadcsvdir/LimeSurvey_PREM_Listing_`country'_$date.xlsx", firstrow(variables) replace nolabel

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
	rename q106 phonenumber
	rename q107 phonenumber2
		
	tostring phonenumber, replace
	tostring phonenumber2, replace
	
	gen listingdate = dofc(submitdate) 	
	format listingdate %td
	
	/*12/8/2023 ZAMBIA SPECIFIC EDIT STARTS*/ 
	
	*to figure out practice vs. real listing data on 12/7/2023
	gen double listingdatetime	= clock(submitdate_string, "YMD hms")
	format listingdatetime %tc 
	
	*take care of cases where phone number was entered instead of name
	gen name_correct = name
		quietly forval j = 0/9 {
			replace name_correct = subinstr(name_correct, "`j'", "", .)
		}
	list submitdate name* phonenumber* if name_correct != name
	
	*revise lisinginfocomplete
	gen byte listinginfoprovided = name!="" & phonenumber!="" /*those who provided name and number*/
	gen byte listinginfocomplete = name!="" & phonenumber!="" & (name_correct == name)/*those whose BOTH name and number are entered*/

	/*12/8/2023 ZAMBIA SPECIFIC EDIT ENDS*/		
	
***** C.3. Create one language variable <<<<<<<<<<== MUST BE ADAPTED: MAKE IT CONSISTENT WITH THE LIME SURVEY FORM
	
		tab q100a q104a /*English*/
		tab q100a q104b /*country language*/
	
	gen language=.
		replace language = q104b if q100a==1 | q100a==2 /*Bemba: Chilanga & Kapiri Mposhi*/ 
		replace language = q104a if q100a==3 | q100a==4 /*English: Lusaka & Mkushi*/ 

***** C.4. Assign facility id <<<<<<<<<<== MUST BE ADAPTED: MAKE IT CONSISTENT WITH THE LIME SURVEY FORM
	
	* Q100b series is in the order of facilities that are programmed in limesurvey backend
	* Check ORANGE TAB
	
	gen facilityid=.
		replace facilityid = 1101 if q100bsq001==1
		replace facilityid = 1202 if q100bsq002==1
		replace facilityid = 1203 if q100bsq003==1
		replace facilityid = 1304 if q100bsq004==1
		replace facilityid = 1305 if q100bsq005==1
		replace facilityid = 2101 if q100bsq006==1
		replace facilityid = 2202 if q100bsq007==1
		replace facilityid = 2203 if q100bsq008==1
		replace facilityid = 2304 if q100bsq009==1
		replace facilityid = 2305 if q100bsq010==1
		replace facilityid = 3101 if q100bsq011==1
		replace facilityid = 3202 if q100bsq012==1
		replace facilityid = 3203 if q100bsq013==1
		replace facilityid = 3304 if q100bsq014==1
		replace facilityid = 3305 if q100bsq015==1
		replace facilityid = 4101 if q100bsq016==1
		replace facilityid = 4202 if q100bsq017==1
		replace facilityid = 4203 if q100bsq018==1
		replace facilityid = 4304 if q100bsq019==1
		replace facilityid = 4305 if q100bsq020==1
	
***** C.5 sort by facility id
		
	sort facilityid /*ready for merging with the sampling design info*/
	
save temp.dta, replace	

**************************************************************
* D. Merge with facility information 
**************************************************************
  
***** D.1. Merge with facility information 

import excel "$chartbookdir/Zambia_PREM_Pilot_Chartbook_WORKING.xlsx", sheet("Facility_sample") firstrow clear 
		
	rename *, lower
		
		d

		/* 
		this worksheet aka ORANGE TAB has background characteristics of the sentinel facilites.
		PREMs team in the country will provide this information
                       
		--------------------------------------------------------------------------------------------------
					  storage   display    value
		variable name   type    format     label      variable label
		--------------------------------------------------------------------------------------------------
		
		province        str7    %9s                   Province
		district_name   str13   %13s                  District_name
		facility_name   str31   %31s                  facility_name
		facility_type~e str19   %19s                  facility_type_name
		managing_auth~e str10   %10s                  managing_authority_name
		number          byte    %10.0g                number
		facilityid      int     %10.0g                facilityid
		district        byte    %10.0g                district
		facility_type   byte    %10.0g                facility_type
		managing_auth~y byte    %10.0g                managing_authority
		target_sample~e byte    %10.0g                target_sample_size
		mode_design     str9    %9s                   mode_design
		language_design str7    %9s                   language_design

		--------------------------------------------------------------------------------------------------

	*/ 
	
		codebook facilityid /*this is assigned for the study, same with A005 in PREMs*/ 
	
	keep if mode_design=="Telephone"
	
	sort facilityid	
	merge facilityid using temp.dta, 
	
		tab _merge
		bysort district: tab facility_name _merge , m

		*****CHECK HERE: 
		
		/*
			
				.                 tab _merge

			 _merge |      Freq.     Percent        Cum.
		------------+-----------------------------------
				  1 |         12       57.14       57.14 <= facilities with no lising data uploaded yet
				  3 |          9       42.86      100.00 <= facilities with lising data uploaded
		------------+-----------------------------------
			  Total |         21      100.00


			 as of 12/8/2023 8:43 EST 
			 .                 tab _merge

			 _merge |      Freq.     Percent        Cum.
		------------+-----------------------------------
				  1 |          2        0.74        0.74
				  3 |        268       99.26      100.00
		------------+-----------------------------------
			  Total |        270      100.00
			  
			  -> district = 2

								  |        _merge
					facility_name |         1          3 |     Total
			----------------------+----------------------+----------
				  Chilanga Urban  |         0         18 |        18 
			Kris Katumba Health.. |         1          0 |         1 
			  Makeni_Konga Rural  |         1          0 |         1 
			  Mt Eugenia Hospital |         0         15 |        15 
			Mt Makulu Health Post |         0          3 |         3 
			----------------------+----------------------+----------
							Total |         2         36 |        38 


		*/
		
		*		all should be 3 (i.e., match) by the end of the listing*/
		*		until then there may be 1 (facilities with no listing) and 3*/
		
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

**************************************************************
* E. Export 
**************************************************************

*
***** E.1 Drop data that were entered for practice and test <= ACTIVATE THIS SECTION WHEN WORKING WITH REAL DATA
		tab listingdate, m
		
	gen byte temp = listingdatetime < clock("`startdatetime'", "YMD hms")
		tab listingdate temp, m

	*drop if listingdate < date("`startdate'","YMD") 
	drop if listingdatetime < clock("`startdatetime'", "YMD hms")
	
		tab listingdate, m
		drop temp
*/
		
***** E.2 Export	
	*date and time when the listing files were combined
	gen updatedate = "$date" 

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"
	
export excel using "$listingdatadir/PREM_`country'_R`round'_LIST.xlsx", firstrow(variables) replace
save "$listingdatadir/PREM_`country'_R`round'_LIST.dta", replace

**************************************************************
* F. Sampling 
**************************************************************

***** have the temp file ready for step G.3 below....
clear
tempfile building
save `building', emptyok	

***** F.1 Keep only those who are "listed" with phone numbers

use "$listingdatadir/PREM_`country'_R`round'_LIST.dta", clear

	sum interest phone language agree listinginfocomplete
			
keep if listinginfocomplete==1
	
	egen num_listed_facility = count(name), by (facilityid) /*number listed by facility*/
	
***** F.2 Sample by each facility

    levelsof facilityid, local(levels)
	
    foreach level of local levels {
		preserve
		keep if facilityid ==`level' 
			
			set seed 38 /*MUST SET SEED for reproducibility*/
			
			sum target_sample_size /*target SS in each facility*/ 
			return list /*save the target SS as a scalar*/ 
			sample `r(mean)', count by(facilityid) /*sample the numer of target clients*/
			list facilityid name phonenumber*
		
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
		collapse (mean) target* num_*, by (district type facilityid) 
		list
		* 	Each type of facility has different target sample size
		* 	Also each facility will have different number of clients who are listed 
		*	they can be similar within a same type, but unlikely identical... 
		* 	Also, it is possible the number of listed is less than the target sample size...
		*	
	restore
		
***** F.4 Export 		

	*** Add 0 infront of the phone number (COUNTRY SPECIFIC)
	gen zero = "0"
	egen phonenumbertemp = concat(zero phonenumber)
		list phonenumber*
		drop phonenumber
	rename phonenumbertemp phonenumber	

	*** Keep only variables essential to call/interview	
	keep  name phonenumber district_name facility_name listingdate facilityid formid district 
	*keep  name phonenumber district_name facility_name listingdate facilityid formid district type
	
	*** Sort and create a serial number
	sort district_name listingdate facility_name formid
	*drop formid
	
	*** Create extra variables that are useful for interview management 
	gen sample_number = _n
	gen language = "English"
		replace language = "`countrylanguage1'" if district_name =="`geoname1'" 
		
	lab var sample_number "sample serial number"
	lab var language "interview language"
	
	*** Order 
	order district_name district language listingdate facility_name facilityid sample_number name phonenumber 

save "$listingdatadir/PREM_`country'_R`round'_SAMPLE.dta", replace	
	drop formid	
export excel using "$listingdatadir/PREM_`country'_R`round'_SAMPLE.xlsx", firstrow(variables) replace nolabel

**************************************************************
* F.A Sampling - NEW SECTION: select all who are listed (12/14/2023) 
**************************************************************
use "$listingdatadir/PREM_`country'_R`round'_SAMPLE.dta", clear
		
	/*EDIT 12/14/2023*/
	*tab district type, m row
	*bysort district: tab facility_name type, m

		/*
		.         tab district type, m row

		+----------------+
		| Key            |
		|----------------|
		|   frequency    |
		| row percentage |
		+----------------+

					  |          facility_type
			 district | First-lev  Health Ce  Health Po |     Total
		--------------+---------------------------------+----------
			   Lusaka |        53         88         36 |       177 
					  |     29.94      49.72      20.34 |    100.00 
		--------------+---------------------------------+----------
			 Chilanga |        52         88         36 |       176 
					  |     29.55      50.00      20.45 |    100.00 
		--------------+---------------------------------+----------
		Kapiri Mposhi |        53         88         36 |       177 
					  |     29.94      49.72      20.34 |    100.00 
		--------------+---------------------------------+----------
			   Mkushi |        53         88         36 |       177 
					  |     29.94      49.72      20.34 |    100.00 
		--------------+---------------------------------+----------
				Total |       211        352        144 |       707 
					  |     29.84      49.79      20.37 |    100.00 
				
		*/
	
use "$listingdatadir/PREM_`country'_R`round'_LIST.dta", clear

keep if listinginfocomplete==1

	*** Add 0 infront of the phone number (COUNTRY SPECIFIC)
	gen zero = "0"
	egen phonenumbertemp = concat(zero phonenumber)
		list phonenumber*
		drop phonenumber
	rename phonenumbertemp phonenumber	

	*** Keep only variables essential to call/interview	
	keep  name phonenumber district_name facility_name listingdate facilityid formid district 
	*keep  name phonenumber district_name facility_name listingdate facilityid formid district type
	
	*** Sort and create a serial number
	sort district_name listingdate facility_name formid
	*drop formid
	
	*** Create extra variables that are useful for interview management 
	gen sample_number = _n
	gen language = "English"
		replace language = "`countrylanguage1'" if district_name =="`geoname1'" 
		
	lab var sample_number "sample serial number"
	lab var language "interview language"
	
	*** Order 
	order district_name district language listingdate facility_name facilityid sample_number name phonenumber 

	*tab district type, m row
	
		/*
		
					  |          facility_type
			 district | First-lev  Health Ce  Health Po |     Total
		--------------+---------------------------------+----------
			   Lusaka |        55         90         45 |       190 
					  |     28.95      47.37      23.68 |    100.00 
		--------------+---------------------------------+----------
			 Chilanga |        52         97         39 |       188 
					  |     27.66      51.60      20.74 |    100.00 
		--------------+---------------------------------+----------
		Kapiri Mposhi |        53         96         41 |       190 
					  |     27.89      50.53      21.58 |    100.00 
		--------------+---------------------------------+----------
			   Mkushi |        53         88         41 |       182 
					  |     29.12      48.35      22.53 |    100.00 
		--------------+---------------------------------+----------
				Total |       213        371        166 |       750 
					  |     28.40      49.47      22.13 |    100.00 

		*/
	
save "$listingdatadir/PREM_`country'_R`round'_SAMPLE_ALL.dta", replace	
	drop formid	
export excel using "$listingdatadir/PREM_`country'_R`round'_SAMPLE_ALL.xlsx", firstrow(variables) nolabel replace

use "$listingdatadir/PREM_`country'_R`round'_SAMPLE.dta", clear
	d
	codebook formid
	sort formid
save "$listingdatadir/PREM_`country'_R`round'_SAMPLE.dta", replace 
	
use "$listingdatadir/PREM_`country'_R`round'_SAMPLE_ALL.dta", clear
	d
	codebook formid
	sort formid	
	
	merge formid using "$listingdatadir/PREM_`country'_R`round'_SAMPLE.dta",
	tab _merge, m
	
	keep if _merge==1
	drop _merge
	
save "$listingdatadir/PREM_`country'_R`round'_SAMPLE_Reserve.dta", replace 	
	drop formid	
export excel using "$listingdatadir/PREM_`country'_R`round'_SAMPLE_Reserve.xlsx", firstrow(variables) nolabel replace	
	
**************************************************************
* G. Assessment of the listing progress - report
**************************************************************
use "$listingdatadir/PREM_`country'_R`round'_LIST.dta", clear

***** G.1 gen listing progress check variables

	gen num_total = 1
	
	gen num_interest = 1 if interest==1 /*interested in the study*/
	gen num_phone = 1 if phone==1 /*PLUS have access to phone numbers*/
	gen num_language = 1 if language==1 /*PLUS speak in the language*/
	
	gen num_agree = 1 if agree==1 /*PLUS agreed to provide name and number*/
	gen num_infoprovided = 1 if listinginfoprovided==1 /*PLUS gave both name and number*/
	gen num_listed = 1 if listinginfocomplete==1 /*PLUS both name and number ENTERED*/
		
	gen numfacilities = 1
	
	save temp.dta, replace 

***** G.2 collapse and export tables 
capture putdocx clear 
putdocx begin
putdocx paragraph, halign(center)
putdocx text ("PREMs `country' pilot"), linebreak bold 
putdocx text ("Listing progress update: `today' `currenttime'"), linebreak bold 

putdocx paragraph
putdocx text ("In this note, progress of listing for phone interviews is presented. ")
putdocx text ("Data mangers produce this note daily during the listing period. ")
putdocx text ("An important goal is to create a sampling frame that is sufficiently larger than ")
putdocx text ("the target number of clients to be sampled. ")
putdocx text ("Considering contact and response rates, the target sample size is ")
putdocx text ("size is `districtss' in each district - in order to achieve 150 completed interviews per ")
putdocx text ("district. Each facility has a different target sample size: `type1ss' in a `type1' , ")
putdocx text ("`type2ss' in a `type2', and `type3ss' in a `type3'."), linebreak  
putdocx text (" "), linebreak  
putdocx text ("Note: the target sample size was estimated based on various assumptions. ")  
putdocx text ("During the pilot, we may need to reassess the assumptions and adjust the target sample size.")  

	*Date and total screened for listing
	use temp.dta, clear	
		collapse (sum) num_total num_infoprovided num_listed, by(district_name) 
		
		putdocx paragraph	
		putdocx text ("Listing progress - overall"), linebreak bold	
		putdocx text ("To date, by district:"), linebreak 
		putdocx text ("- num_total: number of clients screened/approached"), linebreak 
		putdocx text ("- num_infoprovided: number of clients who gave name and number"), linebreak 
		putdocx text ("- num_listed: number of clients listed (i.e., whose BOTH name and number are entered for sampling)"), linebreak 
		putdocx table table = data(*), varnames 
		
	use temp.dta, clear	
		collapse (sum) num_total num_listed, by(district_name listingdate)
		
		*putdocx paragraph	
		*putdocx text ("Listing progress by date"), linebreak bold	
		*putdocx table table = data(*), varnames 
			
		bysort district_name (listingdate) : gen cumnum_listed = sum(num_listed)
		
		#delimit; 
		twoway scatter cumnum_listed listingdate,  
			by(district_name, 
				row(1) 
				title("Cumulative number of listed clients by date and district", size(medium)) 
				note("Horizontal red line is the target number of clients to sample", 
					 size(vsmall)) 
				)
			connect(l) mlabel(cumnum_listed)	
			yline(`districtss') ylabel(,labsize(small)) yscale(range(0, `districtss'))
			xlabel(,labsize(small) angle(45))
			ytitle("Number of clients", size(small)) 
			xtitle("Date", size(small)) 
			ysize(3) xsize(6)	
			;
			#delimit cr

		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

		putdocx paragraph
		putdocx text ("Listing progress by date and district"), linebreak bold	
		putdocx image "temp.png", height(3) width(6)					
		putdocx pagebreak
		
	/* 12/10/2023 EDIT STARTS
	
	use temp.dta, clear	
		collapse (sum) num_total num_listed, by(district_name facility_name listingdate)
		
		*putdocx paragraph	
		*putdocx text ("Listing progress by date"), linebreak bold	
		*putdocx table table = data(*), varnames 
			
		bysort district_name facility_name (listingdate) : gen cumnum_listed = sum(num_listed)
		
		#delimit; 
		twoway scatter cumnum_listed listingdate,  
			by(district_name facility_name, 
				row(4) 
				title("Cumulative number of listed clients by date and district and facility", size(medium)) 					 
				)
			connect(l) mlabel(cumnum_listed)	
			ylabel(,labsize(small)) 
			xlabel(,labsize(small) angle(45))
			ytitle("Number of clients", size(small)) 
			xtitle("Date", size(small)) 
			ysize(8) xsize(6)	
			;
			#delimit cr

		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

		putdocx paragraph
		putdocx text ("Listing progress by date and district and facility"), linebreak bold	
		putdocx image "temp.png", height(8) width(6)					
		putdocx pagebreak	
	
	* 12/10/2023 EDIT ENDS */
		
	*By district, number of listing progress in detail
	
	use temp.dta, clear		
		collapse (sum) num_*, by(district_name)
		
		putdocx paragraph
		putdocx text ("Listing progress by district, detail"), linebreak bold 
		putdocx table table = data(*), varnames	
		putdocx paragraph
		putdocx text ("- num_total: number of clients screened/approached"), linebreak
		putdocx text ("- num_interest: number of clients who expressed interest"), linebreak
		putdocx text ("- num_phone: number of clients have access to phone"), linebreak
		putdocx text ("- num_language: number of clients who speak the study language"), linebreak
		putdocx text (" "), linebreak
		putdocx text ("- num_agree: number of clients who agree to give name and number"), linebreak 
		putdocx text ("- num_infoprovided: number of clients who gave name and number"), linebreak 		
		putdocx text ("- num_listed: number of clients listed (i.e., whose BOTH name and number are entered for sampling)"), linebreak 			
		#delimit; 
		graph bar num_*,  
			by(district, 
				row(1) 
				title("Listing progress by district, detail", size(small)) 
				note("Horizontal red line is the target number of clients to sample", 
					 size(vsmall)) 
				)
			yline(`districtss') ylabel(,labsize(small))
			ytitle("Number of clients", size(small)) 
			blabel(bar)
			legend( 
				pos(6) size(vsmall) stack row(1)
				label(1 "Total asked")
				label(2 "Have interest")
				label(3 "Have phone")
				label(4 "Speak the language" )
				label(5 "Agreed" )
				label(6 "Gave info" )
				label(7 "Listed" )
				label(8 "Target sample size" "(Initial)" )	
				)
			bar(1, color(navy*0.4)) 
			bar(2, color(navy*0.6)) 
			bar(3, color(navy*0.8)) 
			bar(4, color(navy*1.0)) 
			bar(5, color(navy*1.2)) 
			bar(6, color(navy*1.4)) 
			bar(7, color(navy*2)) 				
			bar(8, color(cranberry)) 				
			ysize(3) xsize(6)	
			;
			#delimit cr

		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

		putdocx paragraph
		putdocx image "temp.png", height(3) width(6)					
		putdocx pagebreak
		
	*By district and facility, number of listing progress in detail
	use temp.dta, clear		
		collapse (sum) num_* (mean) target*, by(district_name type facility_name)
		order district_name type facility_name
		sort  district_name type facility_name
				
		putdocx paragraph
		putdocx text ("Listing progress by district and facility, detail"), linebreak bold  
		
		levelsof district_name
		foreach lev in `r(levels)' {
		
		#delimit; 
		graph bar num_* target_sample_size if district_name == "`lev'",  
			by(type facility_name, 
				row(2) iscale(*0.5) yrescale
				title("Listing progress by district and facility, detail - `lev'", size(small)) 
				note("", 
					 size(vsmall)) 
				)
			ylabel(,labsize(small))
			ytitle("Number of clients", size(small)) 
			blabel(bar)
			legend( 
				pos(6) size(vsmall) stack row(1)
				label(1 "Total asked")
				label(2 "Have interest")
				label(3 "Have phone")
				label(4 "Speak the language" )
				label(5 "Agreed" )
				label(6 "Gave info" )
				label(7 "Listed" )
				label(8 "Target sample size" "(Initial)" )				
				)
			bar(1, color(navy*0.4)) 
			bar(2, color(navy*0.6)) 
			bar(3, color(navy*0.8)) 
			bar(4, color(navy*1.0)) 
			bar(5, color(navy*1.2)) 
			bar(6, color(navy*1.4)) 
			bar(7, color(navy*2)) 				
			bar(8, color(cranberry)) 				
			ysize(8) xsize(8)	
			;
			#delimit cr

		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

		putdocx paragraph
		putdocx text ("District: `lev'"), linebreak 
		putdocx image "temp.png", height(8) width(8)
		putdocx pagebreak
		}
		
		putdocx paragraph
		putdocx text ("Data by facility"), linebreak bold	
		putdocx text ("- num_total: number of clients screened/approached"), linebreak
		putdocx text ("- num_interest: number of clients who expressed interest"), linebreak
		putdocx text ("- num_phone: number of clients have access to phone"), linebreak
		putdocx text ("- num_language: number of clients who speak the study language"), linebreak
		putdocx text (" "), linebreak
		putdocx text ("- num_agree: number of clients who agree to give name and number"), linebreak 
		putdocx text ("- num_infoprovided: number of clients who gave name and number"), linebreak 
		putdocx text ("- num_listed: number of clients listed (i.e., whose BOTH name and number are entered for sampling)"), linebreak 		
		putdocx table table = data(*), varnames			
		putdocx pagebreak
		
	/*12/10/2023 EDIT STARTS*/
	use temp.dta, clear		
		collapse (sum) num_* (mean) target*, by(district_name type facility_name listingdate)
		order listingdate district_name type facility_name 
		sort  listingdate district_name type facility_name 
		
		putdocx paragraph
		putdocx text ("Data by facility - SORTED BY DATE"), linebreak bold	
		putdocx text ("- num_total: number of clients screened/approached"), linebreak
		putdocx text ("- num_interest: number of clients who expressed interest"), linebreak
		putdocx text ("- num_phone: number of clients have access to phone"), linebreak
		putdocx text ("- num_language: number of clients who speak the study language"), linebreak
		putdocx text (" "), linebreak
		putdocx text ("- num_agree: number of clients who agree to give name and number"), linebreak 
		putdocx text ("- num_infoprovided: number of clients who gave name and number"), linebreak 
		putdocx text ("- num_listed: number of clients listed (i.e., whose BOTH name and number are entered for sampling)"), linebreak 		
		putdocx table table = data(*), varnames					
	
	/*12/10/2023 EDIT ENDS*/

putdocx save "$listingnotedir/ListingProgress_`country'_$date.docx", replace

***CLEAN UP***

local datafiles: dir "$mydir" files "temp*.*"

foreach datafile of local datafiles {
        rm `datafile'
}

GREAT, END OF DATA CLEANING AND MANAGEMENT AND SAMPLING 
