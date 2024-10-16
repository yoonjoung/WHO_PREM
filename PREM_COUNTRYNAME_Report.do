clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of last code update: 12/07/2023
*   See Github for history of changes: 
*	https://github.com/yoonjoung/WHO_PREM
*	https://github.com/yoonjoung/WHO_PREM/blob/main/PREM_Pilot_Report.do

*This code 
*1) runs the data management do file **BOTH FILES MUST BE IN THE SAME DIRECTORY**
*2) calculates process metrics for evaluation of the PREMs pilot implementation 
*3) produces outputs 
*		=====> Second PURPLE TAB in Chartbook: "Pilot_Implementation"

*  DATA IN:	
*		1. PREMs summary data (i.e., the first PURPLE TAB in Chartbook) 
*		2. Implementation summary data (i.e., the second PURPLE TAB in Chartbook) 

*  DATA OUT: 
*		1. Word document describing Implementation summary data - i.e., the second PURPLE TAB in Chartbook 

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: directories and local macro

* B. Run the implementation do file, which includes data management do file 

* C. Report: Implementation results 

* D. Report: PREMs results 

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

local country	 		 YourCountryName /*country name*/	
local round 			 1 /*round*/		
local year 			 	 2023 /*year of the mid point in data collection*/	
local month 			 12 /*month of the mid point in data collection*/	

local surveyid_lang1 		 123456 /*LimeSurvey survey ID for COUNTRY LANGUAGE 1 form*/
local surveyid_lang2 		 654321 /*LimeSurvey survey ID for COUNTRY LANGUAGE 2 form*/

local startdate 	 	 20231213 /*First date of the actual listing - in YYYYMMDD */ 

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
* B. Run the implementation do file, which includes data management do file 
**************************************************************

do PREM_COUNTRYNAME_Implementation.do

**************************************************************
* C. Report: Implementation results  
**************************************************************

use "$datadir/PREM_Pilot_Process_`country'_R`round'.dta", clear /*Second PURPLE tab*/
	
	*Review categorical variables for which implementatino progress is summarized
		sort group grouplabel
		list group grouplabel axis num_comp
		
	*Create studyarm variable 
		gen temp1 = substr(grouplabel, 1, strpos(grouplabel, "_")-1) 
		gen temp2 = substr(grouplabel, strpos(grouplabel, "_") + 1, .)
			replace temp2 = substr(temp2, 1, strpos(temp2, "_") )
		gen studyarm = temp2 + temp1 
		capture drop temp*

*****1. Overall summary 
capture putdocx clear 
putdocx begin
putdocx paragraph
putdocx text ("PREMs pilot in `country': Implementation progress summary"), bold linebreak
putdocx text ("(last updated on `today' `currenttime')"),  linebreak	
putdocx text (""),  

			sum num_comp if grouplabel=="English_FTF_All"
			return list 
putdocx text ("FTF: Total number interviewed in English: `r(mean)'"), linebreak

			sum num_comp if grouplabel=="`countrylanguage1'_FTF_All"
			return list 
putdocx text ("FTF: Total number interviewed in `countrylanguage1': `r(mean)'"), linebreak

			sum num_comp if grouplabel=="English_Phone_All"
			return list 					
putdocx text ("Phone: Total number interviewed in English: `r(mean)'"), linebreak

			sum num_comp if grouplabel=="`countrylanguage1'_Phone_All"
			return list 
putdocx text ("Phone: Total number interviewed in `countrylanguage1': `r(mean)'"), linebreak

putdocx paragraph	
putdocx text ("1. Number of who were sampled, were contacted, gave consent, and responded"), bold linebreak
{
preserve
		
		keep if group=="Study arm"
		d, short

		#delimit;
		graph bar num_samp num_cntsuccess num_resp num_comp50 num_comp,
			by(studyarm, 
				row(1)
				title("", size(small))				
				note("Preliminary results for internal review. Update as of: $date", size(vsmall)) )
			ytitle("Number") 
			legend( 
				pos(6) size(vsmall) stack row(1)
				label(1 "Sampled")
				label(2 "Contacted successfully")
				label(3 "Consented")
				label(4 "Responded 50% or more of the questions")
				label(5 "Completed interview*")
				)
			blabel(bar)	
			bar(1, color(cranberry*0.4)) 
			bar(2, color(cranberry*0.6)) 			
			bar(3, color(cranberry*0.8)) 
			bar(4, color(navy*0.6)) 
			bar(5, color(navy*0.8)) 
			ysize(3) xsize(6)
		;	
		#delimit cr	

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle[2].style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle[2].style.editstyle linestyle(color(white)) editcopy
		// subtitle[2] edits

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Number of those who are sampled, contacted, consented, and responded, by study arm"), bold linebreak	
putdocx image "temp.png", height(3) width(6)			
restore
}

