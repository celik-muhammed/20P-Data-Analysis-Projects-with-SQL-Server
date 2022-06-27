USE eCommerceData;
GO

--Analyze the data by finding the answers to the questions below:
--1. Using the columns of “market_fact”, “cust_dimen”, “orders_dimen”, “prod_dimen”, “shipping_dimen”, Create a new table, named as “combined_table”. 
with temp as (
	SELECT	c.*, o.*, p.*, s.*
			,m.Discount, m.Order_Quantity
			,m.Product_Base_Margin, m.Sales
	FROM	market_fact m, cust_dimen c, orders_dimen o
			,prod_dimen p, shipping_dimen s
	WHERE	m.Cust_id=c.Cust_id
			and m.Ord_id=o.Ord_id
			and m.Prod_id=p.Prod_id
			and m.Ship_id=s.Ship_id
)
SELECT	*
INTO	combined_table
FROM	temp;
GO

--2. Find the top 3 customers who have the maximum count of orders.
SELECT	TOP 3 Cust_id
		,Customer_Name
		,COUNT(distinct Ord_id) count_of_orders
FROM	combined_table
GROUP BY Cust_id ,Customer_Name
ORDER BY count_of_orders DESC
GO


--3. Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
SELECT	*
		,DATEDIFF(DAY, Order_Date, Ship_Date) DaysTakenForDelivery
FROM	combined_table
GO

ALTER TABLE	combined_table
ADD			DaysTakenForDelivery INT
GO

UPDATE combined_table
SET	DaysTakenForDelivery = DATEDIFF(D, Order_Date, Ship_Date)
GO

SELECT * FROM combined_table
GO

--4. Find the customer whose order took the maximum time to get delivered.
SELECT	TOP 1 Cust_id
		,Customer_Name
		,MAX(DaysTakenForDelivery) maximum_time
FROM	combined_table
GROUP BY Cust_id, Customer_Name
ORDER BY maximum_time DESC
GO

SELECT	TOP 1 *
FROM	combined_table
ORDER BY DaysTakenForDelivery DESC
GO

--5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
SELECT	MONTH(Order_Date) month_2011_01
		,COUNT(distinct Cust_id) Count_total_unique_customers		
FROM	combined_table
WHERE	YEAR(Order_Date)=2011
		and Cust_id in (
			--unique customers in January 2011
			SELECT	DISTINCT Cust_id
			FROM	combined_table
			WHERE	YEAR(Order_Date)=2011
					and MONTH(Order_Date)=1)
GROUP BY MONTH(Order_Date)
GO

--6. Write a query to return for each user the time elapsed between the first purchasing and the third purchasing, in ascending order by Customer ID.
with temp as (
		SELECT	DISTINCT Cust_id, Customer_Name
				,Order_Date 
				,DENSE_RANK() OVER (PARTITION BY Cust_id ORDER BY Order_date) [DENSE_RANK]
		FROM	combined_table
		WHERE	Cust_id in (
				--Order_Date, 917 ord_id-920
				SELECT	Cust_id
				FROM	combined_table
				GROUP BY Cust_id
				HAVING	COUNT(DISTINCT Ord_id)>2)
), temp2 as (
SELECT DISTINCT Cust_id, Customer_Name
		,Order_Date
		,DATEDIFF( DAY
			,FIRST_VALUE(Order_date) OVER (PARTITION BY Cust_id ORDER BY Order_date) 
			,LEAD(Order_date, 2) OVER (PARTITION BY Cust_id ORDER BY Order_date) 
			) diff_third_first
		,[DENSE_RANK]
FROM	temp
) 
select	Cust_id, Customer_Name, diff_third_first 
FROM	temp2
WHERE	[DENSE_RANK]=1
GO

--7. Write a query that returns customers who purchased both product 11 and product 14, as well as the ratio of these products to the total number of products purchased by the customer.
with temp as (
	SELECT	*
			,SUM(Order_Quantity) OVER(PARTITION BY Cust_id) total_all_products
			,SUM (CASE WHEN Prod_id=11 OR Prod_id=14 THEN Order_Quantity ELSE 0 END) 
				OVER(PARTITION BY Cust_id) AS total_11_14_products
			,SUM (CASE WHEN Prod_id=11 THEN Order_Quantity ELSE 0 END) 
				OVER(PARTITION BY Cust_id) AS total_11_products
			,SUM (CASE WHEN Prod_id=14 THEN Order_Quantity ELSE 0 END) 
				OVER(PARTITION BY Cust_id) AS total_14_products
	FROM	combined_table
	WHERE	Cust_id in (
				SELECT	Cust_id
				FROM	combined_table
				WHERE	Prod_id=11
				INTERSECT
				SELECT	Cust_id
				FROM	combined_table
				WHERE	Prod_id=14)
)
SELECT	DISTINCT Cust_id, Customer_Name
		,CAST((total_11_14_products/total_all_products) as numeric(10,2)) product_11_14
		,CAST((total_11_products/total_all_products) as numeric(10,2)) product_11
		,CAST((total_14_products/total_all_products) as numeric(10,2))product_11
FROM	temp
GO