-- ============================================
-- DIGITAL SALES DATABASE PROJECT - SQL SERVER
-- ============================================

-- 1. DATABASE CREATION
CREATE DATABASE DigitalSalesDB;
GO
USE DigitalSalesDB;
GO

-- 2. STAGING TABLE FOR RAW DATA
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

-- 3. BULK IMPORT RAW DATA
-- (Ensure the file path and permissions are correct)
BULK INSERT tbl_stgRawData
FROM 'C:\Users\User\Downloads\Digital Sales - Customer Data.csv'
WITH (
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2,
    TABLOCK
);
GO

-- 4. DATA PROFILING & ANOMALY DETECTION
-- 4.1. View Raw Data
SELECT * FROM tbl_stgRawData;
GO

-- 4.2. Customer Data Consistency
SELECT FirstName, COUNT(DISTINCT Gender) AS GenderCount, COUNT(DISTINCT Country) AS CountryCount
FROM tbl_stgRawData
GROUP BY FirstName
HAVING COUNT(DISTINCT Gender) > 1 OR COUNT(DISTINCT Country) > 1;
GO

-- 4.3. Product Data Consistency
SELECT ProductName, COUNT(DISTINCT Category) AS CategoryCount, COUNT(DISTINCT Price) AS PriceCount
FROM tbl_stgRawData
GROUP BY ProductName
HAVING COUNT(DISTINCT Category) > 1 OR COUNT(DISTINCT Price) > 1;
GO

-- 4.4. Marketing Channel Consistency
SELECT MarketingChannel, COUNT(*) AS ChannelCount
FROM tbl_stgRawData
GROUP BY MarketingChannel
HAVING COUNT(*) > 1;
GO

-- 4.5. Platform Consistency
SELECT Platform, COUNT(*) AS PlatformCount
FROM tbl_stgRawData
GROUP BY Platform
HAVING COUNT(*) > 1;
GO

-- 4.6. Platform-MarketingChannel Relationship
SELECT Platform, COUNT(DISTINCT MarketingChannel) AS MarketingChannelCount
FROM tbl_stgRawData
GROUP BY Platform
HAVING COUNT(DISTINCT MarketingChannel) > 1;
GO

SELECT MarketingChannel, COUNT(DISTINCT Platform) AS PlatformCount
FROM tbl_stgRawData
GROUP BY MarketingChannel
HAVING COUNT(DISTINCT Platform) > 1;
GO

-- 5. NORMALIZED TABLES
-- 5.1 Customer Table
CREATE TABLE tbl_Customer (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    Gender VARCHAR(100) NOT NULL,
    Country VARCHAR(100) NOT NULL
);
GO

-- 5.2 Product Table
CREATE TABLE tbl_Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL CHECK (Price > 0)
);
GO

-- 5.3 Marketing Table
CREATE TABLE tbl_MarketingChannel (
    MarketingID INT IDENTITY(1,1) PRIMARY KEY,
    Platform VARCHAR(100) NOT NULL,
    Channel VARCHAR(100) NOT NULL
);
GO

