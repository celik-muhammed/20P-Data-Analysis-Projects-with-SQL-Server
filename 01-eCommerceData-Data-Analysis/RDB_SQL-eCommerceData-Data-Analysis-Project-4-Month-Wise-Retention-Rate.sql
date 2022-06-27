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