-- 1.What day of the week is used for each week_date value?
select distinct format(dates, 'dddd') as day_of_week
from data_mart.weekly_sales_clean
where transactions is not null;

-- 2.What range of week numbers are missing from the dataset?
WITH Numbers AS (
    SELECT 1 AS v1
    UNION ALL
    SELECT v1 + 1
    FROM Numbers
    WHERE v1 < 52
), temp_table as (
	select distinct wk_no as day_of_week
	from data_mart.weekly_sales_clean
	where transactions is not null)
SELECT v1
FROM Numbers
left join temp_table tt
on tt.day_of_week = Numbers.v1
where tt.day_of_week is null
OPTION (MAXRECURSION 0);

-- 3. How many total transactions were there for each year in the dataset?
select year(dates) as yr, sum(transactions) as total_transactions
from data_mart.weekly_sales_clean
where transactions is not null
group by year(dates)
order by year(dates);

--What is the total sales for each region for each month?
select month(dates) as _month, region, sum(CAST(sales AS BIGINT)) as total_sales
from data_mart.weekly_sales_clean
where sales is not null
group by month(dates), region
order by month(dates), region;

--What is the total count of transactions for each platform
select PLATFORM, count(transactions) as total_transactions
from data_mart.weekly_sales_clean
where transactions is not null
group by PLATFORM;

--What is the percentage of sales for Retail vs Shopify for each month?
select	month(dates) as _month, 
		(sum(iif(PLATFORM ='Shopify', CAST(sales AS decimal(10,2)),0)) /
		sum(CAST(sales AS bigint)) * 100)  as Shopify_sales_pct,  
		(sum(iif(PLATFORM ='Retail', CAST(sales AS decimal(10,2)),0)) /
		sum(CAST(sales AS bigint)) * 100)  as Retail_sales_pct
from data_mart.weekly_sales_clean
where transactions is not null
group by month(dates)
order by month(dates);

--What is the percentage of sales by demographic for each year in the dataset?
select	year(dates) as yr, 
		(sum(iif(demographic ='Couples', CAST(sales AS decimal(10,2)),0)) /
		sum(CAST(sales AS bigint)) * 100)  as Couple_sales_pct,  
		(sum(iif(demographic ='Families', CAST(sales AS decimal(10,2)),0)) /
		sum(CAST(sales AS bigint)) * 100)  as Family_sales_pct,
		(sum(iif(demographic ='Unknown', CAST(sales AS decimal(10,2)),0)) /
		sum(CAST(sales AS bigint)) * 100)  as Family_sales_pct
from data_mart.weekly_sales_clean
where transactions is not null
group by year(dates) 
order by year(dates) ;

--Which age_band and demographic values contribute the most to Retail sales?
select	top 1 age_band, 
		demographic
from data_mart.weekly_sales_clean
where transactions is not null and PLATFORM ='Retail' and demographic <> 'Unknown'
group by age_band, demographic
order by sum(CAST(sales AS bigint)) desc;

--Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
--If not - how would you calculate it instead?
select	year(dates) as yr,
		sum(iif(PLATFORM ='Shopify', cast(sales as decimal),0)) / 
			sum(iif(PLATFORM ='Shopify', transactions,0)) as shopify_tra_size,
		sum(iif(PLATFORM ='Retail', cast(sales as decimal),0)) / 
			sum(iif(PLATFORM ='Retail', transactions,0)) as shopify_tra_size
from data_mart.weekly_sales_clean
where transactions is not null
group by year(dates)

----------------------------------------------------------------------------------------------------------
-- This technique is usually used when we inspect an important event and want to inspect the impact before and after 
-- a certain point in time.

--Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came 
-- into effect.

--We would include all week_date values for 2020-06-15 as the start of the period after 
--the change and the previous week_date values would be before

--Using this analysis approach - answer the following questions:

--1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction 
--   rate in actual values and percentage of sales?
select	sum(iif(dates between dateadd(week, -4, '2020-06-15') and '2020-06-08', cast(sales as bigint),0)) as before_sales,
		sum(iif(dates between '2020-06-15' and dateadd(week, 3, '2020-06-15'), cast(sales as bigint),0)) as after_sales,
		100 - ((sum(iif(dates between '2020-06-15' and dateadd(week, 3, '2020-06-15'), cast(sales as bigint),0))
		/
		sum(iif(dates between dateadd(week, -4, '2020-06-15') and '2020-06-08', cast(sales as decimal),0)))*100) as pct
from data_mart.weekly_sales_clean;

--What about the entire 12 weeks before and after?
select	sum(iif(dates between dateadd(week, -12, '2020-06-15') and '2020-06-08', cast(sales as bigint),0)) as before_sales,
		sum(iif(dates between '2020-06-15' and dateadd(week, 11, '2020-06-15'), cast(sales as bigint),0)) as after_sales,
		100 - ((sum(iif(dates between '2020-06-15' and dateadd(week, 11, '2020-06-15'), cast(sales as bigint),0))
		/
		sum(iif(dates between dateadd(week, -12, '2020-06-15') and '2020-06-08', cast(sales as decimal),0)))*100) as pct
