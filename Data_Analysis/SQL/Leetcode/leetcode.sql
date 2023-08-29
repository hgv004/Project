select *
from trips t
join users u
on u.users_id  = t.client_id  ;

select t.request_at, round(sum(if(t.status = "completed", 0, 1)) / count(t.status),2) as pct
from trips t
inner join users u
on u.users_id  = t.client_id 
inner join users u1
on u1.users_id  = t.driver_id  
where u.banned = "No" and u1.banned = "No"
group by t.request_at
order by t.request_at;

select 	t.request_at as "Day", 
		round(sum(if(t.status like "%cancel%", 1, 0)) / count(t.status),2) "Cancellation Rate"
from trips t
inner join users u
on u.users_id  = t.client_id 
inner join users u1
on u1.users_id  = t.driver_id  
where u.banned = "No" and u1.banned = "No"
group by t.request_at
having count(t.status) > 1
order by t.request_at;

CREATE TABLE temp AS
SELECT * FROM trips;

CREATE TABLE temp_u AS
SELECT * FROM users u ;

insert into temp (id, client_id, driver_id, city_id, status, request_at) VALUES (1, 1, 10, 1, 'cancelled_by_client', '2013-10-04');


INSERT INTO temp_u (users_id, banned, role)
VALUES (1, 'No', 'client'),
       (10, 'No', 'driver');
       
      
select 	t.request_at as "Day", 
		round(sum(if(t.status like "%cancel%", 1, 0)) / count(t.status),2) "Cancellation Rate"
from temp t
inner join temp_u u
on u.users_id  = t.client_id 
inner join temp_u u1
on u1.users_id  = t.driver_id  
where u.banned = "No" and u1.banned = "No"
group by t.request_at
having round(sum(if(t.status like "%cancel%", 1, 0)) / count(t.status),2) <1
order by t.request_at;


Create table If Not Exists Employee1 (id int, name varchar(255), department varchar(255), managerId int);
Truncate table Employee;
insert into Employee1 (id, name, department, managerId) values ('101', 'John', 'A', null);
insert into Employee1 (id, name, department, managerId) values ('102', 'Dan', 'A', '101');
insert into Employee1 (id, name, department, managerId) values ('103', 'James', 'A', '101');
insert into Employee1 (id, name, department, managerId) values ('104', 'Amy', 'A', '101');
insert into Employee1 (id, name, department, managerId) values ('105', 'Anne', 'A', '101');
insert into Employee1 (id, name, department, managerId) values ('106', 'Ron', 'B', '101');

select * from Employee1;

select * 
from Employee1 e1
left join Employee1 e2
on e1.id = e2.managerId;

select e2.name from
	(select managerId , count(id)
	from Employee1 e1
	group by managerId 
	having count(id) > 4) as t 
left join Employee1 e2
on t.managerId = e2.id ;

Create Table If Not Exists Insurance (pid int, tiv_2015 float, tiv_2016 float, lat float, lon float);
Truncate table Insurance;
insert into Insurance (pid, tiv_2015, tiv_2016, lat, lon) values ('1', '10', '5', '10', '10');
insert into Insurance (pid, tiv_2015, tiv_2016, lat, lon) values ('2', '20', '20', '20', '20');
insert into Insurance (pid, tiv_2015, tiv_2016, lat, lon) values ('3', '10', '30', '20', '20');
insert into Insurance (pid, tiv_2015, tiv_2016, lat, lon) values ('4', '10', '40', '40', '40');

select * from insurance i;

with cte1 as (
	select 	*,
			lead(tiv_2015) over(partition by tiv_2015 order by tiv_2015) t
	from insurance i
	order by tiv_2015
	)
select * 
from cte1;


with m1 as (
	select 	tiv_2015 as m15,
			count(pid) as ct
	from insurance i
	group by tiv_2015
	having ct > 1),
	m2 as (
	select 	lat, lon, 
			count(pid) as ct1
	from insurance i
	group by lat, lon
	having ct1 = 1)
