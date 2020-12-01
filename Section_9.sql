-- 73 - ASSIGNMENT: Product-Level Sales Analysis
SELECT 
	YEAR(created_at) AS yr,
	MONTH(created_at) AS mo,
    COUNT(DISTINCT order_id) AS orders,
    SUM(price_usd) AS revenue,
    SUM(price_usd-cogs_usd) AS margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1,2;

-- 75 - ASSIGNMENT: Analyzing Product Launches
SELECT 
	YEAR(website_sessions.created_at) AS yr,
	MONTH(website_sessions.created_at) AS mo,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id)AS conv_rate,
    SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session,
	COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_orders,
    COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_orders
FROM orders
	RIGHT JOIN website_sessions
		ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at > '2012-04-01'
	AND website_sessions.created_at < '2013-04-01'
GROUP BY 1,2;

-- 78 - ASSIGNMENT: Analyzing Product-Level Website Pathing
-- First, dertermine the scope. Product was launched on '2012-01-06'
-- Pre-product created_at BETWEEN '2012-10-06' AND '2013-01-06'
-- Post-product creted_at BETWEEN '2013-01-06' AND '2013-04-06'

WITH sessions_to_analyze AS(
SELECT
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.website_pageview_id,
    website_pageviews.created_at AS pageview_created_at,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
	CASE WHEN pageview_url = '/the-forever-love-bear' THEN 1 ELSE 0 END AS lovebear_page,
    CASE WHEN website_pageviews.created_at BETWEEN '2012-10-06' AND '2013-01-06' THEN 1 ELSE 0 END AS pre_product2,
	CASE WHEN website_pageviews.created_at BETWEEN '2013-01-06' AND '2013-04-06' THEN 1 ELSE 0 END AS post_product2
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at > '2012-10-06'
	AND website_sessions.created_at < '2013-04-06'
    -- AND website_pageviews.pageview_url NOT IN ('/home')
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.created_at
   )
, session_level_made_it_flags AS(
SELECT 
	website_session_id,
    MAX(products_page) AS products_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
	MAX(lovebear_page) AS lovebear_made_it,
    MAX(pre_product2) AS pre_product2,
    MAX(post_product2) AS post_product2
FROM sessions_to_analyze
GROUP BY
	website_session_id
)
-- SELECT * FROM session_level_made_it_flags;
SELECT
    CASE
		WHEN pre_product2 = 1 THEN 'A.pre_product2'
        ELSE 'B.post_product2'
        END AS time_period,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS w_next_pg,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN lovebear_made_it = 1 THEN website_session_id ELSE NULL END) AS to_lovebear
FROM session_level_made_it_flags
GROUP BY 1;

-- I got the problem wrong. Next, answer based on the course (with some small adaptations)

-- Step 1: fiding the /product pageviews we care about
WITH product_pageviews AS(
SELECT
    website_session_id,
    website_pageview_id,
    created_at,
    CASE
		WHEN created_at < '2013-01-06' THEN 'A. Pre_product_2'
        WHEN created_at >= '2013-01-06' THEN 'B. Post_product_2'
        ELSE 'check logic'
	END AS time_period
FROM website_pageviews
WHERE created_at > '2012-10-06'
	AND created_at < '2013-04-06'
    AND pageview_url = '/products'
)
-- Step 2: find the next page view that occur after the product page view
, sessions_w_next_pageview_id AS(
SELECT
	product_pageviews.time_period,
    product_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id
FROM product_pageviews
	LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = product_pageviews.website_session_id
    AND website_pageviews.website_pageview_id > product_pageviews.website_pageview_id
GROUP BY 1, 2
)
-- Step 3: find the pageview_url associated with any applicable next pageview_id
, sessions_w_next_pageview_url AS(
SELECT
	sessions_w_next_pageview_id.time_period,
    sessions_w_next_pageview_id.website_session_id,
    website_pageviews.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id
	LEFT JOIN website_pageviews
    ON sessions_w_next_pageview_id.min_next_pageview_id = website_pageviews.website_pageview_id
)
-- Step 4: Summarizing the data
SELECT
	time_period,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_w_next_page,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT website_session_id) AS pct_to_myfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM sessions_w_next_pageview_url
GROUP BY 1
;
    
