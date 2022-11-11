*************************************************************************************************************************
*** CENTER FOR INNOVATIVE DESIGN AND ANALYSIS
*** PROGRAM NAME: 			Identification of Bouts of MVPA from Wearable Device Data
*** PROGRAMMER: 			Laura "Lala" Grau
*** INVESTIGATOR: 			Seth Creasy 
*** DATE CREATED: 			2022-10-03
*** CURRENT VERSION DATE: 	2022-10-03
*** UPDATES: 	
*** None at this time
*** 


*** The %bouts macro requires data to have the following variables:

&subject 	= 	subject identifier
&date 		=	date
&time 		= 	time of day
&mvpa		=	binary indicator for MVPA minute (1/0)

*Note: The macro expects time and date to be separate variables. If you have a datetime variable, you can separate them 
using the DATEPART() and TIMEPART() functions.

*** Other user inputs:
&data 		= 	name of original data
&outdata	=	name of person-day level data being created


*** Data format prior to running macro:
This macro will work on datasets with one minute epochs that have the variables specified above.
The data should be cleaned prior to running the macro (including removing invalid data, invalid days, etc).



*** The macro will produce a dataset with one record per person per day with:
1) Subject id variable from original data
2) Date variable from original data
3) min_mvpa = Minutes of MVPA 
4) min_bout_mvpa = Minutes of MVPA that took place within bouts


************************************************************************************************************************;

%macro bouts (data= , outdata= ,  subject= , date= , time= , mvpa =);

**********************************************
PART 1: Prepare the data
***********************************************;
*Subset the data to minutes of MVPA;
data mvpa_only;
set &data;
where &mvpa=1;
run;

*Sort by person, date, and time;
proc sort data=mvpa_only;
by &subject &date &time;
run;

**********************************************
PART 2: Identify consecutive bouts of MVPA allowing
for the bout to continue until 3 or more consecutive
minutes on non-MVPA occur
***********************************************;
*Create variables that:
1)	lag_mvpa: records the previous minute of MVPA
2)	diff: records the difference in time between the current minute of MVPA and the previous minute of MVPA
3)  count: if the diff is less than 3 minutes, then keep a running count of the total minutes of MVPA in that bout
4)	start_time: start_time of 'group' of MVPA--not quite bouts yet;
data mvpa_only_1;
set mvpa_only;
by &subject &date &time;

if first.&subject then lag_mvpa=.;
else if not first.&subject then do;
	lag_mvpa=lag(&time);
end;

diff=(lag_mvpa-&time)/60;

retain count;

*If there is a gap of 3 or more minutes, then the bout is over. ;
if diff>=-3 and diff<0 then do;
	count+1;
end;
else count=1;

retain start_time;
if count=1 then start_time=&time;

format start_time time9.;
run;


*Create one record per potential bout of MVPA, with the following variables:
1)	&subject
2)	&date
3)	start_time: start_time of 'group' of MVPA--not quite bouts yet
4)  n_min_mvpa: total number of minutes where MVPA=1 with each 'group'
5)	end_time: end_time of 'group' of MVPA--not quite bouts yet
6) 	diff: difference between start and end time of 'group' of MVPA;
proc sql;
create table mvpa_only_2 as
select &subject, &date, start_time, max(count) as n_min_mvpa, max(&time) as end_time format=time9., intck('minute',start_time, max(&time))+1 as diff
from mvpa_only_1
group by  &subject, &date, start_time;
quit;



**********************************************
PART 3: Identify bouts of MVPA >=10 minutes long 
that have at least 80% of minutes of MVPA
***********************************************;
*Based on the variables above, what counts as a bout of MVPA?
1)	If the time between the start and end of the 'group' of MVPA was >=10 minutes AND
2)  >=80% of the minutes between the start and end were MVPA;

data mvpa_only_3;
set mvpa_only_2;
percent_mvpa=n_min_mvpa/diff;

if diff>=10 and percent_mvpa>=0.8 then bout_of_mvpa=1; else bout_of_mvpa=0;
run;

/*proc tabulate data=mvpa_only_3;*/
/*class bout_of_mvpa ;*/
/*var percent_mvpa n_min_mvpa diff;*/
/*tables (percent_mvpa n_min_mvpa diff),bout_of_mvpa*(n mean std min max);*/
/*run;*/


**********************************************
PART 4: Merge bouts of MVPA back to full data
***********************************************;
*Merge the bout variable back onto the main dataset;
proc sql;
create table all_data_1 as
select a.*, b.bout_of_mvpa
from &data a left join mvpa_only_3 b
on a.&subject=b.&subject and a.&date=b.&date and a.&time between b.start_time and b.end_time
order by a.&subject, a.&date, a.&time;
quit;


**********************************************
PART 5: Create person-day level data
Creates MVPA total and MVPA bouts
***********************************************;
proc sql;
create table &outdata as
select &subject, &date, sum(mvpa) as min_mvpa label="MVPA (min)", sum(CASE WHEN bout_of_mvpa=1 THEN mvpa ELSE 0 END) as min_bout_mvpa label="Bout MVPA (min)"
		from all_data_1  
		group by &subject,&date;
quit;

%mend bouts;

*Gracias for reading my program - Lala!;
