SELECT `Row ID`, `Order ID`, `Order Date`, `Ship Date`, `Ship Mode`, `Customer ID`, `Customer Name`, Segment, Country, City, State, `Postal Code`, Region, `Product ID`, Category, `Sub-Category`, `Product Name`, Sales, Quantity, Discount, Profit
FROM Sample_superstore.sample_superstore_order;

select * from 
sample_superstore_order;

use Sample_superstore;
# Window Functions practice
#1. Find sales for category and subcategory

drop table gb;

select category, subcategory, sum(sales) as total_sales
from SS
group by category, subcategory;

#2
select category,
sum(sales) over() as total_sales
from SS s;

select category,subcategory,
sum(sales) over(partition by subcategory) as total_sales
from SS s;

select * from gb;

# give row number to gb table based on the categories and alphabetically of sub category

select * , row_number() over() as rn
from gb;

select * , row_number() over(partition by category) as rn
from gb;

select * , row_number() over(partition by category order by subcategory) as rn
from gb
order by category, rn;

# Rank of the subcategory from each category based on sales
select * , rank() over(partition by category order by total_sales desc) as rn
from gb
order by category, rn;

#Only show highest ranked rows for furniture
select * from (select * , rank() over(partition by category order by total_sales desc) as rn
	from gb
	order by category, rn) tt
where tt.rn = 1;

use sample_superstore;

SELECT category,subcategory, sum(sales) as total, 
dense_rank() over(partition by category order by sum(sales)) as rank1
FROM SS
group by category,subcategory
order by category;

#1. Create a query that shows the top 3 highest sales for each category and subcategory, including the total sales for the Category and the sub category.
with ct as (
	select category, Subcategory , sum(Sales) as total_sales, 
	rank() over(partition by Category order by sum(sales)) as rank1  
	from ss
	group by category, Subcategory)
select * 
from ct
where rank1 <4;

#2 Create a query that shows the running total of sales for each month and category, sorted by the running total in descending order.
select Category,month(`Order Date`) as mnth, sum(Sales) as total_sales
from ss
where year(`Order Date`)=2016
group by mnth, Category  
order by category, mnth;

select distinct year(`Order Date`)
from ss;

with ct as (select Category,month(`Order Date`) as mnth, sum(Sales) over(partition by Category order by month(`Order Date`)) as t
	from ss
	where year(`Order Date`)=2016 
	order by category, mnth)
select ct.category, ct.mnth, avg(ct.t)
from ct
group by ct.category, ct.mnth;

#3 Create a query that shows the difference in sales between each month for each category.
select Category,month(`Order Date`) as mnth, round(sum(sales),2) as total_sales,
lag(round(sum(sales),2)) over(partition by Category order by month(`Order Date`)) as prv_mnth_sales,
round(sum(sales),2) - ifnull(lag(round(sum(sales),2)) over(partition by Category order by month(`Order Date`)),0) as diff
from ss
group by Category, mnth;

#4 Create a query that shows the percentage change in sales between each month for each category.
with ct1 as (select Category,month(`Order Date`) as mnth, round(sum(sales),2) as total_sales,
	lag(round(sum(sales),2)) over(partition by Category order by month(`Order Date`)) as prv_mnth_sales
	from ss
	group by Category, mnth)
select ct1.*, (ct1.total_sales - ct1.prv_mnth_sales) as diff,
round((ct1.total_sales - ct1.prv_mnth_sales) / ct1.total_sales * 100,2) as pct
from ct1;

--------#5 Create a query that shows the top 10% of sales for each category, based on the total sales for the year.------
select category, year(`Order Date`) as yr, sum(Sales) as gtotal_sales
from ss
group by category,yr
order by category,yr;

select category, round(sum(Sales),2) as total_sales
from ss
group by category
order by category;

#6. Create a query that shows the median sales for each category, using a window function.
select category, round(sum(Sales),2) as total_sales
from ss
group by category
order by category;

select category,sales, row_num
from (SELECT category, sales,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales) AS row_num,
           COUNT(*) OVER (PARTITION BY category) AS count,
           (COUNT(*) OVER (PARTITION BY category) + 1) / 2 AS median_row
    FROM ss) as s
WHERE row_num = median_row OR row_num = median_row + 1;


-------------------------------------------------------------
#8. Create a query that shows the rank of each category based on the total sales for the year, including ties.

select year(`Order Date`) as yr, Category, sum(Sales) as total_sales,
rank() over(partition by year(`Order Date`) order by sum(sales) desc) as rank1
from ss
group by yr, Category
order by yr, rank1, Category;

-------------------------------------------------------------
#9. Create a query that shows the running total of sales for each month, by category, including only the top 5 categories based on the running total. 

select Category , month(`Order Date`) as mnth, sum(Sales) as total_sales
from ss
group by Category, mnth
order by Category, mnth;

-------------------------------------------------------------
#10. Create a query that shows the average sales for each month and category, including the average sales for the year and the average sales for the previous year.

WITH sales_data AS (
	SELECT 	Category, 
			YEAR(`Order Date`) AS yr,
			AVG(Sales) AS cur_yr_sales,
			LAG(AVG(Sales)) OVER (PARTITION BY Category ORDER BY YEAR(`Order Date`)) AS prev_yr_sales
	FROM ss
	GROUP BY Category, yr
	ORDER BY Category, yr
),
ct1 AS (
	SELECT 	Category, 
			YEAR(`Order Date`) AS yr,
			MONTH(`Order Date`) AS mnth,
			AVG(Sales) AS avg_monthly_sales
	FROM ss
	GROUP BY Category, yr, mnth
	ORDER BY Category, yr, mnth
)
SELECT ct1.*, 
	sales_data.cur_yr_sales, 
	sales_data.prev_yr_sales
FROM ct1
LEFT JOIN sales_data ON sales_data.Category = ct1.Category AND sales_data.yr = ct1.yr;

----------------------------------------------------------------
#11. Create a query that shows the top 2 categories by sales for each region, including the total sales for each region.

with ct as 
	(select Region, 
			Category, 
			sum(Sales) as total_sales,
			rank() over(partition by Region order by sum(Sales) desc) as r1
	from ss
	group by Category , Region 
	order by Region ,r1, Category) 
select * 
from ct 
where r1<3;

----------------------------------------------------------
#12. Create a query that shows the rolling average of sales for each category over a 3-month period.

with ct as 
	(select Category , 
			quarter(`Order Date`) as qtr, 
			avg(Sales) as avg_sales
	from ss
	group by Category, qtr
	order by Category, qtr
)
select *, avg(avg_sales) over(partition by Category order by qtr rows between 3 PRECEDING AND CURRENT ROW ) as rollingAvg
from ct;

--------------------------------------------------
#13. Create a query that shows the cumulative percentage of sales for each category, by month.

select Category , month(`Order Date`) as mnth, sum(Sales) as total_sales
from ss
group by Category , mnth
order by Category , mnth;

#14. Create a query that shows the difference in sales between each month and the average sales for the previous 3 months, for each category.

#15. Create a query that shows the percentage change in sales between each month and the same month in the previous year, for each category.

#16. Create a query that shows the number of days between the first and last sale for each category.

#17. Create a query that shows the rank of each category based on the average sales for the year, including ties.

#18. Create a query that shows the percentage of total sales for each category, by year.

#19. Create a query that shows the average sales for each category, including the average sales for the previous year and the percentage change between the two.

#20. Create a query that shows the top 5% of sales for each category, based on the total sales for the previous year.


















