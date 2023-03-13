CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');



--SOLUTIONS

--What is the total amount each customer spent at the restaurant?
SELECT customer_id, 
sum(price) as s
FROM dannys_diner."sales"
JOIN dannys_diner."menu"
ON sales.product_id=menu.product_id
GROUP BY customer_id;
/*
"B"	74
"C"	36
"A"	76
*/

--How many days has each customer visited the restaurant?
SELECT customer_id, 
count(distinct order_date) as c
FROM dannys_diner."sales"
GROUP BY customer_id;
/*
"A"	4
"B"	6
"C"	2
*/

--What was the first item from the menu purchased by each customer?
With Rank as
(
Select customer_id, 
       product_name, 
       order_date,
       DENSE_RANK() OVER (PARTITION BY customer_id Order by order_date) as rank
From dannys_diner."menu" 
join dannys_diner."sales"
On menu.product_id = sales.product_id
group by customer_id, product_name, order_date
)
Select customer_id, product_name
From Rank
Where Rank =1
/*
"A"	"curry"
"A"	"sushi"
"B"	"curry"
"C"	"ramen"
*/

--What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT sales.product_id,
product_name,
COUNT(order_date) as c
FROM dannys_diner."sales"
JOIN dannys_diner."menu"
ON sales.product_id=menu.product_id
GROUP BY sales.product_id, product_name
ORDER BY c DESC;
/*
"ramen"	8
*/

--Which item was the most popular for each customer?
WITH RANK AS
(
SELECT product_name,
customer_id,
COUNT(order_date) as C,
DENSE_RANK() OVER (PARTITION BY customer_id order by COUNT(order_date) DESC) as rank
FROM dannys_diner."sales"
JOIN dannys_diner."menu"
ON sales.product_id=menu.product_id
GROUP BY product_name, customer_id
)
SELECT distinct customer_id, product_name
FROM RANK 
WHERE RANK =1
/*
"A"	"ramen"
"B"	"curry"
"B"	"ramen"
"B"	"sushi"
"C"	"ramen"
*/

--Which item was purchased first by the customer after they became a member?
WITH RANK AS
(
SELECT product_name, 
sales.customer_id,
join_date, 
order_date,
DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY order_date) as rank
FROM dannys_diner."sales"
JOIN dannys_diner."menu"
ON sales.product_id=menu.product_id
JOIN dannys_diner."members"
ON sales.customer_id=members.customer_id
WHERE order_date >= join_date
)
SELECT product_name, 
customer_id
FROM RANK 
WHERE rank=1
/*
"curry"	"A"
"sushi"	"B"
*/

--Which item was purchased just before the customer became a member?
WITH RANK AS
(
SELECT product_name, 
sales.customer_id,
join_date, 
order_date,
DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY order_date desc) as rank
FROM dannys_diner."sales"
JOIN dannys_diner."menu"
ON sales.product_id=menu.product_id
JOIN dannys_diner."members"
ON sales.customer_id=members.customer_id
WHERE order_date < join_date
)
SELECT product_name, 
customer_id, 
FROM RANK 
WHERE rank=1
/*
"sushi"	"A"
"curry"	"A"
"sushi"	"B"
*/

--What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id,
COUNT(product_name),
SUM(price)
FROM dannys_diner."sales"
JOIN dannys_diner."menu"
ON sales.product_id=menu.product_id
JOIN dannys_diner."members"
ON sales.customer_id=members.customer_id
WHERE order_date < join_date
GROUP BY sales.customer_id
/*
"B"	3	40
"A"	2	25
*/

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH POINTS AS
(
Select *, 
	Case When product_id = 1 THEN price*20 Else price*10
	End as Points
From dannys_diner."menu"
)
SELECT 
customer_id,
SUM(points) as points
FROM dannys_diner."sales"
JOIN POINTS
ON sales.product_id=points.product_id
GROUP BY customer_id
ORDER BY customer_id;
/*
"A"	860
"B"	940
"C"	360
*/

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
With Intervald as 
(
Select *, 
join_date + INTERVAL '6 days' as one_week_from_join
From dannys_diner."members"
)
SELECT customer_id, SUM(Points)
FROM
(SELECT *,
CASE When order_date BETWEEN  join_date AND one_week_from_join THEN price*20
When order_date < join_date AND menu.product_name = 'sushi' THEN price*20 Else price*10
End as Points
From Intervald
JOIN dannys_diner."sales" USING (customer_id)
JOIN dannys_diner."menu" USING (product_id)
WHERE order_date < '2021-01-31' AND join_date IS NOT NULL) Intervald
GROUP BY customer_id
/*
"A"	1370
"B"	820
*/