*****2. Rates of contact, consent, and response 
putdocx pagebreak	
putdocx paragraph
putdocx text ("2. Rates of contact, consent, and response"), bold linebreak
{		
preserve
		
		keep if group=="Study arm"
		d, short

		#delimit;
		graph bar rate_cnt rate_cntsuccess rate_coop ,
			by(studyarm, 
				row(1)
				title("", size(small))
				note("Preliminary results for internal review. Update as of: $date", size(vsmall)) )
			ytitle("Response rate (%)") ylabel(0 (20) 100)
			legend( 
				pos(6) size(vsmall) row(1)
				label(1 "Contact, any")
				label(2 "Contact, success")
				label(3 "Cosent")
				)
			blabel(bar)
			bar(1, color(cranberry*0.4)) 
			bar(2, color(cranberry*0.6)) 			
			bar(3, color(cranberry*0.8)) 		
			ysize(3) xsize(6)
		;	
		#delimit cr	
		
		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle[2].style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle[2].style.editstyle linestyle(color(white)) editcopy
		// subtitle[2] edits

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Contact and consent rates among those who are sampled, by study arm"), bold linebreak
putdocx image "temp.png", height(3) width(6)			
		
		#delimit;
		graph bar rate_resp* ,
			by(studyarm, 
				row(1)
				title("", size(small))
				note("Preliminary results for internal review. Update as of: $date", size(vsmall)) )
			ytitle("Response rate (%)") ylabel(0 (20) 100)
			legend( 
				pos(6) size(vsmall) row(1)
				label(1 "Partial response rate")
				label(2 "Response rate")
				)
			blabel(bar)	
			bar(1, color(navy*0.4)) 
			bar(2, color(navy*0.6)) 
			ysize(3) xsize(6)
		;	
		#delimit cr	
		
		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle[2].style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle[2].style.editstyle linestyle(color(white)) editcopy
		// subtitle[2] edits

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Response rate among those who consented, by study arm"), bold linebreak
putdocx image "temp.png", height(3) width(6)	

		keep if regexm(studyarm, "Phone")==1
		
		#delimit;		
		graph hbar ///
			pct_ph_cntcoop pct_ph_cntnocoop ///
			pct_ph_cntsoelse pct_ph_noanswer pct_ph_invwronum,						
			stack
			by(studyarm, 
				col(1)
				title("", size(small))
				note("Preliminary results for internal review. Update as of: $date", size(vsmall)) )
			ytitle("(%)") ylabel(0 (20) 100)
			legend( 
				pos(6) size(vsmall) row(1) stack
				label(1 "Contacted," "respondent consented")
				label(2 "Contacted," "respondent did not consent")
				label(3 "Conrrect number," "respondent unavailable")
				label(4 "No answer" "after 3 calls")
				label(5 "Invalid/wrong number")
				)
			blabel(bar, position(center))	
			bar(1, color(green*0.7)) 	
			bar(2, color(green*0.5)) 	
			bar(3, color(cranberry*0.4)) 	
			bar(4, color(cranberry*0.6)) 	
			bar(5, color(cranberry*0.8)) 
			ysize(3) xsize(6)
		;	
		#delimit cr	
		
		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle[2].style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle[2].style.editstyle linestyle(color(white)) editcopy
		// subtitle[2] edits

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Among those sampled, percent distribution by call result"), bold linebreak
putdocx image "temp.png", height(3) width(6)			

restore
}
	
