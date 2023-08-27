======Pizza Metrics=======

-- How many pizzas were ordered?

select count(*)from customer_orders co ;

-- How many unique customer orders were made?
select count(distinct order_id) as unique_orders
from customer_orders co ;

-- How many successful orders were delivered by each runner?
CREATE TABLE runner_orders1 AS
SELECT order_id, runner_id, pickup_time, distance, duration, IF(cancellation = '', NULL, cancellation) AS cancellation
FROM pizza_runner.runner_orders;

select runner_id , count(order_id)
from runner_orders1 ro
where isnull(cancellation )
group by runner_id;

-- How many of each type of pizza was delivered?
select co.pizza_id , count(co.order_id) as pizza_delivered
from customer_orders co 
left join runner_orders1 ro 
on ro.order_id = co.order_id 
where isnull(ro.cancellation )
group by co.pizza_id;


-- How many Vegetarian and Meatlovers were ordered by each customer?=======
select co.customer_id, pn.pizza_name , count(order_id) as total_pizza
from customer_orders co 
left join pizza_names pn 
on pn.pizza_id = co.pizza_id 
group by co.customer_id, pn.pizza_name
order by co.customer_id, pn.pizza_name;

-- What was the maximum number of pizzas delivered in a single order?
select co.order_id , count(co.customer_id) as pizza_delivered
from customer_orders co 
left join runner_orders1 ro 
on ro.order_id = co.order_id 
where isnull(ro.cancellation) 
group by co.order_id
order by count(co.customer_id) desc
limit 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
CREATE TABLE customer_orders1 AS
select 	order_id, customer_id, pizza_id, 
		IF(exclusions = '', NULL, exclusions) AS exclusions, 
		IF(extras = '', NULL, extras) AS extras, 
		order_time
FROM pizza_runner.customer_orders;

select 	co.customer_id, 
		count(co.order_id) as total_pizza,
		sum(if(isnull(co.exclusions) and isnull(co.extras),1,0)) as no_change,
		sum(if(not isnull(co.exclusions) or not isnull(co.extras),1,0)) as atleast_one_change
from customer_orders1 co 
left join runner_orders1 ro 
on ro.order_id = co.order_id 
where isnull(ro.cancellation) 
group by co.customer_id;

-- for Testing 

select 	co.customer_id, 
		co.extras ,
		co.exclusions 
from customer_orders1 co 
left join runner_orders1 ro 
on ro.order_id = co.order_id 
where isnull(ro.cancellation)
order by co.customer_id ;

-- How many pizzas were delivered that had both exclusions and extras?

select 	co.customer_id, 
		sum(if(not isnull(co.exclusions) and not isnull(co.extras),1,0)) as atleast_one_change
from customer_orders1 co 
left join runner_orders1 ro 
on ro.order_id = co.order_id 
where isnull(ro.cancellation) 
group by co.customer_id
having atleast_one_change >0;

-- What was the total volume of pizzas ordered for each hour of the day?
select 	date(order_time) as dt,
		hour (order_time) as hr,
		count(order_id) as pizza_volume
FROM pizza_runner.customer_orders1
group by dt,hr
order by dt,hr;

-- What was the volume of orders for each day of the week?
select 	dayname(order_time) as Days,
		count(order_id) as pizza_volume
FROM pizza_runner.customer_orders1
group by Days
order by Days;


