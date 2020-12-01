-- 67 - ASSIGNMENT: Analyzing Seasonality
SELECT
    YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM 
    website_sessions
        LEFT JOIN orders
            ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'
GROUP BY 1, 2;

SELECT
    YEARWEEK(website_sessions.created_at) AS year_week,
    MIN(DATE(website_sessions.created_at)) AS week_start_date,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM 
    website_sessions
        LEFT JOIN orders
            ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'
GROUP BY 1;

-- 69 - ASSIGNMENT: Analyzing Business Patterns

SELECT
    HOUR(website_sessions.created_at) AS hr,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN WEEKDAY(website_sessions.created_at) = 0 THEN website_sessions.website_session_id ELSE NULL END) AS monday,
    COUNT(DISTINCT CASE WHEN WEEKDAY(website_sessions.created_at) = 1 THEN website_sessions.website_session_id ELSE NULL END) AS tuesday,
    COUNT(DISTINCT CASE WHEN WEEKDAY(website_sessions.created_at) = 2 THEN website_sessions.website_session_id ELSE NULL END) AS wednesday,
    COUNT(DISTINCT CASE WHEN WEEKDAY(website_sessions.created_at) = 3 THEN website_sessions.website_session_id ELSE NULL END) AS thursday,
    COUNT(DISTINCT CASE WHEN WEEKDAY(website_sessions.created_at) = 4 THEN website_sessions.website_session_id ELSE NULL END) AS friday,
    COUNT(DISTINCT CASE WHEN WEEKDAY(website_sessions.created_at) = 5 THEN website_sessions.website_session_id ELSE NULL END) AS saturday,
    COUNT(DISTINCT CASE WHEN WEEKDAY(website_sessions.created_at) = 6 THEN website_sessions.website_session_id ELSE NULL END) AS sunday
FROM 
    website_sessions
        LEFT JOIN orders
            ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at > '2012-09-15'
    AND website_sessions.created_at < '2012-11-15'
GROUP BY 1;

-- Course answer

SELECT 
    hr,
    ROUND(AVG(CASE WHEN wkday = 0 THEN website_sessions ELSE NULL END),1) AS mon,
    ROUND(AVG(CASE WHEN wkday = 1 THEN website_sessions ELSE NULL END),1) AS tue,
    ROUND(AVG(CASE WHEN wkday = 2 THEN website_sessions ELSE NULL END),1) AS wed,
    ROUND(AVG(CASE WHEN wkday = 3 THEN website_sessions ELSE NULL END),1) AS thu,
    ROUND(AVG(CASE WHEN wkday = 4 THEN website_sessions ELSE NULL END),1) AS fri,
    ROUND(AVG(CASE WHEN wkday = 5 THEN website_sessions ELSE NULL END),1) AS sat,
    ROUND(AVG(CASE WHEN wkday = 6 THEN website_sessions ELSE NULL END),1) AS sun
FROM (
SELECT
    DATE(created_at) AS created_date,
    WEEKDAY(created_at) AS wkday,
    HOUR(created_at) AS hr,
    COUNT(DISTINCT website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1, 2, 3) AS daily_hour_sessions
GROUP BY 1
ORDER BY 1
;

SELECT WEEKDAY(CURDATE());