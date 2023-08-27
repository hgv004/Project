/*A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!*/

=======================================================================================================================================
-- Create Date Calender

drop table calendar ;

create table calendar(
WITH RECURSIVE 
calendar(dates) AS
(
SELECT (select min(start_date) from subscriptions s )
union all
SELECT date_add(dates, INTERVAL 1 DAY)  from calendar where dates < "2021-12-31"
)
SELECT * FROM calendar);

select * from calendar c ;

-- B. Data Analysis Questions
use foodie_fi;

-- How many customers has Foodie-Fi ever had?
select count(distinct customer_id) 
from subscriptions 
where plan_id != 0;

select *
from subscriptions ;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select 	date_add(date_add(LAST_DAY(start_date), interval 1 day), interval -1 month) as dt,
		count(start_date )
from subscriptions s 
where plan_id = 0
group by dt;

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select p.plan_name , count(start_date)
from subscriptions s
inner join plans p 
on p.plan_id = s.plan_id 
where year(start_date) > 2020
group by p.plan_name;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 	COUNT(DISTINCT customer_id) as total_customers,
		COUNT(DISTINCT IF(plan_id = 4, customer_id, NULL)) as churn,
		(COUNT(DISTINCT IF(plan_id = 4, customer_id, NULL)) / COUNT(DISTINCT customer_id))*100 as churn_pct
FROM subscriptions;

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

with ct as (
	select 	customer_id ,
			plan_id,
			lead(plan_id) over(partition by customer_id order by customer_id , start_date, plan_id ) as next_plan
	from subscriptions s)
select 	count(distinct ct.customer_id), 
		count(distinct ct.customer_id) / (select count(distinct customer_id) from subscriptions where plan_id = 0)*100 as churn_pct
from ct 
where ct.next_plan = 4 and ct.plan_id = 0;

-- What is the number and percentage of customer plans after their initial free trial?
with ct as (
	select 	customer_id ,
			plan_id,
			lead(plan_id) over(partition by customer_id order by customer_id , start_date, plan_id ) as next_plan
	from subscriptions s)
select 	p.plan_name , 
		count(*) as plan_activated, 
		count(*) / (select count(distinct customer_id) from subscriptions where plan_id = 0)*100 as activation_pct
from ct 
left join plans p 
on p.plan_id = ct.next_plan
where ct.next_plan is not null
group by p.plan_name;


-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
select 	v.plan_name, 
		count(v.plan_name), 
		count(v.plan_name) / (select count(distinct customer_id) from subscriptions where plan_id = 0)*100 as activation_pct_2020
from 
(select p.plan_name, 
		s.customer_id ,
		row_number() over(partition by s.customer_id order by s.start_date desc) as t
from subscriptions s
inner join plans p 
on p.plan_id = s.plan_id 
where start_date <= "2020-12-31") v 
where v.t=1
group by v.plan_name
order by 2 desc;


-- How many customers have upgraded to an annual plan in 2020?
select count(distinct b.customer_id) from 
(select 	customer_id ,
			start_date ,
			plan_id,
			lead(plan_id) over(partition by customer_id order by customer_id , start_date ) as next_plan,
			(lead(plan_id) over(partition by customer_id order by customer_id , start_date ) - plan_id) as diff
from subscriptions s
where year(start_date) = 2020) b
where b.next_plan !=4;

select 	customer_id ,
			start_date ,
			plan_id,
			lag(plan_id) over(partition by customer_id order by customer_id , start_date ) as next_plan,
			(plan_id -lag(plan_id) over(partition by customer_id order by customer_id , start_date )) as diff
from subscriptions s
where year(start_date) = 2020;

SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions
WHERE plan_id = 3
  AND EXTRACT(YEAR FROM start_date) = '2020';

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with cte as (
 	SELECT *, 
			MIN(start_date) OVER (PARTITION BY customer_id) AS min_start_date,
			if(plan_id = 3, start_date, null) max_start_date
	FROM subscriptions s)
select 	
		avg(datediff(cte.max_start_date, cte.min_start_date)) as avg_time
from cte 
where cte.max_start_date is not null;
-- group by cte.customer_id 
-- order by cte.customer_id 



-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with cte as (
 	SELECT *, 
			MIN(start_date) OVER (PARTITION BY customer_id) AS min_start_date,
			if(plan_id = 3, start_date, null) max_start_date
	FROM subscriptions s)
select 	concat(floor( datediff(cte.max_start_date, cte.min_start_date) / 30)*30 ,"-",
		(floor( datediff(cte.max_start_date, cte.min_start_date) / 30) + 1) * 30 ) as bucket,
		count(*)
from cte 
where cte.max_start_date is not null
group by 1;


-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
select count(v.customer_id) as downgrades from 
(select *,
		lead(plan_id) over(partition by customer_id order by customer_id , start_date) as next_plan
from subscriptions s 
where plan_id in (2,1)) v
where v.next_plan = 1;


/*C. Challenge Payment Question
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments*/


select 	s.customer_id ,
		s.plan_id, 
		p.plan_name, 
		s.start_date , 
		p.price  
from subscriptions s 
inner join plans p 
on p.plan_id = s.plan_id 
order by 	s.customer_id ,
			s.plan_id;