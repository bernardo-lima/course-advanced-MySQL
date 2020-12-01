-- 34. ASSIGNMENT: Finding Top Website Pages
SELECT 
    pageview_url,
    COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews    
WHERE created_at <  '2012-06-09'
GROUP BY pageview_url
ORDER BY pvs DESC; 

-- 36. ASSIGNMENT: Finding Top Entry Pages
-- My take
-- Step 1: Find the first pageview for each session
-- Step 2: Find the URL the customer saw on that first page_view

-- First, I'll find the mininum website_pageview_id per session
SELECT 
    MIN(website_pageview_id)
FROM website_pageviews
WHERE created_at <  '2012-06-12'
GROUP BY website_session_id; 
-- I'll use the result from this table to calculate the distribution of entry pages by pageview_url
-- That is, I'll use the query above as a subquery to identify the landing pages and count how many time they have been viewed

SELECT 
    pageview_url AS entry_page,
    COUNT(DISTINCT website_pageview_id) AS sessions_hitting_entry_page
FROM website_pageviews
WHERE website_pageview_id IN 
    (SELECT 
        MIN(website_pageview_id)
    FROM website_pageviews
    WHERE created_at <  '2012-06-12'
    GROUP BY website_session_id)
GROUP BY
    pageview_url;
    
 -- COURSE Answer
CREATE TEMPORARY TABLE first_pv_per_session
SELECT
    website_session_id,
    MIN(website_pageview_id) AS first_pv
FROM website_pageviews
WHERE created_at <  '2012-06-12'
GROUP BY website_session_id;

-- Now using this as a constraint to retrive the resutls from website_pageviews using that as a constaint
SELECT 
    website_pageviews.pageview_url AS landing_page_url,
    COUNT(DISTINCT first_pv_per_session.website_session_id) AS sessions_hitting_page
FROM first_pv_per_session
    LEFT JOIN website_pageviews
        ON first_pv_per_session.first_pv = website_pageviews.website_pageview_id
GROUP BY website_pageviews.pageview_url
;

-- 39. ASSIGNMENT: Calculating Bounce Rates
-- STEP 1: Find the first website_pageview_id for relevant sessions
-- STEP 2: Identify the landing page of each session 

CREATE TEMPORARY TABLE input_bounce_rate
SELECT    
    website_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page,
    subtable.count_of_pages_viewed
FROM website_pageviews
    INNER JOIN
        (SELECT 
            website_session_id,
            COUNT(website_pageview_id) AS count_of_pages_viewed,
            MIN(website_pageview_id) 
        FROM website_pageviews
        WHERE created_at <  '2012-06-14'
        GROUP BY website_session_id) subtable
            ON website_pageviews.website_session_id = subtable.website_session_id
WHERE website_pageviews.website_pageview_id IN 
    (SELECT 
        MIN(website_pageview_id)
    FROM website_pageviews
    WHERE created_at <  '2012-06-14'
    GROUP BY website_session_id)
   ;

SELECT
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN count_of_pages_viewed = 1 THEN website_session_id ELSE NULL END) AS bounced__sessions,
    COUNT(DISTINCT CASE WHEN count_of_pages_viewed = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS bounce_rate 
FROM input_bounce_rate
GROUP BY 
    landing_page;
    
-- COURSE ANSWER
-- ANALYZING BOUNCE RATES & LANDING PAGES TEST
-- STEP 1: Find the first website_pageview_id for relevant sessions
-- STEP 2: Identify the landing page of each session 
-- STEP 3: Counting the pageviews for each session, to identify "bounces"
-- STEP 4: Summarizing by couting total sessions and bounced sessions

CREATE TEMPORARY TABLE first_pageviews
SELECT
    website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id;

-- next, we'll bring in the lading page, like last time, but restrict to home only
-- this is redundant in this case, since all is to the homepage
CREATE TEMPORARY TABLE sessions_w_lading_page
SELECT
    first_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_pageviews
    INNER JOIN website_pageviews
        ON website_pageviews.website_pageview_id = first_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url = '/home';

-- then a table to have count of pageviews per session
-- then limit it to just the bounce_sessions
CREATE TEMPORARY TABLE bounced_sessions
SELECT
    sessions_w_lading_page.website_session_id,
    sessions_w_lading_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM sessions_w_lading_page
LEFT JOIN website_pageviews
    ON website_pageviews.website_session_id = sessions_w_lading_page.website_session_id
GROUP BY
    sessions_w_lading_page.website_session_id,
    sessions_w_lading_page.landing_page
HAVING 
    COUNT(website_pageviews.website_pageview_id) = 1
    ; 
    
-- we'll do this first just to show what's in this query, then we will count them after
SELECT
    sessions_w_lading_page.website_session_id,
    bounced_sessions.website_session_id AS bounced_website_session_id
FROM sessions_w_lading_page
LEFT JOIN bounced_sessions
    ON bounced_sessions.website_session_id = sessions_w_lading_page.website_session_id
ORDER BY
    sessions_w_lading_page.website_session_id
    ; 

-- final output for Assigment_Calculation_
SELECT
    COUNT(DISTINCT sessions_w_lading_page.website_session_id) AS sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id)/COUNT(DISTINCT sessions_w_lading_page.website_session_id) AS bounce_rate 
