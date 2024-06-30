--1. Impact of Store Size on Sales Volume
  -- Write a query to analyze whether larger stores (in terms of square meters) have higher sales volumes.
 SELECT 
    CASE 
        WHEN st.[Square Meters] < 500 THEN 'Small'
        WHEN st.[Square Meters] BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Large'
    END AS StoreSizeCategory,
    SUM(s.Quantity * TRY_CAST(p.[Unit Price USD] AS DECIMAL(10, 2))) AS TotalSalesVolume,
    COUNT(s.[Order Number]) AS TotalOrders
FROM dbo.Sales s JOIN dbo.Stores st ON s.StoreKey = st.StoreKey
JOIN dbo.Products p ON s.ProductKey = p.ProductKey
GROUP BY 
    CASE 
        WHEN st.[Square Meters] < 500 THEN 'Small'
        WHEN st.[Square Meters] BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Large' END
ORDER BY 
    StoreSizeCategory;   -- By this result, it shows that larger stores have higher sales volume.



 --2. Customer Segmentation by Purchase Behavior and Demographics
    --Write a query to segment customers into groups based on their purchase behaviors (e.g., total spend, number of orders) and demographics (e.g., state, gender).
	
	SELECT 
    c.State,
    c.Gender,
    c.Name,
    COUNT(s.[Order Number]) AS NumberOfOrders,
    SUM(s.Quantity * TRY_CAST(p.[Unit Cost USD] AS DECIMAL(10, 2))) AS TotalSpend,
    CASE
        WHEN SUM(s.Quantity * TRY_CAST(p.[Unit Cost USD] AS DECIMAL(10, 2))) < 500 THEN 'Low Spender'
        WHEN SUM(s.Quantity * TRY_CAST(p.[Unit Cost USD] AS DECIMAL(10, 2))) BETWEEN 500 AND 1500 THEN 'Medium Spender'
      	ELSE 'High Spender'
    END AS SpendCategory
FROM 
    dbo.Customers c
JOIN 
    dbo.Sales s ON c.CustomerKey = s.CustomerKey
JOIN 
    dbo.Products p ON s.ProductKey = p.ProductKey
GROUP BY 
    c.State, 
    c.Gender, 
    c.Name
ORDER BY 
    c.State, 
    c.Gender, 
    TotalSpend DESC;


--Hint: This will require complex joins, aggregations, and case statements.

 --3. Ranking Stores by Sales Volume
 --Write a query to calculate the total sales volume for each store, then rank stores based on their sales volume.

WITH StoreSales AS (
    SELECT 
        st.StoreKey,
        st.State,
        SUM(s.Quantity * TRY_CAST(p.[Unit Cost USD] AS DECIMAL(10, 2))) AS TotalSalesVolume
    FROM 
        dbo.Sales s
    JOIN 
        dbo.Stores st ON s.StoreKey = st.StoreKey
    JOIN 
        dbo.Products p ON s.ProductKey = p.ProductKey
    GROUP BY 
        st.StoreKey,
        st.State
)
SELECT 
    StoreKey,
    State,
    TotalSalesVolume,
    RANK() OVER (ORDER BY TotalSalesVolume DESC) AS SalesRank
FROM 
    StoreSales
ORDER BY 
    SalesRank;
	

 --4. Running Total of Sales Over Time
 --Write a query to retrieve daily sales volumes, then calculate a running total of sales over time, ordered by date.

WITH DailySales AS (
    SELECT 
        [Order Date],
        SUM(TRY_CAST(Quantity AS DECIMAL(10, 2))) AS DailySalesVolume
    FROM 
        Sales
    GROUP BY 
        [Order Date]
),

-- Let's calculate running total of sales
RunningTotal AS (
    SELECT 
        [Order Date],
        SUM(DailySalesVolume) OVER (ORDER BY [Order Date]) AS RunningTotal
    FROM 
        DailySales
)

-- Let's join daily sales and running total
SELECT 
    ds.[Order Date],
    ds.DailySalesVolume,
    rt.RunningTotal
FROM 
    DailySales ds
JOIN 
    RunningTotal rt ON ds.[Order Date] = rt.[Order Date]
ORDER BY 
    ds.[Order Date];


 --5. Lifetime value (LTV) of customers by country
 --Write a query to calculate the lifetime value of each customer based on their country

WITH CustomerLTV AS (
    SELECT 
        c.Country,
        c.CustomerKey,
        SUM(TRY_CAST(s.Quantity AS DECIMAL(18, 2)) * TRY_CAST(p.[Unit Cost USD] AS DECIMAL(18, 2))) AS TotalSpend
    FROM 
        Customers c
    JOIN 
        Sales s ON c.CustomerKey = s.CustomerKey
    JOIN 
        Products p ON s.ProductKey = p.ProductKey
    GROUP BY 
        c.Country,
        c.CustomerKey
),

-- Average LTV for each country and rank countries
AverageLTV AS (
    SELECT 
        Country,
        AVG(TotalSpend) AS AvgLTV,
        ROW_NUMBER() OVER (ORDER BY AVG(TotalSpend) DESC) AS CountryRank
    FROM 
        CustomerLTV
    GROUP BY 
        Country
)

-- Average LTV and rank countries
SELECT 
    Country,
    AvgLTV,
    CountryRank
FROM 
    AverageLTV
ORDER BY 
    AvgLTV DESC;

 --Hint: The output should include the customer’s country, average LTV for that country, and rank the countries based on the average LTV in descending order.

 
 --Bonus:
 --Customer Lifetime Value
 --Write a query to calculate the lifetime value of each customer based on the total amount they’ve spent.
 
WITH CustomerLTV AS (
    SELECT 
        c.CustomerKey,
        c.Country,
        SUM(TRY_CAST(s.Quantity AS DECIMAL(18, 2)) * TRY_CAST(p.[Unit Cost USD] AS DECIMAL(18, 2))) AS TotalSpend
    FROM 
        Customers c
    JOIN 
        Sales s ON c.CustomerKey = s.CustomerKey
    JOIN 
        Products p ON s.ProductKey = p.ProductKey
    GROUP BY 
        c.CustomerKey,
        c.Country
)

-- LTV for each customer
SELECT 
    CustomerKey,
    Country,
    TotalSpend AS LifetimeValue
FROM 
    CustomerLTV
ORDER BY 
    TotalSpend DESC;
