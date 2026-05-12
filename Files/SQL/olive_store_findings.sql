-- Total number of customers
SELECT COUNT(DISTINCT customer_unique_id) AS "Total number of customers"
FROM customers_table;	--o/p 96096

-- Total number of orders 
SELECT COUNT(order_id) AS "Total number of orders"
FROM orders_table;		-- o/p 99441

--Total revenue (sales) 
SELECT ROUND(SUM(total_amount_cost),2) AS "Total Revenue"
FROM items_table;	--O/P 15843553.24

--Total number of products sold 
SELECT COUNT(product_id) AS "total number of products sold"
from items_table; --o/p 112650

--Total number of sellers 
SELECT COUNT(seller_id) AS "total number of sellers"
FROM sellers_table; --o/p 3095

--Average order value (AOV) 
SELECT ROUND(AVG(total_amount_cost),4) AS AOV
FROM items_table; --o/p 140.6441

--Total canceled orders 
SELECT COUNT(order_status) AS "total canceled orders"
FROM orders_table
WHERE order_status='canceled'; --o/p 625

--•	Cancellation rate (%) 
SELECT FORMAT(ROUND((COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) * 1.0 -- 1.0 is used to convert in float, if we dont convert in float, we will get as 0
		/ COUNT(*)) * 100.0,4),'N4') AS "Cancelation rate in Percentage"
FROM orders_table; -- o/p 0.6285

--•	Delivery success rate (%) 
SELECT FORMAT(ROUND((COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) * 100.0)
		/ COUNT(*),4),'N4') AS "Delivery Success Rate"
FROM orders_table; --o/p 97.0203

--•	Total sales per year (this includes all orders including canceled orders, undelivered)
SELECT YEAR(orders_table.order_purchase_timestamp) AS "YEAR",SUM(items_table.total_amount_cost) AS "total sales per year"
FROM orders_table INNER JOIN items_table
ON orders_table.order_id = items_table.order_id
GROUP BY YEAR(order_purchase_timestamp) 
ORDER BY YEAR(order_purchase_timestamp) ASC;

--•	Total sales per month
SELECT YEAR(order_purchase_timestamp) AS "YEAR",MONTH(order_purchase_timestamp) AS "MONTH",
		SUM(items_table.total_amount_cost) AS "total sales per year"
FROM orders_table INNER JOIN items_table
ON orders_table.order_id = items_table.order_id
GROUP BY YEAR(order_purchase_timestamp),MONTH(order_purchase_timestamp) 
ORDER BY YEAR(order_purchase_timestamp),MONTH(order_purchase_timestamp) ASC;

--Why there is no sale in 2016 of 11 month
SELECT COUNT(*) AS total_orders
FROM orders_table
WHERE YEAR(order_purchase_timestamp) = 2016
  AND MONTH(order_purchase_timestamp) = 11; --since there is no sales for 2016 and month 11

--•	Monthly growth rate 
WITH monthly_sales AS (
					SELECT FORMAT(orders_table.order_purchase_timestamp,'yyyy-mm') AS Year_Month,
					SUM(items_table.total_amount_cost) AS total_sales
					FROM orders_table INNER JOIN items_table
					ON orders_table.order_id = items_table.order_id
					WHERE orders_table.order_status = 'delivered'
					GROUP BY FORMAT(orders_table.order_purchase_timestamp,'yyyy-mm')
					)

SELECT Year_Month,total_sales,
	LAG(total_sales) OVER(ORDER BY Year_Month) AS Prev_month_sales,
	ROUND(
		(total_sales - LAG(total_sales) OVER(ORDER BY Year_Month)) * 100.0
	/
	LAG(total_sales) OVER(ORDER BY Year_Month),2) AS growth_rate_percentage
FROM monthly_sales; --LAG() is a window function that lets you access the previous row’s value without doing joins.

--•	Which month has highest sales? 
WITH monthly_sales AS (
					SELECT FORMAT(o.order_purchase_timestamp,'yyyy-MM') year_month, -- in format if we use 'mm' then it consideres as minutes not month so we have to write MM
					SUM(i.total_amount_cost) AS total_sales
					FROM orders_table AS o JOIN
						items_table AS i
					ON o.order_id = i.order_id
					WHERE order_status = 'delivered'
					GROUP BY FORMAT(o.order_purchase_timestamp,'yyyy-MM')
)
SELECT *,
		RANK() OVER(ORDER BY total_sales DESC) AS rank
FROM monthly_sales;

--•	Which year has highest growth? 
WITH yearly_sales AS (
							SELECT YEAR(o.order_purchase_timestamp) AS year,
							SUM(i.total_amount_cost) AS total_sales
							FROM orders_table o 
							JOIN items_table i
							ON o.order_id = i.order_id
							WHERE o.order_status ='delivered'
							GROUP BY YEAR(o.order_purchase_timestamp)
), growth_table AS (
					SELECT year,total_sales,
					LAG(total_sales) OVER(ORDER BY total_sales) AS previous_year_Sale,
					(total_sales - LAG(total_sales) OVER(ORDER BY year)) * 100.0
					/ LAG(total_sales) OVER(ORDER BY year) AS growth_rate
				FROM yearly_sales
				)
