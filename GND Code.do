clear all

import excel "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LA Dataset.xlsx", sheet ("Sheet1") firstrow clear

gen MedianWage1 = real(MedianWage)
		drop MedianWage
		rename MedianWage1 MedianWage
		
bysort lad19cd: keep if _n==1	
		
save "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LA Dataset.dta", replace



cd "/Volumes/GoogleDrive/My Drive/PhD Work /Data/LA Shapefile"

spshape2dta Local_Authority_Districts__December_2019__Boundaries_UK_BGC, replace

use Local_Authority_Districts__December_2019__Boundaries_UK_BGC, clear

**** DATA ARE IN PLANAR UNITS RATHER THAN LAT AND LONG SO WILL NEED TO CONVERT BEFORE OR FIGURE OUT DISATANCES 
 
 save, replace 
 
merge 1:m lad19cd using  "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LA Dataset.dta"
 
* camden to city of london = 5726 units (3.5 miles, 1636 = 1 mile), Galsgow to London = 555660 (400 miles, 1389 = 1 mile ). Let's call it 1500
 
 nearstat (_CX _CY), near(_CX _CY) distvar(dist) kth(1)  cart
 
 
  ** ALPHA =2 DISTANCE OF SPACE TAKES MORE TIME
  
 spwmatrix gecon _CX _CY , wname(W) wtype(inv)  row alpha(2) cart
splagvar GVA, wname(W) wfrom(Stata) moran(GVA) 
drop _merge

 save "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADataset.dta", replace
 keep if MedianWage != . 
 
 spwmatrix gecon _CX _CY if MedianWage != . , wname(Wage) wtype(inv)  row alpha(2) cart
splagvar MedianWage if MedianWage != ., wname(Wage) wfrom(Stata) moran(MedianWage) 

 save "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADatasetWage.dta", replace
   
   ** ALPHA effectively equals 1 but there is a cut off at 300n DISTANCE OF SPACE TAKES MORE TIME

    use "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADataset.dta", clear
keep if Employment !=. 

   spwmatrix gecon _CX _CY if Employment != . , wname(Employment) wtype(inv)  row alpha(2) cart
splagvar Employment if Employment != ., wname(Employment) wfrom(Stata) moran(Employment) 

 save "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADatasetEmployment.dta", replace

 
 
	 use "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADataset.dta", replace

	 
	 ****** TRANSPORT TIME REGRESSIONS AND THEN IMPUTED *****
	
quietly {
reg SchoolPT PopulationDensity if PopulationDensity <101 & PopulationDensity !=.
predict Transporttime0 if PopulationDensity <101 & PopulationDensity !=.

reg SchoolPT PopulationDensity if PopulationDensity >100 & PopulationDensity<250
predict Transporttime1 if PopulationDensity >100 & PopulationDensity<250

reg SchoolPT PopulationDensity if PopulationDensity >249 & PopulationDensity<500
predict Transporttime2 if PopulationDensity >249 & PopulationDensity<500

reg SchoolPT PopulationDensity if PopulationDensity >499 & PopulationDensity<1500
predict Transporttime3 if PopulationDensity >499 & PopulationDensity<1500


reg SchoolPT PopulationDensity if PopulationDensity >1499 & PopulationDensity<1750
predict Transporttime7 if PopulationDensity >1499 & PopulationDensity<1750

reg SchoolPT PopulationDensity if PopulationDensity >1749 & PopulationDensity<2000
predict Transporttime8 if PopulationDensity >1749 & PopulationDensity<2000

reg SchoolPT PopulationDensity if PopulationDensity >1999 & PopulationDensity<2500
predict Transporttime9 if PopulationDensity >1999 & PopulationDensity<2500

reg SchoolPT PopulationDensity if PopulationDensity >2499 & PopulationDensity<5000
predict Transporttime10 if PopulationDensity >2499 & PopulationDensity<5000

reg SchoolPT PopulationDensity if PopulationDensity > 5000
predict Transporttime11 if  PopulationDensity > 5000

foreach i in 0 1 2 3  7 8 9 10 11{
	replace Transporttime`i' = 0 if Transporttime`i' == .
}


gen Transporttime = Transporttime0 + Transporttime1 + Transporttime2 + Transporttime3 + Transporttime7 + Transporttime8 + Transporttime9 + Transporttime10 + Transporttime11

gen Transporttimediff = Transporttime - SchoolPT

keep if Transporttimediff != .
}

twoway (scatter Transporttime PopulationDensity) 

graph export "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Charts/Predicted TransportTime.jpg", as(jpg) name("Graph") quality(90) replace



twoway (scatter Transporttime PopulationDensity) (scatter SchoolPT PopulationDensity, mcolor(red))