from data_mart.weekly_sales_clean;

--How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
-- For 4 weeks
select	year(dates), 
		sum(iif(wk_no between 21 and 24, cast(sales as bigint),0)) before_sales,
		sum(iif(wk_no between 25 and 28, cast(sales as bigint),0)) after_sales,
		(sum(iif(wk_no between 25 and 28, cast(sales as bigint),0)) -
		sum(iif(wk_no between 21 and 24, cast(sales as bigint),0))) as sales_diff,
		((sum(iif(wk_no between 25 and 28, cast(sales as decimal(10,2)),0)) /
		sum(iif(wk_no between 21 and 24, cast(sales as bigint),0)))*100) - 100 as pct
from data_mart.weekly_sales_clean
where year(dates) < 2021
group by year(dates)
order by year(dates);

-- For 12 weeks 
select	year(dates), 
		sum(iif(wk_no between 13 and 24, cast(sales as bigint),0)) before_sales,
		sum(iif(wk_no between 25 and 36, cast(sales as bigint),0)) after_sales,
		(sum(iif(wk_no between 25 and 36, cast(sales as bigint),0)) -
		sum(iif(wk_no between 13 and 24, cast(sales as bigint),0))) as sales_diff,
		((sum(iif(wk_no between 25 and 36, cast(sales as decimal(10,2)),0)) /
		sum(iif(wk_no between 13 and 24, cast(sales as bigint),0)))*100) - 100 as pct
from data_mart.weekly_sales_clean
where year(dates) < 2021
group by year(dates)
order by year(dates);

-- Example: Creating a stored procedure
--CREATE PROCEDURE GetEmployeeByID
--    @EmployeeID INT
--AS
--BEGIN
--    SELECT EmployeeID, FirstName, LastName
--    FROM Employees
--    WHERE EmployeeID = @EmployeeID;
--END;

-- Example: Creating a stored procedure
CREATE PROCEDURE data_mart.Before_after
    @weeks INT
AS
BEGIN
    select	year(dates), 
		sum(iif(wk_no between 25 - @weeks and 24, cast(sales as bigint),0)) before_sales,
		sum(iif(wk_no between 25 and 24 + @weeks, cast(sales as bigint),0)) after_sales,
		(sum(iif(wk_no between 25 and 24 + @weeks, cast(sales as bigint),0)) -
		sum(iif(wk_no between 25 - @weeks and 24, cast(sales as bigint),0))) as sales_diff,
		((sum(iif(wk_no between 25 and 24 + @weeks, cast(sales as decimal(10,2)),0)) /
		sum(iif(wk_no between 25 - @weeks and 24, cast(sales as bigint),0)))*100) - 100 as pct
	from data_mart.weekly_sales_clean
	where year(dates) < 2021
	group by year(dates)
	order by year(dates);
END;

exec data_mart.Before_after @weeks =4;

-- Bonus Question
CREATE PROCEDURE data_mart.Before_after_column
    @weeks INT, @column nvarchar(50)
AS
BEGIN
	select	@column,
			((sum(iif(wk_no between 25 and 24 + @weeks, cast(sales as decimal(10,2)),0)) /
			sum(iif(wk_no between 25 - @weeks and 24, cast(sales as bigint),0)))*100) - 100 as pct
	from data_mart.weekly_sales_clean
	where year(dates) = 2020 and sales is not null
	group by @column
	order by pct
end;

select	top 1 region,
		((sum(iif(wk_no between 25 and 36, cast(sales as decimal(10,2)),0)) /
		sum(iif(wk_no between 13 and 24, cast(sales as bigint),0)))*100) - 100 as pct
from data_mart.weekly_sales_clean
where year(dates) = 2020 and sales is not null
group by region
order by pct

CREATE PROCEDURE data_mart.Before_after_column
    @weeks INT, @column nvarchar(50)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX);
	SET @sql = N'
		SELECT top 1 +' + QUOTENAME(@column) + ',
			((SUM(IIF(wk_no BETWEEN 25 AND 24 + ' + CAST(@weeks AS NVARCHAR(10)) + ', CAST(sales AS DECIMAL(10,2)), 0)) /
			SUM(IIF(wk_no BETWEEN 25 - ' + CAST(@weeks AS NVARCHAR(10)) + ' AND 24, CAST(sales AS BIGINT), 0))) * 100) - 100 AS pct
		FROM data_mart.weekly_sales_clean
		WHERE YEAR(dates) = 2020 AND sales IS NOT NULL
		GROUP BY ' + QUOTENAME(@column) + '
		ORDER BY pct';
	EXEC sp_executesql @sql;
END;
drop procedure data_mart.Before_after_column

exec data_mart.Before_after_column @weeks =12, @column = 'platform' ;
exec data_mart.Before_after_column @weeks =12, @column = 'region';
exec data_mart.Before_after_column @weeks =12, @column = 'age_band';
exec data_mart.Before_after_column @weeks =12, @column = 'demographic';
exec data_mart.Before_after_column @weeks =12, @column = 'customer_type';