FROM sessions_w_lading_page
LEFT JOIN bounced_sessions
    ON bounced_sessions.website_session_id = sessions_w_lading_page.website_session_id
GROUP BY 
    sessions_w_lading_page.landing_page
    ; 

-- 41. ASSIGNMENT: Analyzing Landing Page Tests
-- Finding the first instance of /lander-1 to set the analysis timeframe
SELECT 
    MIN(created_at), -- We can use either of these results as the lower limit of period we'll analyse (see both implemented below)
    MIN(website_pageview_id)
FROM
    website_pageviews
WHERE
    pageview_url = '/lander-1'
    AND created_at IS NOT NULL 
;

CREATE TEMPORARY TABLE input_bounce_rate1
SELECT    
    website_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page,
    subtable.count_of_pages_viewed
FROM website_pageviews 
    INNER JOIN
        (SELECT -- subquery to calculate the aggregate results (i.e. COUNT of pages viewed in each session)
            website_pageviews.website_session_id,
            COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
        FROM website_pageviews
            INNER JOIN website_sessions
            ON website_sessions.website_session_id = website_pageviews.website_session_id
        WHERE website_pageviews.created_at <  '2012-07-28' 
            AND website_pageviews.website_pageview_id > 23504 -- this restriction comes from the frist query in the exercise 
            AND utm_source = 'gsearch'
            AND utm_campaign = 'nonbrand'
        GROUP BY website_pageviews.website_session_id) subtable
            ON website_pageviews.website_session_id = subtable.website_session_id
WHERE website_pageviews.website_pageview_id IN -- restriction to get only the landing page of each session
    (SELECT 
        MIN(website_pageview_id)
    FROM website_pageviews
    WHERE created_at <  '2012-07-28' AND created_at > '2012-06-19 00:35:54' -- this restriction comes from the first query in the exercise
    GROUP BY website_session_id)
   ;

SELECT *
FROM input_bounce_rate1
;

SELECT
    landing_page,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN count_of_pages_viewed = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
    COUNT(DISTINCT CASE WHEN count_of_pages_viewed = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS bounce_rate 
FROM input_bounce_rate1
GROUP BY 
    landing_page;   
    
-- 43. ASSIGNMENT: Landing page trending analysis
CREATE TEMPORARY TABLE input_bounce_rate2
SELECT    
    website_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page,
    website_pageviews.created_at AS session_created_at,
    subtable.count_of_pages_viewed
FROM website_pageviews 
    INNER JOIN
        (SELECT -- subquery to calculate the aggregate results (i.e. COUNT of pages viewed in each session)
            website_pageviews.website_session_id,
            COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
        FROM website_pageviews
            INNER JOIN website_sessions
            ON website_sessions.website_session_id = website_pageviews.website_session_id
        WHERE website_pageviews.created_at <  '2012-08-31' 
            AND website_pageviews.created_at > '2012-06-01'
            AND utm_source = 'gsearch'
            AND utm_campaign = 'nonbrand'
        GROUP BY website_pageviews.website_session_id) subtable
            ON website_pageviews.website_session_id = subtable.website_session_id
WHERE website_pageviews.website_pageview_id IN -- restriction to get only the landing page of each session
    (SELECT 
        MIN(website_pageview_id)
    FROM website_pageviews
    WHERE created_at <  '2012-08-31' AND created_at > '2012-06-01'
    GROUP BY website_session_id)
   ;
   
SELECT *
FROM input_bounce_rate2
;

SELECT
    YEARWEEK(session_created_at) AS year_week,
    MIN(DATE(session_created_at)) AS week_start_date,
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN count_of_pages_viewed = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
    COUNT(DISTINCT CASE WHEN count_of_pages_viewed = 1 THEN website_session_id ELSE NULL END)*1.0/COUNT(DISTINCT website_session_id) AS bounce_rate,
    COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM input_bounce_rate2
GROUP BY 
    YEARWEEK(session_created_at);   

-- 46. ASSIGNMENT: Bulding Conversion Funnels
-- STEP 1: select all pageviews for relevant sessions
-- STEP 2: identify each pageview as the specific funnel step
-- STEP 3: create the session-level conversion funnel view
-- STEP 4: aggragate the data to assess funnel performance

-- To find that the pages I'll analyze
SELECT 
    utm_source,
    utm_campaign,
    utm_content,
    COUNT(*)
FROM website_sessions
    LEFT JOIN website_pageviews
        ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
    AND website_pageviews.pageview_url = '/lander-1'
GROUP BY 1,2,3
;
SELECT 
    pageview_url,
    COUNT(*)
FROM website_sessions
    LEFT JOIN website_pageviews
        ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
    AND website_sessions.utm_source = 'gsearch'
    AND website_pageviews.pageview_url NOT IN ('/home')
GROUP BY 1
;
/* Pages that I'should focus on based on the query above
('/the-original-mr-fuzzy',
'/thank-you-for-your-order',
'/shipping',
'/products',
'/lander-1',
'/home',
'/cart',
'/billing')

-> Only need to exclude /home  
*/

WITH sessions_to_analyze AS(
SELECT
    website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at AS pageview_created_at,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
    LEFT JOIN website_pageviews
        ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at > '2012-08-05'
    AND website_sessions.created_at < '2012-09-05'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
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
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM sessions_to_analyze
GROUP BY
    website_session_id
)
-- SELECT * FROM session_level_made_it_flags;
SELECT
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END)
        /COUNT(DISTINCT website_session_id) AS lander_clicktrough_rate,    
    COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)
        /COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS products_clicktrough_rate,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
        /COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_clicktrough_rate, 
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
        /COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_clicktrough_rate, 
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
        /COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_clicktrough_rate, 
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
        /COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_clicktrough_rate,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it_flags;

