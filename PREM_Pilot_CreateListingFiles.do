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

*This code is creates listing files... 

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
cd "~/Dropbox/0iSquared/iSquared_WHO/PREM/DataAnalysis/"

*** Define a directory for the chartbook (can be same or different from the main directory)
global chartbookdir "~/Dropbox/0iSquared/iSquared_WHO/PREM/DataAnalysis/"

*** Define a directory for LISTING data files
global listingfilesdir "~/Dropbox/0iSquared/iSquared_WHO/PREM/DataAnalysis/ListingFilesDownloaded/"

*** Define a directory for COMBINED LISTING data files
global listingdatadir "~/Dropbox/0iSquared/iSquared_WHO/PREM/DataAnalysis/ListingDataCombined/"

*** Define a directory for stata log files
global statalog "~/Dropbox/0iSquared/iSquared_WHO/PREM/DataAnalysis/StataLog/"

**************************************************************
* B. Prepare listing data for sampling 
**************************************************************

***** B.0 JUST FOR YJ TO PREPARE MOCK LISTING DATA!!!!!!!!!!

dir $listingfilesdir

*** 1. download and open "123_1_1" and create other facilities... 
	import excel using "$listingfilesdir/seed/Listing_Digital_123_1 (responses).xlsx", firstrow allstring clear 
	export excel using "$listingfilesdir/Listing_Digital_123_1.xlsx", firstrow(variables) replace

	import excel using "$listingfilesdir/Listing_Digital_123_1.xlsx", firstrow allstring clear 
	export excel using "$listingfilesdir/Listing_Digital_123_2.xlsx", firstrow(variables) replace

	import excel using "$listingfilesdir/Listing_Digital_123_1.xlsx", firstrow allstring clear 
	export excel using "$listingfilesdir/Listing_Digital_131_1.xlsx", firstrow(variables) replace

	import excel using "$listingfilesdir/Listing_Digital_123_1.xlsx", firstrow allstring clear 
	export excel using "$listingfilesdir/Listing_Digital_111_1.xlsx", firstrow(variables) replace

	import excel using "$listingfilesdir/Listing_Digital_123_1.xlsx", firstrow allstring clear 
	export excel using "$listingfilesdir/Listing_Digital_111_2.xlsx", firstrow(variables) replace
	
	import excel using "$listingfilesdir/Listing_Digital_123_1.xlsx", firstrow allstring clear 
	export excel using "$listingfilesdir/Listing_Digital_111_3.xlsx", firstrow(variables) replace	

	import excel using "$listingfilesdir/Listing_Digital_123_1.xlsx", firstrow allstring clear 
	export excel using "$listingfilesdir/Listing_Digital_311_1.xlsx", firstrow(variables) replace

*** 2. expand each file 
local filenames: dir "$listingfilesdir" files "*.xlsx"

	foreach file of local filenames {
	import excel using `"$listingfilesdir/`file'"', firstrow allstring clear 
		
		expand 10, 
				
		gen unique = Pleaseenterclientsfullname + Pleaseenterclientsphonenumb
		codebook unique
		
	export excel using `"$listingfilesdir/`file'"', firstrow(variables) replace
	}
	
*** 3. change phone numbers to make it unique

	foreach file of local filenames {
	import excel using `"$listingfilesdir/`file'"', firstrow allstring clear 
		
		bysort Pleaseenterclientsfullname: gen num=_n
			tostring num, replace
			
			replace Pleaseenterclientsphonenumb = ///
				Pleaseenterclientsphonenumb + num ///
				if Pleaseenterclientsphonenumb !=""			
			
		gen unique2 = Pleaseenterclientsfullname + Pleaseenterclientsphonenumb
		codebook unique2
		
		drop num unique*
		
	export excel using `"$listingfilesdir/`file'"', firstrow(variables) replace
	}

*** 4. fix the second phone number to match with the revised first one in most cases

	foreach file of local filenames {
	import excel using `"$listingfilesdir/`file'"', firstrow allstring clear 
				
		set seed 2023
		generate random = runiform() if  Pleasereenterclientsphonen!=""
			replace Pleasereenterclientsphonen = ///
				Pleaseenterclientsphonenumb if random<=0.95
					
		drop random			
				
	export excel using `"$listingfilesdir/`file'"', firstrow(variables) replace
	}	
				
			
END OF CREATION