*****3. Progerss over time 
putdocx pagebreak	
putdocx paragraph
putdocx text ("3. Cumulative number of completed interviews and calls made over time"), bold linebreak
{			
preserve
	
		keep if regexm(group, "Date")==1

			*gen date variable 
				replace axis = axis + "/2023"
				gen date = date(axis, "MDY")
				format date %td
				
			*gen cumulative variable
				sort studyarm date 
				foreach var of varlist num_comp num_call{
					gen `var'cum = `var' 
					replace `var'cum = `var'cum + `var'cum[_n-1] ///
											if studyarm==studyarm[_n-1]										
				}
			
			*reshape
				keep studyarm date num_*cum 	
				reshape wide num_*cum, i(date) j(studyarm) string
			
		#delimit;
		graph twoway line num_compcum* date , 
			title("")
			note("Preliminary results for internal review. Update as of: $date", size(vsmall)) 
			ytitle("Cumulative number") 		
			yline(150)
			legend( 
				pos(3) size(vsmall) stack col(1)
				label(1 "FTF_English")
				label(2 "FTF_`countrylanguage1'")
				label(3 "Phone_English")
				label(4 "Phone_`countrylanguage1'")
				)			
			ysize(3) xsize(6)	
		;	
		#delimit cr

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color		
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Cumulative number of completed interviews over time, by study arm"), bold linebreak
putdocx image "temp.png", height(3) width(6)		

			
		#delimit;
		graph twoway line num_callcumPhone* date , 
			title("")
			note("Preliminary results for internal review. Update as of: $date", size(vsmall)) 
			ytitle("Cumulative number") 		
			legend( 
				pos(3) size(vsmall) stack col(1)
				label(1 "Phone_English")
				label(2 "Phone_`countrylanguage1'")
				)	
			ysize(3) xsize(6)	
		;	
		#delimit cr
		
		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color		
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Cumulative number of calls made over time, by study arm"), bold linebreak
putdocx image "temp.png", height(3) width(6)		

restore 
}

*****4. Completed interviews by call attempt number
putdocx pagebreak	
putdocx paragraph
putdocx text ("4. Distribution of completed interviews by the number of call attempt"), bold linebreak

{
use "$datadir/PREM_`country'_R`round'.dta", clear /*First PURPLE tab*/
		tab mode xcomplete, m

	keep if mode=="Phone" & xcomplete==1
	
	*sum the number of completed interviews by call number - a008
	collapse (sum) xcomplete , by(language a008) 
		
		* take care of missing
			replace a008 =99 if a008==. 
		* convert to percenta
			egen temp = sum(xcomplete), by(language) 
			replace xcomplete = round(100*xcomplete/temp, 0.1)
			drop temp
		* rename for legend 
			rename xcomplete call_attemp_ 
		
	*reshape to viz	
	reshape wide call_attemp_, i(language) j(a008)	
	
		#delimit;		
		graph hbar call_attemp_* ,						
			stack
			by(language, 
				col(1)
				title("", size(small))
				note("Preliminary results for internal review. Update  as of: $date"
					 "Note 1: 99 = missing"
					 "Note 2: call attempt number greater than 6 is likely a data entry error?" 
					 "Note 3: rounded to integer and the sum may not be 100%.", 
					 size(vsmall)) )
			ytitle("(%)") ylabel(0 (20) 100)
			legend( 
				pos(6) size(vsmall) row(1) stack
				label(1 "1")
				label(2 "2")
				label(3 "3")
				label(4 "4")
				label(5 "5")
				label(6 "6 calls")
				)							
			blabel(bar, pos(center))	
			bar(1, color(green*0.2)) 	
			bar(2, color(green*0.4)) 	
			bar(3, color(green*0.6)) 	
			bar(4, color(cranberry*0.2)) 	
			bar(5, color(cranberry*0.4)) 	
			bar(6, color(cranberry*0.6)) 	
			bar(7, color(cranberry*1.0)) 	
			bar(8, color(cranberry*1.1)) 			
			bar(9, color(cranberry*1.2)) 			
			bar(10, color(cranberry*1.3)) 			
			bar(11, color(cranberry*1.4)) 			
			bar(12, color(cranberry*1.5)) 			
			bar(13, color(cranberry*1.6)) 			
			bar(14, color(cranberry*1.7)) 			
			ysize(3) xsize(6)
		;	
		#delimit cr	
			
		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle[2].style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle[2].style.editstyle linestyle(color(white)) editcopy
		// subtitle[2] edits

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Among completed phone interviews, percent distribution by the number of attempted call to contact the respondent"), bold linebreak
putdocx image "temp.png", height(3) width(6)		
}

*****Save the note	
putdocx save "$datanotedir/Report_PREMs_Pilot_Implementation_`country'_$date.docx", replace		