-- 48. ASSIGNMENT: Analyzing Conversion Funnel Tests
-- STEP 1: Find the first website_pageview_id for relevant sessions
    -- That is, the first time /billing-2 was seen-- STEP 2: Identify the landing page of each session 
-- STEP 2: Counting the pageviews for each session, to identify "bounces"
-- STEP 3: Summarizing by couting total sessions and bounced sessions

SELECT 
    MIN(created_at), -- We can use either of these results as the lower limit of period we'll analyse (see both implemented below)
    MIN(website_pageview_id)
FROM
    website_pageviews
WHERE
    pageview_url = '/billing-2'
    AND created_at IS NOT NULL 
;
-- # MIN(created_at), MIN(website_pageview_id)
-- '2012-09-10 00:13:05', '53550'

SELECT 
    pageview_url,
    COUNT(*)
FROM website_pageviews
WHERE website_pageview_id > 53550
    AND created_at < '2012-11-10'
GROUP BY 1;

-- MY ANSWER
 
CREATE TEMPORARY TABLE input_bounce_rate_billing
SELECT    
    website_pageviews.website_session_id,
    website_pageviews.pageview_url AS billing_page,
    subtable.count_of_pages_viewed
FROM website_pageviews 
    INNER JOIN
        (SELECT -- subquery to calculate the aggregate results (i.e. COUNT of pages viewed in each session)
            website_session_id,
            COUNT(website_pageview_id) AS count_of_pages_viewed
        FROM website_pageviews 
        WHERE website_pageview_id >= 53550
            AND created_at < '2012-11-10'
            AND pageview_url IN ('/billing','/billing-2','/thank-you-for-your-order')
        GROUP BY website_session_id) subtable
            ON website_pageviews.website_session_id = subtable.website_session_id
WHERE website_pageview_id IN -- restriction to get only the landing page of each session
    (SELECT 
        MIN(website_pageview_id)
    FROM website_pageviews
    WHERE website_pageview_id >= 53550
            AND created_at < '2012-11-10'
            AND pageview_url IN ('/billing','/billing-2','/thank-you-for-your-order')
    GROUP BY website_session_id)
   ;
 
SELECT
    billing_page,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN count_of_pages_viewed = 2 THEN website_session_id ELSE NULL END) AS orders,
    COUNT(DISTINCT CASE WHEN count_of_pages_viewed = 2 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS billing_to_order_rt 
FROM input_bounce_rate_billing
GROUP BY 
    billing_page;   

-- COURSE Answer
-- In order to identify if the client planced an order they use the ORDERS table instead of thank-you-for-your order page
-- The course solution is more sound and parcimonious
SELECT 
    website_pageviews.website_session_id,
    website_pageviews.pageview_url AS billing_version_seen,
    orders.order_id
FROM website_pageviews
    LEFT JOIN orders
        ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.website_pageview_id >= 53550
    AND website_pageviews.created_at < '2012-11-10'
    AND website_pageviews.pageview_url IN ('/billing','/billing-2');

SELECT
    billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS billing_to_order_rt
FROM(
SELECT 
    website_pageviews.website_session_id,
    website_pageviews.pageview_url AS billing_version_seen,
    orders.order_id
FROM website_pageviews
    LEFT JOIN orders
        ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.website_pageview_id >= 53550
    AND website_pageviews.created_at < '2012-11-10'
    AND website_pageviews.pageview_url IN ('/billing','/billing-2')
) AS billing_sessions_w_orders
GROUP BY 
    billing_version_seen
;