graph export "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Charts/Predicted vs Actual TransportTime.jpg", as(jpg) name("Graph") quality(90) replace


 spwmatrix gecon _CX _CY if Transporttimediff != . , wname(Transporttimediff) wtype(inv)  row alpha(2) cart
splagvar Transporttimediff if Transporttimediff != ., wname(Transporttimediff) wfrom(Stata) moran(Transporttimediff) 

 save "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADatasetTransport.dta", replace

  *** CREATe SPATIALLGY LAGGED VARIABLES 
  
 use "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADataset.dta", replace
 
merge 1:1  lad19cd using "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADatasetWage.dta"
drop _merge

merge 1:1  lad19cd using "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADatasetEmployment.dta"

	drop _merge
	
	
	merge 1:1  lad19cd using "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADatasetTransport.dta"

	drop _merge
	
	

*	keep lad19cd lagincomequintiles lagincomedeciles incomedeciles incomequintiles year meanEmp meanInc Empdifference MedianWage GVAdifference Wagedifference Empdifference
	
	 encode UrbanRural, gen(UrbanRuralNum)
	 
	   

 save "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADatasetweight.dta", replace
 
 
 ******* END CREATION OF SPATIAL FILES ********
 
  use "/Volumes/GoogleDrive/My Drive/NEF Work /Green New Deal/Data/LADatasetweight.dta", clear


  

replace Life_Expectancy_Men_Bir = . if  Life_Expectancy_Men_Bir == 0

*Change code to reflect fact that higher numbers are now better *

foreach i in "CivicAssets" "Connectedness"  "EngagedCommunity"  {
	replace `i' = `i' * -1
	
}

gen negTransporttimediff = Transporttimediff * -1

*Create normalised variables for easy categorisation **

*** DEPRIVED VARIABLES THOSE MORE THAN HALF AN SD BELOW ZERO ****


foreach i in "Employment" "CivicAssets" "Connectedness" "EngagedCommunity" "GraduateShare" "Life_Expectancy_Men_Bir" "GVA" "negTransporttimediff" "wy_GVA" {
	summarize `i'
	gen `i'N = (`i' - r(mean)) / r(sd)

	gen dep`i' = 0 
	replace dep`i' = 1 if `i'N< -0.5
	
}

**** GENERATE DEPRIVATION SCORES THAT ADD ALL DEPRIVATION VARIABLES ****

gen depscore = depEmployment + depCivicAssets + depConnectedness + depEngagedCommunity + depLife_Expectancy_Men_Bir +depGVA +depnegTransporttimediff

pwcorr Employment  GraduateShare Life_Expectancy_Men_Bir GVA Transporttimediff MedianWage wy_GVA, sig


**** CORRELATION BETWEEN VALUES AND SPATIALLY LAGGED VALUES

foreach i in"Employment" "Transporttimediff" "GVA" "MedianWage"  { 
	
	corr `i' wy_`i'
}


****** REGIONAL CORRELATION BETWEEN GVA AND WY_GVA FOR EACH REGION AND THE TRANSPORT TIME DIFFERNEC E****


foreach i in "East" "East Midlands" "London"  "North East" "North West" "South East" "South West" "West Midlands"  "Yorkshire and The Humber"  {
		display "`i'"
	pwcorr GVA wy_GVA if Region == "`i'", sig
	summarize Transporttimediff if Region == "`i'"
		summarize SchoolPT if Region == "`i'",


	
}

**** Employment Gap Adjustment ***


egen TotEmploymentgap = sum(EmploymentGap) if EmploymentGap > 0
egen TotalWAPop = sum(WAPopulation)

gen WAPopshare = WAPopulation/TotalWAPop

sort Employment 

gen Employmentrank = _n

gen Employmentadjust = 0 

replace Employmentadjust = 1.33 - (((Employmentrank-1)/382)*0.66)

gen NetZeroCore = WAPopshare * (230000 + 140000 + 95000) * Employmentadjust
gen PublicLimited = WAPopshare * (527000) * Employmentadjust
gen PublicExpansion = WAPopshare * (1628000) * Employmentadjust

gen NetZeroCoreMultiply = NetZeroCore*  1.5
gen PublicLimitedMultiply = PublicLimited*0.5
gen PublicExpansionMultiply = PublicExpansion*0.5


egen NetZeroCoreTot = sum(NetZeroCore)

gen EmploymentRateNetZero = 0

foreach i in NetZeroCore PublicLimited  PublicExpansion{
	gen Emp`i' =0 
	gen Emp`i'M = 0
	
}

foreach i in NetZeroCore PublicLimited  PublicExpansion{
	replace Emp`i' = `i'/WAPopulation
	replace Emp`i'M = `i'Multiply/WAPopulation
	
}

gen rentprice = TwoBedMedianRent/MedianWage

