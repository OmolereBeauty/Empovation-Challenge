----------------------------------- WEEK 2 CHALLENGE --------------------------------------
--	1.	Average Price of Products in a Category
--Write a query to find the average unit price of products in each category

SELECT Category, AVG(CAST([Unit Price USD] AS DECIMAL(10, 2))) AS AvgUnitPrice
FROM Products
WHERE ISNUMERIC([Unit Price USD]) = 1 -- Ensure only numeric values are considered
GROUP BY Category;


--	2.	Customer Purchases by Gender
--Write a query to count the number of orders placed by each gender.

SELECT c.Gender, COUNT([Order Number]) AS OrderCount
FROM Customers c
JOIN Sales o ON c.CustomerKey = o.CustomerKey
GROUP BY c.Gender;


--	3.	List of Products Not Sold
--Write a query to list all products that have never been sold.

SELECT p.ProductKey, p.[Product Name]
FROM dbo.Products p
LEFT JOIN dbo.Sales s ON p.ProductKey = s.ProductKey
WHERE s.ProductKey IS NULL;

--	4.	Currency Conversion for Orders
--Write a query to show the total amount in USD, round to 2 decimal point for orders made in other currencies, using the Exchange Rates table to convert the prices.

SELECT s.[Order Number], 
       ROUND(SUM(s.Quantity * TRY_CAST(p.[Unit Price USD] 
AS DECIMAL(10, 2)) * COALESCE(TRY_CAST(er.Exchange AS DECIMAL(10, 2)), 1)), 2) AS TotalAmountUSD
FROM dbo.Sales s
JOIN dbo.Products p ON s.ProductKey = p.ProductKey
LEFT JOIN dbo.Exchange_Rates er ON s.[Currency Code] = er.Currency
GROUP BY s.[Order Number];