**************************************************************
* D. Report: PREMs results 
**************************************************************

use "$datadir/summary_PREM_`country'_R`round'.dta", clear /*First PURPLE tab*/
gen dummy=.
save temp.dta, replace

*****1. Summary and domain-specific PREMs: Overall 

capture putdocx clear 
putdocx begin
putdocx paragraph
putdocx text ("PREMs pilot in `country': PRELIMINARY results"), bold linebreak
putdocx text ("(last updated on `today' `currenttime')"),  linebreak	
putdocx text (" "), linebreak
putdocx text ("1. Summary and domain-specific PREMs: overall"), bold linebreak
{
	use temp.dta, clear
		
		keep if group=="All"  
			tab grouplabel, m
			replace grouplabel = "All languages"
		
		#delimit;
		graph hbar total_score dummy domain_score_* ,
			by(grouplabel, 
				row(1)
				title("", size(small))
				note("Preliminary results for internal review. Update as of: $date", size(vsmall))
				legend(pos(3)) )
			ytitle("Score (0-100)", size(small)) yscale(r(0 10)) 
			legend( 
				size(vsmall) stack col(1)
				label(1 "PREMs summary" "(weighted average across domains)")
				label(2 "")
				label(3 "First contact")
				label(4 "Continuity")
				label(5 "Comprehensiveness")
				label(6 "Coordination")
				label(7 "Person-centered care")
				label(8 "Care plan")
				label(9 "Professional competence")				
				)
			blabel(bar)	
			bar(1, color(navy*2)) 
			bar(2, color(white)) 
			bar(3, color(navy*0.2))
			bar(4, color(navy*0.4))
			bar(5, color(navy*0.6))
			bar(6, color(navy*0.8))
			bar(7, color(navy*1))
			bar(8, color(navy*1.2))
			bar(9, color(navy*1.4))
			
		;	
		#delimit cr	

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle.style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle.style.editstyle linestyle(color(white)) editcopy
		// subtitle edits

		gr_edit .plotregion1.subtitle.style.editstyle size(small) editcopy
		// subtitle size

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Summary and domain-specific PREMs score"), bold linebreak
putdocx image "temp.png", height(3) width(6)
}

*****2. Summary and domain-specific PREMs: by language
putdocx pagebreak	
putdocx paragraph
putdocx text ("2. Summary and domain-specific PREMs: by language"), bold linebreak
{
	use temp.dta, clear
		
		keep if group=="Language" 
			tab grouplabel, m	

		#delimit;
		graph hbar total_score dummy domain_score_* ,
			by(grouplabel, 
				col(1)
				title("", size(small))
				note("Preliminary results for internal review. Update as of: $date", size(vsmall))
				legend(pos(3)) )
			ytitle("Score (0-100)", size(small)) yscale(r(0 10)) 
			legend( 
				size(vsmall) stack col(1)
				label(1 "PREMs summary" "(weighted average across domains)")
				label(2 "")
				label(3 "First contact")
				label(4 "Continuity")
				label(5 "Comprehensiveness")
				label(6 "Coordination")
				label(7 "Person-centered care")
				label(8 "Care plan")
				label(9 "Professional competence")		
				)
			blabel(bar, size(small))	
			bar(1, color(navy*2)) 
			bar(2, color(white)) 
			bar(3, color(navy*0.2))
			bar(4, color(navy*0.4))
			bar(5, color(navy*0.6))
			bar(6, color(navy*0.8))
			bar(7, color(navy*1))
			bar(8, color(navy*1.2))
			bar(9, color(navy*1.4))			
			ysize(7.5) xsize(6)
		;	
		#delimit cr	

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle[2].style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle[2].style.editstyle linestyle(color(white)) editcopy
		// subtitle[2] edits

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Summary and domain-specific PREMs score, by study arm"), bold linebreak
putdocx image "temp.png", height(7.5) width(6)
}

*****3. Summary and domain-specific PREMs: by background characteristics 
putdocx pagebreak	
putdocx paragraph
putdocx text ("3. Summary and domain-specific PREMs: by background characteristics"), bold linebreak

