USE mavenfuzzyfactory;
SELECT @@GLOBAL.time_zone, @@SESSION.time_zone;
SET session time_zone = '-5:00';

-- Q1: Volume growth
-- Pull overall session and order volume by quarter
SELECT
	YEAR(website_sessions.created_at) AS yr,
    QUARTER(website_sessions.created_at) AS q,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM 
	website_sessions
		LEFT JOIN orders
			ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- Q2: Session-to-order coversion rate, revenue per order, revenue per session 
SELECT
	YEAR(website_sessions.created_at) AS yr,
    QUARTER(website_sessions.created_at) AS q,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rt,
    SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS revenue_per_order,
    SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM 
	website_sessions
		LEFT JOIN orders
			ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1, 2;

-- Q3: Quarterly orders from 1) gsearch_nonbrand, 2) bsearch_nonbrand 3) brand_overall, 4) organic search, 5) direct_type_in
SELECT 
	YEAR(website_sessions.created_at) AS yr,
    QUARTER(website_sessions.created_at) AS q,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS 'orders_gsearch_nonbrand',
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS 'orders_bsearch_nonbrand',
	COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS 'orders_paid_brand',
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN orders.order_id ELSE NULL END) AS 'orders_organic_search',
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) AS 'orders_direct_type_in'
FROM 
	website_sessions
		LEFT JOIN orders
			ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1, 2;

-- Q4:
SELECT 
	YEAR(website_sessions.created_at) AS yr,
    QUARTER(website_sessions.created_at) AS q,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS 'cnvt_rt_gsearch_nonbrand',
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS 'cnvt_rt_bsearch_nonbrand',
	COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS 'cnvt_rt_paid_brand',
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com','https://www.bsearch.com') THEN website_sessions.website_session_id ELSE NULL END) AS 'cnvt_rt_organic_search',
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS 'cnvt_rt_direct_type_in'
FROM 
	website_sessions
		LEFT JOIN orders
			ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1, 2;

-- Q5:
SELECT 
	SUM(price_usd) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_sales
FROM orders
WHERE created_at > '2014-01-01';

SELECT
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS revenue_p1,
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS margin_p1,
    SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS revenue_p1,
    SUM(CASE WHEN product_id = 2 THEN (price_usd - cogs_usd) ELSE NULL END) AS margin_p2,
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS revenue_p1,
    SUM(CASE WHEN product_id = 3 THEN (price_usd - cogs_usd) ELSE NULL END) AS margin_p3,
    SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS revenue_p1,
    SUM(CASE WHEN product_id = 4 THEN (price_usd - cogs_usd) ELSE NULL END) AS margin_p4,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd-cogs_usd) AS total_marging
FROM order_items
GROUP BY 1, 2;

-- Q6: 
WITH product_pageviews AS(
SELECT
    website_session_id,
    website_pageview_id AS product_page_id, 
    created_at AS product_page_created_at
FROM website_pageviews
WHERE pageview_url = '/products'
)
-- Step 2: find the next page view that occur after the product page view
, sessions_w_next_pageview_id AS(
SELECT
	product_pageviews.website_session_id,
    product_pageviews.product_page_id,
    product_pageviews.product_page_created_at,
    MIN(website_pageviews.website_pageview_id) AS next_pageview_id
FROM product_pageviews
	LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = product_pageviews.website_session_id
    AND website_pageviews.website_pageview_id > product_pageviews.product_page_id
GROUP BY 1,2,3
)
-- Step 3: joing with order table
, sessions_w_next_pageview_id_orders AS(
SELECT
	sessions_w_next_pageview_id.website_session_id,
    sessions_w_next_pageview_id.product_page_id,
    sessions_w_next_pageview_id.product_page_created_at,
    sessions_w_next_pageview_id.next_pageview_id,
	orders.order_id
FROM sessions_w_next_pageview_id
	LEFT JOIN orders
    ON sessions_w_next_pageview_id.website_session_id = orders.website_session_id
)
SELECT
	YEAR(product_page_created_at) AS yr,
    MONTH(product_page_created_at) AS mo,
    COUNT(DISTINCT product_page_id) AS product_page_sessions,
    COUNT(DISTINCT next_pageview_id) AS clicked_through_another_page,
    COUNT(DISTINCT next_pageview_id)/COUNT(DISTINCT product_page_id) AS pct_clicked_another_page,
    COUNT(DISTINCT order_id) AS placed_order,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT product_page_id) AS product_to_order_rate
FROM sessions_w_next_pageview_id_orders
GROUP BY 1,2;

-- Based on the course answer
WITH product_pageviews AS(
SELECT
    website_session_id,
    website_pageview_id AS product_page_id, 
    created_at AS product_page_created_at
FROM website_pageviews
WHERE pageview_url = '/products'
)
SELECT
	YEAR(product_page_created_at) AS yr,
    MONTH(product_page_created_at) AS mo,
    COUNT(DISTINCT product_pageviews.website_session_id) AS product_page_sessions,
    COUNT(DISTINCT website_pageviews.website_session_id) AS clicked_through_another_page,
    COUNT(DISTINCT website_pageviews.website_session_id)/COUNT(DISTINCT product_page_id) AS pct_clicked_another_page,
    COUNT(DISTINCT orders.order_id) AS placed_order,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT product_page_id) AS product_to_order_rate
FROM product_pageviews
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = product_pageviews.website_session_id
		AND website_pageviews.website_pageview_id > product_pageviews.product_page_id
	LEFT JOIN orders
		ON product_pageviews.website_session_id = orders.website_session_id
GROUP BY 1,2;

-- Q7: Cross Sell Table  
CREATE TEMPORARY TABLE primary_products
SELECT
	order_id,
    primary_product_id,
    created_at AS ordered_at
FROM orders
WHERE created_at > '2014-12-05'
;

SELECT 
	primary_product_id,
    COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) AS _xsold_p1,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) AS _xsold_p2,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) AS _xsold_p3,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) AS _xsold_p4,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p1_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p2_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p3_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p4_xsell_rt
FROM(
SELECT
	primary_products.*,
    order_items.product_id AS cross_sell_product_id
FROM primary_products
	LEFT JOIN order_items
		ON order_items.order_id = primary_products.order_id
        AND order_items.is_primary_item = 0 -- only bringing in cross-sells
) AS pprimary_w_cross_sell
GROUP BY 1;
