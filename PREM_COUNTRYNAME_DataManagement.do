clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of the PREM questionniare version: 
*	Patient experiences in primary care: The WHO PREM PC Suite of patient questionnaires
*	Version 5.0.0. survey, 20th August 2024
*	LINK HERE
* Date of last code update: 08/31/2024
*	https://github.com/yoonjoung/WHO_PREM

*This code 
*1) imports and cleans dataset from Lime Survey, and 
*2) creates indicator estimate data for dashboards and chartbook. 
*		=====> First PURPLE Tab in Chartbook: "PREMs_estimates"
*3) conducts minimum data quality check 

*  DATA IN:	
*		1. CSV file daily downloaded from Limesurvey 	
*		2. facility sample information in Chartbook (ORANGE TAB)

*  DATA OUT: 
*		1. raw data (as is, downloaded from Limesurvey) 
*			=> CSV, dta, and GREEN TAB in Chartbook   	
*		2. cleaned data with additional analytical variables in Chartbook and, 
*			for further analyses, as a datafile 
*			=> CSV, dta, and BLUE TAB in Chartbook 
*		3. summary estimates of indicators in Chartbook and as a datafile 	
*			=> CSV, dta, and the first PURPLE TAB in Chartbook 

*  NOTE OUT (log file for minimum data quality check)  
*		1. DataCheck_CombinedCOVID19HFA_`country'_R`round'_$date.log

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: directories and local macro

* B. Import and drop duplicate cases
*****B.1. Import raw data from LimeSurvey AND export/save in CSV
*****B.2. Export raw Respondent-level data to chartbook (GREEN TAB)
*****B.3. Drop duplicate cases 

* C. Cleaning - variables
*****C.1. Change var names to lowercase
*****C.2. Assess and drop timestamp data, as needed 
*****C.3. Change var names 
*****C.4. Consolidate interview result variable Q403
*****C.5. Find non-numeric variables and desting 
*****C.6. Label values 
*****C.7. Prepare for merge with facility information  

* D. Merge with facility information 
*****D.1. Merge with facility information 
*****D.2. More cleaning 

* D.A. Expand and scramble the mock data <<<<<<<<<<== DELETE THIS SECTION WHEN WORKING WITH REAL DATA

* E. Create analytical variables 
*****E.0. Drop data that were entered for practice and test <<<<<<<<<<== ACTIVATE THIS SECTION
*****E.1. Construct analysis variables 
*****E.2. Export Clean Respondent-level data to chartbook (BLUE TAB)

* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chartbook (PURPLE TAB) and for dashboard

* G. MINIMUM data quality check 

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

local country	 		YourCountryName /*country name*/	
local round 			1 /*round*/		
local year 			 	2023 /*year of the mid point in data collection*/	
local month 			12 /*month of the mid point in data collection*/	

local surveyid_lang1 	123456 /*LimeSurvey survey ID for COUNTRY LANGUAGE 1 form*/
local surveyid_lang2 	654321 /*LimeSurvey survey ID for COUNTRY LANGUAGE 2 form*/

local version 	 	 	full /*Q version among the four, for Section E.1 */
// local version 	 	 	compact /*Q version among the four, for Section E.1 */
// local version 	 	 	short /*Q version among the four, for Section E.1 */
// local version 	 	 	screen /*Q version among the four, for Section E.1 */

local startdate 	 	20231214 /*First date of the actual listing - in YYYYMMDD */ 

*** Define local macro for response options specific to the country 

local countrylanguage1	 Korean /*Country language 1*/
local countrylanguage2	 Spanish /*Country language 2*/

/*Study district names: must match with district code in ORANGE tab*/
local geoname1	 		 Maryland
local geoname2	 		 Texas
local geoname3	 		 California
local geoname4	 		 Georgia

/*Facility type: must match with facility_type numeric code in ORANGE tab*/
local type1 			 District Hospital 
local type2 			 Health Center 
local type3 			 Health Post
		
*** local macro for analysis (no change needed)  
local today		= c(current_date)
local c_today	= "`today'"
global date		= subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import raw data from LimeSurvey AND export/save in CSV

