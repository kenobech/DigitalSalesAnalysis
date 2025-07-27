--ENTITY DEFINITIONS
--1. tbl_Customer
--Primary Key: CustomerID

--Attributes: FirstName, Gender, Country

--2. tbl_Product
--Primary Key: ProductID

--Attributes: ProductName, Category, Price

--3. tbl_MarketingChannel
--Primary Key: MarketingID

--Attributes: Platform, Channel

--4. tbl_SalesTransaction
--Primary Key: TransactionID

--Foreign Keys:

--CustomerID → tbl_Customer

--ProductID → tbl_Product

--MarketingID → tbl_MarketingChannel

--Attributes: TransactionDate, Quantity, Revenue, NPS_Score

--5. tbl_stgRawData
--No PrimaryK (staging table)

--Cardinality
| From                                            | To            | Relationship Type                              |
| ----------------------------------------------- | ------------- | ---------------------------------------------- |
| `tbl_Customer` → `tbl_SalesTransaction`         | **1-to-many** | One customer can have many transactions        |             |
| `tbl_Product` → `tbl_SalesTransaction`          | **1-to-many** | One product can appear in many transactions    |             |
| `tbl_MarketingChannel` → `tbl_SalesTransaction` | **1-to-many** | One channel can be linked to many transactions |             |
| `tbl_SalesTransaction`                          | Fact Table    | Many-to-1 to all above                         |             |
