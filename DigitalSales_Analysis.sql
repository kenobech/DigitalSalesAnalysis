-- CREATE DATABASE
CREATE DATABASE DigitalSalesDB;
GO
USE DigitalSalesDB;
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

-- Explore the raw Digital Sales Data and Find out if the table is Normalized
---View the whole raw data
SELECT *
FROM tbl_stgRawData;

---Check for repeated Customer info
SELECT
	 FirstName,
	 COUNT(DISTINCT Gender) AS GenderCount,
	 COUNT (DISTINCT Country) AS CountryCount
FROM tbl_stgRawData
GROUP BY FirstName
HAVING COUNT(DISTINCT Gender)>1 AND COUNT(DISTINCT Country)>1;
GO

---Check for repeated Product info
SELECT
	ProductName,
	COUNT(DISTINCT Category) AS CategoryCount,
	COUNT (DISTINCT Price) AS PriceCount
FROM tbl_stgRawData
GROUP BY ProductName
HAVING COUNT(DISTINCT Category) >1 AND COUNT (DISTINCT Price) >1;
GO

---Check Duplicate Marketing Channels
SELECT
	MarketingChannel,
	COUNT(*) AS ChannelCount
FROM tbl_stgRawData
GROUP BY MarketingChannel
HAVING COUNT(*)>1;
GO

---Check Duplicate Platforms
SELECT
	Platform,
	COUNT(*) AS PlatformCount
FROM tbl_stgRawData
GROUP BY Platform
HAVING COUNT(*)>1;
GO

---Platforms that uses more than one MarketingChannel
SELECT
	Platform,
	COUNT(DISTINCT MarketingChannel) AS MarketingChannelCount
FROM tbl_stgRawData
GROUP BY Platform
HAVING COUNT(DISTINCT MarketingChannel)>1;
GO

---MarketingChannels that uses more than one Platform
SELECT
	MarketingChannel,
	COUNT(DISTINCT Platform) AS PlatformCount
FROM tbl_stgRawData
GROUP BY MarketingChannel
HAVING COUNT(DISTINCT Platform)>1;
GO

--CREATE NORMALISED TABLES
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

-- Deduplicate and Insert Data into the New Normalized Tables
--Customer Table
INSERT INTO tbl_Customer (FirstName, Gender, Country)
SELECT DISTINCT FirstName, Gender, Country
FROM tbl_stgRawData;
GO

--Product Table
INSERT INTO tbl_Product (ProductName, Category, Price)
SELECT DISTINCT ProductName, Category, Price
FROM tbl_stgRawData;
GO

-- Marketing Channels Table
INSERT INTO tbl_MarketingChannel (Platform, Channel)
SELECT DISTINCT Platform, MarketingChannel
FROM tbl_stgRawData;
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
GO

-- create Indexes
CREATE NONCLUSTERED INDEX IX_tbl_SalesTransaction_CustomerID
    ON tbl_SalesTransaction (CustomerID);

CREATE NONCLUSTERED INDEX IX_tbl_SalesTransaction_ProductID
    ON tbl_SalesTransaction (ProductID);

CREATE NONCLUSTERED INDEX IX_tbl_SalesTransaction_TransactionDate
    ON tbl_SalesTransaction (TransactionDate);
GO

--CUSTOMER LEVEL ANALYSIS

--Total Customers
SELECT COUNT(DISTINCT CustomerID) AS CustomerCount
FROM tbl_Customer;

--Total Number of Countries Used for Analysis
SELECT COUNT (DISTINCT Country) AS CountryCount
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
WHERE CustomerID NOT IN (SELECT DISTINCT CustomerID FROM tbl_SalesTransaction WHERE CustomerID IS NOT NULL);
GO

SELECT 
	c.* 
FROM tbl_Customer c 
LEFT JOIN tbl_SalesTransaction s 
	ON c.CustomerID = s.CustomerID 
WHERE s.CustomerID IS NULL;
GO

--Repeat Customers
SELECT 
	CustomerID,
	COUNT(*) AS TransactionCount
FROM tbl_SalesTransaction
GROUP BY CustomerID
HAVING COUNT (*) > 1;
--Transactions Per Customer
SELECT
	c.CustomerID,
	c. FirstName,
	COUNT(s.TransactionID) AS TransactionCount
FROM tbl_Customer c
LEFT JOIN tbl_SalesTransaction s
	ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.FirstName;
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
GO

--PRODUCT LEVEL ANALYSIS
-- Product Count
SELECT COUNT (DISTINCT ProductName) AS ProductCount
FROM tbl_Product;

--ProductName and Count
SELECT 
	ProductName, 
	COUNT(*) as ProductCount 
