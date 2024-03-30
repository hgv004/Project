![image](https://github.com/hgv004/Project/assets/105195779/a05c3abc-25e5-48ae-814c-c794674c0fb8)
## Introduction
- Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

- Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

1. sales
2. menu
3. embers

## Database creation
```sql
create database dannys_diner;

use dannys_diner;

CREATE TABLE sales (
  `customer_id` VARCHAR(264),
  `order_date` DATE,
  `product_id` INTEGER
);


INSERT INTO sales
  (`customer_id`, `order_date`, `product_id`)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

select * from sales;

CREATE TABLE menu (
  product_id INT,
  product_name VARCHAR(5),
  price INT
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
```
## Solutions
### 1. What is the total amount each customer spent at the restaurant?
```sql
create or replace view final_view as (
select s.customer_id , s.order_date , s.product_id , m.product_name , m.price , m2.join_date  
from sales s
join menu m 
on s.product_id = m.product_id 
left join members m2 
on s.customer_id = m2.customer_id );

select * from final_view;

select customer_id,sum(price) as total_amt
from final_view
group by customer_id ;
```
### 2. How many days has each customer visited the restaurant?
```sql
select customer_id, count(distinct order_date) as times_visits
from final_view
group by customer_id ;
```
### 3. What was the first item from the menu purchased by each customer?
```sql
select * from final_view order by customer_id , order_date ;
WITH ranked_data AS (
  SELECT customer_id, order_date, product_name, 
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rank1
  FROM final_view fv
)
SELECT customer_id, product_name
FROM ranked_data
WHERE rank1 = 1;
```

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
select product_name , count(product_name) ct
from final_view fv 
group by product_name 
order by ct desc;
```
### 5. Which item was the most popular for each customer?
```sql
select customer_id, product_name , count(product_name) ct
from final_view fv 
group by customer_id, product_name 
order by customer_id, product_name;
```
### 6. Which item was purchased first by the customer after they became a member?
```sql
with cte as (
	select 	customer_id , 
			product_name, 
			DATEDIFF(join_date,order_date) as diff, 
			rank() over(partition by customer_id order by DATEDIFF(join_date,order_date)) as rn
	from final_view
	where DATEDIFF(join_date,order_date)>= 0)
select customer_id, product_name  
from cte
where cte.rn =1;
```
### 7. Which item was purchased just before the customer became a member?

```sql
select * from final_view;

with cte as (
	select 	customer_id , 
			product_name, 
			datediff(join_date, order_date) as diff, 
			rank() over(partition by customer_id order by datediff(join_date, order_date)) as rn
	from final_view
	where datediff(join_date, order_date) > 0)
select customer_id, product_name  
from cte
where cte.rn =1;
```
### 8. What is the total items and amount spent for each member before they became a member?
```sql
select customer_id , count(product_id) as total_items, sum(price) as total_amt 
from final_view
where datediff(join_date, order_date) > 0
group by customer_id;
```
### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
select customer_id , sum(if(product_name = 'sushi', 20*price, 10* price) ) as total_pts
from final_view
group by customer_id;
```
### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
select 	customer_id ,
		sum(case WHEN datediff(order_date, join_date) between 0 and 6 THEN 20*price
    		WHEN product_name = 'sushi' THEN 20*price
	    	ELSE 10*price end) as final_pts
from final_view
where order_date <="2021-01-31"
group by customer_id;
```
