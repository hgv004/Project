use data_bank;

select * from data_bank.customer_nodes cn ;

-- A. Customer Nodes Exploration

-- How many unique nodes are there on the Data Bank system?

select count(distinct node_id ) as unique_nodes
from customer_nodes cn ;

-- What is the number of nodes per region?
select r.region_name , count(node_id) as node_counts
from customer_nodes cn
join regions r 
on r.region_id = cn.region_id 
group by r.region_name ;

-- How many customers are allocated to each region?
select r.region_name , count(distinct customer_id) as customers
from customer_nodes cn
join regions r 
on r.region_id = cn.region_id 
group by r.region_name ;

-- How many days on average are customers reallocated to a different node?
select avg(datediff(end_date, start_date)) as avg_days
from customer_nodes cn 
where year(end_date) !=9999;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH date_diff AS
(
	SELECT cn.customer_id,
	       cn.region_id,
	       r.region_name,
	       DATEDIFF(DAY, start_date, end_date) AS reallocation_days
	FROM customer_nodes cn
	INNER JOIN regions r
	ON cn.region_id = r.region_id
	WHERE end_date != '9999-12-31'
)
SELECT DISTINCT region_id,
	        region_name,
	        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY reallocation_days) OVER(PARTITION BY region_name) AS median,
	        PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY reallocation_days) OVER(PARTITION BY region_name) AS percentile_80,
	        PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY reallocation_days) OVER(PARTITION BY region_name) AS percentile_95
FROM date_diff
ORDER BY region_name;

=========================================================================================
-- B. Customer Transactions

-- What is the unique count and total amount for each transaction type?
select txn_type , sum(txn_amount) as total_amt, count(customer_id) as unique_counts
from customer_transactions ct 
group by txn_type;

-- What is the average total historical deposit counts and amounts for all customers?
with cte as (
	select customer_id , count(txn_type) as deposits, sum(txn_amount) as total_amt
	from customer_transactions ct 
	where txn_type  = 'deposit'
	group by customer_id
	order by customer_id)
select avg(cte.deposits) avg_deposit_count, avg(cte.total_amt) avg_deposit_amount
from cte;

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

with cte as (
	select 	DATE_FORMAT(txn_date , "%M- %Y") as my,
			customer_id ,
			count(if(txn_type = 'deposit', txn_type,null)) as deposit,
			count(if(txn_type = 'purchase', txn_type,null)) as purchase,
			count(if(txn_type = 'withdrawal', txn_type,null)) as withdrawal
	from customer_transactions ct 
	group by my, customer_id
	having deposit > 1 and purchase + withdrawal !=0
	order by my, customer_id)
select cte.my, count(distinct cte.customer_id) as customer_counts
from cte
group by cte.my
order by cte.my;


-- What is the closing balance for each customer at the end of the month?

select 	DATE_FORMAT(txn_date, "%b-%y") as my,
		customer_id ,
		sum(if(txn_type = 'deposit', txn_amount ,0)) as deposit,
		sum(if(txn_type = 'purchase', txn_amount,0)) as purchase,
		sum(if(txn_type = 'withdrawal', txn_amount,0)) as withdrawal,
		sum(if(txn_type = 'deposit', txn_amount ,0)) - 
		sum(if(txn_type = 'purchase', txn_amount,0)) - 
		sum(if(txn_type = 'withdrawal', txn_amount,0)) as final_balance
from customer_transactions ct 
group by my, last_day(txn_date), customer_id
order by last_day(txn_date), customer_id;

with cte as (
	select 	DATE_FORMAT(txn_date, "%b-%y") as my,
			last_day(txn_date) as ld,
			customer_id ,
			sum(if(txn_type = 'deposit', txn_amount ,0)) - 
			sum(if(txn_type = 'purchase', txn_amount,0)) - 
			sum(if(txn_type = 'withdrawal', txn_amount,0)) as fb
	from customer_transactions ct 
	group by my, ld, customer_id
	order by customer_id, ld)
select 	cte.customer_id,
		cte.my as "Month", 
		sum(cte.fb) over(partition by cte.customer_id order by cte.ld rows between unbounded preceding  and current row) as final_balance
from cte;


-- What is the percentage of customers who increase their closing balance by more than 5%?

with cte as (
	select 	DATE_FORMAT(txn_date, "%b-%y") as my,
			last_day(txn_date) as ld,
			customer_id ,
			sum(if(txn_type = 'deposit', txn_amount ,0)) - 
			sum(if(txn_type = 'purchase', txn_amount,0)) - 
			sum(if(txn_type = 'withdrawal', txn_amount,0)) as fb
	from customer_transactions ct 
	group by my, ld, customer_id
	order by customer_id, ld),
cte2 as (
	select 	cte.customer_id,
			cte.my as "Month", 
			cte.fb,
			if(cte.fb >= 0.05*lag(fb) over(partition by cte.customer_id),1,0) as increase
	from cte)
select count(distinct cte2.customer_id) / (select count(distinct customer_id) from customer_transactions)
from cte2
where cte2.increase =1;

with cte as (
	select 	DATE_FORMAT(txn_date, "%b-%y") as my,
			last_day(txn_date) as ld,
			customer_id ,
			sum(if(txn_type = 'deposit', txn_amount ,0)) - 
			sum(if(txn_type = 'purchase', txn_amount,0)) - 
			sum(if(txn_type = 'withdrawal', txn_amount,0)) as fb
	from customer_transactions ct 
	group by my, ld, customer_id
	order by customer_id, ld),
select 	cte.customer_id,
		cte.my as "Month", 
		cte.fb,
		if(cte.fb >= 0.05*lag(fb) over(partition by cte.customer_id),1,0) as increase
from cte;

with cte as (
	select 	DATE_FORMAT(txn_date, "%b-%y") as my,
			last_day(txn_date) as ld,
			customer_id ,
			sum(if(txn_type = 'deposit', txn_amount ,0)) - 
			sum(if(txn_type = 'purchase', txn_amount,0)) - 
			sum(if(txn_type = 'withdrawal', txn_amount,0)) as fb
	from customer_transactions ct 
	group by my, ld, customer_id
	order by customer_id, ld),
cte2 as(
	select 	cte.customer_id,
			cte.ld,	
			cte.my as "Month", 
			sum(cte.fb) over(partition by cte.customer_id order by cte.ld rows between unbounded preceding  and current row) as final_balance
	from cte),
cte3 as (
	select 	*, 
			if(cte2.final_balance > 1.05*lag(cte2.final_balance) over(partition by cte2.customer_id), 1, 0) as lb_check
	from cte2)
count(distinct cte3.customer_id) / (select count(distinct customer_id) from customer_transactions)
from cte3
where cte3.lb_check =1;