dir $downloadcsvdir

* COUNTRY LANGUAGE 1
* suppress the next line until you have your own surveyid. We will work with the practice data instead. 
// import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid_lang1'&language=en&function=createExport", case(preserve) clear
import delimited "$downloadcsvdir/LimeSurvey_PREM_EXAMPLE_R1_Lang1.csv", case(preserve) clear 
export delimited using "$downloadcsvdir/LimeSurvey_PREM_`country'_R`round'_`countrylanguage1'_$date.csv", replace
	
	d, short	
	d Q001 Q3*
	tab Q001 Q301, m
	gen limesurveyform = "`countrylanguage1'"	
	save temp.dta, replace

* COUNTRY LANGUAGE 2
* suppress the next line until you have your own surveyid. We will work with the practice data instead. 	
// import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid_lang1'&language=en&function=createExport", case(preserve) clear
import delimited "$downloadcsvdir/LimeSurvey_PREM_EXAMPLE_R1_Lang2.csv", case(preserve) clear 
export delimited using "$downloadcsvdir/LimeSurvey_PREM_`country'_R`round'_`countrylanguage2'_$date.csv", replace
		
		
	d, short
	d Q001 Q3*
	tab Q001 Q301, m
	gen limesurveyform = "`countrylanguage2'"
			
	append using temp.dta, 

		tab limesurveyform, m
		tab limesurveyform Q001, m
		tab A001 limesurveyform, m

