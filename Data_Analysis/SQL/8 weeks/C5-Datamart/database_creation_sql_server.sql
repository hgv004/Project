create database _8_week_sql;

use _8_week_sql;

create schema data_mart;

-- DROP TABLE IF EXISTS weekly_sales;

select count(*) from data_mart.weekly_sales;

select *, datename(week, wk_date) as wk_no 
from data_mart.weekly_sales;

-- Convert the week_date to a DATE format
UPDATE data_mart.weekly_sales
SET wk_date = cast(wk_date as date);

-- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
select	*, 
		datename(week, wk_date) as wk_no,
		year(wk_date) as wk_year,
		month(wk_date) as wk_month
from data_mart.weekly_sales;

--Calendar Table --------------------------------------
DECLARE @StartDate date, @EndDate date;
SELECT @StartDate = DATEFROMPARTS(MIN(YEAR(wk_date)),1,1) FROM data_mart.weekly_sales;
SELECT @EndDate = DATEFROMPARTS(MAX(YEAR(wk_date)),12,31) FROM data_mart.weekly_sales;

WITH calendar_table (dates) AS (
	SELECT @StartDate as dates
	UNION ALL
	SELECT DATEADD(day, 1, dates) 
	FROM calendar_table
	WHERE dates <= @EndDate
)
SELECT	dates, 
		DATEPART(week, dates) as wk_no,
		YEAR(dates) as wk_year,
		MONTH(dates) as wk_month
INTO data_mart.new_calendar_table 
FROM calendar_table 
OPTION (MAXRECURSION 0);

-- Adding Dim tables

CREATE TABLE data_mart.dim_segment (
    segment int NOT NULL,
    age_band varchar(20),
	PRIMARY KEY (segment)
);

INSERT INTO data_mart.dim_segment (segment, age_band)
VALUES	(1, 'Young Adults'),
		(2, 'Middle Aged'),
		(3, 'Retirees'),
		(4, 'Retirees');


-- Create clean table
select * 
into data_mart.weekly_sales_clean
from (
	select	ct.*, 
			ws.region,
			ws.platform,
			case 
				when iif(ws.segment = 'null', null, left(ws.segment,1)) = 'C' then 'Couples'
				when iif(ws.segment = 'null', null, left(ws.segment,1)) = 'F' then 'Families'
				else 'Unknown' end as demographic,
			case 
				when iif(ws.segment = 'null', null, right(ws.segment,1)) = 1 then 'Young Adults'
				when iif(ws.segment = 'null', null, right(ws.segment,1)) = 2 then 'Middle Aged'
				when iif(ws.segment = 'null', null, right(ws.segment,1)) in (3, 4) then 'Retirees'
				else 'Unknown' end as age_band,
			ws.customer_type,
			ws.transactions,
			ws.sales,
			cast(round(cast(ws.sales as decimal)/ ws.transactions,2) as decimal(10,2)) as avg_transaction 
	from data_mart.new_calendar_table ct
	left join data_mart.weekly_sales ws
	on ws.wk_date = ct.dates) c;

select * from data_mart.weekly_sales_clean;

-- drop table data_mart.weekly_sales_clean;

