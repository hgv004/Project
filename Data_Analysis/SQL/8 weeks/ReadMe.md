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
### 2. What is the total generated revenue for all products before discounts?
```sql
SELECT p.product_name, SUM(s.qty * s.price) AS total_rev
FROM balanced_tree.sales s
LEFT JOIN balanced_tree.product_details p ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY total_rev DESC;
```
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
## Transaction Analysis

### 1. How many unique transactions were there?
```sql
SELECT COUNT(DISTINCT s.txn_id) AS unq_transaction
FROM balanced_tree.sales s;
```s
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
### 6. What is the average revenue for member transactions and non-member transactions?
```sql
SELECT IFF(member = true, 'member', 'non-member') AS is_member,
       ROUND(AVG(qty * price), 1) AS avg_price
FROM balanced_tree.sales
GROUP BY is_member;
```
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
### 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
```sql
WITH TransactionProductCount AS (
    SELECT txn_id
    FROM balanced_tree.sales
    GROUP BY txn_id
    HAVING count(distinct prod_id) >= 3
),
TransactionProductCombinations AS (
    SELECT txn_id, LISTAGG(prod_id, ',') WITHIN GROUP(ORDER BY prod_id) AS product_combination
    FROM balanced_tree.sales
    WHERE txn_id IN (SELECT txn_id FROM TransactionProductCount)
    GROUP BY txn_id
)
SELECT product_combination, COUNT(*) AS occurrence_count
FROM TransactionProductCombinations
GROUP BY product_combination
ORDER BY occurrence_count DESC
LIMIT 1;
Bonus Question
sql
Copy code
select  p.product_id,
        p.price,
        concat(h1.level_text, ' ', h2.level_text, '-', h3.level_text) as product_name,
        h2.parent_id as cat_id,
        h1.parent_id as seg_id,
        h1.id as style_id,
        h3.level_text as category,
        h2.level_text as segment,
        h1.level_text as style
from balanced_tree.product_prices p
inner join balanced_tree.product_hierarchy h1
on h1.id = p.id
inner join balanced_tree.product_hierarchy h2
on h2.id = h1.parent_id
inner join balanced_tree.product_hierarchy h3
on h3.id = h2.parent_id ;
```