select * 
from insurance i1
left join m1
on i1.tiv_2015 = m1.m15;


Create table If Not Exists Products (product_id int, new_price int, change_date date);
Truncate table Products;
insert into Products (product_id, new_price, change_date) values ('1', '20', '2019-08-14');
insert into Products (product_id, new_price, change_date) values ('2', '50', '2019-08-14');
insert into Products (product_id, new_price, change_date) values ('1', '30', '2019-08-15');
insert into Products (product_id, new_price, change_date) values ('1', '35', '2019-08-16');
insert into Products (product_id, new_price, change_date) values ('2', '65', '2019-08-17');
insert into Products (product_id, new_price, change_date) values ('3', '20', '2019-08-18');


select 	p.product_id , 
		p.change_date as from_date, 
		ifnull( date_add(lead(change_date) over(partition by product_id order by change_date),interval -1 day),v.md) as to_date,
		if('2019-08-16' between p.change_date and ifnull( date_add(lead(change_date) over(partition by product_id order by change_date),interval -1 day),v.md),1,0) as t,
		if(change_date > '2019-08-16', 10, new_price),
		new_price
from 	products p 
left join (
	select product_id , max(change_date) md
	from products p 
	group by product_id) as v
on v.product_id = p.product_id
order by p.product_id , change_date ;

select product_id , change_date , new_price , if(change_date <= '2019-08-16', 1, 10)as _check
from products p 
order by 1, 2, 3;

# Write your MySQL query statement below
WITH cte AS
(SELECT *, RANK() OVER (PARTITION BY product_id ORDER BY change_date DESC) AS r 
FROM Products
WHERE change_date<= '2019-08-16')
SELECT product_id, new_price AS price
FROM cte
WHERE r = 1
UNION
SELECT product_id, 10 AS price
FROM Products
WHERE product_id NOT IN (SELECT product_id FROM cte);

select product_id , change_date , new_price 
from products p 
order by 1, 2, 3;

Create table If Not Exists Transactions (id int, country varchar(4), state enum('approved', 'declined'), amount int, trans_date date);
Truncate table Transactions;
insert into Transactions (id, country, state, amount, trans_date) values ('121', 'US', 'approved', '1000', '2018-12-18');
insert into Transactions (id, country, state, amount, trans_date) values ('122', 'US', 'declined', '2000', '2018-12-19');
insert into Transactions (id, country, state, amount, trans_date) values ('123', 'US', 'approved', '2000', '2019-01-01');
insert into Transactions (id, country, state, amount, trans_date) values ('124', 'DE', 'approved', '2000', '2019-01-07');

select * from transactions ;

select 	left(trans_date, 7) as "month", 
		country ,
		count(id) as trans_count,
		sum(if(state = "approved",1, 0)) as approved_counts,
		sum(amount) as trans_total_amount ,
		sum(if(state = "approved",amount , 0)) as approved_total_amount
from transactions 
group by left(trans_date, 7), country ;

Create table If Not Exists Employee (id int, salary int);
Truncate table Employee;
insert into Employee (id, salary) values ('1', '100');
insert into Employee (id, salary) values ('2', '200');
insert into Employee (id, salary) values ('3', '300');

select * from employee e ;

with cte as (
	select t.salary, rank() over(partition  by t.a order by t.salary) as r
	from (
		select *, "All" as a
		from employee e) as t)
select * 
from cte;

select max(salary) as SecondHighestSalary 
from employee e 
where salary < (select max(salary)
				from employee e);
			
Create table If Not Exists Logs (id int, num int);
Truncate table Logs;
insert into Logs (id, num) values ('1', '1');
insert into Logs (id, num) values ('2', '1');
insert into Logs (id, num) values ('3', '1');
insert into Logs (id, num) values ('4', '2');
insert into Logs (id, num) values ('5', '1');
insert into Logs (id, num) values ('6', '2');
insert into Logs (id, num) values ('7', '2');
insert into Logs (id, num) values ('8', '3');
insert into Logs (id, num) values ('9', '3');
insert into Logs (id, num) values ('10', '3');
insert into Logs (id, num) values ('11', '3');


