-- ============================================
-- ENTITY DEFINITIONS & CARDINALITY (STAR SCHEMA)
-- ============================================

-- 1. tbl_Customer (Dimension)
-- Primary Key: CustomerID (INT, IDENTITY)
-- Attributes:
--   - FirstName VARCHAR(100)
--   - Gender VARCHAR(100)
--   - Country VARCHAR(100)

-- 2. tbl_Product (Dimension)
-- Primary Key: ProductID (INT, IDENTITY)
-- Attributes:
--   - ProductName VARCHAR(100)
--   - Category VARCHAR(100)
--   - Price DECIMAL(10,2)

-- 3. tbl_MarketingChannel (Dimension)
-- Primary Key: MarketingID (INT, IDENTITY)
-- Attributes:
--   - Platform VARCHAR(100)
--   - Channel VARCHAR(100)

-- 4. tbl_SalesTransaction (Fact Table)
-- Primary Key: TransactionID (INT, IDENTITY)
-- Foreign Keys:
--   - CustomerID → tbl_Customer(CustomerID)
--   - ProductID → tbl_Product(ProductID)
--   - MarketingID → tbl_MarketingChannel(MarketingID)
-- Attributes:
--   - TransactionDate DATE
--   - Quantity INT
--   - Revenue DECIMAL(12,2)
--   - NPS_Score INT

-- 5. tbl_stgRawData (Staging Table)
-- No Primary Key (used for raw data import and cleansing)

-- ============================================
-- CARDINALITY & RELATIONSHIPS
-- ============================================
-- One-to-Many Relationships:
--   tbl_Customer        1 → N tbl_SalesTransaction
--   tbl_Product         1 → N tbl_SalesTransaction
--   tbl_MarketingChannel 1 → N tbl_SalesTransaction

-- Fact Table:
--   tbl_SalesTransaction is the central fact table, referencing all dimensions.

-- Star Schema Diagram (Textual):
--   tbl_Customer        |
--   tbl_Product         |--- tbl_SalesTransaction (Fact Table)
--   tbl_MarketingChannel|

