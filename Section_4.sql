USE mavenfuzzyfactory;
SELECT @@GLOBAL.time_zone, @@SESSION.time_zone;

SELECT @@GLOBAL.time_zone, @@SESSION.time_zone;
SET session time_zone = '-5:00';

-- Code from lecture
SELECT 
    *
FROM
    website_sessions
WHERE
    website_session_id BETWEEN 1000 AND 2000;

SELECT 
    utm_content, 
    COUNT(DISTINCT website_session_id) AS sessions
FROM
    website_sessions
GROUP BY utm_content
ORDER BY sessions DESC;

SELECT 
    website_sessions.utm_content, 
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rt
FROM
    website_sessions
		LEFT JOIN orders
			ON website_sessions.website_session_id = orders.website_session_id
GROUP BY website_sessions.utm_content
ORDER BY sessions DESC;

--  21. Assingment: Finding Top Traffic Sources
-- Scope: website sessions, from 12/04/2012, by UMT Source, Campaign, Referring domain
SELECT COUNT(DISTINCT website_session_id)
FROM website_sessions
WHERE created_at < '2012-04-12';

-- Answer
SELECT 
	utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS number_of_sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY 
	utm_source, 
    utm_campaign, 
    http_referer
ORDER BY number_of_sessions DESC;

-- Answer including percent of total
SELECT 
	utm_source,
    utm_campaign,
    http_referer,
	COUNT(DISTINCT website_session_id) AS number_of_sessions,
    (100.0 * COUNT(DISTINCT website_session_id)) /
    (SELECT 
		COUNT(DISTINCT website_session_id)
    FROM website_sessions
	WHERE created_at < '2012-04-12') as perct_of_sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY 
		utm_source, 
		utm_campaign, 
		http_referer
ORDER BY number_of_sessions DESC;


-- 23. Assingment: Traffic Source Conversion Rates
-- Include Conversion rate (CVR) from session to order
SELECT 
	website_sessions.utm_source,
    website_sessions.utm_campaign,
    website_sessions.http_referer,
    COUNT(DISTINCT website_sessions.website_session_id) AS number_of_sessions,
    COUNT(DISTINCT orders.order_id) AS number_of_orders,
    (COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id))*100.00 AS session_to_order_conv_rate
FROM 
	website_sessions 
    LEFT JOIN orders 
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-04-12'
GROUP BY 
	website_sessions.utm_source, 
    website_sessions.utm_campaign, 
    website_sessions.http_referer
ORDER BY number_of_sessions DESC;

-- Cleaner
SELECT 
	website_sessions.utm_source,
    website_sessions.utm_campaign,
    COUNT(DISTINCT website_sessions.website_session_id) AS number_of_sessions,
    COUNT(DISTINCT orders.order_id) AS number_of_orders,
    (COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id))*100.00 AS session_to_order_conv_rate
FROM 
	website_sessions 
    LEFT JOIN orders 
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-04-12'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
;

-- 26. Assingment: Traffic Source Tranding
SELECT
	YEAR(created_at) AS yr,
    WEEK(created_at) AS wk,
    MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT website_session_id) AS sessions
FROM 
	website_sessions 
WHERE website_sessions.created_at < '2012-05-10'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 1, 2;

-- 27. Assingment: Traffic Source Conversion Rates
SELECT 
	website_sessions.utm_source,
    website_sessions.utm_campaign,
    website_sessions.device_type,
    COUNT(DISTINCT website_sessions.website_session_id) AS number_of_sessions,
    COUNT(DISTINCT orders.order_id) AS number_of_orders,
    (COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id))*100.00 AS session_to_order_conv_rate
FROM 
	website_sessions 
    LEFT JOIN orders 
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-05-11'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY device_type
;

-- 30. Assingment: Trending w/ Granular Segments
SELECT
	YEAR(created_at) AS yr,
    WEEK(created_at) AS wk,
    MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions,
    COUNT(DISTINCT website_session_id) AS total_sessions
FROM 
	website_sessions
WHERE website_sessions.created_at > '2012-04-15' 
AND website_sessions.created_at < '2012-06-09'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 1, 2;