SELECT *
FROM growth_table
ORDER BY growth_rate;

--•	Day-wise sales trend (weekend vs weekday) 
SELECT 
    CASE 
        WHEN DATENAME(WEEKDAY, o.order_purchase_timestamp) IN ('Saturday', 'Sunday') 
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    
    SUM(i.total_amount_cost) AS total_sales,
    COUNT(o.order_id) AS total_orders

FROM orders_table o
JOIN items_table i 
    ON o.order_id = i.order_id

WHERE o.order_status = 'delivered'

GROUP BY 
    CASE 
        WHEN DATENAME(WEEKDAY, o.order_purchase_timestamp) IN ('Saturday', 'Sunday') 
            THEN 'Weekend'
        ELSE 'Weekday'
    END;

	--•	Top 10 most purchased product categories 
	SELECT TOP 10 p.product_category_name,COUNT(*) AS "total_items_sold"
	FROM items_table i JOIN
		products_table p
	ON i.product_id = p.product_id
	GROUP BY p.product_category_name
	ORDER BY COUNT(*) DESC;

	--•	Top 10 highest revenue categories 
	SELECT TOP 10 p.product_category_name, SUM(i.total_amount_cost)
	FROM items_table i JOIN
		products_table p
	ON i.product_id = p.product_id
	GROUP BY p.product_category_name
	ORDER BY SUM(i.total_amount_cost) DESC;

	--•	Least selling products 
	SELECT TOP 10 p.product_category_name,COUNT(*) AS "total_items_sold"
	FROM items_table i JOIN
		products_table p
	ON i.product_id = p.product_id
	GROUP BY p.product_category_name
	ORDER BY COUNT(*);

	--•	Products with high orders but low revenue 
	WITH product_stats AS (
    SELECT 
        p.product_category_name,
        COUNT(*) AS total_orders,
        SUM(i.price) AS total_revenue
    FROM items_table i
	JOIN products_table p 
	ON i.product_id = p.product_id
    GROUP BY p.product_category_name
)

SELECT *,
       RANK() OVER (ORDER BY total_orders DESC) AS order_rank,
       RANK() OVER (ORDER BY total_revenue ASC) AS revenue_rank
FROM product_stats;

--•	Products with high cancellations 
SELECT 
    p.product_category_name_english,
    COUNT(*) AS total_cancellations
FROM products_table p 
JOIN items_table i
    ON p.product_id = i.product_id
JOIN orders_table o
    ON o.order_id = i.order_id
WHERE o.order_status = 'canceled'
GROUP BY p.product_category_name_english
ORDER BY total_cancellations DESC;

--•	Category-wise sales distribution 
SELECT p.product_category_name_english, SUM(i.total_amount_cost) AS gross_sales,
	SUM(CASE WHEN o.order_status = 'delivered' THEN i.total_amount_cost END) AS net_sale
FROM items_table i JOIN products_table p
ON i.product_id = p.product_id
JOIN orders_table o
ON o.order_id = i.order_id
GROUP BY p.product_category_name_english
ORDER BY SUM(i.total_amount_cost) DESC;

--•	Total unique customers 
SELECT 
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    COUNT(customer_id) AS total_records
FROM customers_table;

--•	Repeat vs new customers 
WITH customer_orders AS (
						SELECT customer_unique_id, COUNT(*) AS total_orders
						FROM customers_table
						GROUP BY customer_unique_id
)
SELECT CASE WHEN total_orders = 1 THEN 'unique_customer' ELSE 'repeated_customer' END AS custpmer_type, COUNT(*) AS total_customers,
ROUND(COUNT(*)*100.0 / SUM(COUNT(*)) OVER() ,2) AS percentage
FROM customer_orders
GROUP BY
		CASE WHEN total_orders = 1 THEN 'unique_customer' ELSE 'repeated_customer'
		END;

--•	Top 10 high-value customers 
WITH high_value_customer AS (
	SELECT c.customer_unique_id, COUNT(o.order_id) AS total_orders, SUM(i.total_amount_cost) AS total_expending, AVG(i.total_amount_cost) AS avg_expending
	FROM orders_table o JOIN items_table i
	ON o.order_id = i.order_id
	JOIN customers_table c
	ON c.customer_id = o.customer_id
	WHERE o.order_status = 'delivered'
	GROUP BY c.customer_unique_id
)
SELECT TOP 10*
FROM high_value_customer
ORDER BY total_expending DESC;

