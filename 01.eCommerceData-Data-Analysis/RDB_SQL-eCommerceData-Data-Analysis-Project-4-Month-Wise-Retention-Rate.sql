USE eCommerceData;
GO

--Month-Wise Retention Rate
--Find month-by-month customer retention ratei since the start of the business.

--There are many different variations in the calculation of Retention Rate. But we will try to calculate the month-wise retention rate in this project.

--So, we will be interested in how many of the customers in the previous month could be retained in the next month.

--Proceed step by step by creating “views”. You can use the view you got at the end of the Customer Segmentation section as a source.
--1. Find the number of customers retained month-wise. (You can use time gaps)
--2. Calculate the month-wise retention rate.
--Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total 
--Number of Customers in the Current Month
--iCustomer retention refers to the ability of a company or product to retain its customers over some specified period.
--https://en.wikipedia.org/wiki/Customer_retention

--1. Find the number of customers retained month-wise. (You can use time gaps)
with log_customer as (
	SELECT	DISTINCT Cust_id, Ord_id
			,Order_date, MONTH(Order_Date) [Month], YEAR(Order_Date) [Year]
	FROM	combined_table
)
SELECT	DISTINCT [Year], [Month], 
		SUM (CASE WHEN Monthly_time_gap = 1 THEN 1 ELSE 0 END) 
				OVER (PARTITION BY [Year], [Month])	AS number_retained_customers
FROM	
(
	SELECT	*
			,DATEDIFF(month, Order_date, lead(Order_date) 
				OVER (PARTITION BY Cust_id ORDER BY Order_Date )) AS Monthly_time_gap
	FROM	log_customer 
) tbl
ORDER BY 1,2, 3 DESC
GO

--2. Calculate the month-wise retention rate.
--Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total 
with log_customer as (
	SELECT	DISTINCT Cust_id, Ord_id
			,Order_date, MONTH(Order_Date) [Month], YEAR(Order_Date) [Year]
	FROM	combined_table
)
SELECT	[Year], [Month],
		SUM (CASE WHEN Monthly_time_gap = 1 THEN 1 ELSE 0 END) retained_customers,
		COUNT(DISTINCT Cust_id) total_customer,
		CONVERT(decimal(10,2)
				,(1.0*SUM (CASE WHEN Monthly_time_gap = 1 THEN 1 ELSE 0 END)/COUNT(DISTINCT Cust_id))
				) As retention_rate
FROM	
(
	SELECT	*
			,DATEDIFF(month, Order_date
					, lead(Order_date) OVER (PARTITION BY Cust_id ORDER BY Order_Date )
					) AS Monthly_time_gap
			--,DENSE_RANK() OVER (PARTITION BY [YEAR], [Month] Order By Cust_id) unique_cust_id
	FROM	log_customer 
) tbl
GROUP BY [Year], [Month]
ORDER BY 1,2, 3 DESC
GO
--END







--Denemelerim

--customer retention strategy
--Repeat customer rate - # of Customers That Purchased More Than Once / # Unique Customers
--Purchase frequency - # of Orders Placed / # Unique Customers 
--Average Order Value (AOV) - Total Revenue Earned / # Orders Placed