*putdocx pagebreak
putdocx paragraph
putdocx text ("3.1. Clients' Age"), bold linebreak
{
	use temp.dta, clear
				
		keep if strpos(group, "Age")>0
			tab grouplabel, m
			
				split grouplabel, p(_) limit(5)
			
				capture drop dummy	
				gen dummy="_"
				
			egen studyarm = concat(grouplabel1)
			gen axis = grouplabel2
			
			list grouplabel studyarm axis
				
		#delimit;
		graph hbar total_score ,
			over(axis)	
			by(studyarm, 
				col(1)
				title("", size(small))
				note("Preliminary results for internal review. Update as of: $date", size(vsmall))
				legend(off) )
			ytitle("Score (0-100)", size(small)) yscale(r(0 10))
			blabel(bar)	
			bar(1, color(navy*2)) 
			ysize(7.5) xsize(6)
		;	
		#delimit cr	

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle[2].style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle[2].style.editstyle linestyle(color(white)) editcopy
		// subtitle[2] edits

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Summary PREMs score by age group and study arm"), bold linebreak
putdocx image "temp.png", height(7.5) width(6)
}

putdocx pagebreak	
putdocx paragraph
putdocx text ("3.2. Clients' Gender"), bold linebreak
{
	use temp.dta, clear
		
		keep if strpos(group, "Gender")>0
			tab grouplabel, m
			
				split grouplabel, p(_) limit(5)
			
				capture drop dummy	
				gen dummy="_"
				
			egen studyarm = concat(grouplabel1)
			gen axis = grouplabel2
			
			list grouplabel studyarm axis
				
		#delimit;
		graph hbar total_score ,
			over(axis)	
			by(studyarm, 
				col(1)
				title("", size(small))
				note("Preliminary results for internal review. Update as of: $date", size(vsmall))
				legend(off) )
			ytitle("Score (0-100)", size(small)) yscale(r(0 10))
			blabel(bar)	
			bar(1, color(navy*2)) 
			ysize(7.5) xsize(6)
		;	
		#delimit cr	

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle[2].style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle[2].style.editstyle linestyle(color(white)) editcopy
		// subtitle[2] edits

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color		
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Summary PREMs score by gender and study arm"), bold linebreak
putdocx image "temp.png", height(7.5) width(6)
}

putdocx pagebreak	
putdocx paragraph
putdocx text ("3.3. Clients' Education"), bold linebreak
{
	use temp.dta, clear
		
		keep if strpos(group, "Education")>0
			tab grouplabel, m
			
				split grouplabel, p(_) limit(5)
			
				capture drop dummy	
				gen dummy="_"
				
			egen studyarm = concat(grouplabel1)
			gen axis = grouplabel2
			
			list grouplabel studyarm axis
				
		#delimit;
		graph hbar total_score ,
			over(axis)	
			by(studyarm, 
				col(1)
				title("", size(small))
				note("Preliminary results for internal review. Update as of: $date", size(vsmall))
				legend(off) )
			ytitle("Score (0-100)", size(small)) yscale(r(0 10))
			blabel(bar)	
			bar(1, color(navy*2)) 
			ysize(7.5) xsize(6)
		;	
		#delimit cr	

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .plotregion1.subtitle[2].style.editstyle fillcolor(white) editcopy
		gr_edit .plotregion1.subtitle[2].style.editstyle linestyle(color(white)) editcopy
		// subtitle[2] edits

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color		
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Summary PREMs score by education and study arm"), bold linebreak
putdocx image "temp.png", height(7.5) width(6)
}

*****4. Analysis sample profile 
putdocx pagebreak	
putdocx paragraph
putdocx text ("4. Background characteristics of the analysis sample"), bold linebreak

*putdocx pagebreak	
putdocx paragraph
putdocx text ("4.1. Clients' Age"), bold linebreak
{
	use temp.dta, clear
		
		keep if strpos(group, "Age")>0
			tab grouplabel, m
			
				split grouplabel, p(_) limit(5)
			
				capture drop dummy	
				gen dummy="_"
				
			egen studyarm = concat(grouplabel1)
			gen axis = grouplabel2
			
			list grouplabel studyarm axis
			gen axisnum=.
				replace axisnum=1 if axis=="18-29"
				replace axisnum=2 if axis=="30-39"
				replace axisnum=3 if axis=="40-49"
				replace axisnum=4 if axis=="50+"
			keep studyarm axisnum obs
			reshape wide obs, i(studyarm) j(axisnum)
				
		#delimit;
		graph hbar obs* ,
			over(studyarm) stack	
			title("", size(small))
			note("Preliminary results for internal review. Update as of: $date", size(vsmall))
			ytitle("Number of respondents") 
			blabel(bar, position(center))	
			legend( 
				pos(6) size(small) row(1)
				label(1 "18-29")
				label(2 "30-39")
				label(3 "40-49")
				label(4 "50+")
				)				
			bar(1, color(cranberry*0.4)) 
			bar(2, color(forest_green*0.4)) 
			bar(3, color(orange*0.4)) 
			bar(4, color(navy*0.4)) 
			ysize(4) xsize(6)
		;	
		#delimit cr	

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color		
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Distribution of analysis sample, by age group and study arm"), bold linebreak
putdocx image "temp.png", height(4) width(6)
}

