DROP TABLE IF EXISTS walmart;
SELECT * FROM walmart;

-- Business Problems
-- 1.Find different payment method and number of transactions, number of quantity sold
SELECT payment_method, COUNT(*) AS number_of_transactions, SUM(quantity) AS number_of_quantity_sold
FROM walmart
GROUP BY payment_method;

-- 2.Identify the highest rated category in each branch, displaying the branch, category avg rating
SELECT branch, category, avg_rating FROM 
(
	SELECT branch, category, ROUND(AVG(rating)::NUMERIC,2) AS avg_rating,
		   RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
	FROM walmart
	GROUP BY 1,2
)
WHERE rank = 1;

-- 3.Identify the busiest day for each branch based on the number of transactions
SELECT branch, day_name, no_of_transactions FROM
(
	SELECT branch, TO_CHAR(TO_DATE(date,'DD/MM/YY'), 'Day') AS day_name,
		   COUNT(*) AS no_of_transactions,
		   RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
	FROM walmart
	GROUP BY 1,2
	ORDER BY 1,3 DESC
)
WHERE rank = 1;

-- 4.Calculate the total quantity of items sold per payment method. List payment_method and total_quantity.
SELECT payment_method, SUM(quantity) AS tot_quantity
FROM walmart
GROUP BY 1;

-- 5.Determine the average, minimum and maximum rating of products for each city.
SELECT 	city, ROUND(AVG(rating)::NUMERIC,2) AS avg_rating, MAX(rating) AS max_rating, MIN(rating) AS min_rating
FROM walmart
GROUP BY city;

-- 6.Calculate the total profit for each category by considering total_profit
SELECT category,ROUND(SUM(total)::NUMERIC, 2), ROUND(SUM(total * profit_margin)::NUMERIC, 2) AS profit
FROM walmart
GROUP BY category;

-- 7.Calculate the total profit for each city by considering total_profit
SELECT city,ROUND(SUM(total)::NUMERIC, 2), ROUND(SUM(total * profit_margin)::NUMERIC, 2) AS profit
FROM walmart
GROUP BY city
ORDER BY profit DESC;

-- 8.Determine the most comman payment method for each branch.
WITH cte AS
(
	SELECT branch, payment_method, COUNT(*) AS no_of_transactions,
		   RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
	FROM walmart
	GROUP BY 1,2
)
SELECT branch,payment_method,no_of_transactions
FROM cte 
WHERE rank = 1;

-- 9.Categorize sales into 3 group morning,afternoon and evening.
--   Find out the shift and number of invoices
SELECT branch, 
	   CASE 
	   	   WHEN EXTRACT(HOUR FROM (time::time)) < 12 THEN 'Morning'
		   WHEN EXTRACT(HOUR FROM (time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
		   ELSE 'Evening'
	   END AS shift,
	   COUNT(*) AS no_of_invoices
FROM walmart
GROUP BY 1,2
ORDER BY 1,3 DESC;

-- 10.Identify 5 branch with highest decrease ratio in revenue comapre to last year
WITH revenue_2022 AS
(
	SELECT branch, ROUND(SUM(total):: NUMERIC,2) AS revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
	GROUP BY 1
),
revenue_2023 AS
(
	SELECT branch, ROUND(SUM(total):: NUMERIC,2) AS revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	GROUP BY 1
)

SELECT ls.branch,ls.revenue,cs.revenue,
	   ROUND((ls.revenue - cs.revenue)::NUMERIC / ls.revenue ::NUMERIC * 100,2) AS rev_dec_ratio
FROM revenue_2022 ls
JOIN revenue_2023 cs
ON ls.branch = cs.branch
WHERE ls.revenue > cs.revenue
ORDER BY 4 DESC LIMIT 5;

-- 11.Monthly revenue growth
WITH monthly_revenue AS 
(
    SELECT
        EXTRACT(MONTH FROM TO_DATE(date, 'DD/MM/YY')) AS month,
        ROUND(SUM(total):: NUMERIC,2) AS revenue
    FROM walmart
    GROUP BY EXTRACT(MONTH FROM TO_DATE(date, 'DD/MM/YY'))
)

SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(
        ((revenue - LAG(revenue) OVER (ORDER BY month)) :: NUMERIC
        / LAG(revenue) OVER (ORDER BY month)) :: NUMERIC * 100,
        2
    ) AS growth_percentage
FROM monthly_revenue
ORDER BY month;