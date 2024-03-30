use datamart;

select * from weekly_sales ws ;

-- Convert to date

SELECT STR_TO_DATE(week_date, '%d/%m/%y') 
from weekly_sales;

ALTER TABLE weekly_sales
ADD COLUMN wk_date DATE;

UPDATE weekly_sales
SET wk_date = STR_TO_DATE(week_date, '%d/%m/%y');

ALTER TABLE weekly_sales
DROP COLUMN week_date;

-- Cleaning steps

create table clean_sales as 
select 	*, 
		week(wk_date) as week_number , 
		month(wk_date) as month_number ,
		year(wk_date) as calendar_year,
		case 
		WHEN RIGHT(segment,1) = '1' THEN 'Young Adults'
	    WHEN RIGHT(segment,1) = '2' THEN 'Middle Aged'
	    WHEN RIGHT(segment,1) in ('3','4') THEN 'Retirees'
	    ELSE 'unknown' END AS age_band,
	    CASE 
	    WHEN LEFT(segment,1) = 'C' THEN 'Couples'
	    WHEN LEFT(segment,1) = 'F' THEN 'Families'
	    ELSE 'unknown' END AS demographic,
	    ROUND((sales/transactions),2) AS avg_transaction
from weekly_sales;

select * from clean_sales;

-- 1. What day of the week is used for each week_date value?
select distinct dayname(wk_date) 
from clean_sales;

-- 2.What range of week numbers are missing from the dataset?
select distinct week_number 
from clean_sales cs 
order by week_number;