putdocx pagebreak	
putdocx paragraph
putdocx text ("4.2. Clients' Gender"), bold linebreak
{
	use temp.dta, clear
		
		keep if strpos(group, "Gender")>0
			tab grouplabel, m
			
				split grouplabel, p(_) limit(5)
			
				capture drop dummy	
				gen dummy="_"
				
			egen studyarm = concat(grouplabel1)
			gen axis = grouplabel2
			
			list grouplabel studyarm axis
			gen axisnum=.
				replace axisnum=1 if axis=="Female"
				replace axisnum=2 if axis=="Male"
				replace axisnum=3 if axis=="Other/NoResponse"
			keep studyarm axisnum obs
			reshape wide obs, i(studyarm) j(axisnum)
				
		#delimit;
		graph hbar obs* ,
			over(studyarm) stack	
			title("", size(small))
			note("Preliminary results for internal review. Update as of: $date", size(vsmall))
			ytitle("Number of respondents") 
			blabel(bar, position(center))	
			legend( 
				pos(6) size(small) row(1)
				label(1 "Female")
				label(2 "Male")
				label(3 "Other/NoResponse")
				)				
			bar(1, color(cranberry*0.4)) 
			bar(2, color(forest_green*0.4)) 
			bar(3, color(navy*0.4)) 
			ysize(4) xsize(6)
		;	
		#delimit cr	

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color				
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Distribution of analysis sample, by gender and study arm"), bold linebreak
putdocx image "temp.png", height(4) width(6)
}

putdocx pagebreak	
putdocx paragraph
putdocx text ("4.3. Clients' Education"), bold linebreak
{
	use temp.dta, clear

		keep if strpos(group, "Education")>0
			tab grouplabel, m
			
				split grouplabel, p(_) limit(5)
			
				capture drop dummy	
				gen dummy="_"
				
			egen studyarm = concat(grouplabel1)
			gen axis = grouplabel2
			
			list grouplabel studyarm axis
			gen axisnum=.
				replace axisnum=1 if axis=="Primary or less"
				replace axisnum=2 if axis=="Secondary or higher"
			keep studyarm axisnum obs
			reshape wide obs, i(studyarm) j(axisnum)
				
		#delimit;
		graph hbar obs* ,
			over(studyarm) stack	
			title("", size(small))
			note("Preliminary results for internal review. Update as of: $date", size(vsmall))
			ytitle("Number of respondents") 
			blabel(bar, position(center))	
			legend( 
				pos(6) size(small) row(1)
				label(1 "Primary or less")
				label(2 "Secondary or higher")
				)				
			bar(1, color(cranberry*0.4)) 
			bar(2, color(forest_green*0.4)) 
			ysize(4) xsize(6)
		;	
		#delimit cr	

		gr_edit .style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit .style.editstyle boxstyle(linestyle(color(white))) editcopy
		// Graph color

		gr_edit .legend.style.editstyle boxstyle(linestyle(color(white))) editcopy
		// legend color				
		
		graph save Graph "temp.gph", replace
		graph export "temp.png", replace	

putdocx paragraph
putdocx text ("Figure: Distribution of analysis sample, by education and study arm"), bold linebreak
putdocx image "temp.png", height(4) width(6)
}

*****Save the note
putdocx save "$datanotedir/Report_PREMs_Pilot_prelimresults_`country'_$date.docx", replace		

***CLEAN UP***

local datafiles: dir "$mydir" files "temp*.*"

foreach datafile of local datafiles {
        rm `datafile'
}

GREAT, END OF REPORT GENERATION - Yay! 
