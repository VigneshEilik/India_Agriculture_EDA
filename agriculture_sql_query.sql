select * from "Agri";

-----------------------------------------------------------------------------------
---1.Year-wise Trend of Rice Production Across States (Top 3)

WITH Top3_States AS (
    SELECT "State_Name",
           SUM("Rice_Production_1000_Tons") AS total_rice_production
    FROM "Agri"
    GROUP BY "State_Name"
    ORDER BY total_rice_production DESC
    LIMIT 3
)
SELECT a."Year",
       a."State_Name",
       SUM(a."Rice_Production_1000_Tons") AS yearly_rice_production
FROM "Agri" a
JOIN Top3_States t
  ON a."State_Name" = t."State_Name"
GROUP BY a."Year", a."State_Name"
ORDER BY a."Year", yearly_rice_production DESC;

---------------------------------------------------------------------------------
----2.Top 5 Districts by Wheat Yield Increase Over the Last 5 Years

WITH Year_Range AS (
    -- Get the last 5 years available in the dataset
    SELECT MAX("Year") AS max_year,
           MAX("Year") - 4 AS min_year
    FROM "Agri"
),
District_Yield AS (
    -- Get average yield for each district in first and last year
    SELECT a."Dist_Name",
           a."State_Name",
           MIN(CASE WHEN a."Year" = y.min_year THEN a."Wheat_Yield_Kg_Per_Ha" END) AS yield_start,
           MIN(CASE WHEN a."Year" = y.max_year THEN a."Wheat_Yield_Kg_Per_Ha" END) AS yield_end
    FROM "Agri" a
    CROSS JOIN Year_Range y
    WHERE a."Year" BETWEEN y.min_year AND y.max_year
    GROUP BY a."Dist_Name", a."State_Name"
),
Yield_Change AS (
    SELECT "Dist_Name",
           "State_Name",
           (yield_end - yield_start) AS yield_increase
    FROM District_Yield
    WHERE yield_start IS NOT NULL AND yield_end IS NOT NULL
)
SELECT "Dist_Name", "State_Name", yield_increase
FROM Yield_Change
ORDER BY yield_increase DESC
LIMIT 5;

--------------------------------------------------------------------------
----3.States with the Highest Growth in Oilseed Production (5-Year Growth Rate)

WITH Year_Range AS (
    SELECT MAX("Year") AS max_year,
           MAX("Year") - 4 AS min_year
    FROM "Agri"
),
State_Oilseeds AS (
    SELECT a."State_Name",
           SUM(CASE WHEN a."Year" = y.min_year THEN a."Oilseeds_Production_1000_Tons" END) AS prod_start,
           SUM(CASE WHEN a."Year" = y.max_year THEN a."Oilseeds_Production_1000_Tons" END) AS prod_end
    FROM "Agri" a
    CROSS JOIN Year_Range y
    WHERE a."Year" BETWEEN y.min_year AND y.max_year
    GROUP BY a."State_Name"
),
Growth AS (
    SELECT "State_Name",
           prod_start,
           prod_end,
           CASE 
               WHEN prod_start = 0 OR prod_start IS NULL THEN NULL
               ELSE ROUND( ((prod_end - prod_start) / prod_start * 100)::numeric, 2 )
           END AS growth_rate_percent
    FROM State_Oilseeds
)
SELECT "State_Name", prod_start, prod_end, growth_rate_percent
FROM Growth
WHERE growth_rate_percent IS NOT NULL
ORDER BY growth_rate_percent DESC
LIMIT 5;

-------------------------------------------------------------------------
----4.District-wise Correlation Between Area and Production for Major Crops (Rice, Wheat, and Maize)

SELECT "Dist_Name",
       "State_Name",
       corr("Rice_Area_1000_Ha", "Rice_Production_1000_Tons")   AS rice_corr,
       corr("Wheat_Area_1000_Ha", "Wheat_Production_1000_Tons") AS wheat_corr,
       corr("Maize_Area_1000_Ha", "Maize_Production_1000_Tons") AS maize_corr
