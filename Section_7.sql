-- 55. ASSIGNMENT: Analyzing Channel Portfolios
SELECT
	-- YEARWEEK(created_at) AS year_week,
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_sessions
FROM
	website_sessions
WHERE website_sessions.created_at < '2012-11-29'
	AND website_sessions.created_at > '2012-08-22'
	AND website_sessions.utm_source IN ('gsearch', 'bsearch')
    AND utm_campaign = 'nonbrand' 
GROUP BY YEARWEEK(created_at);

-- 57. ASSIGNMENT: Comparing channel characteristics
SELECT
	utm_source,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END)/
    COUNT(DISTINCT website_session_id)AS pct_desktop,
    COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END)/
    COUNT(DISTINCT website_session_id)AS pct_mobile
FROM
	website_sessions
WHERE website_sessions.created_at < '2012-11-30'
	AND website_sessions.created_at > '2012-08-22'
	AND website_sessions.utm_source IN ('gsearch', 'bsearch')
    AND utm_campaign = 'nonbrand' 
GROUP BY utm_source;

-- 59. ASSIGNMENT: Cross-channel optimization bid
SELECT
	website_sessions.device_type,
    website_sessions.utm_source,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM
	website_sessions
		LEFT JOIN orders
			ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-09-19'
	AND website_sessions.created_at > '2012-08-22'
	AND website_sessions.utm_source IN ('gsearch', 'bsearch')
    AND website_sessions.utm_campaign = 'nonbrand' 
GROUP BY 1,2;

-- 61. ASSIGNMENT: Analyzing  Channel Portfolio Trends
SELECT
	-- YEARWEEK(created_at) AS year_week,
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' AND website_sessions.device_type ='desktop' THEN website_sessions.website_session_id ELSE NULL END) AS g_dtop_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' AND website_sessions.device_type ='desktop' THEN website_sessions.website_session_id ELSE NULL END) AS b_dtop_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' AND website_sessions.device_type ='desktop' THEN website_sessions.website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' AND website_sessions.device_type ='desktop' THEN website_sessions.website_session_id ELSE NULL END) AS b_pct_of_g_dtop,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' AND website_sessions.device_type ='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS g_mob_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' AND website_sessions.device_type ='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS b_mob_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'bsearch' AND website_sessions.device_type ='mobile' THEN website_sessions.website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN website_sessions.utm_source = 'gsearch' AND website_sessions.device_type ='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS b_pct_of_g_mob
FROM
	website_sessions
WHERE website_sessions.created_at < '2012-12-22'
	AND website_sessions.created_at > '2012-11-04'
	AND website_sessions.utm_source IN ('gsearch', 'bsearch')
    AND utm_campaign = 'nonbrand' 
GROUP BY YEARWEEK(created_at);

-- 64. ASSIGNMENT: Analyzing Direct Traffic 

SELECT
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source IS NOT NULL AND website_sessions.utm_campaign ='nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source IS NOT NULL AND website_sessions.utm_campaign ='brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source IS NULL AND website_sessions.http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_source IS NULL AND website_sessions.http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic
FROM 
	website_sessions
WHERE website_sessions.created_at < '2012-12-23'
GROUP BY 1, 2;

-- COURSE ANSWER
SELECT
	website_session_id,
    created_at,
    CASE
		WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
		WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand' 
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	END AS channel_group
FROM website_sessions
WHERE created_at <'2012-12-23';

-- Wrapping this as a subquery
SELECT
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) AS brand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END) AS direct,
    COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) AS organic,
    COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM(
SELECT
	website_session_id,
    created_at,
    CASE
		WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
		WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand' 
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	END AS channel_group
FROM website_sessions
WHERE created_at <'2012-12-23'
) AS sessions_w_channel_group
GROUP BY
	YEAR(created_at),
    MONTH(created_at)
;