FROM tbl_Product
GROUP BY ProductName
ORDER BY ProductName DESC;
GO

--Total Quantity sold per Product
WITH ProductSales AS (
	SELECT
		p.ProductName,
		SUM (s.Quantity) AS TotalQuantity
FROM tbl_SalesTransaction s
JOIN tbl_Product p
	ON s.ProductID = p.ProductID
GROUP BY p.ProductName
)
SELECT *
FROM  ProductSales;

--Highest And Lowest Quantity of Product Sold

WITH ProductSales AS (
	SELECT
		p.ProductName,
		SUM (s.Quantity) AS TotalQuantity
FROM tbl_SalesTransaction s
JOIN tbl_Product p
	ON s.ProductID = p.ProductID
GROUP BY p.ProductName
)
SELECT *
FROM  ProductSales
WHERE TotalQuantity = (SELECT MAX(TotalQuantity) FROM ProductSales)
	OR TotalQuantity = (SELECT MIN(TotalQuantity) FROM ProductSales);
GO

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

--Max and Min Price of Each Product
SELECT
	 p.ProductName,
	 MAX(p.Price) AS MaxPrice,
	 MIN (p.Price) AS MinPrice
FROM tbl_Product p
JOIN tbl_SalesTransaction s
	ON p.ProductID = s.ProductID
GROUP BY p.ProductName
ORDER BY p.ProductName;
GO

--Products With Extreme Price Fluctuations
WITH PriceExtremes AS (
	SELECT 
		p.ProductName,
		p.Price
	FROM tbl_Product p
	JOIN tbl_SalesTransaction s
		ON p.ProductID = s.ProductID
),
Extremes AS (
	SELECT
		MAX (Price) AS MaxPrice,
		MIN (Price) AS MinPrice
	FROM PriceExtremes
)

SELECT DISTINCT pe.ProductName
FROM PriceExtremes pe, Extremes e
WHERE pe.Price IN (e.MaxPrice, e.MinPrice)
GROUP BY pe.ProductName
HAVING COUNT (DISTINCT pe.Price) = 2;
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

--Revenue Per Product
SELECT DISTINCT 
	p.ProductName, 
	SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Product p
ON p.ProductID = s.ProductID
GROUP BY p.ProductName
ORDER BY TotalRevenue DESC;

--2024 TOTAL REVENUE
SELECT SUM(Revenue) AS TotalRevenue
FROM tbl_SalesTransaction
WHERE YEAR(TransactionDate) = 2024;

-- 2025 TOTAL REVENUE
SELECT SUM(Revenue) AS TotalRevenue
FROM tbl_SalesTransaction
WHERE YEAR(TransactionDate) = 2025;

-- TOTAL REVENUE
SELECT SUM(Revenue) AS TotalRevenue
FROM tbl_SalesTransaction;

--MARKETING LEVEL ANALYSIS
--Marketing Channel Count
SELECT COUNT (DISTINCT Channel) AS ChannelCount
FROM tbl_MarketingChannel;

--Marketing Platform Count
SELECT COUNT (DISTINCT Platform) AS ChannelPlatform
FROM tbl_MarketingChannel;

--Transactions Per Maketing Channel
SELECT 
	m.Channel,
	COUNT(s.TransactionID) AS TotalTransactions
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s
	ON m.MarketingID = s.MarketingID
GROUP BY m.Channel;

--Transactions Per Platform
SELECT
	m.Platform,
	COUNT(s.TransactionID) AS TotalTransactions
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s
	ON m.MarketingID = s.TransactionID
GROUP BY m.Platform;

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
SELECT
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

-- Average NPS score per Marketing Channel
SELECT
	m.Channel,
	AVG(s.NPS_Score) AS AvgNPS
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s
	ON m.MarketingID = s.MarketingID
GROUP BY m.Channel;

--AVG NPS score per Marketing Platform
SELECT
	m.Platform,
	AVG(s.NPS_Score) AS AvgNPS
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s
	ON m.MarketingID = s.MarketingID
GROUP BY m.Platform;

--	 REPORTS AND KPIs
--Daily Transactions
SELECT 
	TransactionDate,
	SUM (Revenue) AS DailyTotal
FROM tbl_SalesTransaction
GROUP BY TransactionDate
ORDER BY TransactionDate;

--Weekly Transaction
SELECT 
	DATEPART (WEEK, TransactionDate) AS WeekNumber,
	YEAR(TransactionDate) AS Year,
	SUM (Revenue) AS DailyTotal
FROM tbl_SalesTransaction
GROUP BY YEAR(TransactionDate), DATEPART (WEEK, TransactionDate)
ORDER BY Year, WeekNumber;