*****B.2. Export raw Respondent-level data to chartbook (GREEN TAB)	

	* MASK idenitifiable information for respondents/interviewers.
	* Interviewer name 
	foreach var of varlist Q002SQ001comment {
		replace `var'=""
		}		
		
export excel using "$chartbookdir/PREM_COUNTRYNAME_Chartbook.xlsx", sheet("Client_raw_data") sheetreplace firstrow(variables) nolabel

	/*
	This data would have all sampled cases:
	For FTF, the dataset will grow as list/enrollment is going 
	For Phone interviews, the dataset will have all sampled cases -
	even when interviewers have not called them yet or 
	even when interviewers refused to participate 
	
	check against limesurvey. see how it will be structured...
	*/
		
*****B.3. Drop duplicate cases 

	* B.3.1 check variables with "id" in their names
		lookfor *id
		
		*****CHECK HERE: 
		codebook *id 	
		*	this is an ID variable generated by LimeSurvey, not client ID
		*	do not use it for analysis 
		*	still there should be no missing	
	
	* B.3.2 check rows with all missing values
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
	
	* B.3.3 check duplicates, based on unique ID variables for clients
		duplicates tag A004 A005 A007, gen(duplicate) 
				
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
			list submitdate* in 1/5			
				
		sort A001 duplicate A004 A005 A007 submitdate	
		list A004 A005 A007 submitdate if duplicate!=0  
		
		*****CHECK HERE: 
		*	check submitdate within each repeated client, 
		*	Again, in the mock dataset, 
		*	there are two clients that have three data entries for practice purpose. 

		*****drop duplicates before the latest submission 
		egen double submitdatelatest = max(submitdate) if duplicate!=0, ///						
			by(A004 A005 A007) /*LATEST TIME WITHIN EACH DUPLICATE*/	
			
			*format %tcnn/dd/ccYY_hh:MM submitdatelatest /*"format line without seconds*/
			format %tcnn/dd/ccYY_hh:MM:SS submitdatelatest /*"format line with seconds*/
			
			sort A004 A005 A007 submitdate			
			list A004 A005 A007 submitdate* if duplicate!=0  
						
	* B.3.4 drop duplicates
	
		drop if duplicate!=0  & submitdate!=submitdatelatest 
		
		*****confirm there's no duplicate cases, based on facility code
		duplicates report A004 A005 A007, /*EDIT 1/10/2024*/
		*****CHECK HERE: 
		*	Now there should be no duplicate, yay!!   

		drop duplicate submitdatelatest 

**************************************************************
* C. Data cleaning - variables 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower

*****C.2. Assess and drop timestamp data, as needed 

	capture drop *time* 
	*interviewtime is availabl in dataset only when directly downloaded from the server, not via export plug-in used in this code
	*So, just do not deal with interview time for now. 

*****C.3. Change var names 

	*to drop odd elements "y" "sq" - because of Lime survey's naming convention 

	/*
	rename (*sq*) (*_*) 		
	rename (q201_*_a1) (q201_*_a)
	rename (q201_*_a2) (q201_*_b)
	rename (q503*) (q503_0*)
		
	lookfor sq
	lookfor a
	lookfor b
	
	lookfor other /* We have only two questions where text entry for other is allowed*/ 
	*/

*****C.4. Consolidate interview result variable q302 - 

	gen q302=""
		replace q302 = q302b if a001=="A1" /*PHONE*/
		replace q302 = q302a if a001=="A2" /*FTF*/
	
*****C.5. Find non-numeric variables and desting 

	*****************************
	* Cover
	*****************************
	sum a*

	foreach var of varlist a001 a010 a011 {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}

	sum a*

	*****************************
	* Section 0
	*****************************
	sum q0*

	sum q001		
	
	*****************************
	* Section 1
	*****************************
	sum q1*
	
	foreach var of varlist q1* {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}

	sum q1*			
	
	*****************************	
	* Section 2
	*****************************
	sum q2*	
		
	foreach var of varlist q202 q203  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	sum q2*		

	*****************************	
	* Section 3
	*****************************
	sum q3*
		
	foreach var of varlist q301 q302*  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
		
	sum q3*
		
*****C.6. Label values 

	*****************************	
	* Cover
	*****************************
	
	#delimit;	
	
	lab define mode
		1 "1.Phone"
		2 "2.Face-to-face"
		;
	lab values a001 mode; 
	
	*****************************	
	* Section 1 
	*****************************

	* label defined in each version-specific do files. See Section E.1 Section 1
	
	*****************************	
	* Section 2
	*****************************
	
	#delimit;	
		
	lab define gender
		1 "1.Male"
		2 "2.Female"
		3 "3.Other"
		4 "4.Prefer not to respond"
		;
	lab values q202 gender; 
	
	lab define education
		1 "Never attended school"
		2 "Primary school"
		3 "Middle school" 
		4 "JSS/JHS"
		5 "SSS/SHS"
		6 "Vocational/technical"
		7 "Tertiary"
		;
	lab values q203 education; 

	#delimit cr
	
	*****************************	
	* Section 3
	*****************************
	
	#delimit;	

	lab define language
		1 "`countrylanguage1'"
		2 "`countrylanguage2'"
		;
	lab values q301 language; 
	
	lab define result
		1 "1.Completed"
		2 "2.Refused"
		3 "3.Partly completed"
		4 "4.POSTPONED"
		5 "5.PARTLY COMPLETED AND RESCHEDULED"
		6 "6.CALL DROPPED"
		;
	lab values q302 result; 

	#delimit cr

*****C.7. Prepare for merge with facility information 
			
	rename a005 facilityid 
	rename a007 samplenumber 	
	
	sort facilityid 	
	save temp.dta, replace

**************************************************************
* D. Merge with facility information 
**************************************************************
  
*****D.1. Merge with facility information 

import excel "$chartbookdir/PREM_COUNTRYNAME_Chartbook.xlsx", sheet("Facility_sample") firstrow clear 
		
	rename *, lower

		capture drop target_sample_size 
		d

		/* this worksheet has background characteristics of the sampled facilities.
		PREMs team in the country will provide this information
		
		  obs:            42                          
		 vars:            21                          
		 size:         6,300                          
		-------------------------------------------------------------------------------------------------------------
					  storage   display    value
		variable name   type    format     label      variable label
		-------------------------------------------------------------------------------------------------------------
		zone            str8    %9s                   Zone
		region          str8    %9s                   Region
		district_name   str10   %10s                  District_name
		facility_name   str27   %27s                  facility_name
		facility_type~e str36   %36s                  facility_type_name
		managing_auth~e str19   %19s                  managing_authority_name
		number          byte    %10.0g                number
		facilityid      int     %10.0g                facilityid
		district        byte    %10.0g                district
		facility_type   byte    %10.0g                facility_type
		managing_auth~y byte    %10.0g                managing_authority


		*/ 
	
		codebook facilityid /*this is assigned for the study, same with A005 in PREMs*/ 
	
	sort facilityid	
	merge facilityid using temp.dta, 
	
		tab _merge, m
		
		*****CHECK HERE: 
		*	all should be 3 (i.e., match) by the end of the data collection*/
						
		keep if _merge==3
		
		drop _merge*
		
*****D.2. More cleaning 
	
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
	
	lab define sector
		1 "`sector1'"
		2 "`sector2'" 
		;
	lab values sector sector; 		

	#delimit cr

**************************************************************
* D.A Expand and scramble the mock data <= DELETE THIS SECTION WHEN WORKING WITH REAL DATA
**************************************************************
/* 
You do not need to use this section when you use the practice data for the workshop. 
This section is helpful when you practice and check the code 
using mock interview data to your country's lime survey links. 
In that way, you can produce analysis results daily once actual data collection starts.
Specifically, it does the following: 
- increase the number of observations by 50
- scramble/recode values in randomly selected cases to give more variation
*/ 

// 	expand 50 
	
// 	* SCRAMBLE
// 	set seed 410	
// 	foreach var of varlist q1* q2* q302 q303{
// 	generate random = runiform()
// 		recode `var' (1=2) (4=3) if random>0.80
// 		recode `var' (2=1) (4=3) if random<0.20
// 		drop random 
// 	}	

**************************************************************
* E. Create analytical variables 
**************************************************************

***** E.0 Drop data that were entered for practice and test <= ACTIVATE THIS SECTION WHEN WORKING WITH REAL DATA

	codebook a002
	gen double interviewdate 	= dofc(clock(a002, "YMD hms")) 	
	format interviewdate  %td
	
		tab interviewdate, m
		
	list interviewdate q302* q002sq001comment if interviewdate < date("`startdate'","YMD") 
	/*CHECK THESE ARE INDEED PRACTICE INTWERVIEWS*/
		
	drop if interviewdate < date("`startdate'","YMD") 
		tab interviewdate, m		

*****E.1. Construct analysis variables 

* give prefix z for background characteristics, which can be used as analysis strata     
* give prefix x for binary variables, which will be used to calculate percentage   
* give prefix y for integer/continuous variables, which will be used to calculate total

	*****************************
	* Cover  
	*****************************
		
		/*
		* a005 has been renamed as facilityid
		lab var facilityid "facility ID from sample list" 
		*/
		
		gen str4 st_facilityid = string(facilityid,"%04.0f")
		gen str4 st_samplenumber = string(samplenumber,"%04.0f")
		
		codebook st_*
		
		gen clientid = st_facilityid + "_" + st_samplenumber 
		
		codebook *id
		
		gen country = "`country'"
		gen round 	= "`round'"
		gen month	=`month'
		gen year	=`year'
		
		gen mode 	= ""
			replace mode = "Phone" if a001==1
			replace mode = "FTF" if a001==2
		
		gen language = ""
			replace language = "`countrylanguage1'" if q301==1
			replace language = "`countrylanguage2'" if q301==2

	*****************************
	* Cover + Section 3 + q100a/B
	*****************************
	
	***** basic variables for disaggregated analysis 
						
		egen zage = cut(q201), at(18 30 40 50 99)
			codebook zage
			tabstat q201, by(zage) stats(min max)
			recode zage (18=1) (30=2) (40=3) (50=4)  
			*lab define zage 1 "18-34" 2 "35-49" 3 "50-64" 4 "65+" 
			lab define zage 1 "18-29" 2 "30-39" 3 "40-49" 4 "50+" 			
			lab values zage zage
		
		gen zgender = q202
			recode zgender 4=3
			lab define zgender 1 "Male" 2 "Female" 3 "Other/NoResponse"
			lab values zgender zgender
			
		gen byte zedu = q203>=3 & q203!=.
			lab define zedu 0 "primary or less" 1 "secondary or higher"
			lab values zedu zedu
		
		gen zdistrict = district
		gen ztype = type
		gen zsector = sector 
			lab values zdistrict geoname
			lab values ztype type 	
			lab values zsector sector 		
	
		gen version = "`version'"
			
	*****************************
	* Section 1: Items 
	*****************************
	
		tab version, m

/*this do file label raw variables and generate analysis variables*/  		
do PREM_DataManagement_items_`version'_version.do

	sum y_*

	*****************************
	* Section 1: Scale
	*****************************			
		
	***** Total score (0-10)
	/*
	Total PREMs score is average of select 9 items. 
	It is calculated consistenly across all four versions. 
		
		y_fc_soon			Did you receive care as soon as you needed?
		y_cont_allinfo		Do you believe that your primary care professionals had all the information they needed to treat your health problems, such as previous medical problems or current medication?
		y_comp_emo			Did your primary care professionals ask about your emotional health and well-being?
		y_coor_other		Did your primary care professional coordinate other professionals in managing your health care?
		y_coor_allinfo		When you were referred to other professionals, do you believe that they had all the information they needed about you to manage your health problems?
		y_pcc_care			Did your primary care professionals show care and compassion?
		y_cp_agree			Did you and your primary care professionals agree on a care plan and goals that would work for you? A care plan is a document to help you and others manage your health day-to-day. Care plans can include information about medicines, an eating or exercise plan, and goals you want to achieve, such as returning to work after injuries.
		y_prof_understand	Did your primary care professionals speak to you in a way you could understand?
		y_overall			How would you rate your overall experience of receiving care from your primary care professionals in the previous 12 months?	

	*/
		#delimit; 
		egen total_score = rowmean(
								y_fc_soon
								y_cont_allinfo
								y_comp_emo								
								y_coor_other
								y_coor_allinfo
								y_pcc_care
								y_cp_agree
								y_prof_understand								
								y_overall		
								)
		;
		#delimit cr
		
			replace total_score = ((total_score -1)/ 4)*10 
		
	***** Domain specific average score (0-10)	
		global itemlist "fc cont comp coor pcc cp prof"
		foreach item in $itemlist{	
			egen domain_score_`item' = rowmean(y_`item'*) 
			replace domain_score_`item' = ((domain_score_`item' -1)/ 4)*10 /*5-category response options: 1-5*/ 
			}	
	
		/*
		rowmean(varlist)
		may not be combined with by. It creates the (row) means of the variables in varlist, ignoring
		missing values. For example, if three variables are specified and, in some observations, one
		of the variables is missing, in those observations newvar will contain the mean of the two
		variables that do exist. Other observations will contain the mean of all three variables. If all
		values in varlist are missing for an observation, newvar is set to missing for that observation.
		*/

	***** SUPPRESS DOMAIN SPECIFIC SCORES IF SCREEN VERSION *
		global itemlist "fc cont comp coor pcc cp prof"
		foreach item in $itemlist{				
			replace domain_score_`item' = . if version=="screen"
			}			
			
		bysort version: sum *score*

	*****************************
	* Interview results
	*****************************

		gen xcomplete= q001==1 & q302==1
		
		tab q302 zdistrict, m
		bysort zdistrict: tab mode language, m

*****E.2. Export clean facility-level data to chart book 
	
	sort clientid
	save "$datadir/PREM_`country'_R`round'.dta", replace 		

	export delimited "$datadir/PREM_`country'_R`round'", replace 

	export excel using "$chartbookdir/PREM_COUNTRYNAME_Chartbook.xlsx", sheet("Client_clean_data") sheetreplace firstrow(variables) nolabel
		
**************************************************************
* F. Create indicator estimate data 
**************************************************************

use "$datadir/PREM_`country'_R`round'.dta", clear

	***** To get the total number of observations per relevant part 
	
	gen obs=1 	
	
	tab xcomplete, m
	keep if xcomplete==1
	drop xcomplete	
	
	save temp.dta, replace 
	
*****F.1. Calculate estimates - 

*** All languages 

		use temp.dta, clear
		collapse (count) obs (mean) y_* *score* , ///
			by(country round year month)
						
			gen language="All languages"
		
			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 	

*** By subgroup
			
		use temp.dta, clear				
		foreach subgroupvar of varlist zage zgender zedu {
		
		preserve
		drop if `subgroupvar'==.
		collapse (count) obs (mean) y_* *score* , ///
			by(country round year month `subgroupvar')
		
			gen language="All languages"
			
			append using "$datadir/summary_PREM_`country'_R`round'.dta"	, force	
			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 
		restore
		}			
			
*** By language

		use temp.dta, clear
		collapse (count) obs (mean) y_* *score* , ///
			by(country round year month language)
	
			append using "$datadir/summary_PREM_`country'_R`round'.dta"	, force	
			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 

*** By language: AND subgroup
			
		use temp.dta, clear				
		foreach subgroupvar of varlist zage zgender zedu {
		
		preserve
		drop if `subgroupvar'==.
		collapse (count) obs (mean) y_* *score* , ///
			by(country round year month language `subgroupvar')
		
			append using "$datadir/summary_PREM_`country'_R`round'.dta"	, force	
			save "$datadir/summary_PREM_`country'_R`round'.dta", replace 
		restore
		}
		
		
use "$datadir/summary_PREM_`country'_R`round'.dta", clear
		
		gen group=""
								
			replace group="Age" if zage!=.
			replace group="Gender" if zgender!=.
			replace group="Education" if zedu!=.
						
			replace group="Language_" + group 	if language!="" & group!="" /*by subgroup within district*/
			replace group="Language" 			if language!="" & group=="" 
			replace group="All" 				if language=="All languages" & group=="Language" 
			
		gen grouplabel=""	
		
			replace grouplabel="18-29" 	if zage==1
			replace grouplabel="30-39" 	if zage==2
			replace grouplabel="40-49" 	if zage==3
			replace grouplabel="50+" 	if zage==4

			replace grouplabel="Male" 				if zgender==1
			replace grouplabel="Female" 			if zgender==2
			replace grouplabel="Other/NoResponse" 	if zgender==3

			replace grouplabel="Primary or less" 	 if zedu==0
			replace grouplabel="Secondary or higher" if zedu==1			

			replace grouplabel="`countrylanguage1'_" + grouplabel if language=="`countrylanguage1'" & grouplabel!="" /*by subgroup within district*/
			replace grouplabel="`countrylanguage2'_" + grouplabel if language=="`countrylanguage2'" & grouplabel!="" /*by subgroup within district*/
			replace grouplabel="All_" + grouplabel if language=="All languages" & grouplabel!="" /*by subgroup within district*/
	
			replace grouplabel="`countrylanguage1'" if language=="`countrylanguage1'" & group=="Language"
			replace grouplabel="`countrylanguage2'" if language=="`countrylanguage2'" & group=="Language"		
			replace grouplabel="All" 				if language=="All languages"  & group=="All"		
				
		keep obs country language round year month group* y_* *score* z*

	***** trim decimal points 
		foreach var of varlist y_* {
			replace `var'=round(`var', 0.1)	
			format `var' %2.1f
			}		
			
		foreach var of varlist *score* {
			replace `var'=round(`var', 0.1)	
			format `var' %2.0f
			}				

	***** assess n, and suppress if estimates are based on small n
	* We will pick an acceptable and widely used but still arbitrary number. 
	* 25 as used in the DHS final report
	* https://dhsprogram.com/data/Guide-to-DHS-Statistics/Analyzing_DHS_Data.htm
	
		*****CHECK HERE: 
		sum obs, detail
		histogram obs, w(5)	freq ///
			xline(`r(p50)', lcolor(red)) xline(25, lcolor(blue)) ///
			title("Distribution of denominator size") ///
			xtitle("Number of observations in denominator") ///
			note("Red vertical line: median" "Blue vertical line: 25")
		*	Check the distribution. Figure out what rows that have a small N

		list language group grouplabel obs if obs<25
				
		foreach var of varlist y_* *score* {
			replace `var' =. if obs<25
		}
				
	***** replace grouplabel and check duplicates
		gen grouplabelcheck=""
		replace grouplabelcheck = language + "_" + group + "_" + grouplabel 
			
		*****CHECK HERE: 
		duplicates tag grouplabelcheck, gen(duplicate)
		tab duplicate
		* 	Ensure grouplabel is unique for every row 
	
			sort grouplabelcheck
			list language grouplabel grouplabelcheck z* obs if duplicate>0
					
			* Drop duplicates: 
			drop if grouplabelcheck == grouplabelcheck[_n-1]
			codebook grouplabelcheck
			drop duplicate
			drop z* grouplabelcheck
				
	***** order columns
		order country round year month language group grouplabel obs 
	
	***** sort rows
		sort country round year month language group grouplabel 
		
save "$datadir/summary_PREM_`country'_R`round'.dta", replace 
		
export delimited using "$datadir/summary_PREM_`country'_R`round'.csv", replace 

erase temp.dta	
*****F.2. Export indicator estimate data to chartbook AND dashboard

use "$datadir/summary_PREM_`country'_R`round'.dta", clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"

export excel using "$chartbookdir/PREM_COUNTRYNAME_Chartbook.xlsx", sheet("PREMs_estimates") sheetreplace firstrow(variables) nolabel keepcellfmt

**************************************************************
* G. MINIMUM data quality check 
**************************************************************

capture log close
log using "$datanotedir/DataCheck_PREM_`country'_R`round'_$date.log", replace

*** Minimum red-flag indicators will be listed. So, the shorter log, the better.  

*** 1. Estimates exceeding boundaries 

*WHAT DO THEY SUGGEST? Error(s) in analysis code. 
*ACTION: review and revise the code

use "$datadir/summary_PREM_`country'_R`round'.dta", clear	
	
	/*
	Estimates for core (0-10) that exceed boundaris.  	
	*/
	
	sort group grouplabel

			foreach var of varlist *score* {
				list group grouplabel `var' if `var'<0 | (`var'>100 & `var'!=.)
			}			
	
*** 2. Excessive missing/NA

*WHAT DO THEY SUGGEST? Data entry error by interviewers or respodent's poor partcipation 
*ACTION: monitor and improve interviewer performance 
	
use "$datadir/PREM_`country'_R`round'.dta", clear
log off

	/*count number of missing responses*/
	keep if xcomplete==1

			foreach var of varlist q2* {
				gen byte mbasic`var' = `var'==.
			}						
			foreach var of varlist q1* {
				gen byte mprem`var' = `var'==.
			}
			
// 			foreach var of varlist q2* {
// 				gen byte mwho5`var' = `var'==.
// 			}			
			
			global itemlist "basic prem"
			foreach item in $itemlist{	
				egen totalm`item'= rowtotal(m`item'*)
				}				
			egen totalm = rowtotal(mbasic* mprem*)
			gen byte evermissing = totalm>=1
			
			gen obs=1

log on
 			
	*QUESTION: 
	*1. What proportion of respondents have at least one missing responses? 
	preserve	
	collapse (count) obs (mean) evermissing, by(country language mode)
	list
	restore
	
	*2. What is the average number of missing responses in an interview? 
	preserve
	collapse (count) obs (mean) totalm* , by(country language mode)
	list 
	restore
	
	*QUESTION: 
	*3. Is missing concentrated in particular respondents? 
	*4. What is the highest number of missing responses in an interview? 
	preserve
	collapse (count) obs (max) totalm*, by(country language mode)
	list
	restore
	
	*QUESTION: 
	*5. Are there particular questions that drive missing responses?  	
	*6. What is the total number of missing responses in each question? 
	collapse (count) obs (sum) mbasic* mprem* , by(country language mode)
	bysort language mode: list
	
log close
	
*END OF DATA CLEANING AND MANAGEMENT 
