*************************************************************************************************************************
*** CENTER FOR INNOVATIVE DESIGN AND ANALYSIS
*** PROGRAM NAME: 			Identification of Physical Activity from Wearable Device Data
*** PROGRAMMER: 			Laura "Lala" Grau
*** INVESTIGATOR: 			Seth Creasy 
*** DATE CREATED: 			2022-10-12
*** CURRENT VERSION DATE: 	2022-10-12
*** UPDATES: 	
*** None at this time
*** 

*** The %pa macro requires data to have the following variables:

&subject 	= 	subject identifier
&date 		=	date
&time 		= 	time 
&METs		= 	MET minutes

*** Other user inputs:
&data 		= 	name of minute-by-minute original data
&outdata	=	name of minute-by-minute data being produced, with physical activity variables


*** Data format prior to running macro:
This macro will work on datasets with one minute epochs that have the variables specified above.
The data you input into this macro should have already been cleaned to remove invalid data. 
Additionally, the data set should exclude the sleep window.

*** The macro will produce a dataset (named &outdata) with one record per person per minute with:
1) Subject id variable from original data
2) Date variable from original data
3) Time variable from original data
4) Sedentary 	= binary indicator for sedentary minute (1/0)
5) LPA			= binary indicator for light physical activity (LPA) minute (1/0)
6) MPA			= binary indicator for moderate physical activity (MPA) minute (1/0)
7) VPA			= binary indicator for vigorous physical activity (VPA) minute (1/0)
8) MVPA			= binary indicator for moderate to vigorous physical activity (MVPA) minute (1/0)


*** The macro will also produce a dataset (named dl_&outdata) with one record per person per day with:
1) Subject id variable from original data
2) Date variable from original data
3) Total_mins	= total number of minutes per day
4) Sedentary 	= total number of sedentary minutes 
5) LPA			= total number of light physical activity (LPA) minutes
6) MPA			= total number of moderate physical activity (MPA) minutes
7) VPA			= total number of vigorous physical activity (VPA) minutes
8) MVPA			= total number of moderate to vigorous physical activity (MVPA) minutes

************************************************************************************************************************;

%macro pa (data= , outdata= ,  subject= , date= , time= , mets =);

**********************************************
PART 1: Read in the data and create variables of interest
***********************************************;

data &outdata;
set &data;
*Create flags for PA variables;
if &METs=< 1.5 then sedentary=1; else sedentary=0;
if &METs>1.5 and &METs<3 then lpa=1; else lpa=0;
if &METs>=3 and &METs<6 then mpa=1; else mpa=0;
if &METs>=6 then vpa=1; else vpa=0;
if &METs>=3 then mvpa=1; else mvpa=0;

min=1;
run;

**********************************************
PART 2: Create day-level dataset
***********************************************;

proc sql;
create table dl_&outdata as
select &subject, &date, sum(min) as Total_mins, 
						sum(sedentary) as sedentary,
						sum(lpa) as lpa,
						sum(mpa) as mpa,
						sum(vpa) as vpa,
						sum(mvpa) as mvpa
from &data
group by &subject, &date;
quit;

%mend pa;





*Gracias for reading my program - Lala!;