-- 80 - ASSIGNMENT: Building Product-Level Conversion Funnels
-- Step 1: fiding the website_sessions_id we care about. I can used this in the where statement. 
-- My answer
WITH sessions_to_analyze AS(
SELECT
    website_session_id,
    CASE
		WHEN pageview_url = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN pageview_url = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'check logic'
	END AS product_seen
FROM website_pageviews
WHERE created_at >= '2013-01-06'
	AND created_at < '2013-04-10'
    AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear')
)
, data_to_analyze AS(
SELECT
    sessions_to_analyze.product_seen,
	website_pageviews.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url
FROM website_pageviews
	LEFT JOIN sessions_to_analyze
		ON website_pageviews.website_session_id = sessions_to_analyze.website_session_id
WHERE created_at >= '2013-01-06'
	AND created_at < '2013-04-10'
    AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear','/cart','/shipping','/billing-2','/thank-you-for-your-order')
ORDER BY 2,3
)
SELECT
	product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN pageview_url = '/shipping' THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN pageview_url = '/billing-2' THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN pageview_url = '/thank-you-for-your-order' THEN website_session_id ELSE NULL END) AS to_thankyou
FROM data_to_analyze
GROUP BY 1;

WITH sessions_to_analyze AS(
SELECT
    website_session_id,
    CASE
		WHEN pageview_url = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN pageview_url = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'check logic'
	END AS product_seen
FROM website_pageviews
WHERE created_at >= '2013-01-06'
	AND created_at < '2013-04-10'
    AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear')
)
, data_to_analyze AS(
SELECT
    sessions_to_analyze.product_seen,
	website_pageviews.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url
FROM website_pageviews
	LEFT JOIN sessions_to_analyze
		ON website_pageviews.website_session_id = sessions_to_analyze.website_session_id
WHERE created_at >= '2013-01-06'
	AND created_at < '2013-04-10'
    AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear','/cart','/shipping','/billing-2','/thank-you-for-your-order')
ORDER BY 2,3
)
SELECT
	product_seen,
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS product_page_click_rt,
    COUNT(DISTINCT CASE WHEN pageview_url = '/shipping' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS cart_click_rt,
    COUNT(DISTINCT CASE WHEN pageview_url = '/billing-2' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN pageview_url = '/shipping' THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    COUNT(DISTINCT CASE WHEN pageview_url = '/thank-you-for-your-order' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN pageview_url = '/billing-2' THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM data_to_analyze
GROUP BY 1

-- COURSE ANSWER 
-- SETEP 1: sellect all pageviews for relevant sessions
-- SETEP 2: figure out which pageview url to look for
-- SETEP 3: pull all pageviews and identify the funnel steps 
-- SETEP 4: create the session-level conversion funnel view
-- SETEP 5: aggregate the data to assess funnel performance 

CREATE TEMPORARY TABLE sessions_seeing_product_pages
SELECT
	website_session_id,
	website_pageview_id,
	pageview_url AS product_page_seen
FROM website_pageviews
WHERE created_at > '2013-01-06'
	AND created_at < '2013-04-10'
    AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear')
;
-- fiding the right pageview_urls to build the funnels
SELECT DISTINCT
	website_pageviews.pageview_url
FROM sessions_seeing_product_pages
	LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
    AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id -- restricts to pages that were saw after the product pages 

-- we'll look into the inner query first to look over the pageview level results 
-- then, turn it into a subquery and make it the summary with flags
SELECT 
	sessions_seeing_product_pages.website_session_id,
	sessions_seeing_product_pages.product_page_seen,
	CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages
	LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
    AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY
	sessions_seeing_product_pages.website_session_id,
	website_pageviews.created_at
    ;
  
CREATE TEMPORARY TABLE session_product_level_made_it_flags
SELECT
	website_session_id,
    CASE
		WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'check logic'
	END AS product_seen,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
SELECT 
	sessions_seeing_product_pages.website_session_id,
	sessions_seeing_product_pages.product_page_seen,
	CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages
	LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
    AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY
	sessions_seeing_product_pages.website_session_id,
	website_pageviews.created_at
) AS pageview_level
GROUP BY 1,2
;

SELECT
	product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN cart_made_it THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flags
GROUP BY 1;

-- 83 - ASSIGNMENT: Cross-sell Analysis

WITH product_pageviews AS(
SELECT
    website_session_id,
    website_pageview_id,
    created_at,
    CASE
		WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
        WHEN created_at >= '2013-09-25' THEN 'B. Post_Cross_Sell'
        ELSE 'check logic'
	END AS time_period
FROM website_pageviews
WHERE created_at > '2013-08-25'
	AND created_at < '2013-10-25'
    AND pageview_url = '/cart'
)
-- Step 2: find the next page view that occur after the product page view
, sessions_w_next_pageview_id AS(
SELECT
	product_pageviews.time_period,
    product_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS next_pageview_id
FROM product_pageviews
	LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = product_pageviews.website_session_id
    AND website_pageviews.website_pageview_id > product_pageviews.website_pageview_id
GROUP BY 1, 2
)
, sessions_w_next_pageview AS(
SELECT
	sessions_w_next_pageview_id.time_period,
    sessions_w_next_pageview_id.website_session_id,
    sessions_w_next_pageview_id.next_pageview_id,
    website_pageviews.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id
	LEFT JOIN website_pageviews
    ON sessions_w_next_pageview_id.next_pageview_id = website_pageviews.website_pageview_id
)
, data_to_analyse AS( 
SELECT
	sessions_w_next_pageview.time_period,
    sessions_w_next_pageview.website_session_id,
    sessions_w_next_pageview.next_pageview_id,
    sessions_w_next_pageview.next_pageview_url,
    orders.price_usd,
    orders.items_purchased
FROM sessions_w_next_pageview
	LEFT JOIN orders
    ON orders.website_session_id = sessions_w_next_pageview.website_session_id
)
SELECT 
	time_period,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT next_pageview_id) AS clickthroughs,
    COUNT(DISTINCT next_pageview_id)/COUNT(DISTINCT website_session_id) AS cart_ctr,
    SUM(items_purchased)/COUNT(items_purchased) AS products_per_order,
    AVG(price_usd) AS aov,
    SUM(price_usd)/COUNT(DISTINCT website_session_id) AS rev_per_cart
FROM data_to_analyse
GROUP BY 1;

-- COURSE ANSWER (mine is more parcimonius)
-- STEEP 1: Identify the relevant /cart page views and their sessions
-- STEEP 2: See which of those cart sessions clicked through to the shipping page
-- STEEP 3: Find the orders associeted with the cart sessions. Analyze products purchased, AOV
-- STEEP 4: Aggregate and analyze a summary of findings

CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT
    CASE
		WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
        WHEN created_at >= '2013-09-25' THEN 'B. Post_Cross_Sell'
        ELSE 'check logic'
	END AS time_period,
    website_session_id AS cart_session_id,
    website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
    AND pageview_url = '/cart';

CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT
	sessions_seeing_cart.time_period,
	sessions_seeing_cart.cart_session_id,
    MIN(website_pageviews.website_pageview_id) AS pv_id_after_cart
FROM sessions_seeing_cart
	LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = sessions_seeing_cart.cart_session_id
    AND website_pageviews.website_pageview_id > sessions_seeing_cart.cart_pageview_id
GROUP BY
	sessions_seeing_cart.time_period,
	sessions_seeing_cart.cart_session_id
HAVING 
	   MIN(website_pageviews.website_pageview_id) IS NOT NULL;
       
CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
	time_period,
	cart_session_id,
    order_id,
    items_purchased,
    price_usd
FROM sessions_seeing_cart
	INNER JOIN orders
		ON orders.website_session_id = sessions_seeing_cart.cart_session_id;

-- First, look at this query that will be transformaed into a subquery 
SELECT 
	sessions_seeing_cart.time_period,
	sessions_seeing_cart.cart_session_id,
    CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
	CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart
	LEFT JOIN cart_sessions_seeing_another_page
		ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
	LEFT JOIN pre_post_sessions_orders
		ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
ORDER BY cart_session_id
;

SELECT 
	time_period,
	COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    SUM(clicked_to_another_page)/COUNT(DISTINCT cart_session_id) AS cart_ctr,
    SUM(items_purchased)/SUM(placed_order) AS products_per_order,
    SUM(price_usd)/SUM(placed_order) AS aov,
    SUM(price_usd)/COUNT(DISTINCT cart_session_id) AS rev_per_cart
FROM(
SELECT 
	sessions_seeing_cart.time_period,
	sessions_seeing_cart.cart_session_id,
    CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
	CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart
	LEFT JOIN cart_sessions_seeing_another_page
		ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
	LEFT JOIN pre_post_sessions_orders
		ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
ORDER BY cart_session_id
) AS full_data
GROUP BY 1;

-- 85 - ASSIGNMENT: Product Portfolio Expansion

WITH sessions_to_analyze AS(
SELECT
    website_session_id,
    CASE
		WHEN created_at < '2013-12-12' THEN 'A. Pre_Bday_Bear'
        WHEN created_at >= '2013-09-25' THEN 'B. Post_Bday_Bear'
        ELSE 'check logic'
	END AS time_period
FROM website_sessions
WHERE created_at BETWEEN '2013-11-12' AND '2014-01-12'
)
, sessions_plus_order AS( 
SELECT
	sessions_to_analyze.time_period,
    sessions_to_analyze.website_session_id,
	orders.order_id,
    orders.price_usd,
    orders.items_purchased
FROM sessions_to_analyze
	LEFT JOIN orders
    ON orders.website_session_id = sessions_to_analyze.website_session_id
)
SELECT 
	time_period,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS conv_rate,
    AVG(price_usd) AS aov,
    SUM(items_purchased)/COUNT(items_purchased) AS products_per_order,
    SUM(price_usd)/COUNT(DISTINCT website_session_id) AS rev_per_session
FROM sessions_plus_order
GROUP BY 1;

-- COURSE ANSWER
SELECT 
	CASE
		WHEN website_sessions.created_at < '2013-12-12' THEN 'A. Pre_Bday_Bear'
		WHEN website_sessions.created_at >= '2013-09-25' THEN 'B. Post_Bday_Bear'
		ELSE 'check logic'
	END AS time_period,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    SUM(orders.price_usd) AS total_revenue,
    SUM(orders.items_purchased) AS total_products_sold,
    SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS average_order_value,
    SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) AS products_per_order,
    SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session    
