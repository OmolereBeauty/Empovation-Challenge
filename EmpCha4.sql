-- 1.	Year-over-Year Growth in Sales per Category
--Write a query to calculate the total annual sales per product category for the current year and the previous year, and then use window functions to calculate the year-over-year growth percentage.

-- Total Annual Sales per product category for the current year and the previous year
WITH AnnualSales AS (
    SELECT 
        c.Category,
        YEAR(s.[Order Date]) AS SalesYear,
        SUM(TRY_CAST(s.Quantity AS DECIMAL(18, 2)) * TRY_CAST(p.[Unit Cost USD] AS DECIMAL(18, 2))) AS TotalSales
    FROM 
        Sales s
    JOIN 
        Products p ON s.ProductKey = p.ProductKey
    JOIN 
        Categories c ON p.CategoryKey = c.CategoryKey
    GROUP BY 
        c.Category,
        YEAR(s.[Order Date])
),

-- Year-Over-Year growth percentage
YoYGrowth AS (
    SELECT 
        Category,
        SalesYear,
        TotalSales,
        LAG(TotalSales, 1) OVER (PARTITION BY Category ORDER BY SalesYear) AS PreviousYearSales,
        CASE
            WHEN LAG(TotalSales, 1) OVER (PARTITION BY Category ORDER BY SalesYear) IS NULL THEN NULL
            ELSE (TotalSales - LAG(TotalSales, 1) OVER (PARTITION BY Category ORDER BY SalesYear)) * 100.0 / LAG(TotalSales, 1) OVER (PARTITION BY Category ORDER BY SalesYear)
        END AS YoYGrowthPercentage
    FROM 
        AnnualSales
)

-- Final query 
SELECT 
    Category,
    SalesYear,
    TotalSales,
    PreviousYearSales,
    YoYGrowthPercentage
FROM 
    YoYGrowth
ORDER BY 
    Category,
    SalesYear;


-- 2.	-- Calculate each customer’s total purchase amount within each store
WITH CustomerPurchases AS (
    SELECT 
        s.StoreKey,
        s.CustomerKey,
        SUM(TRY_CAST(s.Quantity AS DECIMAL(18, 2)) * TRY_CAST(p.[Unit Cost USD] AS DECIMAL(18, 2))) AS TotalPurchase
    FROM 
        Sales s
    JOIN 
        Products p ON s.ProductKey = p.ProductKey
    GROUP BY 
        s.StoreKey, 
        s.CustomerKey
),

-- Customers' Rank 
CustomerRankings AS (
    SELECT 
        StoreKey,
        CustomerKey,
        TotalPurchase,
        RANK() OVER (PARTITION BY StoreKey ORDER BY TotalPurchase DESC) AS PurchaseRank
    FROM 
        CustomerPurchases
)

-- Final query 
SELECT 
    cr.StoreKey,
    st.State,
    cr.CustomerKey,
    cr.TotalPurchase,
    cr.PurchaseRank
FROM 
    CustomerRankings cr
JOIN 
    Stores st ON cr.StoreKey = st.StoreKey
ORDER BY 
    cr.StoreKey,
    cr.PurchaseRank;

	
-- 3.	Customer Retention Analysis
--Perform a customer retention analysis to determine the percentage of customers who made repeat purchases within three months of their initial purchase. Calculate the percentage of retained customers by gender, age group, and location.

