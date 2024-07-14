CREATE SCHEMA diner;
Use diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

SELECT
  	product_id,
    product_name,
    price
FROM diner.menu
ORDER BY price DESC
LIMIT 5;
Select* from diner.members;
-- 1. What is the total amount each customer spent at the restaurant?  
Select s.customer_id,Sum(m.price)as Sum_total_spend
From sales s
join menu m
on s.product_id=m.product_id
group by s.customer_id
order by s.customer_id;
-- 2. How many days has each customer visited the restaurant?

Select customer_id,Count(Distinct(order_date)) as "days_visited" from sales
group by customer_id;
-- 3. What was the first item from the menu purchased by each customer?
with CTE_2 as (Select row_number() over (partition by s.customer_id order by s.customer_id) as "index_number",s.customer_id,m.product_name,s.order_date
from sales s
inner join menu m
on s.product_id=m.product_id)
Select * from CTE_2
where index_number=1;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
With CTE_3 as (Select m.product_name,count(product_name) over(partition by product_name) as "Product_count"
from sales s
inner join menu m
on s.product_id=m.product_id)
Select * from CTE_3
order by product_count desc limit 1;
-- 5. Which item was the most popular for each customer?
With CTE_4 as (Select s.customer_id,m.product_name,dense_rank() over (partition by s.customer_id order by count(product_name) desc) as "DenseRank"
from sales s 
inner join menu m
on s.product_id=m.product_id
group by s.customer_id,m.product_name)
Select * from CTE_4;
-- 6. Which item was purchased first by the customer after they became a member?
With CTE_5 as (Select s.customer_id,m.product_name,s.order_date,mm.join_date
from sales s
inner join menu m
on s.product_id=m.product_id
join members mm
on s.customer_id=mm.customer_id)
Select * from CTE_5
where order_Date>join_Date order by order_date asc;
-- 7. Which item was purchased just before the customer became a member?
With CTE_6 as (Select s.customer_id,m.product_name,s.order_date,mm.join_date
from sales s
inner join menu m
on s.product_id=m.product_id
join members mm
on s.customer_id=mm.customer_id)
Select * from CTE_6
where order_Date<join_Date order by order_date desc;
-- 8. What is the total items and amount spent for each member before they became a member?
With CTE_7 as (Select s.customer_id,m.product_name,m.price,s.order_date,mm.join_date
from sales s
inner join menu m
on s.product_id=m.product_id
join members mm
on s.customer_id=mm.customer_id
where order_Date<join_Date)
Select *,count(product_name) over (partition by s.customer_id) as "Product_count",sum(price) over (partition by s.customer_id) as "Total_amount" from CTE_7;
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
alter table menu
add column points int;
set sql_safe_updates=0;
Update  menu
set points= IF(Product_name="sushi",price*20,price*10);
Select s.customer_id,sum(points) over(partition by customer_id) as "Total_Points"
from sales s
inner join menu m
on s.product_id=m.product_id;
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH CTE_9 AS (
    SELECT 
        s.customer_id,
        s.order_date,mm.join_date,m.product_name,
        CASE 
            WHEN s.order_date BETWEEN mm.join_date AND DATE_ADD(mm.join_date, INTERVAL 6 DAY) 
            THEN m.points * 2
            ELSE m.points
        END AS points
    FROM 
        sales s
    JOIN 
        menu m ON s.product_id = m.product_id
	join
		members mm on s.customer_id=mm.customer_id)

SELECT
    customer_id,
    SUM(points) AS total_points from CTE_9 
    GROUP BY
    customer_id;


	