select distinct v.num as ConsecutiveNums from (
	select 	num ,
			if(avg(num) over(order by id rows between 2 preceding and 0 following) 
			= floor(avg(num) over(order by id rows between 2 preceding and 0 following)),1,0) as checkp,
			row_number () over(order by id) as r
	from logs l) as v
where v.checkp = 1;

select 	*, 
		lag(num) over(order by id) as pv ,
		if(num = lag(num) over(order by id), 1, 0)
from logs;

SELECT distinct num as ConsecutiveNums 
FROM (
    SELECT 
        num,
        LAG(num, 1) OVER (ORDER BY id) AS prev_number,
        LEAD(num, 1) OVER (ORDER BY id) AS next_number
    FROM logs
) AS subquery
WHERE num = prev_number AND num = next_number;


Create table If Not Exists Queue (person_id int, person_name varchar(30), weight int, turn int);
Truncate table Queue;
insert into Queue (person_id, person_name, weight, turn) values ('5', 'Alice', '250', '1');
insert into Queue (person_id, person_name, weight, turn) values ('4', 'Bob', '175', '5');
insert into Queue (person_id, person_name, weight, turn) values ('3', 'Alex', '350', '2');
insert into Queue (person_id, person_name, weight, turn) values ('6', 'John Cena', '400', '3');
insert into Queue (person_id, person_name, weight, turn) values ('1', 'Winston', '500', '6');
insert into Queue (person_id, person_name, weight, turn) values ('2', 'Marie', '200', '4');

with cte as (
	select 	person_name  , sum(weight) over(order by turn rows unbounded preceding) as weight_fillup
	from Queue
	order by turn),
	v1 as (
	select cte.*, row_number() over(order by cte.weight_fillup desc) as v
	from cte
	where weight_fillup <= 1000)
select person_name 
from v1
where v1.v = 1;

# Write your MySQL query statement below
SELECT 
    q1.person_name
FROM Queue q1 
JOIN Queue q2 
ON q1.turn >= q2.turn
GROUP BY q1.turn
HAVING SUM(q2.weight) <= 1000
ORDER BY SUM(q2.weight) DESC
LIMIT 1;

select * from Queue
order by turn;


CREATE TABLE IF NOT EXISTS Employee2 (
    id INT,
    name VARCHAR(255),
    salary INT,
    departmentId INT
);

CREATE TABLE IF NOT EXISTS Department (
    id INT,
    name VARCHAR(255)
);

TRUNCATE TABLE Employee2;

INSERT INTO Employee2 (id, name, salary, departmentId) VALUES (1, 'Joe', 70000, 1);
INSERT INTO Employee2 (id, name, salary, departmentId) VALUES (2, 'Jim', 90000, 1);
INSERT INTO Employee2 (id, name, salary, departmentId) VALUES (3, 'Henry', 80000, 2);
INSERT INTO Employee2 (id, name, salary, departmentId) VALUES (4, 'Sam', 60000, 2);
INSERT INTO Employee2 (id, name, salary, departmentId) VALUES (5, 'Max', 90000, 1);

TRUNCATE TABLE Department;

INSERT INTO Department (id, name) VALUES (1, 'IT');
INSERT INTO Department (id, name) VALUES (2, 'Sales');

select v.d_name as Department , v.ename as Employee , v.salary as salary
from (
	select 	d.name as d_name,
			e.name  as ename, 
			e.salary,
			rank() over(partition by d.name order by e.salary desc) as r
	from Employee2 e 
	left join department d 
	on e.departmentId = d.id) as v
where v.r =1;


Create table If Not Exists Stadium (id int, visit_date DATE NULL, people int);

Truncate table Stadium;