WITH CustomerInitialPurchases AS (
    SELECT 
        CustomerKey, 
        MIN([Order Date]) AS InitialPurchaseDate
    FROM 
        Sales
    GROUP BY 
        CustomerKey
),
CustomerRepeatPurchases AS (
    SELECT 
        s.CustomerKey, 
        COUNT(*) AS RepeatPurchaseCount
    FROM 
        Sales s
        INNER JOIN CustomerInitialPurchases cip 
            ON s.CustomerKey = cip.CustomerKey
            AND s.[Order Date] > cip.InitialPurchaseDate
            AND s.[Order Date] <= DATEADD(month, 3, cip.InitialPurchaseDate)
    GROUP BY 
        s.CustomerKey
),
CustomerRetention AS (
    SELECT 
        c.CustomerKey,
        c.Gender,
        c.Birthday,
        c.City,
        c.State,
        c.Country,
        CASE 
            WHEN crp.RepeatPurchaseCount > 0 THEN 1 
            ELSE 0 
        END AS IsRetained
    FROM 
        Customers c
        LEFT JOIN CustomerRepeatPurchases crp 
            ON c.CustomerKey = crp.CustomerKey
)
SELECT 
    Gender,
    CASE 
        WHEN DATEDIFF(year, Birthday, GETDATE()) < 20 THEN 'Under 20'
        WHEN DATEDIFF(year, Birthday, GETDATE()) BETWEEN 20 AND 29 THEN '20-29'
        WHEN DATEDIFF(year, Birthday, GETDATE()) BETWEEN 30 AND 39 THEN '30-39'
        WHEN DATEDIFF(year, Birthday, GETDATE()) BETWEEN 40 AND 49 THEN '40-49'
        WHEN DATEDIFF(year, Birthday, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END AS AgeGroup,
    City,
    State,
    Country,
    COUNT(CustomerKey) AS TotalCustomers,
    SUM(IsRetained) AS RetainedCustomers,
    (SUM(IsRetained) * 100.0 / COUNT(CustomerKey)) AS RetentionRate
FROM 
    CustomerRetention
GROUP BY 
    Gender,
    CASE 
        WHEN DATEDIFF(year, Birthday, GETDATE()) < 20 THEN 'Under 20'
        WHEN DATEDIFF(year, Birthday, GETDATE()) BETWEEN 20 AND 29 THEN '20-29'
        WHEN DATEDIFF(year, Birthday, GETDATE()) BETWEEN 30 AND 39 THEN '30-39'
        WHEN DATEDIFF(year, Birthday, GETDATE()) BETWEEN 40 AND 49 THEN '40-49'
        WHEN DATEDIFF(year, Birthday, GETDATE()) BETWEEN 50 AND 59 THEN '50-59'
        ELSE '60+'
    END,
    City,
    State,
    Country
ORDER BY 
    Gender, 
    AgeGroup, 
    City, 
    State, 
    Country;


--Hint: The output should include a table with the customer demographics such as gender, age, location and calculated total customer count, retained customer count and the retention rate, in your analysis.
--Additionally, identify any trends or patterns in customer retention based on these demographics.

--TRENDS AND PATTERNS IN CUSTOMER RETENTION BASED ON DEMOGRAPHICS.
--	A.	Retention Rate:
--The overall retention rate is relatively low at around 31.58%.
--Females and males have similar retention rates (31.41% for females and 31.73% for males).

--	B.	Age Range:
--For both genders, younger customers (20-29) have slightly higher retention rates compared to older age groups.
--The highest retention rate is seen in females aged 20-29 (35.47%) and the lowest in females aged 60+ (29.13%).
--For males, the retention rates are more consistent across age ranges, with a slight dip for ages 40-49.

--	C.	Customer Distribution:
--The distribution of total customers is quite similar for both genders, with a slightly higher number of male customers.
--The age range 60+ has the highest number of total customers for both genders.


--4.	Optimize the product mix for each store location to maximize sales revenue.
--Analyze historical sales data to identify the top-selling products in each product category for each store.  Determine the optimal product assortment for each store based on sales performance, product popularity, and profit margins.

--Hint: The output should include a table with the store key, category, product assortment (separated by ‘,’) and the quantities sold.


WITH SalesData AS (
    SELECT
        S.StoreKey,
        C.Category,
        P.[Product Name] AS ProductName,
        SUM(CAST(S.Quantity AS INT)) AS TotalQuantity,
        P.[Unit Price USD],
        (SUM(CAST(S.Quantity AS INT)) * P.[Unit Price USD]) AS TotalSales
    FROM
        Sales S
    JOIN
        Products P ON S.ProductKey = P.ProductKey
    JOIN
        Categories C ON P.SubcategoryKey = C.SubcategoryKey AND P.CategoryKey = C.CategoryKey
    GROUP BY
        S.StoreKey, C.Category, P.[Product Name], P.[Unit Price USD]
),
TopProducts AS (
    SELECT
        StoreKey,
        Category,
        [Product Name],
        [Total Quantity],
        RANK() OVER (PARTITION BY StoreKey, Category ORDER BY TotalQuantity DESC) AS ProductRank
    FROM
        Sales
)
SELECT
    StoreKey,
    Category,
    STUFF((
        SELECT ',' + ProductName
        FROM TopProducts TP
        WHERE TP.StoreKey = T.StoreKey AND TP.Category = T.Category AND TP.ProductRank <= 5
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS ProductAssortment,
    STUFF((
        SELECT ',' + CAST(TotalQuantity AS NVARCHAR)
        FROM TopProducts TP
        WHERE TP.StoreKey = T.StoreKey AND TP.Category = T.Category AND TP.ProductRank <= 5
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS QuantitiesSold
FROM
    TopProducts T
GROUP BY
    StoreKey, Category
ORDER BY
    StoreKey, Category;





	WITH SalesData AS (
    SELECT
        S.StoreKey,
        C.[Category] AS Category,
        P.[Product Name] AS ProductName,
        SUM(CAST(TRY_CAST(S.Quantity AS INT) AS INT)) AS TotalQuantity,
        P.[Unit Price USD] AS UnitPriceUSD,
        (SUM(CAST(TRY_CAST(S.Quantity AS INT) AS INT)) * P.[Unit Price USD]) AS TotalSales
    FROM
        Sales S
    JOIN
        Products P ON S.ProductKey = P.ProductKey
    JOIN
        Categories C ON P.SubcategoryKey = C.SubcategoryKey AND P.CategoryKey = C.CategoryKey
    WHERE
        TRY_CAST(S.Quantity AS INT) IS NOT NULL
    GROUP BY
        S.StoreKey, C.[Category], P.[Product Name], P.[Unit Price USD]
),
TopProducts AS (
    SELECT
        StoreKey,
        Category,
        ProductName,
        TotalQuantity,
        RANK() OVER (PARTITION BY StoreKey, Category ORDER BY TotalQuantity DESC) AS ProductRank
    FROM
        SalesData
)
SELECT
    StoreKey,
    Category,
    STUFF((
        SELECT ',' + ProductName
        FROM TopProducts TP
        WHERE TP.StoreKey = T.StoreKey AND TP.Category = T.Category AND TP.ProductRank <= 5
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS ProductAssortment,
    STUFF((
        SELECT ',' + CAST(TotalQuantity AS NVARCHAR)
        FROM TopProducts TP
        WHERE TP.StoreKey = T.StoreKey AND TP.Category = T.Category AND TP.ProductRank <= 5
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS QuantitiesSold
FROM
    TopProducts T
GROUP BY
    StoreKey, Category
ORDER BY
    StoreKey, Category;