FROM website_sessions
	LEFT JOIN orders
		ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;

-- 88 - ASSIGNMENT: Product Portfolio Expansion
SELECT 
	YEAR(order_items.created_at) AS yr,
	MONTH(order_items.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_items.order_id ELSE NULL END) AS p1_orders,
    -- COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS p1_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_item_refunds.order_item_refund_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN order_items.order_id ELSE NULL END) AS p1_refunds_rt,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_items.order_id ELSE NULL END) AS p2_orders,
    -- COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS p2_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_item_refunds.order_item_refund_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_items.order_id ELSE NULL END) AS p2_refunds_rt,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_items.order_id ELSE NULL END) AS p3_orders,
    -- COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS p3_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_item_refunds.order_item_refund_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_items.order_id ELSE NULL END) AS p3_refunds_rt,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_items.order_id ELSE NULL END) AS p4_orders,
    -- COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_item_refunds.order_item_refund_id ELSE NULL END) AS p4_refunds,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_item_refunds.order_item_refund_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN order_items.order_id ELSE NULL END) AS p4_refunds_rt
FROM
	order_items
		LEFT JOIN order_item_refunds
			ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE order_items.created_at < '2014-10-15'
GROUP BY 1,2;

-- ANother approach just to resude the code in the count part
SELECT 
	YEAR(created_at) AS yr,
	MONTH(created_at) AS mo,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_id ELSE NULL END) AS p1_orders,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refund_id ELSE NULL END) AS p1_refunds,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_id ELSE NULL END) AS p2_orders,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refund_id ELSE NULL END) AS p2_refunds,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_id ELSE NULL END) AS p3_orders,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refund_id ELSE NULL END) AS p3_refunds,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_id ELSE NULL END) AS p4_orders,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refund_id ELSE NULL END) AS p4_refunds
FROM(
SELECT 
	order_items.order_id,
	order_items.created_at,
    order_items.order_item_id,
	order_items.price_usd,
	order_items.product_id,
    order_item_refunds.order_item_refund_id,
	order_item_refunds.refund_amount_usd
FROM
	order_items
		LEFT JOIN order_item_refunds
			ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE order_items.created_at < '2014-10-15'
) AS data_to_analyze
GROUP BY 1,2;