FROM "Agri"
GROUP BY "Dist_Name", "State_Name"
ORDER BY "State_Name", "Dist_Name";

------------------------------------------------------------------------------
---5.Yearly Production Growth of Cotton in Top 5 Cotton Producing States

WITH yearly_production AS (
    SELECT 
        a."Year",
        a."State_Name",
        SUM(a."Cotton_Production_1000_Tons") AS yearly_cotton_production
    FROM "Agri" a
    WHERE a."State_Name" IN ('Gujarat', 'Maharashtra', 'Punjab', 'Haryana', 'Telangana')
    GROUP BY a."Year", a."State_Name"
),

-- Get the last 5 years available in dataset
last_five_years AS (
    SELECT DISTINCT "Year"
    FROM yearly_production
    ORDER BY "Year" DESC
    LIMIT 5
)

SELECT 
    y."State_Name",
    y."Year",
    y.yearly_cotton_production,
    ROUND(
        (
            (y.yearly_cotton_production - LAG(y.yearly_cotton_production) 
                OVER (PARTITION BY y."State_Name" ORDER BY y."Year")) 
            / NULLIF(LAG(y.yearly_cotton_production) 
                OVER (PARTITION BY y."State_Name" ORDER BY y."Year"), 0)
        )::numeric, 2
    ) AS yoy_growth_percent
FROM yearly_production y
JOIN last_five_years l ON y."Year" = l."Year"
ORDER BY y."State_Name", y."Year";

----------------------------------------------------------------------------------
---6.Districts with the Highest Groundnut Production in 2020

SELECT 
    "Dist_Name",
    "State_Name",
    SUM("Groundnut_Production_1000_Tons") AS total_groundnut_production
FROM "Agri"
WHERE "Year" = 2017
GROUP BY "Dist_Name", "State_Name"
ORDER BY total_groundnut_production DESC
LIMIT 10;

-----------------------------------------------------------------------
---7.Annual Average Maize Yield Across All States

SELECT 
    "Year","State_Name",
    ROUND(AVG("Maize_Yield_Kg_Per_Ha")::numeric, 2) AS avg_maize_yield
FROM "Agri"
GROUP BY "Year","State_Name"
ORDER BY "Year";

--------------------------------------------------------------------------
---8.Total Area Cultivated for Oilseeds in Each State

SELECT 
    "State_Name",
    SUM("Oilseeds_Area_1000_Ha") AS total_oilseeds_area
FROM "Agri"
GROUP BY "State_Name"
ORDER BY total_oilseeds_area DESC;

-----------------------------------------------
---9.Districts with the Highest Rice Yield

SELECT 
    "Dist_Name",
    "State_Name",
    ROUND(AVG("Rice_Yield_Kg_Per_Ha")::numeric, 2) AS avg_rice_yield
FROM "Agri"
GROUP BY "Dist_Name", "State_Name"
ORDER BY avg_rice_yield DESC
LIMIT 10;

----------------------------------------------------------
---10.Compare the Production of Wheat and Rice for the Top 5 States Over 10 Years

WITH top_states AS (
    SELECT 
        "State_Name",
        SUM("Wheat_Production_1000_Tons" + "Rice_Production_1000_Tons") AS total_cereal_production
    FROM "Agri"
    GROUP BY "State_Name"
    ORDER BY total_cereal_production DESC
    LIMIT 5
),

last_10_years AS (
    SELECT DISTINCT "Year"
    FROM "Agri"
    ORDER BY "Year" DESC
    LIMIT 10
),

yearly_production AS (
    SELECT 
        a."Year",
        a."State_Name",
        SUM(a."Rice_Production_1000_Tons") AS rice_production,
        SUM(a."Wheat_Production_1000_Tons") AS wheat_production
    FROM "Agri" a
    JOIN top_states t ON a."State_Name" = t."State_Name"
    JOIN last_10_years y ON a."Year" = y."Year"
    GROUP BY a."Year", a."State_Name"
)

SELECT 
    "State_Name",
    "Year",
    rice_production,
    wheat_production
FROM yearly_production
ORDER BY "State_Name", "Year";

--------------------------------------------------------------------------------