--Monthly Transaction
SELECT
	DATENAME(MONTH,TransactionDate) AS Month,
	MONTH(TransactionDate) AS MonthNumber,
	YEAR(TransactionDate) AS Year,
	SUM (Revenue) AS MonthlyTotal
FROM tbl_SalesTransaction
GROUP BY 
	DATENAME(MONTH,TransactionDate),
	MONTH(TransactionDate),
	YEAR(TransactionDate) 
ORDER BY 
	YEAR,
	MonthNumber;

--Quarterly Revenue
SELECT
	YEAR (TransactionDate) AS YEAR,
	DATEPART (QUARTER, TransactionDate) AS Quarter,
	SUM (Revenue) AS QuarterlyTotal
FROM tbl_SalesTransaction
GROUP BY DATEPART (QUARTER, TransactionDate),YEAR(TransactionDate) 
ORDER BY Quarter, YEAR DESC;

--Yearly Revenue
SELECT
	YEAR (TransactionDate) AS YEAR,
	SUM (Revenue) AS YearlyTotal
FROM tbl_SalesTransaction
GROUP BY YEAR(TransactionDate) 
ORDER BY YEAR DESC;

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
GO

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
GO

--Product with no Sales
SELECT * 
FROM tbl_Product 
WHERE ProductID NOT IN (SELECT DISTINCT ProductID FROM tbl_SalesTransaction);
GO

-- Top 5 Most Patronizing Customers
SELECT TOP 5 
    c.FirstName,
    c.Country,
    SUM(s.Revenue) AS TotalSpent
FROM tbl_SalesTransaction s
JOIN tbl_Customer c ON c.CustomerID = s.CustomerID
GROUP BY c.FirstName, c.Country
ORDER BY TotalSpent DESC;
GO

--Product Sales Summary
SELECT DISTINCT
	p.ProductID,
    p.ProductName,
    COUNT(DISTINCT s.TransactionID) AS TotalSales,
    SUM(s.Quantity) AS TotalUnitsSold,
    SUM(s.Revenue) AS TotalRevenue,
    AVG(CAST(s.NPS_Score AS FLOAT)) AS AvgNPS
FROM tbl_Product p
LEFT JOIN tbl_SalesTransaction s ON s.ProductID = p.ProductID
GROUP BY
	p.ProductID,
	p.ProductName;
GO

SELECT
    p.ProductName,
    MAX(p.Category) AS Category,
    SUM(s.Quantity) AS TotalUnitsSold,
    COUNT(DISTINCT s.TransactionID) AS TotalSales,
    SUM(s.Revenue) AS TotalRevenue,
    AVG(CAST(s.NPS_Score AS FLOAT)) AS AvgNPS
FROM tbl_Product p
JOIN tbl_SalesTransaction s ON s.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY p.ProductName;
GO


--Executive Summary Report (KPI)
CREATE VIEW vw_ExecutiveSummary AS
SELECT
    (SELECT COUNT(DISTINCT CustomerID) FROM tbl_Customer) AS TotalCustomers,
    (SELECT COUNT(DISTINCT ProductName) FROM tbl_Product) AS TotalProducts,
    (SELECT COUNT(DISTINCT TransactionID) FROM tbl_SalesTransaction) AS TotalTransactions,
    (SELECT SUM(Revenue) FROM tbl_SalesTransaction) AS TotalRevenue,
    (SELECT AVG(NPS_Score * 1.0) FROM tbl_SalesTransaction) AS AvgNPS,
    (SELECT COUNT(DISTINCT Country) FROM tbl_Customer) AS TotalCountries,
    (SELECT COUNT(DISTINCT Platform) FROM tbl_MarketingChannel) AS TotalPlatforms,
	(SELECT COUNT (DISTINCT Channel) FROM tbl_MarketingChannel) AS TotalMarketingChannel;
GO
SELECT *
FROM vw_ExecutiveSummary;
GO

--Sales Stored Procedure
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

-- Stored Procedure For Revenue Per Product
CREATE PROCEDURE usp_RevenuePerProduct
AS
BEGIN
SELECT
        p.ProductName,
        SUM(s.Revenue) AS TotalRevenue
    FROM tbl_SalesTransaction s
    JOIN tbl_Product p ON s.ProductID = p.ProductID
    GROUP BY p.ProductName
    ORDER BY TotalRevenue DESC;
END;

--Total Revenue Function
CREATE FUNCTION fn_TotalRevenue()
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TotalRevenue DECIMAL(18, 2);
    SELECT @TotalRevenue = SUM(Revenue)
    FROM tbl_SalesTransaction;
    RETURN @TotalRevenue;
END;

GO