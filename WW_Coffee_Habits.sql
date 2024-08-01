/*
CREATED BY: Brandy Nolan
CREATED ON: July 28,2024
DESCRIPTION: EDA of a synthetic dataset, designed to offer a detailed view of global coffee consumption trends.
*/

-- Number of Countries represented. 50
-- SELECT COUNT(DISTINCT `Country`) Total
-- FROM coffee;

-- Top 5 Countries with the highest `Population` from 2020-2022. 
SELECT 
	`Country`,
    SUM(`Population (millions)`) total_population
    FROM coffee
WHERE `Year` BETWEEN 2020 AND 2022
GROUP BY
	`Country`
ORDER BY 2 DESC
LIMIT 5 ;

-- The count and avg_price of each type of coffee consumed in the highest populated Countries from 2020-2022. 
WITH top_pop_cte AS (SELECT *
FROM coffee
WHERE `Country` IN ('Country_3', 'Country_23','Country_47','Country_48','Country_49') AND `Year` BETWEEN 2020 AND 2022
ORDER BY 2
),
coffee_type_cte AS (SELECT 
	`Type of Coffee Consumed`,
    `Year`,
   COUNT(*) coffee_type_count,
   ROUND(avg(`Average Coffee Price (USD per kg)`),2) avg_coffee_price
FROM top_pop_cte
GROUP BY 
	`Type of Coffee Consumed`,
    `Year`
ORDER BY 1,2,3 DESC, 4 DESC
),
elastic_demand_cte AS (SELECT *,
	ROUND(avg_coffee_price - LAG(avg_coffee_price) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`), 2) AS price_change_YoY,
    ROUND(coffee_type_count - LAG(coffee_type_count) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`), 2) AS qauntity_demand_YoY
FROM coffee_type_cte
),
ped_cte AS (SELECT 
	*,
    CASE
    WHEN LAG(coffee_type_count) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`) IS NOT NULL THEN
		ROUND(((coffee_type_count - LAG(coffee_type_count) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`)) / LAG(coffee_type_count) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`)) * 100, 2)
        ELSE NULL
    END AS percentage_change_quantity_YoY,
	CASE
        WHEN LAG(avg_coffee_price) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`) IS NOT NULL THEN
            ROUND(((avg_coffee_price - LAG(avg_coffee_price) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`)) / LAG(avg_coffee_price) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`)) * 100, 2)
        ELSE NULL
    END AS percentage_change_price_YoY,
    CASE
        WHEN LAG(avg_coffee_price) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`) IS NOT NULL THEN
            ROUND(((coffee_type_count - LAG(coffee_type_count) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`)) / LAG(coffee_type_count) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`)) * 100, 2) /
            ROUND(((avg_coffee_price - LAG(avg_coffee_price) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`)) / LAG(avg_coffee_price) OVER (PARTITION BY `Type of Coffee Consumed` ORDER BY `Year`)) * 100, 2)
        ELSE NULL
    END AS price_elasticity_of_demand
FROM elastic_demand_cte
)
SELECT
	`Type of Coffee Consumed`,
    `Year`,
    price_elasticity_of_demand
FROM ped_cte
GROUP BY 
	`Type of Coffee Consumed`,
    `Year`,
	price_elasticity_of_demand;



