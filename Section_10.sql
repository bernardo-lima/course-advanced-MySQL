SELECT 
	order_items.order_id,
	order_items.created_at,
    order_items.order_item_id,
	order_items.price_usd,
	order_items.product_id,
    order_item_refunds.order_item_refund_id,
	order_item_refunds.refund_amount_usd,
    DATEDIFF(order_item_refunds.created_at, order_items.created_at) AS days_order_to_refund
FROM
	order_items
		LEFT JOIN order_item_refunds
			ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE order_items.created_at < '2014-10-15';

-- 92 - ASSIGNMENT: Identifying Repeat Visitors
-- My answer 
SELECT 
	sessions_per_user,
    COUNT(DISTINCT user_id) AS users
FROM
(SELECT
	user_id,
    COUNT(DISTINCT website_session_id) AS sessions_per_user
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
GROUP BY 1) AS input
GROUP BY 1
;
-- Problems with my analysis:
-- Ignores that some users are returning but I only observe 1 session in the time period
-- To Fix this problem I included the WHERE clause below to restrict the analysis to users that have a new session (i.e. is_repeated = 0)

SELECT 
	sessions_per_user,
    COUNT(DISTINCT user_id) AS users
FROM
(SELECT
	user_id,
    COUNT(DISTINCT website_session_id) AS sessions_per_user
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
GROUP BY 1) AS input
WHERE user_id IN(
	select 
		user_id
	from website_sessions
	where created_at between '2014-01-01' AND '2014-11-01'
		and is_repeat_session = 0)
GROUP BY 1
;

-- Course answer 
-- STEEP 1: Identify the relevant sessions
-- STEEP 2: Use the user_id value from steep 1 to find repated session those users had
-- STEEP 3: Analyze the data at the user level (how many sessions each user have?)
-- STEEP 4: Aggregate the user-level analysis to generate your behavioral analysis

create temporary table sessions_w_repeat
select
	new_sessions.user_id,
    new_sessions.website_session_id AS new_session_id,
    website_sessions.website_session_id AS repeat_session_id
from(
select 
	user_id,
	website_session_id
from website_sessions
where created_at between '2014-01-01' AND '2014-11-01'
	and is_repeat_session = 0
) as new_sessions    
	LEFT JOIN website_sessions
		ON website_sessions.user_id = new_sessions.user_id
        AND website_sessions.created_at between '2014-01-01' AND '2014-11-01'
        AND website_sessions.is_repeat_session = 1 -- was a repeat session (redundant but good to illustrate)
        AND website_sessions.website_session_id > new_sessions.website_session_id -- session was later than new session 
;

select
	repeat_sessions,
    count(distinct user_id) as users
from(
select
	user_id,
    COUNT(DISTINCT new_session_id) AS new_sessions,
    COUNT(DISTINCT repeat_session_id) AS repeat_sessions
from sessions_w_repeat
group by 1
order by 3 desc
) as user_level
group by 1;

-- 94 - ASSIGNMENT: Analyzing time to repeat

create temporary table first_sessions
SELECT 
	user_id,
	website_session_id AS first_session_id,
    created_at AS first_session_created
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-03'
	AND is_repeat_session = 0;

create temporary table second_sessions
SELECT
	new_sessions.user_id,
    MIN(website_sessions.website_session_id) AS second_session_id,
    MIN(website_sessions.created_at) AS second_session_created
FROM(
SELECT 
	user_id,
	website_session_id
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-03'
	AND is_repeat_session = 0
) AS new_sessions    
	INNER JOIN website_sessions
		ON website_sessions.user_id = new_sessions.user_id
        AND website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-03'
        AND website_sessions.is_repeat_session = 1 -- was a repeat session (redundant but good to illustrate)
        AND website_sessions.website_session_id > new_sessions.website_session_id -- session was later than new session 
GROUP BY 1
;
select * from second_sessions;

SELECT
	AVG(days_first_to_second),
    MIN(days_first_to_second),
    MAX(days_first_to_second)
FROM(
SELECT
	first_sessions.user_id,
	first_sessions.first_session_id,
    first_sessions.first_session_created,
    second_sessions.second_session_id,
	second_sessions.second_session_created,
    DATEDIFF(second_sessions.second_session_created, first_sessions.first_session_created) AS days_first_to_second
FROM first_sessions
	INNER JOIN second_sessions
		ON second_sessions.user_id = first_sessions.user_id
	) AS input
;

-- COURSE ANSWER 

CREATE TEMPORARY TABLE sessions_w_repeats
SELECT
	new_sessions.user_id,
    new_sessions.website_session_id AS new_session_id ,
    new_sessions.created_at AS new_session_created_at,
    website_sessions.website_session_id AS repeated_session_id,
    website_sessions.created_at AS repeated_created_at
FROM(
SELECT 
	user_id,
	website_session_id,
    created_at
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-03'
	AND is_repeat_session = 0
) AS new_sessions    
	LEFT JOIN website_sessions
		ON website_sessions.user_id = new_sessions.user_id
        AND website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-03'
        AND website_sessions.is_repeat_session = 1 -- was a repeat session (redundant but good to illustrate)
        AND website_sessions.website_session_id > new_sessions.website_session_id -- session was later than new session 
;

CREATE TEMPORARY TABLE users_first_to_second
SELECT 
	user_id,
	DATEDIFF(second_session_created_at, new_session_created_at) AS days_first_to_second
FROM(
SELECT
user_id,
new_session_id,
new_session_created_at,
MIN(repeated_session_id) AS second_session_id,
MIN(repeated_created_at) AS second_session_created_at
FROM sessions_w_repeats
WHERE repeated_session_id IS NOT NULL
GROUP BY 1,2,3
) AS first_second;

SELECT
	AVG(days_first_to_second),
    MIN(days_first_to_second),
    MAX(days_first_to_second)
FROM users_first_to_second
;

-- 96 - ASSIGNMENT: Analyzing Repeated Channel Behavior
-- My answer

SELECT 
 CASE
		WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
		WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand' 
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
	END AS channel_group,
 -- COUNT(DISTINCT website_session_id) AS sessions,
 COUNT(DISTINCT CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END)	AS new_sessions,
 COUNT(DISTINCT CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END)  AS repeated_sessions
FROM website_sessions
WHERE user_id IN(
	SELECT 
		user_id
	FROM website_sessions
	WHERE created_at BETWEEN '2014-01-01' AND '2014-11-05'
		AND is_repeat_session = 0) 
	AND created_at BETWEEN '2014-01-01' AND '2014-11-05'
GROUP BY 1
;

-- Course answer. Answer is not a bit inconsistent. Now he is ignoring the "AND is_repeat_session = 0" constraint
-- It would it be that since he is only interested in the channels he is relaxing the assumption of focusing on a clear set of customers
SELECT 
 CASE
		WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
		WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand' 
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
	END AS channel_group,
 -- COUNT(DISTINCT website_session_id) AS sessions,
 COUNT(DISTINCT CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END)	AS new_sessions,
 COUNT(DISTINCT CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END)  AS repeated_sessions
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-05'
GROUP BY 1
;
-- 98 - ASSIGNMENT: Analyzing New and Repeat Concersion Rates 

SELECT 
	website_sessions.is_repeat_session,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS rev_per_session
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-08'
GROUP BY 1
;
