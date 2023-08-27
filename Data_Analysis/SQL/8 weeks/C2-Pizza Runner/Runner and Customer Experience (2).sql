-- B. Runner and Customer Experience


-- Preparing date Table

use pizza_runner;

create table date_table
	(WITH RECURSIVE 
	all_date (_date) AS
		(
		SELECT "2020-01-01"
		union all
		SELECT date_add(_date, INTERVAL 1 DAY) from all_date where _date < "2020-12-31"
		)
	SELECT max(_date) FROM all_date);

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01) [Look]

select week(registration_date) as _week, count(runner_id) as sign_up 
from runners r 
group by _week;


-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

with order_time as (
	select order_id, max(order_time) as ot
	from customer_orders1
	group by order_id) 
select ro.runner_id, avg(minute(timediff(od.ot, ro.pickup_time))) as avg_mins
from runner_orders1 ro
inner join  order_time od
on ro.order_id = od.order_id
group by ro.runner_id;


-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

with order_time as (
	select order_id, max(order_time) as ot, count(order_id) as pizzas
	from customer_orders1
	group by order_id) 
select ro.order_id , sum(od.pizzas) as total_pizzas, sum(minute(timediff(od.ot, ro.pickup_time))) as total_mins 
from runner_orders1 ro
inner join  order_time od
on ro.order_id = od.order_id
where ro.pickup_time is not null
group by ro.order_id;

-- What was the average distance travelled for each customer?

select 	co.customer_id ,
		avg(if(substring(distance,3,1) =".",left(distance,4),left (distance,2))) as dist
from runner_orders1 ro
inner join  customer_orders1 co 
on ro.order_id = co.order_id
where ro.pickup_time is not null
group by co.customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?

select  (max(left(duration,2))- min(left(duration,2))) as diff
from runner_orders1 ro;


-- What was the average speed for each runner for each delivery and do you notice any trend for these values?

select r.runner_id, avg(speed) as avg_speed
from (
	select 	runner_id ,
			if(substring(distance,3,1) =".",left(distance,4),left (distance,2)) 
			/
			(left(duration,2) / 60 ) as speed
	from runner_orders1 ro 
	where duration is not null) as r
group by r.runner_id;

-- What is the successful delivery percentage for each runner?

select runner_id , (sum(if(duration is not null,1,0)) / count(order_id))*100 as succ_delivery
from runner_orders1 ro
group by runner_id;


-- https://deepnote.com/@npda/Case-Study-2-Pizza-Runner-07504a14-9128-4a66-bd6c-611a6e23952f