-- 5.4 Sales Transaction Table
CREATE TABLE tbl_SalesTransaction (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL FOREIGN KEY REFERENCES tbl_Customer(CustomerID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES tbl_Product(ProductID),
    MarketingID INT NOT NULL FOREIGN KEY REFERENCES tbl_MarketingChannel(MarketingID),
    TransactionDate DATE NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    Revenue DECIMAL(12,2) NOT NULL CHECK (Revenue >= 0),
    NPS_Score INT CHECK (NPS_Score BETWEEN 0 AND 10)
);
GO

-- 6. DEDUPLICATION & DATA INSERTION
-- 6.1. Insert Unique Customers
INSERT INTO tbl_Customer (FirstName, Gender, Country)
SELECT DISTINCT FirstName, Gender, Country
FROM tbl_stgRawData;
GO

-- 6.2. Insert Unique Products
INSERT INTO tbl_Product (ProductName, Category, Price)
SELECT DISTINCT ProductName, Category, Price
FROM tbl_stgRawData;
GO

-- 6.3. Insert Unique Marketing Channels
INSERT INTO tbl_MarketingChannel (Platform, Channel)
SELECT DISTINCT Platform, MarketingChannel
FROM tbl_stgRawData;
GO

-- 6.4. Insert Transactions
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

-- 7. INDEXES FOR PERFORMANCE
CREATE NONCLUSTERED INDEX IX_tbl_SalesTransaction_CustomerID ON tbl_SalesTransaction (CustomerID);
CREATE NONCLUSTERED INDEX IX_tbl_SalesTransaction_ProductID ON tbl_SalesTransaction (ProductID);
CREATE NONCLUSTERED INDEX IX_tbl_SalesTransaction_TransactionDate ON tbl_SalesTransaction (TransactionDate);
GO

-- 8. CUSTOMER LEVEL ANALYSIS
-- 8.1. Total Customers
SELECT COUNT(DISTINCT CustomerID) AS CustomerCount FROM tbl_Customer;
GO

-- 8.2. Customers by Country
SELECT Country, COUNT(*) AS CustomerCount FROM tbl_Customer GROUP BY Country ORDER BY CustomerCount DESC;
GO

-- 8.3. Customers by Gender
SELECT Gender, COUNT(*) AS CustomerCount FROM tbl_Customer GROUP BY Gender ORDER BY CustomerCount DESC;
GO

-- 8.4. Repeat Customers
SELECT CustomerID, COUNT(*) AS TransactionCount FROM tbl_SalesTransaction GROUP BY CustomerID HAVING COUNT(*) > 1;
GO

-- 8.5. Customer Segmentation
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

-- 9. PRODUCT LEVEL ANALYSIS
-- 9.1. Total Products
SELECT COUNT(DISTINCT ProductName) AS ProductCount FROM tbl_Product;
GO

-- 9.2. Product Sales Summary
SELECT 
    p.ProductName,
    SUM(s.Quantity) AS TotalUnitsSold,
    SUM(s.Revenue) AS TotalRevenue,
    AVG(CAST(s.NPS_Score AS FLOAT)) AS AvgNPS
FROM tbl_Product p
LEFT JOIN tbl_SalesTransaction s ON s.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalRevenue DESC;
GO

-- 9.3. Top & Bottom Selling Products
WITH ProductSales AS (
    SELECT p.ProductName, SUM(s.Quantity) AS TotalQuantity
    FROM tbl_SalesTransaction s
    JOIN tbl_Product p ON s.ProductID = p.ProductID
    GROUP BY p.ProductName
)
SELECT * FROM ProductSales WHERE TotalQuantity = (SELECT MAX(TotalQuantity) FROM ProductSales)
   OR TotalQuantity = (SELECT MIN(TotalQuantity) FROM ProductSales);
GO

-- 9.4. Product Price Range
SELECT 
    ProductName,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM tbl_Product
GROUP BY ProductName;
GO

-- 10. MARKETING & PLATFORM ANALYSIS
-- 10.1. Marketing Channel Performance
SELECT 
    m.Channel,
    COUNT(s.TransactionID) AS TotalTransactions,
    SUM(s.Revenue) AS TotalRevenue,
    AVG(s.NPS_Score) AS AvgNPS
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s ON m.MarketingID = s.MarketingID
GROUP BY m.Channel
ORDER BY TotalRevenue DESC;
GO

-- 10.2. Platform Performance
SELECT 
    m.Platform,
    COUNT(s.TransactionID) AS TotalTransactions,
    SUM(s.Revenue) AS TotalRevenue,
    AVG(s.NPS_Score) AS AvgNPS
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s ON m.MarketingID = s.MarketingID
GROUP BY m.Platform
ORDER BY TotalRevenue DESC;
GO

-- 11. REVENUE & GEOGRAPHY ANALYSIS
-- 11.1. Revenue by Country
SELECT 
    c.Country,
    SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY TotalRevenue DESC;
GO

-- 11.2. Revenue by Product and Country (View)
CREATE OR ALTER VIEW vw_ProductRevenueByCountry AS
SELECT
    p.ProductName,
    c.Country,
    SUM(s.Revenue) AS TotalRevenue
FROM tbl_SalesTransaction s
JOIN tbl_Product p ON s.ProductID = p.ProductID
JOIN tbl_Customer c ON s.CustomerID = c.CustomerID
GROUP BY p.ProductName, c.Country;
GO

-- 12. NPS ANALYSIS
-- 12.1. Overall NPS Score
SELECT
    COUNT(*) AS TotalResponses,
    SUM(CASE WHEN NPS_Score BETWEEN 9 AND 10 THEN 1 ELSE 0 END) AS Promoters,
    SUM(CASE WHEN NPS_Score BETWEEN 7 AND 8 THEN 1 ELSE 0 END) AS Passives,
    SUM(CASE WHEN NPS_Score BETWEEN 0 AND 6 THEN 1 ELSE 0 END) AS Detractors,
    ROUND(
        (
            (SUM(CASE WHEN NPS_Score BETWEEN 9 AND 10 THEN 1 ELSE 0 END) -
             SUM(CASE WHEN NPS_Score BETWEEN 0 AND 6 THEN 1 ELSE 0 END)) * 100.0
        ) / NULLIF(COUNT(*), 0), 2
    ) AS OverallNPS
FROM tbl_SalesTransaction;
GO

-- 12.2. NPS Score Per Product
SELECT
    p.ProductName,
    COUNT(*) AS Responses,
    ROUND(
        (
            (SUM(CASE WHEN s.NPS_Score BETWEEN 9 AND 10 THEN 1 ELSE 0 END) -
             SUM(CASE WHEN s.NPS_Score BETWEEN 0 AND 6 THEN 1 ELSE 0 END)) * 100.0
        ) / NULLIF(COUNT(*), 0), 2
    ) AS NPS_Score
FROM tbl_SalesTransaction s
JOIN tbl_Product p ON s.ProductID = p.ProductID
WHERE s.NPS_Score IS NOT NULL
GROUP BY p.ProductName;
GO

-- 12.3. NPS by Channel & Platform
SELECT
    m.Channel,
    AVG(s.NPS_Score) AS AvgNPS
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s ON m.MarketingID = s.MarketingID
GROUP BY m.Channel;
GO

SELECT
    m.Platform,
    AVG(s.NPS_Score) AS AvgNPS
FROM tbl_MarketingChannel m
JOIN tbl_SalesTransaction s ON m.MarketingID = s.MarketingID
GROUP BY m.Platform;
GO

-- 13. REPORTS AND KPIs
-- 13.1. Daily Revenue Trend
SELECT 
    TransactionDate,
    SUM(Revenue) AS DailyTotal
FROM tbl_SalesTransaction
GROUP BY TransactionDate
ORDER BY TransactionDate;
GO

-- 13.2. Weekly Revenue Trend
SELECT
    DATEPART(WEEK, TransactionDate) AS WeekNumber,
    YEAR(TransactionDate) AS Year,
    SUM(Revenue) AS WeeklyTotal
FROM tbl_SalesTransaction
GROUP BY YEAR(TransactionDate), DATEPART(WEEK, TransactionDate)
ORDER BY Year, WeekNumber;
GO

-- 13.3. Monthly Revenue Trend
SELECT
    DATENAME(MONTH, TransactionDate) AS Month,
    MONTH(TransactionDate) AS MonthNumber,
    YEAR(TransactionDate) AS Year,
    SUM(Revenue) AS MonthlyTotal
FROM tbl_SalesTransaction
GROUP BY DATENAME(MONTH, TransactionDate), MONTH(TransactionDate), YEAR(TransactionDate)
ORDER BY Year, MonthNumber;
GO

-- 13.4. Quarterly Revenue Trend
SELECT
    YEAR(TransactionDate) AS Year,
    DATEPART(QUARTER, TransactionDate) AS Quarter,
    SUM(Revenue) AS QuarterlyTotal
FROM tbl_SalesTransaction
GROUP BY YEAR(TransactionDate), DATEPART(QUARTER, TransactionDate)
ORDER BY Year, Quarter;
GO

-- 13.5. Yearly Revenue Trend
SELECT
    YEAR(TransactionDate) AS Year,
    SUM(Revenue) AS YearlyTotal
FROM tbl_SalesTransaction
GROUP BY YEAR(TransactionDate)
ORDER BY Year DESC;
GO

-- 14. EXECUTIVE SUMMARY VIEW
CREATE OR ALTER VIEW vw_ExecutiveSummary AS
SELECT
    (SELECT COUNT(DISTINCT CustomerID) FROM tbl_Customer) AS TotalCustomers,
    (SELECT COUNT(DISTINCT ProductName) FROM tbl_Product) AS TotalProducts,
    (SELECT COUNT(*) FROM tbl_SalesTransaction) AS TotalTransactions,
    (SELECT SUM(Revenue) FROM tbl_SalesTransaction) AS TotalRevenue,
    (SELECT AVG(NPS_Score * 1.0) FROM tbl_SalesTransaction) AS AvgNPS,
    (SELECT COUNT(DISTINCT Country) FROM tbl_Customer) AS TotalCountries,
    (SELECT COUNT(DISTINCT Platform) FROM tbl_MarketingChannel) AS TotalPlatforms,
    (SELECT COUNT(DISTINCT Channel) FROM tbl_MarketingChannel) AS TotalMarketingChannels;
GO

-- 15. STORED PROCEDURES
-- 15.1. Show Sales Procedure
CREATE OR ALTER PROCEDURE usp_ShowSales
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

-- Query: Execute Show Sales Procedure
EXEC usp_ShowSales;
GO

-- 15.2. Revenue Per Product Procedure
CREATE OR ALTER PROCEDURE usp_RevenuePerProduct
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
GO

-- 16. SCALAR FUNCTION
-- 16.1. Total Revenue Function
CREATE OR ALTER FUNCTION fn_TotalRevenue()
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TotalRevenue DECIMAL(18, 2);
    SELECT @TotalRevenue = SUM(Revenue) FROM tbl_SalesTransaction;
    RETURN @TotalRevenue;
END;
GO