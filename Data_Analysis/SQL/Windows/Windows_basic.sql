
create database window_basic;
use window_basic;

drop table employee;
create table employee
( emp_ID int
, emp_NAME varchar(50)
, DEPT_NAME varchar(50)
, SALARY int);

INSERT INTO employee 
VALUES 
  (101, 'Mohan', 'Admin', 4000),
  (102, 'Rajkumar', 'HR', 3000),
  (103, 'Akbar', 'IT', 4000),
  (104, 'Dorvin', 'Finance', 6500),
  (105, 'Rohit', 'HR', 3000),
  (106, 'Rajesh', 'Finance', 5000),
  (107, 'Preet', 'HR', 7000),
  (108, 'Maryam', 'Admin', 4000),
  (109, 'Sanjay', 'IT', 6500),
  (110, 'Vasudha', 'IT', 7000),
  (111, 'Melinda', 'IT', 8000),
  (112, 'Komal', 'IT', 10000),
  (113, 'Gautham', 'Admin', 2000),
  (114, 'Manisha', 'HR', 3000),
  (115, 'Chandni', 'IT', 4500),
  (116, 'Satya', 'Finance', 6500),
  (117, 'Adarsh', 'HR', 3500),
  (118, 'Tejaswi', 'Finance', 5500),
  (119, 'Cory', 'HR', 8000),
  (120, 'Monica', 'Admin', 5000),
  (121, 'Rosalin', 'IT', 6000),
  (122, 'Ibrahim', 'IT', 8000),
  (123, 'Vikram', 'IT', 8000),
  (124, 'Dheeraj', 'IT', 11000);

/* **************
   Video Summary
 ************** */

SELECT * FROM employee;

SELECT count(*) FROM employee;

select emp_NAME, count(emp_ID)
from employee 
group by emp_NAME;

-- Using Aggregate function as Window Function
-- Without window function, SQL will reduce the no of records.
SELECT dept_name, MAX(salary) FROM employee
GROUP BY dept_name;

-- By using MAX as a window function, SQL will not reduce records, but the result will be shown corresponding to each record.
SELECT e.*,
MAX(salary) OVER() AS max_salary
FROM employee e;

SELECT e.*,
MAX(salary) OVER(PARTITION BY dept_name) AS max_salary
FROM employee e;

-- row_number(), rank(), and dense_rank()
SELECT e.*,
ROW_NUMBER() OVER(PARTITION BY dept_name) AS rn
FROM employee e;

-- Fetch the first 2 employees from each department to join the company.
SELECT * FROM (
	SELECT e.*,
	ROW_NUMBER() OVER(PARTITION BY dept_name ORDER BY emp_id) AS rn
	FROM employee e) x
WHERE x.rn < 3;

-- Fetch the top 3 employees in each department earning the max salary.
SELECT * FROM (
	SELECT e.*,
	RANK() OVER(PARTITION BY dept_name ORDER BY salary DESC) AS rnk
	FROM employee e) x
WHERE x.rnk < 4;

-- Checking the different between rank, dense_rnk and row_number window functions:
select e.*,
rank() over(partition by dept_name order by salary desc) as rnk,
dense_rank() over(partition by dept_name order by salary desc) as dense_rnk,
row_number() over(partition by dept_name order by salary desc) as rn
from employee e;



-- lead and lag

-- fetch a query to display if the salary of an employee is higher, lower or equal to the previous employee.
select e.*,
lag(salary) over(partition by dept_name order by emp_id) as prev_empl_sal,
case when e.salary > lag(salary) over(partition by dept_name order by emp_id) then 'Higher than previous employee'
     when e.salary < lag(salary) over(partition by dept_name order by emp_id) then 'Lower than previous employee'
	 when e.salary = lag(salary) over(partition by dept_name order by emp_id) then 'Same than previous employee' end as sal_range
from employee e;

-- Similarly using lead function to see how it is different from lag.
select e.*,
lag(salary) over(partition by dept_name order by emp_id) as prev_empl_sal,
lead(salary) over(partition by dept_name order by emp_id) as next_empl_sal
from employee e;
