-- Create Database
CREATE DATABASE DigitalSalesDB;
GO
USE DigitalSalesDB;
GO


-- Create Customer Table
CREATE TABLE tbl_Customer (
	CustomerID INT IDENTITY (1,1) CONSTRAINT PK_tbl_Customer PRIMARY KEY,
	FirstName VARCHAR (100) NOT NULL,
	Gender VARCHAR (100) NOT NULL,
	Country VARCHAR (100) NOT NULL
);
GO

-- Create Product Table
CREATE TABLE tbl_Product (
	ProductID INT IDENTITY(1,1) CONSTRAINT PK_tbl_Product PRIMARY KEY,
	ProductName VARCHAR (100) NOT NULL,
	Category VARCHAR (100) NOT NULL,
	Price DECIMAL (10,2) NOT NULL CONSTRAINT CHK_tbl_Product_Price_Positive CHECK (Price>0)
);
GO

-- Create Marketing Channel Table
CREATE TABLE tbl_MarketingChannel (
	MarketingID INT IDENTITY (1,1) CONSTRAINT PK_tbl_MarketingChannel PRIMARY KEY,
	Platform VARCHAR (100) NOT NULL,
	Channel VARCHAR (100) NOT NULL
);
GO

-- Create Sales Transaction Table
CREATE TABLE tbl_SalesTransaction (
    TransactionID INT IDENTITY(1,1) CONSTRAINT PK_tbl_SalesTransaction PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES tbl_Customer(CustomerID),
    ProductID INT FOREIGN KEY REFERENCES tbl_Product(ProductID),
    MarketingID INT FOREIGN KEY REFERENCES tbl_MarketingChannel(MarketingID),
    TransactionDate DATE NOT NULL,
    Quantity INT NOT NULL CONSTRAINT CHK_tbl_SalesTransaction_Quantity_Positive CHECK (Quantity > 0),
    Revenue DECIMAL(12,2) NOT NULL CONSTRAINT CHK_tbl_SalesTransaction_Revenue_Positive CHECK (Revenue >= 0),
    NPS_Score INT CONSTRAINT CHK_tbl_SalesTransaction_NPS_Valid CHECK (NPS_Score BETWEEN 0 AND 10)
);
GO


-- Create the Staging Table
CREATE TABLE tbl_stgRawData (
	TransactionDate DATE,
    FirstName VARCHAR(100),
    Gender VARCHAR(100),
    ProductName VARCHAR(100),
    Category VARCHAR(100),
    Price DECIMAL(10,2),
    Quantity INT,
    Revenue DECIMAL(12,2),
    Country VARCHAR(100),
    Platform VARCHAR(100),
    MarketingChannel VARCHAR(100),
    NPS_Score INT
);
GO

-- Import the Raw Digital Sales Data
BULK INSERT tbl_stgRawData
FROM 'C:\Users\User\Downloads\Digital Sales - Customer Data.csv'
WITH (
	FIELDTERMINATOR = ';',
	ROWTERMINATOR = '\n',
	FIRSTROW = 2,
	TABLOCK
);
GO

-- Deduplicate and Insert Data into the New Normalized Tables
--Customer Table
INSERT INTO tbl_Customer (FirstName, Gender, Country)
SELECT DISTINCT FirstName, Gender, Country
FROM tbl_stgRawData;

--Product Table
INSERT INTO tbl_Product (ProductName, Category, Price)
SELECT DISTINCT ProductName, Category, Price
FROM tbl_stgRawData;

-- Marketing Channels Table
INSERT INTO tbl_MarketingChannel (Platform, Channel)
SELECT DISTINCT Platform, MarketingChannel
FROM tbl_stgRawData;

-- create Indexes
CREATE NONCLUSTERED INDEX IX_tbl_SalesTransaction_CustomerID
    ON tbl_SalesTransaction (CustomerID);

CREATE NONCLUSTERED INDEX IX_tbl_SalesTransaction_ProductID
    ON tbl_SalesTransaction (ProductID);

CREATE NONCLUSTERED INDEX IX_tbl_SalesTransaction_TransactionDate
    ON tbl_SalesTransaction (TransactionDate);
GO

-- Transaction Table
INSERT INTO tbl_SalesTransaction (
    CustomerID, ProductID, MarketingID, TransactionDate, Quantity, Revenue, NPS_Score
)
SELECT 
    c.CustomerID,
    p.ProductID,
    m.MarketingID,
    s.TransactionDate,
    s.Quantity,
    s.Revenue,
    s.NPS_Score
