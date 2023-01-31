/****** DATA INSPECTING ******/
SELECT * FROM [portfolioproject].[dbo].[sales_data]

-- Check for unique values
SELECT distinct status FROM [portfolioproject].[dbo].[sales_data]
SELECT distinct year_id FROM [portfolioproject].[dbo].[sales_data]
SELECT distinct productline FROM [portfolioproject].[dbo].[sales_data]
SELECT distinct country FROM [portfolioproject].[dbo].[sales_data]
SELECT distinct dealsize FROM [portfolioproject].[dbo].[sales_data]
SELECT distinct territory FROM [portfolioproject].[dbo].[sales_data]

/****** ANALYSIS ******/
-- Question 1. Show sales by productline
SELECT 
	productline,
	sum(sales) revenue
FROM 
	[portfolioproject].[dbo].[sales_data]
GROUP BY
	productline
ORDER BY
	2 DESC

-- Question 2. Show sales by year
SELECT 
	year_id,
	sum(sales) revenue
FROM 
	[portfolioproject].[dbo].[sales_data]
GROUP BY
	year_id
ORDER BY
	2 DESC
	-- Why did 2005 recorded lowest sales? Lets check if we have sales for the whole year
	SELECT distinct month_id FROM [portfolioproject].[dbo].[sales_data] WHERE year_id = 2005
	-- We only have 5months sales

-- Question 3. Revenue by deal size
SELECT 
	dealsize,
	sum(sales) revenue
FROM 
	[portfolioproject].[dbo].[sales_data]
GROUP BY
	dealsize
ORDER BY
	2 DESC
	-- Medium dealsize recorded more revenue than small and large

-- Question 4. Best sales month for specific year and therevenue generated?
SELECT 
	month_id,
	sum(sales) revenue,
	count(ordernumber) frequency
FROM 
	[portfolioproject].[dbo].[sales_data]
WHERE 
	year_id = 2004
GROUP BY
	month_id
ORDER BY
	2 DESC
	-- November 2003 = 1029837.66271973 with 296 orders
	-- November 2004 = 1089048.00762939 with 301 orders
	-----November is the best month for both 2003 and 2004

-- Question 5. What product sales most in the month of November
SELECT 
	month_id,
	productline,
	sum(sales) revenue,
	count(ordernumber) frequency
FROM 
	[portfolioproject].[dbo].[sales_data]
WHERE 
	year_id = 2003 and month_id = 11
GROUP BY
	month_id,productline
ORDER BY
	3 DESC
	-- Classic cars is the top selling product in the month of November

-- Question 6. Who is the best customer based on RFM(Recency Frequency Monetory)
		-- RFM - An indexing technique that uses past purchases behavior to segment customers
		-- RFM report is a way of segmenting customers using three key matrics:
							-- recency (How long ago their last purchase was),
							-- frequency (How often they purchase)
							-- monetory value (howmuch they spent)

/* 
	Creating #rfm temp table
*/
DROP TABLE IF EXISTS #rfm;
WITH rfmCte AS(
	SELECT 
		customername,
		sum(sales) monetory_value,
		avg(sales) avg_monetory_value,
		count(ordernumber) frequency,
		max(orderdate) last_order_date,
		(SELECT max(orderdate) FROM [portfolioproject].[dbo].[sales_data]) max_ordered_date,
		datediff(DD, max(orderdate), (SELECT max(orderdate) FROM [portfolioproject].[dbo].[sales_data])) recency
	FROM 
		[portfolioproject].[dbo].[sales_data]
	GROUP BY
		customername
),
rfmCalcCte as(
	SELECT
		r.*,
		NTILE(4) OVER(ORDER BY r.recency DESC) rfm_recency,
		NTILE(4) OVER(ORDER BY r.frequency) rfm_frequency,
		NTILE(4) OVER(ORDER BY monetory_value) rfm_monetory
	FROM
		rfmCte r
)
SELECT 
	rc.* ,
	rfm_recency + rfm_frequency + rfm_monetory as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetory as varchar)  as rfm_cell_str
	INTO #rfm
FROM 
	rfmCalcCte rc

SELECT 
	customername,
	rfm_recency, 
	rfm_frequency, 
	rfm_monetory,
	CASE
		WHEN rfm_cell_str IN (111,112,121,122,123,132,211,212,114,141)
		THEN 'lost customer'
		WHEN rfm_cell_str IN (133, 134, 143, 244, 334, 343, 344, 144)
		THEN 'slipping away' -- Big spending cutomers who havent purchased recently
		WHEN rfm_cell_str IN (311, 411, 331)
		THEN 'new customers'
		WHEN rfm_cell_str IN (222, 223,233, 322)
		THEN 'potential churn'
		WHEN rfm_cell_str IN (323, 332, 333, 321,422, 432)
		THEN 'active' -- Customers who buy at low price, recently and often
		WHEN rfm_cell_str IN (433, 434, 443, 444)
		THEN 'loyal'
	END rfm_segment
FROM 
	#rfm


-- Question 6. Products that are most sold together
SELECT distinct ordernumber, stuff(
	(SELECT
		','+productcode
	FROM 
		[portfolioproject].[dbo].[sales_data] p
	WHERE
		ordernumber IN (
			SELECT
				o.ordernumber
			FROM
				(SELECT 
					ordernumber,
					count(*)  frq
				FROM 
					[portfolioproject].[dbo].[sales_data]
				WHERE 
					status = 'Shipped'
				GROUP BY
					ordernumber
					) o
			WHERE
				o.frq = 2
			) AND p.ordernumber = s.ordernumber
	FOR	
		xml path(''))
		, 1, 1, '') product_codes
FROM 
	[portfolioproject].[dbo].[sales_data] s
ORDER BY	
	2 DESC

--CITIES WITH HIGHER SALES