CREATE OR ALTER VIEW customersInformation as
--DEFINE TABLE UNIQUE VALUE AND CALCULATE DATES(YEAR-MONTH-WEEK)
SELECT	Cust_id
		,Order_Date
		,LAST_VALUE(Order_Date) OVER(PARTITION BY Cust_id ORDER BY YEAR(Order_Date) 
				RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) highest_order_date
		,DENSE_RANK() OVER(PARTITION BY Cust_id ORDER BY Ord_id) dence_rank_Ord_id
		,DENSE_RANK() OVER(PARTITION BY Cust_id ORDER BY YEAR(Order_Date)) dence_rank_year
		,DATEDIFF(YEAR
				,Order_Date
				,LAST_VALUE(Order_Date) OVER(PARTITION BY Cust_id ORDER BY YEAR(Order_Date) 
								RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
				) diff_date_year
		,DENSE_RANK() OVER(PARTITION BY Cust_id ORDER BY YEAR(Order_Date), MONTH(Order_Date)) dence_rank_month
		,DATEDIFF(MONTH
				,Order_Date
				,LAST_VALUE(Order_Date) OVER(PARTITION BY Cust_id ORDER BY YEAR(Order_Date) 
								RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
				) diff_date_month
		,DATEDIFF(WEEK
				,Order_Date
				,LAST_VALUE(Order_Date) OVER(ORDER BY Order_Date 
								RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
				) diff_week_today_order --from 2012-12-30
FROM	combined_table
--WHERE	Cust_id=314
GO

CREATE OR ALTER VIEW customersStatistics as
--LOOK CUSTOMERS STATISTICS
SELECT	Cust_id
		,MAX(dence_rank_Ord_id) max_Order_num
		,MAX(dence_rank_year) max_year_Order_Date
		,MAX(dence_rank_month) max_month_Order_Date
		,MIN(diff_week_today_order) diff_week_today_last_order
FROM	customersInformation
GROUP BY Cust_id
ORDER BY max_Order_num DESC
GO


CREATE OR ALTER VIEW customersNum_Values as
--DETECT CUSTOMER GROUP
SELECT	*
FROM	(
	--Number of total Customer: 1832 customer
	SELECT	(SELECT 'Number of Total Customer') Numerical_Values, COUNT(Cust_id) Counts
	FROM	customersStatistics
	UNION ALL
	--Number of have 1 Order: 575 customer
	SELECT	(SELECT 'Have 1 Order') Numerical_Values, COUNT(Cust_id) Counts
	FROM	customersStatistics
	WHERE	max_Order_num=1
	UNION ALL
	--Number of have more then 1 Order: 1257
	SELECT	(SELECT 'Have more then 1 Order') Numerical_Values, COUNT(Cust_id) Counts
	FROM	customersStatistics
	WHERE	max_Order_num>1
	UNION ALL
	--Number of last order time in a year: 955 customer
	SELECT	(SELECT 'Last order time in a year') Numerical_Values, COUNT(Cust_id) Counts
	FROM	customersStatistics
	WHERE	diff_week_today_last_order<52
	UNION ALL
	--Number of last order time more then 1y: 867 customer
	SELECT	(SELECT 'Last order time more then a year') Numerical_Values, COUNT(Cust_id) Counts
	FROM	customersStatistics
	WHERE	diff_week_today_last_order>52
	UNION ALL
	--FOCUS CUSTOMER GROUP
	--HAVE 2 Order and Ones in Year: 817 customer
	SELECT	(SELECT 'HAVE 2 Order and Ones in Year') Numerical_Values, COUNT(Cust_id) Counts
	FROM	customersStatistics
	WHERE	max_Order_num>1
			and diff_week_today_last_order<52

) customersNum_Values
GO

CREATE OR ALTER VIEW customersGroup_A as
--FOCUS CUSTOMER GROUP
SELECT	*
		,DATEDIFF(DAY ,Order_Date ,Ship_Date) delay_time
FROM	(
	SELECT	*
	FROM	combined_table a
	WHERE	EXISTS (
				--HAVE 2 Order and Ones in Year
				SELECT	Cust_id
				FROM	customersStatistics b
				WHERE	a.Cust_id=b.Cust_id
						and max_Order_num>1
						and diff_week_today_last_order<52
			)
) customersGroup_A
GO


----WHICH PRODUCT MORE SALES
--SELECT	Prod_id, Product_Category
--		,COUNT(ORD_id) Number_of_Orders
--		,MIN(delay_time) delay_time
--FROM	customersGroup_A
--GROUP BY Prod_id, Product_Category
--ORDER BY Number_of_Orders DESC, delay_time DESC