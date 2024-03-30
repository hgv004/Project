# Case Study Questions

The following questions can be considered key business questions and metrics that the Balanced Tree team requires for their monthly reports.

Each question can be answered using a single query - but as you are writing the SQL to solve each individual problem, keep in mind how you would generate all of these metrics in a single SQL script which the Balanced Tree team can run each month.

## High Level Sales Analysis

### 1. What was the total quantity sold for all products?

```sql
SELECT p.product_name, SUM(s.qty) AS total_qty_sold
FROM balanced_tree.sales s
LEFT JOIN balanced_tree.product_details p ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY total_qty_sold;
```
![image](https://github.com/hgv004/Project/assets/105195779/e6bba452-1875-4a74-84da-f3ccea81d595)


### 2. What is the total generated revenue for all products before discounts?
```sql
SELECT p.product_name, SUM(s.qty * s.price) AS total_rev
FROM balanced_tree.sales s
LEFT JOIN balanced_tree.product_details p ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY total_rev DESC;
```
![image](https://github.com/hgv004/Project/assets/105195779/334afd56-e08c-49a6-9ef1-258c194c670d)

### 3. What was the total discount amount for all products?
```sql
-- Discount by Product
SELECT p.product_name, ROUND(SUM(s.qty * s.price * (s.discount / 100)), 1) AS total_discount
FROM balanced_tree.sales s
LEFT JOIN balanced_tree.product_details p ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY total_discount DESC;

-- Total Discount
SELECT ROUND(SUM(s.qty * s.price * (s.discount / 100)), 1) AS total_discount
FROM balanced_tree.sales s;
```
![image](https://github.com/hgv004/Project/assets/105195779/44565923-75f7-48b2-85a1-e78075faa8a1)

## Transaction Analysis

### 1. How many unique transactions were there?
```sql
SELECT COUNT(DISTINCT s.txn_id) AS unq_transaction
FROM balanced_tree.sales s;
```
![image](https://github.com/hgv004/Project/assets/105195779/067bf1f0-81f4-4f3f-9a70-2a9a1e62b9c1)

### 2. What is the average unique products purchased in each transaction?
```sql
WITH cte AS (
  SELECT s.txn_id, COUNT(DISTINCT s.prod_id) AS unq_prods
  FROM balanced_tree.sales s
  GROUP BY s.txn_id
)
SELECT FLOOR(AVG(cte.unq_prods)) AS avg_uniq_prods
FROM cte;
```
![image](https://github.com/hgv004/Project/assets/105195779/7d304499-0633-430b-98d1-4b1e037f0f88)

### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
```sql
WITH t AS (
  SELECT txn_id, SUM(qty * price) AS transaction_revenue
  FROM balanced_tree.sales
  GROUP BY 1
)
SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY transaction_revenue) AS revenue_25percentile,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY transaction_revenue) AS revenue_50percentile,
       PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY transaction_revenue) AS revenue_75percentile
FROM t;
```
![image](https://github.com/hgv004/Project/assets/105195779/fd157c84-eac4-4530-8c41-25a75d1bf3e8)

### 4. What is the average discount value per transaction?
```sql
WITH t AS (
  SELECT txn_id, SUM(qty * price * discount / 100) AS txn_discount
  FROM balanced_tree.sales
  GROUP BY 1
)
SELECT ROUND(AVG(txn_discount), 2) AS avg_txn_discount
FROM t;
```
![image](https://github.com/hgv004/Project/assets/105195779/f16d163a-daee-462c-80f7-4d9de9fc4a78)

### 5. What is the percentage split of all transactions for members vs non-members?
```sql
WITH cte AS (
  SELECT member, COUNT(DISTINCT txn_id) AS txns
  FROM balanced_tree.sales
  GROUP BY member
)
SELECT IFF(member = true, 'member', 'non-member') AS Is_member,
       ROUND(100 * (txns / SUM(txns) OVER()), 1) AS pct
FROM cte;
```
![image](https://github.com/hgv004/Project/assets/105195779/a043e94e-e980-4433-b5a5-26d306ee9bc4)

### 6. What is the average revenue for member transactions and non-member transactions?
```sql
SELECT IFF(member = true, 'member', 'non-member') AS is_member,
       ROUND(AVG(qty * price), 1) AS avg_price
FROM balanced_tree.sales
GROUP BY is_member;
```
![image](https://github.com/hgv004/Project/assets/105195779/2a59aa37-b86a-46d4-aa69-e47beed121f2)

## Product Analysis
### 1. What are the top 3 products by total revenue before discount?
```sql
WITH cte AS (
SELECT p.product_name, 
       SUM(s.qty*s.price) AS rev
FROM balanced_tree.sales s
LEFT JOIN balanced_tree.product_details p ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY rev DESC
)
SELECT cte.product_name, cte.rev
FROM cte
LIMIT 3;
```
![image](https://github.com/hgv004/Project/assets/105195779/bc22a423-ad09-4312-a512-b9cd8ff44b32)

### 2. What is the total quantity, revenue and discount for each segment?
```sql
SELECT p.segment_name,
       SUM(s.qty) total_qty,
       SUM(s.price * s.qty) AS total_rev,
       ROUND(SUM(s.qty * s.price * s.discount/100),2) AS total_disc
FROM balanced_tree.sales s
LEFT JOIN balanced_tree.product_details p ON p.product_id = s.prod_id
GROUP BY p.segment_name;
```
![image](https://github.com/hgv004/Project/assets/105195779/f56f0009-1a47-470d-9f0b-d52d00d42cc4)

### 3. What is the top selling product for each segment?
```sql
WITH cte AS (
SELECT p.segment_name,
       p.product_name,
       SUM(s.qty) total_qty
FROM balanced_tree.sales s
LEFT JOIN balanced_tree.product_details p ON p.product_id = s.prod_id
GROUP BY p.segment_name, p.product_name
)
SELECT cte.segment_name,
       cte.product_name AS top_selling_product,
       cte.total_qty  
FROM cte
QUALIFY ROW_NUMBER() OVER(PARTITION BY cte.segment_name ORDER BY cte.total_qty DESC) = 1
ORDER BY cte.segment_name, cte.product_name;
```
![image](https://github.com/hgv004/Project/assets/105195779/93bf83f9-9b24-495d-bb55-e92469e96055)

### 4. What is the total quantity, revenue and discount for each category?
```sql
SELECT p.category_name,
       SUM(s.qty) total_qty,
       SUM(s.price * s.qty) AS total_rev,
       SUM(s.discount) AS total_disc
FROM balanced_tree.sales s
LEFT JOIN balanced_tree.product_details p ON p.product_id = s.prod_id
GROUP BY p.category_name;
```
![image](https://github.com/hgv004/Project/assets/105195779/bee42792-c474-4b15-83ca-f4e9b3780ebe)

### 5. What is the top selling product for each category?

```sql
with cte as(
select  p.category_name,
        p.product_name,
        sum(s.qty) total_qty
from balanced_tree.sales s
left join balanced_tree.product_details p
on p.product_id = s.prod_id
group by p.category_name, p.product_name)
select  cte.category_name,
        cte.product_name as top_selling_product,
        cte.total_qty
from cte
QUALIFY row_number() over(partition by cte.category_name order by cte.total_qty desc) = 1
order by cte.category_name,
        cte.product_name;
```
![image](https://github.com/hgv004/Project/assets/105195779/1c038f89-37f1-48b9-b9c6-2cc25c89f944)

### 6. What is the percentage split of revenue by product for each segment?
```sql
with cte as (
select  p.segment_name,
        p.product_name,
        sum(s.qty*s.price) total_rev
from balanced_tree.sales s
left join balanced_tree.product_details p
on p.product_id = s.prod_id
group by p.segment_name, p.product_name)
select  cte.segment_name, 
        cte.product_name,
        round(100*(cte.total_rev / sum(cte.total_rev) over(partition by cte.segment_name)),1) as pct
from cte
order by    cte.segment_name, 
            cte.product_name;
```
![image](https://github.com/hgv004/Project/assets/105195779/e95765cd-1bf3-4de6-a09f-995865225812)

### 7. What is the percentage split of revenue by segment for each category?
```sql
with cte as (
select  p.category_name,
        p.segment_name,
        sum(s.qty*s.price) total_rev
from balanced_tree.sales s
left join balanced_tree.product_details p
on p.product_id = s.prod_id
group by p.category_name, p.segment_name)
select  cte.category_name, 
        cte.segment_name,
        round(100*(cte.total_rev / sum(cte.total_rev) over(partition by cte.category_name)),1) as pct
from cte
order by    cte.category_name, 
            cte.segment_name;
```
![image](https://github.com/hgv004/Project/assets/105195779/48aab3ea-d19e-461a-ad98-649782264ac9)

### 8. What is the percentage split of total revenue by category?
```sql
with cte as (
select  p.category_name,
        sum(s.qty*s.price) total_rev
from balanced_tree.sales s
left join balanced_tree.product_details p
on p.product_id = s.prod_id
group by p.category_name)
select  cte.category_name,
        round(100*(cte.total_rev / sum(cte.total_rev) over()),1) as pct
from cte
order by cte.category_name;
```
![image](https://github.com/hgv004/Project/assets/105195779/c1caa06d-4ee6-4a3c-9b2e-3b0ceb0c432f)

### 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
```sql
SELECT  
    p.product_name,
    (COUNT(s.txn_id) OVER (PARTITION BY p.product_name) / COUNT(DISTINCT s.txn_id) OVER ()) AS pen
FROM 
    balanced_tree.sales s
LEFT JOIN 
    balanced_tree.product_details p ON p.product_id = s.prod_id
QUALIFY 
    ROW_NUMBER() OVER (PARTITION BY p.product_name ORDER BY s.txn_id) = 1;
```
![image](https://github.com/hgv004/Project/assets/105195779/c4f477b9-6b16-4d99-873c-8f43d10ca8d5)

### 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
```sql
SELECT s.prod_id, t1.prod_id, t2.prod_id, COUNT(*) AS combination_cnt       
FROM balanced_tree.sales s
JOIN balanced_tree.sales t1 ON t1.txn_id = s.txn_id 
AND s.prod_id < t1.prod_id
JOIN balanced_tree.sales t2 ON t2.txn_id = s.txn_id
AND t1.prod_id < t2.prod_id
GROUP BY 1, 2, 3
ORDER BY 4 DESC
LIMIT 1;
```
![image](https://github.com/hgv004/Project/assets/105195779/1dcdc130-265c-433b-8d0f-bdb3f5a0decf)

## Bunus Question
### Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
```sql
select
  p.product_id,
  p.price,
  concat(
    h1.level_text,
    ' ',
    h2.level_text,
    '-',
    h3.level_text
  ) as product_name,
  h2.parent_id as cat_id,
  h1.parent_id as seg_id,
  h1.id as style_id,
  h3.level_text as category,
  h2.level_text as segment,
  h1.level_text as style
from
  balanced_tree.product_prices p
  inner join balanced_tree.product_hierarchy h1 on h1.id = p.id
  inner join balanced_tree.product_hierarchy h2 on h2.id = h1.parent_id
  inner join balanced_tree.product_hierarchy h3 on h3.id = h2.parent_id;
```
![image](https://github.com/hgv004/Project/assets/105195779/e8abfaac-309f-4c0d-81f9-7e0ee1c6fe13)