insert into Stadium (id, visit_date, people) values ('1', '2017-01-01', '10');
insert into Stadium (id, visit_date, people) values ('2', '2017-01-02', '109');
insert into Stadium (id, visit_date, people) values ('3', '2017-01-03', '150');
insert into Stadium (id, visit_date, people) values ('4', '2017-01-04', '99');
insert into Stadium (id, visit_date, people) values ('5', '2017-01-05', '145');
insert into Stadium (id, visit_date, people) values ('6', '2017-01-06', '1455');
insert into Stadium (id, visit_date, people) values ('7', '2017-01-07', '199');
insert into Stadium (id, visit_date, people) values ('8', '2017-01-09', '188');

select * 
from Stadium;

select 	*,
		id + 1,
		lead(id) over(order by id) as ld,
		id - 1,
		lag(id) over(order by id) as lg,
		if(lead(id) over(order by id) = id + 1 and lag(id) over(order by id) = id - 1, 1, 0) cnd,
		if(ifnull(lead(id) over(order by id), max(id) over()+1) = id + 1, 1, 0) cnd1		
from Stadium 
where people>=100;

with cte as (
	select 	*,
			if(ifnull(lead(id) over(order by id), max(id) over()+1) = id + 1, 1, 0) cnd1
	from Stadium 
	where people>=100),
cte2 as (
	select *, avg(cte.cnd1) over(order by cte.id rows between current row and 2 following) as is_cons
	from cte)
select cte2.id, cte2.visit_date, cte2.people
from cte2
where cte2.is_cons = 1;


with cte as (
	select 	*,
			if(ifnull(lead(id) over(order by id), max(id) over()+1) = id + 1, 1, 0) cnd1
	from Stadium 
	where people>=100)
select *, avg(cte.cnd1) over(order by cte.id rows between current row and 2 following) as is_cons
from cte;


with filtered_data as (
select id, 
       visit_date, 
       people, 
       LAG(id,1) OVER(order by id) as prevID_1, 
       LAG(id,2) OVER(order by id) as prevID_2,
       LEAD(id,1) OVER(order by id) as nextID_1, 
       LEAD(id,2) OVER(order by id) as nextID_2
from Stadium 
where people>=100
), ordered_filtered_data as (
select *, 
       CASE WHEN id+1=nextID_1 AND id+2 = nextID_2 then 'Y' 
            WHEN id-1=prevID_1 AND id-2 = prevID_2 then 'Y' 
            WHEN id-1 = prevID_1 and id+1=nextID_1 then 'Y'
            ELSE 'N' END as flag
from filtered_data
)
select id, visit_date, people from ordered_filtered_data where flag = 'Y';

-- Write a solution to find the people who have the most friends and the most friends number.
-- The test cases are generated so that only one person has the most friends.

Create table If Not Exists RequestAccepted (requester_id int not null, accepter_id int null, accept_date date null); 
Truncate table RequestAccepted;
insert into RequestAccepted (requester_id, accepter_id, accept_date) values ('1', '2', '2016/06/03');
insert into RequestAccepted (requester_id, accepter_id, accept_date) values ('1', '3', '2016/06/08');
insert into RequestAccepted (requester_id, accepter_id, accept_date) values ('2', '3', '2016/06/08');
insert into RequestAccepted (requester_id, accepter_id, accept_date) values ('3', '4', '2016/06/09');

select * from RequestAccepted;

with cte as (
	select requester_id  
	from RequestAccepted
	union all
	select accepter_id  
	from RequestAccepted)
select requester_id as id, count(requester_id) as num
from cte
group by requester_id
order by num desc 
limit 1;


-- https://leetcode.com/problems/tree-node/

Create table If Not Exists Tree (id int, p_id int);
Truncate table Tree;
insert into Tree (id, p_id) values ('1', null);
insert into Tree (id, p_id) values ('2', '1');
insert into Tree (id, p_id) values ('3', '1');
insert into Tree (id, p_id) values ('4', '2');
insert into Tree (id, p_id) values ('5', '2');

select 	id, 
		CASE WHEN p_id is null then 'Root' 
			WHEN id in (select p_id from Tree where p_id is not null) then 'Inner'
        	ELSE 'Leaf' END as type 
from Tree;