FROM tbl_stgRawData s
JOIN tbl_Customer c ON s.FirstName = c.FirstName AND s.Gender = c.Gender AND s.Country = c.Country
JOIN tbl_Product p ON s.ProductName = p.ProductName AND s.Category = p.Category AND s.Price = p.Price
JOIN tbl_MarketingChannel m ON s.Platform = m.Platform AND s.MarketingChannel = m.Channel;

SELECT name 
FROM sys.tables;

SELECT *
FROM tbl_stgRawData;

SELECT *
FROM tbl_Customer;

--Customer Per Country
SELECT  
	Country, 
	COUNT(*) AS CustomerCount
FROM tbl_Customer
GROUP BY Country
ORDER BY  CustomerCount DESC;
GO

-- Customer Count Per Gender
SELECT  
	Gender, 
	COUNT(*) AS CustomerCount
FROM tbl_Customer
GROUP BY Gender
ORDER BY  CustomerCount DESC;
GO

--Customers with 0 Transaction
SELECT * 
FROM tbl_Customer 
WHERE CustomerID NOT IN (SELECT DISTINCT CustomerID FROM tbl_SalesTransaction);

--Customer Segmentation
SELECT 
    c.CustomerID,
    c.FirstName,
    c.Gender,
    c.Country,
    COUNT(s.TransactionID) AS TransactionCount,
    SUM(s.Revenue) AS LifetimeValue,
    MAX(s.TransactionDate) AS LastPurchaseDate,
    DATEDIFF(DAY, MAX(s.TransactionDate), GETDATE()) AS DaysSinceLastPurchase,
    AVG(s.NPS_Score * 1.0) AS AvgSatisfaction
FROM tbl_Customer c
JOIN tbl_SalesTransaction s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.Gender, c.Country;

SELECT *
FROM tbl_Product;

--ProductName and Count
SELECT 
	ProductName, 
	COUNT(*) as ProductCount 
FROM tbl_Product
GROUP BY ProductName
-- Top 10 Expensive Products
SELECT TOP 10 
	ProductName, 
	MAX(Price) AS Product_Price
FROM tbl_Product
GROUP BY ProductName
ORDER BY Product_Price DESC;
GO
-- Top 10 Cheapest Products
SELECT TOP 10 
	ProductName, 
	MIN(Price) AS Product_Price
FROM tbl_Product
GROUP BY ProductName
ORDER BY Product_Price;
GO
--Most Priced Categories of Products
SELECT 
	Category, 
	MAX(Price) AS Product_Price
FROM tbl_Product
GROUP BY Category
ORDER BY Product_Price DESC;
GO

--Cheapest Category of Products
SELECT 
	Category, 
	MIN(Price) AS Product_Price
FROM tbl_Product
GROUP BY Category
ORDER BY Product_Price ASC;
GO
SELECT *
FROM tbl_MarketingChannel;

SELECT *
FROM tbl_SalesTransaction;

-- Marketing Channel Per Product
WITH ChannelUsage AS (
    SELECT 
        p.ProductName,
        m.Channel,
        COUNT(*) AS ChannelCount,
        ROW_NUMBER() OVER (
            PARTITION BY p.ProductName 
            ORDER BY COUNT(*) DESC
        ) AS RankPerProduct
    FROM tbl_Product p
    JOIN tbl_SalesTransaction s ON p.ProductID = s.ProductID
    JOIN tbl_MarketingChannel m ON s.MarketingID = m.MarketingID
    GROUP BY p.ProductName, m.Channel
)
SELECT ProductName, Channel, ChannelCount
FROM ChannelUsage
WHERE RankPerProduct = 1
ORDER BY ChannelCount DESC;
GO

-- Most Effective Marketing channel per Revenue
SELECT TOP 5
	m.Channel,
	SUM(s.Revenue) AS TotalRevenue
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s
ON m.MarketingID = s.MarketingID
GROUP BY m.Channel
ORDER BY TotalRevenue DESC;
GO

-- Revenue per Marketing Platform
SELECT
	m.Platform,
	SUM(s.Revenue) AS TotalRevenue
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s
ON m.MarketingID = s.MarketingID
GROUP BY m.Platform
ORDER BY TotalRevenue DESC;
GO

