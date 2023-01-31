-- Data cleaning
SELECT id, country, date_entered, source_url
	FROM public.accounts LIMIT 5;
	
-------------------------------------------------------------------
/*
The following 4 elements are located in the 'source_url'
ad_id, utm_source, utm_medium, utm_campaign we need to 
extract them to new columns */

-- create view accounts_clean
CREATE OR REPLACE VIEW public.accounts_view AS
-- cte for extracting columns from the url
WITH extract_from_url_cte as(
SELECT
	id,	
	CASE
      WHEN substring(source_url, 'ad_id[=%3D]([^%]+)') IS NOT NULL 
      THEN coalesce(replace(replace(substring(lower(source_url), 'ad_id[=%3d]([^%&]+)'),'253d',''),'3d',''),null)
      ELSE coalesce(replace(substring(lower(source_url), 'utm_id[=%3d]([^%&]+)'),'3d',''),null)
    END AS ad_id 
,
  	replace(replace(substring(lower(source_url),'utm_source[=%3d]([^%&]+)'),'3d',''),'25','') source,
	replace(replace(substring(lower(source_url),'utm_medium[=%3d]([^%&]+)'),'3d',''),'25','') medium,
	replace(replace(substring(source_url,'utm_campaign[=%3D]([^%&]+)'),'3D',''),'25','') campaign
FROM
  public.accounts
)
SELECT 
	a.id,
	CAST(nullif(e.ad_id, '') AS bigint) ad_id,
	e.medium,
	CASE
		WHEN position('?' in source) > 0
		THEN left(source, position('?' in source) - 1)
		ELSE source
	END AS source,
	e.campaign,
	cast(a.date_entered as date) as date_entered
FROM 
	extract_from_url_cte e
JOIN 
	public.accounts a
ON 
	e.id = a.id;
-- Data Cleaning Ends Here

---###Answering Business Questions###-----
 -------------------------------------------------------------
 -- Question 1. Month on month Registrations growth for Facebook Google Campigns per year.
 
  SELECT 
 	source,
	count(*) totals,
	date_part('year',date_entered) as year,
	to_char(date_entered,'fmMonth') as month
 FROM 
 	public.accounts_view 
 WHERE 
 	source IS NOT NULL and source IN ('google','facebook')
 GROUP BY
 	source, date_part('year',date_entered),
	date_part('month',date_entered), to_char(date_entered,'fmMonth')
 ORDER BY
 	year, date_part('month',date_entered)
 
 -- Key Findings
 -- Google campagn produced the most registrations with the highest being August 2022: A total of 48 registrations
 
 -----------------------------------------------------------------------------------
 -- Question 2. Which traffic source drove ma registrations from Aug 2022- Oct 2022 amongs the sources recorded in accounts table
 SELECT
 	source,
	count(*) total_regestrations
 FROM
 	public.accounts_view
 WHERE
 	date_entered between '2022-08-01' and '2022-10-31'
 GROUP BY
 	source
 ORDER BY
 	2 DESC
 LIMIT 1
--Key Findings
-- For the period between Aug 2022 - Oct 2022 google Campaing drove highest registrations
------------------------------------------------------------------------------------------------------------
-- Question 3. Top 5 Facebook Campaign that drove highest number of registration in the period between Aug 2022 and Oct 2022
 SELECT 
	campaign_name,
	count(*) total_regstrations
 FROM 
	fb_ads 
 WHERE
 	to_char(date_period :: date,'yyyy-mm-dd') 
		between '2022-08-01' and '2022-10-31'
 GROUP BY
 	campaign_name
 ORDER BY
 	2 DESC
 LIMIT 5

------------------------------------------------------------------------------------------------------------
-- Question 4. Facebook Campaign that drove lowest cost per registration between Aug 2022 and Oct 2022
 SELECT 
	campaign_name,
	round(cast(sum(f.spend)/count(a.id) as numeric),2) cost_per_reg
 FROM 
	fb_ads f
 JOIN
	accounts_view a
 ON
	f.ad_id = a.ad_id
 AND
 	to_char(date_period :: date,'yyyy-mm-dd')
		between '2022-08-01' and '2022-10-31'
 GROUP BY
 	campaign_name
 ORDER BY
 	2 
 LIMIT 1
 
 -- Key Insights
 -- Campaign VN_VI_Acq_Conv_interest_targeting_220913_toptradercontest_Android has the lowest cost per registration: $2.50
 ---------------------------------------------------------------------------------
 -- Question 5: Top 3 campaigns which drove the highest RIO%(Cost vs Net Deposit). RIO for each month in 2022
 SELECT 
 	campaign_name,
	to_char(date_period :: date,'fmMonth'),
	round(cast(((sum(diposits)-sum(spend))/sum(spend)) * 100 as numeric),2) rio
 FROM 
	accounts_view a
 JOIN
	account_transactions at
 ON
	a.id = at.id 
 JOIN
 	fb_ads f
 ON
 	a.ad_id = f.ad_id
 WHERE
 	to_char(date_period :: date,'yyyy-mm-dd') >= '2022-01-01'
 GROUP BY
 	campaign_name,to_char(date_period :: date,'fmMonth')
 ORDER BY
 	3 DESC
 LIMIT 3
 

