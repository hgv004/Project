# **Case Study #3 - Foodie-Fi**
![image](https://github.com/hgv004/Project/assets/105195779/63279288-9416-4f3b-bfc3-9dc835cbaf9d)



## Introduction
- Subscription based businesses are super popular and Danny realised that there was a large gap in the market - he wanted to create a new streaming service that only had food related content - something like Netflix but with only cooking shows!

- Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

- Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.

## Available Data
- Danny has shared the data design for Foodie-Fi and also short descriptions on each of the database tables - our case study focuses on only 2 tables but there will be a challenge to create a new table for the Foodie-Fi team.
# **Case Study Questions**

This case study is split into an initial data understanding question before diving straight into data analysis questions before finishing with 1 single extension challenge.
### Create Date Calender
```sql
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
```
### **A. Customer Journey**

Based off the 8 sample customers provided in the sample from the `subscriptions` table, write a brief description about each customer’s onboarding journey.

## **B. Data Analysis Questions**
### 1. How many customers has Foodie-Fi ever had?
```sql
select count(distinct customer_id) 
from subscriptions 
where plan_id != 0;
```
### 2. What is the monthly distribution of `trial` plan `start_date` values for our dataset - use the start of the month as the group by value
```sql
select 	date_add(date_add(LAST_DAY(start_date), interval 1 day), interval -1 month) as dt,
		count(start_date )
from subscriptions s 
where plan_id = 0
group by dt;
```
### 3. What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`
```sql
select p.plan_name , count(start_date)
from subscriptions s
inner join plans p 
on p.plan_id = s.plan_id 
where year(start_date) > 2020
group by p.plan_name;
```
### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
SELECT 	COUNT(DISTINCT customer_id) as total_customers,
		COUNT(DISTINCT IF(plan_id = 4, customer_id, NULL)) as churn,
		(COUNT(DISTINCT IF(plan_id = 4, customer_id, NULL)) / COUNT(DISTINCT customer_id))*100 as churn_pct
FROM subscriptions;
```
### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```sql
with ct as (
	select 	customer_id ,
			plan_id,
			lead(plan_id) over(partition by customer_id order by customer_id , start_date, plan_id ) as next_plan
	from subscriptions s)
select 	count(distinct ct.customer_id), 
		count(distinct ct.customer_id) / (select count(distinct customer_id) from subscriptions where plan_id = 0)*100 as churn_pct
from ct 
where ct.next_plan = 4 and ct.plan_id = 0;
```
### 6. What is the number and percentage of customer plans after their initial free trial?
```sql
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
```
### 7. What is the customer count and percentage breakdown of all 5 `plan_name` values at `2020-12-31`?
```sql
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
```
### 8. How many customers have upgraded to an annual plan in 2020?
```sql
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
```
### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
with cte as (
 	SELECT *, 
			MIN(start_date) OVER (PARTITION BY customer_id) AS min_start_date,
			if(plan_id = 3, start_date, null) max_start_date
	FROM subscriptions s)
select 	
		avg(datediff(cte.max_start_date, cte.min_start_date)) as avg_time
from cte 
where cte.max_start_date is not null;
```
### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```sql
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
```
### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
select count(v.customer_id) as downgrades from 
(select *,
		lead(plan_id) over(partition by customer_id order by customer_id , start_date) as next_plan
from subscriptions s 
where plan_id in (2,1)) v
where v.next_plan = 1;
```
### **C. Challenge Payment Question**

### The Foodie-Fi team wants you to create a new `payments` table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:

- monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments
```sql
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
```
## **D. Outside The Box Questions**

- The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

### 1. How would you calculate the rate of growth for Foodie-Fi?
```sql

```
### 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
```sql

```
### 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?
```sql

```
### 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
```sql

```
### 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?
```sql

```