--•	Average orders per customer 
-- By using CTE
WITH avg_order AS (
	SELECT c.customer_unique_id, COUNT(o.order_id) AS total_orders
	FROM orders_table o JOIN customers_table c
	ON o.customer_id = c.customer_id
	GROUP BY c.customer_unique_id
)
SELECT AVG(total_orders) avg_order_per_customer
FROM avg_order;

--By using Subquery
SELECT AVG(total_orders) AS average_order_per_customer
FROM (SELECT c.customer_unique_id, COUNT(o.order_id) AS total_orders
	FROM orders_table o JOIN customers_table c
	ON o.customer_id = c.customer_id
	GROUP BY c.customer_unique_id
	) avg_orders;

--•	Customer lifetime value (basic) 
SELECT c.customer_unique_id, SUM(i.total_amount_cost) AS amount_spended_by_customer
FROM orders_table o JOIN customers_table c
ON o.customer_id = c.customer_id
JOIN items_table i
ON o.order_id = i.order_id
WHERE order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY amount_spended_by_customer DESC;

--•	Which locations (city/state) have most customers? 
SELECT customer_state,COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers_table
GROUP BY customer_state
ORDER BY total_customers DESC;

--•	Which location generates highest revenue? 
SELECT TOP 1 c.customer_state,c.customer_city, SUM(i.total_amount_cost) AS total_revenue
FROM orders_table o JOIN customers_table c
ON o.customer_id = c.customer_id
JOIN items_table i
ON o.order_id = i.order_id
WHERE order_status = 'delivered'
GROUP BY c.customer_state,c.customer_city
ORDER BY total_revenue DESC;

--ORDER & DELIVERY ANALYSIS--
--•	Average delivery time 
WITH delivery_time AS (
	SELECT  DATEDIFF(DAY,order_purchase_timestamp,order_delivered_customer_date) AS delivery_day
	FROM orders_table
	WHERE order_delivered_customer_date IS NOT NULL
	)
SELECT AVG(delivery_day) AS avg_delivery_day
FROM delivery_time;

--•	Fastest delivery vs slowest delivery 
SELECT MIN(date_diff) AS fastest_delivery, MAX(date_diff) AS slowest_delivery
FROM (SELECT DATEDIFF(DAY,order_purchase_timestamp,order_delivered_customer_date) AS date_diff
	FROM orders_table
	WHERE order_status = 'delivered'
	AND order_delivered_customer_date IS NOT NULL) AS date_difference
	;

--•	Percentage of late deliveries 
WITH late_deliveries_orders AS (
	SELECT 
		CASE	
			WHEN order_estimated_delivery_date < order_delivered_customer_date THEN 1
			ELSE 0 END AS is_late
	FROM orders_table
	WHERE order_delivered_customer_date IS NOT NULL
	AND order_estimated_delivery_date IS NOT NULL
	AND order_status = 'delivered'
	)
SELECT SUM(is_late)*100.0 / COUNT(*) AS percentage_of_late_deliveries
FROM late_deliveries_orders;

--By simple query
SELECT 
    COUNT(CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date 
        THEN 1 
    END) * 100.0 / COUNT(*) AS percentage_of_late_deliveries
FROM orders_table
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

 -- •Orders delivered on time vs delayed 
SELECT CASE
			WHEN order_delivered_customer_date>order_estimated_delivery_date THEN 'Delayed'
			ELSE 'on_time'
			END AS delivery_status,
			COUNT(*) AS total_orders
FROM orders_table
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
 GROUP BY CASE WHEN order_delivered_customer_date>order_estimated_delivery_date THEN 'Delayed'
			ELSE 'on_time'
		END;

--•	Delivery time by product category 
WITH order_delivery AS (
	SELECT o.order_id, DATEDIFF(DAY,o.order_purchase_timestamp,o.order_delivered_customer_date) AS delivery_time
	FROM orders_table o 
	WHERE order_status = 'delivered'
	AND o.order_purchase_timestamp IS NOT NULL 
	AND o.order_delivered_customer_date IS NOT NULL
	)
SELECT p.product_category_name_english, AVG(od.delivery_time) AS avg_delivery_time
FROM order_delivery od JOIN items_table i
	ON od.order_id = i.order_id
	JOIN products_table p
	ON p.product_id = i.product_id
GROUP BY p.product_category_name_english;

--•	Delivery time by seller 
WITH order_delivery AS (
	SELECT o.order_id, DATEDIFF(DAY,o.order_purchase_timestamp,o.order_delivered_customer_date) AS delivery_time
	FROM orders_table o 
	WHERE order_status = 'delivered'
	AND o.order_purchase_timestamp IS NOT NULL 
	AND o.order_delivered_customer_date IS NOT NULL
	)
SELECT i.seller_id, AVG(od.delivery_time) AS avg_delivery_time_by_seller
FROM order_delivery od JOIN items_table i
	ON od.order_id = i.order_id
GROUP BY i.seller_id;

--🔷 6. PAYMENT ANALYSIS
--•	Most used payment method 