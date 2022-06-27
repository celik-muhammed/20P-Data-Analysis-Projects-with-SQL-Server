USE eCommerceData;
GO

--Customer Segmentation
--Categorize customers based on their frequency of visits. The following steps will guide you. If you want, you can track your own way.

--1. Create a “view” that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
CREATE OR ALTER VIEW logs_cust_monthly as
SELECT	DISTINCT Cust_id, Ord_id
		,YEAR(Order_Date) years
		,MONTH(Order_Date) months
FROM	combined_table
GO

--2. Create a “view” that keeps the number of monthly visits by users. (Show separately all months from the beginning business)
CREATE OR ALTER VIEW logs_cust_monthly_num as
SELECT	*
FROM	(
	SELECT	DISTINCT years, months
			,COUNT(Cust_id) visits
	FROM	logs_cust_monthly
	GROUP BY years, months
	--ORDER BY 1,2
) tbl
PIVOT (
	AVG(visits)
	FOR months in (
	[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12]
	)
) pvt
GO

--3. For each visit of customers, create the next month of the visit as a separate column.
SELECT	*
		,LEAD(months) OVER(PARTITION BY Cust_id, years ORDER BY months) next_visits
FROM	logs_cust_monthly
GO

--4. Calculate the monthly time gap between two consecutive visits by each customer.
with tbl as (
	SELECT DISTINCT Cust_id, Ord_id, Order_date, MONTH(Order_Date) [Month], YEAR(Order_Date) [Year]
	FROM	combined_table
)
SELECT	DISTINCT Cust_id, Ord_id
		,COUNT(Ord_id) OVER(PARTITION BY Cust_id) Count_order
		,Order_Date
		,LEAD(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date) second_mont
		,DATEDIFF(MONTH
				,Order_Date
				,LEAD(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date)
				) diff_day
FROM	tbl
order by 1,3
GO


--5. Categorise customers using average time gaps. Choose the most fittedlabeling model for you.
--For example: 
--o Labeled as churn if the customer hasn't made another purchase in the months since they made their first purchase.
--o Labeled as regular if the customer has made a purchase every month. 
--Etc.

--Customer Value = Purchase Frequency x Average Order Value
with tbl AS (
	SELECT	Cust_id
			,Customer_Name
			,COUNT(Ord_id) OVER(PARTITION BY Cust_id) Count_order
			,DENSE_RANK() OVER(PARTITION BY Cust_id, YEAR(Order_Date) ORDER BY MONTH(Order_Date)) [DENSE_RANK]
	FROM	combined_table
)
SELECT	Cust_id ,Customer_Name
		,Count_order
		,MAX([DENSE_RANK]) number_of_year
		,CASE
			WHEN MAX([DENSE_RANK]) = 1 THEN 'Churn'
			WHEN MAX([DENSE_RANK]) > 3 THEN 'Most Regular'
			ELSE 'Regular'
			END customersCategorise 
--INTO	#tempTable
FROM	tbl
GROUP BY Cust_id ,Customer_Name	,Count_order
ORDER BY 1,2
GO


SELECT	customersCategorise, COUNT(Cust_id) CategoriseCount
FROM	#tempTable
GROUP BY customersCategorise
--customersCategorise	CategoriseCount
--Churn					1014
--Most Regular			88
--Regular				730