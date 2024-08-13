CREATE DATABASE Pizza;

USE Pizza;

SELECT * FROM pizzas;

SELECT * FROM pizza_types;

SELECT * FROM orders;

SELECT * FROM order_details;


-- Solution

--Retrieve the total number of orders placed.

SELECT COUNT(order_id) total_orders FROM orders;


--Calculate the total revenue generated from pizza sales.

SELECT 
	ROUND(SUM(quantity*price),2) total_sales
FROM order_details od
INNER JOIN pizzas p
ON p.pizza_id=od.pizza_id;

-- Identify the highest-priced pizza.

SELECT TOP 1 pt.name,p.price
FROM pizzas p
INNER JOIN pizza_types pt
ON p.pizza_type_id=pt.pizza_type_id
ORDER BY price desc;

--Identify the most common pizza size ordered.

SELECT 
	TOP 1 size, 
	COUNT(order_details_id) Highest_ordered
FROM pizzas p
JOIN order_details od
	ON p.pizza_id=od.pizza_id
GROUP BY size
ORDER BY size;

-- List the top 5 most ordered pizza types along with their quantities.


SELECT TOP 5 pt.name,SUM(od.quantity) quantities
FROM order_details od
INNER JOIN pizzas p
ON p.pizza_id=od.pizza_id
INNER JOIN pizza_types pt
ON pt.pizza_type_id=p.pizza_type_id
GROUP BY pt.name
ORDER BY quantities DESC;

-- Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT pt.category category, SUM(od.quantity) quantities
FROM pizza_types pt
INNER JOIN pizzas p
ON pt.pizza_type_id=p.pizza_type_id
INNER JOIN order_details od
ON od.pizza_id=p.pizza_id
GROUP BY pt.category
ORDER BY quantities desc;

-- Determine the distribution of orders by hour of the day.

SELECT * FROM orders;

SELECT DATEPART(hour,order_time) as hour, count(order_id) as order_count
FROM orders
GROUP BY DATEPART(hour,order_time)
ORDER BY DATEPART(hour,order_time);

-- Join relevant tables to find the category-wise distribution of pizzas.

SELECT category, COUNT(name) pizzas
FROM pizza_types
GROUP BY category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT AVG(quantity)  as 'Avg pizza ordered per Day'
FROM
(
SELECT order_date, SUM(quantity) as quantity
FROM orders o
INNER JOIN order_details od
ON o.order_id=od.order_id
GROUP BY order_date) as order_quantity

-- Determine the top 3 most ordered pizza types based on revenue.

SELECT * FROM order_details;
SELECT * FROM pizza_types;

SELECT TOP 3 name, SUM(quantity*price) as revenue
FROM order_details od
INNER JOIN pizzas p
ON od.pizza_id=p.pizza_id
INNER JOIN pizza_types pt
ON pt.pizza_type_id=p.pizza_type_id
GROUP BY name,price
ORDER BY revenue DESC;

-- Calculate the percentage contribution of each pizza type to total revenue.

WITH cte_pizza_contro as
(SELECT category, 
	SUM(quantity*price) as revenue
FROM pizza_types pt
Inner Join pizzas p
ON p.pizza_type_id=pt.pizza_type_id
Inner JOIN order_details od
ON od.pizza_id=p.pizza_id
GROUP BY category
--ORDER BY revenue desc
)
SELECT category,
	PERCENT_RANK() OVER(
	ORDER BY revenue DESC) percent_contribution
FROM cte_pizza_contro;

--                               SECOND Solution

SELECT category, 
	ROUND(SUM(quantity*price) / 
	(SELECT ROUND(SUM(quantity*price),2) total_sales FROM order_details od JOIN pizzas p ON p.pizza_id=od.pizza_id) * 100,2) as revenue
FROM pizza_types pt
Inner Join pizzas p
ON p.pizza_type_id=pt.pizza_type_id
Inner JOIN order_details od
ON od.pizza_id=p.pizza_id
GROUP BY category
ORDER BY revenue DESC;

--Analyze the cumulative revenue generated over time.

WITH cte_pizza_revenue as
(SELECT order_date, SUM(quantity*price) as revenue
FROM orders o
INNER JOIN order_details od
ON od.order_id=o.order_id
INNER JOIN pizzas p
ON p.pizza_id=od.pizza_id
GROUP BY order_date)
SELECT MONTH(order_date) order_month,
		ROUND(CUME_DIST() OVER(
		ORDER BY MONTH(order_date)),2) as cum_revenue
FROM cte_pizza_revenue
GROUP BY MONTH(order_date);

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

WITh cte_pizza_sales as

(SELECT category,name,revenue,
	RANK() OVER(
	PARTITION BY category
	ORDER BY revenue desc) rn
FROM
	(
	SELECT category, name, SUM(quantity*price) revenue
	FROM pizza_types pt
	JOIN pizzas p 
	ON pt.pizza_type_id=p.pizza_type_id
	JOIN order_details od
	ON od.pizza_id=p.pizza_id
	GROUP BY category,name
	) as sales
	)
SELECT category, name, rn
FROM cte_pizza_sales
WHERE rn <= 3;