pwcorr Employment  GraduateShare Life_Expectancy_Men_Bir GVA Transporttimediff MedianWage wy_GVA rentprice wy_Employment, sig


twoway (scatter Employment rentprice) (lfit Employment rentprice), ytitle("Employment (%)") saving(rentEmployment, replace) scheme(538) legend(off)
twoway (scatter MedianWage rentprice) (lfit MedianWage rentprice), ytitle("Median Wage") saving(rentGVA, replace) scheme(538) legend(off)


graph combine rentEmployment.gph rentGVA.gph

twoway (scatter wy_Employment rentprice) (lfit wy_Employment rentprice), ytitle("Employment (%) of surrounding area") saving(lagrentEmployment, replace) scheme(538) legend(off)
twoway (scatter wy_MedianWage rentprice) (lfit wy_MedianWage rentprice), ytitle("Median Wage of surrounding area") saving(lagrentGVA, replace) scheme(538) legend(off)


graph combine lagrentEmployment.gph lagrentGVA.gph



*** hardcoded values from correlation results ***

gen GVAcorrRegion = 0 
gen Transporttimediffregion = 0

**** twoway graph Employment GVA

twoway (scatter Employment GVA) (lfit Employment GVA), ytitle("Employment (%)") saving(EmploymentGVA, replace) scheme(538) legend(off)
twoway (scatter Life_Expectancy_Men_Bir GVA) (lfit Life_Expectancy_Men_Bir GVA), ytitle("Life Expectancy Men") saving(LifeGVA, replace) scheme(538) legend(off)


graph combine EmploymentGVA.gph LifeGVA.gph

**** twoway graph Life GVA

 
twoway (scatter Employment Life_Expectancy_Men_Bir) (lfit Life_Expectancy_Men_Bir Life_Expectancy_Men_Bir), saving(LifeGVA) scheme(538) legend(off)
twoway (scatter Employment Life_Expectancy_Men_Bir) (lfit Life_Expectancy_Men_Bir Life_Expectancy_Men_Bir), saving(LifeWage) scheme(538) legend(off)

graph combine LifeGVA.gph LifeWage.gph


**** twoway graph Life GVA


twoway (scatter Life_Expectancy_Men_Bir Employment) (lfit Life_Expectancy_Men_Bir Employment), saving(LifeEmployment)
twoway (scatter Life_Expectancy_Men_Bir Employment) (lfit Life_Expectancy_Men_Bir MedianWage), saving(LifeWage)

graph combine LifeGVA.gph LifeWage.gph


 twoway (scatter Transporttime1  PopulationDensity if PopulationDensity<500) (scatter SchoolPT  PopulationDensity if PopulationDensity<500 , mcolor(red) mlabel(LocalAuthorityName) )
 
  twoway (scatter IND_F_Construction  Employment ) (lfit  IND_F_Construction  Employment  )
    twoway (scatter IND_F_Construction  wy_Employment ) (lfit  IND_F_Construction  wy_Employment  )

  
    twoway (scatter IND_F_Construction  wy_GVA ) (lfit  IND_F_Construction   wy_GVA  )
	
	    twoway (scatter IND_H_Transport_Storage  Employment ) (lfit  IND_H_Transport_Storage  Employment  )

			    twoway (scatter IND_C_Manufacturing  ResidentialLand if ResidentialLand <50000000 ) (lfit  IND_C_Manufacturing  ResidentialLand if ResidentialLand <50000000) (scatter IND_C_Manufacturing  IndustrialLand) (lfit IND_C_Manufacturing  IndustrialLand)
				
				graph bar IND_C_Manufacturing, over(UrbanRuralNum) horizontal
				


							    twoway (scatter IND_C_Manufacturing  PopulationDensity if PopulationDensity<1000 ) (lfit  IND_C_Manufacturing  PopulationDensity if PopulationDensity<1000)

  twoway (scatter IND_C_Manufacturing  Employment ) (lfit  IND_C_Manufacturing  Employment  )
  
    twoway (scatter IND_C_Manufacturing  GVA ) (lfit  IND_C_Manufacturing  GVA  )

  
    twoway (scatter IND_D_Utilities  GVA, mcolor(red) mlabel(LocalAuthorityName)  ) (lfit  IND_D_Utilities  GVA  )
	
	    twoway (scatter IND_H_Transport_Storage  GVA ) (lfit  IND_H_Transport_Storage  GVA  )



gen MedianWage1 = real(MedianWage)
		drop MedianWage
		rename MedianWage1 MedianWage
		
		twoway (scatter Employment MedianWage,mlabel(LocalAuthorityName))
	
corr Employment MedianWage

gen PublicEmployment = 0
replace PublicEmployment = 1 if depEmployment ==1 & depCivicAssets == 1 