-- Revenue per country
SELECT
    c.Country,
    SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Product p ON s.ProductID = p.ProductID
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY TotalRevenue DESC;
GO

-- View of Revenue Per Product and Country
CREATE VIEW vw_ProductRevenueByCountry AS
SELECT
    p.ProductName,
    c.Country,
    SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Product p ON s.ProductID = p.ProductID
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
GROUP BY p.ProductName, c.Country;
GO
SELECT *
FROM vw_ProductRevenueByCountry;

-- Temp Table
SELECT TOP 5
	p.ProductID, 
	p.ProductName, 
	SUM(s.Revenue) AS TotalRevenue
INTO #TopProducts
FROM tbl_SalesTransaction s
JOIN tbl_Product p
ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalRevenue DESC;

--Top 5 Revenue Generating Products
SELECT TOP 5 
	p.ProductID, 
	p.ProductName, 
	SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Product p
ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalRevenue DESC;

--Product Lifecycle Revenue
SELECT
    p.ProductID,
    p.ProductName,
    FORMAT(s.TransactionDate, 'yyyy-MM') AS SaleMonth,
    SUM(s.Revenue) AS MonthlyRevenue,
    SUM(s.Quantity) AS UnitsSold
FROM tbl_SalesTransaction s
JOIN tbl_Product p ON s.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName, FORMAT(s.TransactionDate, 'yyyy-MM');

-- Top 10 Highest Countries Per Revenue
SELECT TOP 10
    c.Country,
    SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Product p ON s.ProductID = p.ProductID
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY TotalRevenue DESC;
GO

-- Top 10 lowest countries per revenue
SELECT TOP 10
    c.Country,
    SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Product p ON s.ProductID = p.ProductID
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY TotalRevenue ASC;
GO

--Revenue per Country and Platform
SELECT
    c.Country,
    m.Platform,
    SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
JOIN tbl_MarketingChannel m ON s.MarketingID = m.MarketingID
GROUP BY c.Country, m.Platform
ORDER BY TotalRevenue DESC;

--High Performing Marketing Channels by Revenue Contribution
SELECT
    m.Channel,
    COUNT(*) AS TransactionCount,
    SUM(s.Revenue) AS TotalRevenue,
    AVG(s.Revenue) AS AvgRevenuePerTransaction
FROM tbl_SalesTransaction s
JOIN tbl_MarketingChannel m ON s.MarketingID = m.MarketingID
GROUP BY m.Channel
ORDER BY TotalRevenue DESC;

-- Product Cross Sell Opportunities
WITH CustomerProduct AS (
    SELECT CustomerID, ProductID
    FROM tbl_SalesTransaction
    GROUP BY CustomerID, ProductID
),
Pairs AS (
    SELECT 
        cp1.ProductID AS ProductA,
        cp2.ProductID AS ProductB,
        COUNT(*) AS CoPurchaseCount
    FROM CustomerProduct cp1
    JOIN CustomerProduct cp2 ON cp1.CustomerID = cp2.CustomerID AND cp1.ProductID < cp2.ProductID
    GROUP BY cp1.ProductID, cp2.ProductID
)
SELECT 
    p1.ProductName AS ProductA,
    p2.ProductName AS ProductB,
    CoPurchaseCount
FROM Pairs
JOIN tbl_Product p1 ON p1.ProductID = Pairs.ProductA
JOIN tbl_Product p2 ON p2.ProductID = Pairs.ProductB
ORDER BY CoPurchaseCount DESC;

-- Temp Table for Top 10 Highest Selling Products
SELECT top 10
	p.ProductID,
    p.ProductName,
    SUM(s.Revenue) AS TotalRevenue
INTO #TopProducts
FROM tbl_SalesTransaction s
JOIN tbl_Product p 
ON s.ProductID = p.ProductID
GROUP BY p.ProductName, p.ProductID
order by TotalRevenue DESC;

SELECT *
FROM #TopProducts;
GO

--Top 10 Lowest Selling Products
SELECT TOP 10
    p.ProductName,
    SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Product p ON s.ProductID = p.ProductID
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
GROUP BY p.ProductName
order by TotalRevenue ASC;
GO

--Product with no Sales
SELECT * 
FROM tbl_Product 
WHERE ProductID NOT IN (SELECT DISTINCT ProductID FROM tbl_SalesTransaction);
-- Top 5 Most Patronizing Customers
SELECT TOP 5 
    c.FirstName,
    c.Country,
    SUM(s.Revenue) AS TotalSpent
