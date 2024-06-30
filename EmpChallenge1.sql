------------------------ WEEK 1 CHALLENGE -------------------------------------

--1. COUNT THE TOTAL ORDERS
--Write a query to count the total number of orders per customer order in desc

SELECT 
    CustomerKey, 
    COUNT([Order Number]) AS TotalOrders
FROM 
    Sales
GROUP BY 
    CustomerKey
ORDER BY 
    TotalOrders DESC;


	--2. LIST OF PRODUCTS
	--Write a query to list of products sold in 2020

SELECT DISTINCT p.ProductKey, p.[Product Name], p.Category
FROM Sales s
JOIN Products p ON s.ProductKey = p.ProductKey
WHERE YEAR(s.[Order Date]) = 2020;


--3. FIND CUSTOMERS IN A SPECIFIC CITY
-- Write a query to find all customer details from California (CA)

SELECT *
FROM Customers
WHERE [State] = 'California';


--4. CALCULATE TOTAL SALES QUANTITY
-- Write a query to calculate the total sales quantity for product 2115.

SELECT ProductKey, SUM(CAST(Quantity AS INT)) AS [Total Quantity]
FROM Sales
WHERE ProductKey = 2115
GROUP BY ProductKey;


--5. STORE INFORMATION RETRIEVAL
--Write a query to retrieve the Top 5 stores with the mostn sales transaction.

SELECT Top 5 StoreKey, COUNT(*) AS Transaction_Count
FROM Sales
GROUP BY StoreKey
ORDER BY Transaction_Count DESC;


