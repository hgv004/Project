======================================================================================================================
-- C. Ingredient Optimisation

-- What are the standard ingredients for each pizza?
use pizza_runner;

select pn.pizza_name , pt.topping_name 
from pz_recipie pr 
inner join pizza_names pn
on pn.pizza_id = pr.pizza_id 
left join pizza_toppings pt 
on pt.topping_id = pr.Toppings ;

-- What was the most commonly added extra?

WITH RECURSIVE
  unwound AS (
    SELECT *
      FROM pizza_recipes
    UNION ALL
    SELECT pizza_id , regexp_replace(toppings , '^[^,]*,', '') topp
      FROM unwound
      WHERE toppings LIKE '%,%'
  )
  SELECT pizza_id, regexp_replace(toppings, ',.*', '') topp
    FROM unwound
    ORDER BY pizza_id
;

create table co1(
	select 	row_number() over() as transaction_id,
			order_id,
			customer_id,
			pizza_id,
			order_time 
	from customer_orders1 co
	order by order_id) ;

create table extras (
	select row_number() over() as transaction_id,
			left(extras, 1) as extras,
			left(exclusions, 1) as exclusions 
	from customer_orders1 co
	order by order_id);

-- Added 2 rows manually 

select * from extras e;


select pt.topping_name , count(*) most_common
from extras e 
left join pizza_toppings pt 
on pt.topping_id = e.extras 
where e.extras is not null
group by pt.topping_name;
-- What was the most common exclusion?
select pt.topping_name , count(*) most_common
from extras e 
left join pizza_toppings pt 
on pt.topping_id = e.exclusions  
where e.exclusions  is not null
group by pt.topping_name;

/*Generate an order item for each record in the customers_orders table in the format of one of the following:
	Meat Lovers
	Meat Lovers - Exclude Beef
	Meat Lovers - Extra Bacon
	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers */
-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?





=====================================================================================================================================
-- D. Pricing and Ratings

-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
select 	ro.runner_id, 
		sum(case when pn.pizza_name = "Meatlovers" then 12 when pn.pizza_name = "Vegetarian" then 10 else 0 end) total_money
from customer_orders1 co 
inner join runner_orders1 ro 
on ro.order_id = co.order_id 
inner join pizza_names pn 
on pn.pizza_id = co.pizza_id 
where ro.duration is not null
group by ro.runner_id;

-- What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
select 	ro.runner_id  , 
		sum(case when extras = 1 then 2 when extras is not null then 1 else 0 end
		+
		case when c.pizza_id = 1 then 12 when c.pizza_id = 2 then 10 else 0 end) as total
from extras e 
left join co1 c 
on c.transaction_id = e.transaction_id 
left join runner_orders1 ro 
on ro.order_id = c.order_id 
where ro.duration is not null
group by ro.runner_id;

-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

drop table rating_table;
create table rating_table (
	select order_id, if(duration is not null, FLOOR(1 + RAND() * 5),null) rating  
	from runner_orders1 ro) ;

/*Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas*/

select 	co.customer_id, 
		co.order_id, 
		ro.runner_id, 
		rt.rating,
		co.order_time ,
		ro.pickup_time ,
		minute (timediff(ro.pickup_time, co.order_time)) diff,
		ro.duration ,
		if(substring(ro.distance,3,1) =".",left(ro.distance,4),left (ro.distance,2)) 
			/
			(left(ro.duration,2) / 60 ) as speed_kmh			
from customer_orders1 co 
inner join runner_orders1 ro 
on ro.order_id = co.order_id 
left join rating_table rt 
on rt.order_id = co.order_id
where ro.cancellation is null;




/*If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?*/

create table pizza_with_rate (
select *, if(pizza_id = 1, 12,10) as rate
from pizza_names pn );

select 	sum(pwr.rate) as rev,
		sum(if(substring(ro.distance,3,1) =".",left(ro.distance,4),left (ro.distance,2)))*0.3 as extra_cost,
		sum(pwr.rate) - (sum(if(substring(ro.distance,3,1) =".",left(ro.distance,4),left (ro.distance,2)))*0.3) as profit
from customer_orders1 co 
left join pizza_with_rate pwr 
on pwr.pizza_id = co.pizza_id 
left join runner_orders1 ro 
on ro.order_id = co.order_id 
where ro.cancellation is null;






