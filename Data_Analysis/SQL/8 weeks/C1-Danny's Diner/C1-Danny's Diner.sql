create database 8week;

use 8week;

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
-----------------------------------------------------------------------------------------------------

-- 1. What is the total amount each customer spent at the restaurant?
create view final_view as (
select s.customer_id , s.order_date , s.product_id , m.product_name , m.price , m2.join_date  
from sales s
join menu m 
on s.product_id = m.product_id 
join members m2 
on s.customer_id = m2.customer_id );

select * from final_view;

select customer_id,sum(price)
from final_view
group by customer_id ;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date)
from final_view
group by customer_id ;

-- 3. What was the first item from the menu purchased by each customer?
select * from final_view order by customer_id , order_date ;
WITH ranked_data AS (
  SELECT customer_id, order_date, product_name, 
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rank1
  FROM final_view fv
)
SELECT customer_id, product_name
FROM ranked_data
WHERE rank1 = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name , count(product_name) ct
from final_view fv 
group by product_name 
order by ct desc;

-- 5. Which item was the most popular for each customer?====================
select customer_id, product_name , count(product_name) ct
from final_view fv 
group by customer_id, product_name 
order by customer_id, product_name;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT *, DATEDIFF(order_date,join_date) AS diff 
FROM final_view fv
WHERE DATEDIFF(order_date,join_date) > 0;

-- 7. Which item was purchased just before the customer became a member?

-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
 