FROM tbl_SalesTransaction s
JOIN tbl_Customer c ON c.CustomerID = s.CustomerID
GROUP BY c.FirstName, c.Country
ORDER BY TotalSpent DESC;

--Monthly Revenue Trend
SELECT 
    FORMAT(TransactionDate, 'yyyy-MM') AS Month,
    SUM(Revenue) AS MonthlyRevenue
FROM tbl_SalesTransaction
GROUP BY FORMAT(TransactionDate, 'yyyy-MM')
ORDER BY Month;


--Product Sales Summary
SELECT
    p.ProductName,
    p.Category,
    COUNT(s.TransactionID) AS TotalSales,
    SUM(s.Quantity) AS TotalUnitsSold,
    SUM(s.Revenue) AS TotalRevenue,
    AVG(CAST(s.NPS_Score AS FLOAT)) AS AvgNPS
FROM tbl_Product p
JOIN tbl_SalesTransaction s ON s.ProductID = p.ProductID
GROUP BY p.ProductName, p.Category;

--NPS Breakdown Per Country and Product
SELECT
    c.Country,
    p.ProductName,
    COUNT(*) AS Responses,
    AVG(CAST(s.NPS_Score AS FLOAT)) AS AvgNPS,
    SUM(CASE WHEN s.NPS_Score >= 9 THEN 1 ELSE 0 END) AS Promoters,
    SUM(CASE WHEN s.NPS_Score BETWEEN 0 AND 6 THEN 1 ELSE 0 END) AS Detractors,
    ROUND((CAST(SUM(CASE WHEN s.NPS_Score >= 9 THEN 1 ELSE 0 END) AS FLOAT) 
          - SUM(CASE WHEN s.NPS_Score BETWEEN 0 AND 6 THEN 1 ELSE 0 END)) 
          / COUNT(*), 2) * 100 AS NPS_Percentage
FROM tbl_SalesTransaction s
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
JOIN tbl_Product p ON s.ProductID = p.ProductID
GROUP BY c.Country, p.ProductName
ORDER BY AvgNPS DESC;


-- Customer Retention and Satisfaction Metrics
SELECT 
    c.FirstName,
    c.Country,
    COUNT(s.TransactionID) AS Transactions,
    AVG(s.NPS_Score * 1.0) AS AvgNPS
FROM tbl_SalesTransaction s
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
GROUP BY c.FirstName, c.Country
HAVING COUNT(s.TransactionID) > 1
ORDER BY Transactions DESC;


--Executive Summary Report (KPI)
CREATE VIEW vw_ExecutiveSummary AS
SELECT
    (SELECT COUNT(*) FROM tbl_Customer) AS TotalCustomers,
    (SELECT COUNT(*) FROM tbl_Product) AS TotalProducts,
    (SELECT COUNT(*) FROM tbl_SalesTransaction) AS TotalTransactions,
    (SELECT SUM(Revenue) FROM tbl_SalesTransaction) AS TotalRevenue,
    (SELECT AVG(NPS_Score * 1.0) FROM tbl_SalesTransaction) AS AvgNPS,
    (SELECT COUNT(DISTINCT Country) FROM tbl_Customer) AS TotalCountries,
    (SELECT COUNT(DISTINCT Platform) FROM tbl_MarketingChannel) AS TotalPlatforms;
GO

SELECT
	s.TransactionDate,
	p.ProductName,
	s.Quantity,
	s.Revenue,
	s.NPS_Score
FROM tbl_SalesTransaction s
JOIN tbl_Product p 
ON s.ProductID = p.ProductID

SELECT
	p.ProductID,
    p.ProductName,
    SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Product p 
ON s.ProductID = p.ProductID
GROUP BY p.ProductName, p.ProductID
order by TotalRevenue DESC;


CREATE PROCEDURE usp_ShowSales
AS
BEGIN
SELECT
    c.FirstName AS CustomerName,
    c.Country,
    p.ProductName,
    p.Category,
    m.Channel,
    s.TransactionDate,
    s.Quantity,
    s.Revenue,
    s.NPS_Score
FROM tbl_SalesTransaction s
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
JOIN tbl_Product p ON s.ProductID = p.ProductID
JOIN tbl_MarketingChannel m ON s.MarketingID = m.MarketingID;
END;
GO

EXECUTE usp_ShowSales;