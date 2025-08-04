# Digital Sales Database Project

## Overview

This project showcases the end-to-end design and implementation of a digital sales database solution for product performance analysis, customer segmentation, and marketing impact assessment. The primary goal is to **extract actionable business insights from digital sales data** to inform product strategy, optimize marketing, and enhance customer experience.

## Features

- Transaction Date
- Customer Details (First Name, Gender, Country)
- Product Details (Name, Category, Price)
- Quantity & Revenue
- Platform & Marketing Channel
- NPS Score

## Objectives

- Identify high-value markets and marketing platforms.
- Analyze product performance by sales volume and revenue.
- Assess marketing channel and platform effectiveness.
- Uncover geographic trends in customer acquisition and revenue.
- Enable data-driven decisions for product, marketing, and customer strategies.

## Project Structure

- `README.md`
- `DigitalSales_Analysis.sql`
- `DigitalSalesCardinality.sql`
- `Digital Sales - Customer Data.csv`
- `DigitalSalesAnalysis.pbix`

## Setup & Requirements

- SQL Server
- Git (Version Control)
- Microsoft Power BI

## Data Pipeline
1. ** Create DigitalSales Database**: Create the Digital Sales Database

 **For example** :

  ![Create DigitalSalesDB](./Images/Create%20DigitalSales%20Database.png)

2. **Raw Data Ingestion**: Create a staging table (`tbl_stgRawData`) that is used to bulk-import unstructured CSV sales data. Staging table is vital because it ensures data validation and, cleansing, performance optimization, schema flexibility and, monitor incremental loads. In other words, a staging table provides a safe and, efficient zone between raw data ingestion and, final data storage.

**For Example**: 

![Create tbl_stgRawData](./Images/Screenshot%202025-07-31%20112851.png)

3. **Import Data**: Bulk import the CSV data into the staging table.

For example:

![Import Data](./Images/Import%20Raw%20Data.png)

4. **Data Profiling**: SQL queries are used to detect data anomalies like duplicated customers, pricing inconsistencies, and repeated marketing values. Use data from the Staging Table.

For example, the following querries were used to check the integrity of the table and find out whether it is normalised. 

**Repeated customer info** 

![Repeated customer Info](./Images/RepeatedCustomerinfo.png)

**Repeated product info** 

![Repeated Product Info](./Images/RepeatedProductInfo.png)

**Duplicate Platforms** 

![Duplicate Platforms](./Images/DuplicatePlatforms.png)

**Duplicate Marketing Channels** 

![Duplicate Marketing Channels](./Images/DuplicateMarketingChannels.png)


5. **Normalization**: The raw data has customer info, product info, marketing info, sales and transaction info. This means that the raw data needs to be normalised upto 3NF. Therefore, the raw data must be decomposed into four main normalized entities: The new tables are normalised ensuring that each table has a Primary Key (PK) and, where necessary a Foreign Key (FK).
   
   * Customers
   * Products
   * Marketing Channels
   * Transactions

   **Example**:

   ![Customer, Products and, Marketing Table](./Images/Customertable.png)


   ![SalesTransactionTable](./Images/salesTable.png)

6. **Data Deduplication**: Insert data into the newly created normalised tables
  
  ![Customers, Products and, Marketing Table](./Images/Dedup1.png)


  ![SalesTable](./Images/Dedup2.png)


7. **Referential Integrity**: Primary and Secondary Keys are introduced for data relationships, ensuring data consistency, integrity and supporting complex joins.

8. **SQL Analysis**: The following  are a series of SQL scripts used for Analysis

**Customer Level Analysis**

![Customer Level Analysis](./Images/CustomerLevelAnalysis.png)

![Product Level Analysis](./Images/ProductAnalysis.png)

![Revenue Analysis](./Images/Revenueanalysis.png)

![NPS Score](./Images/NPS%20Score.png)

![KPIs](./Images/KPIs.png)

![Stored Procedure](./Images/StoredProcedure.png)

![Stored Function](./Images/Function.png)


## Visualizations
- I built an interactive DigitalSales Dashboard for executive summaries and detailed analysis.

![DigitalSales Dashboard](./Images/DigitalSales%20Dashboard.png)

## Key Analytical Findings

- **KPIs**:  
  - Total Customers: 8,946  
  - Total Revenue: $74.17M  
  - Total Transactions: 294K  
  - Marketing Channels: 8  
  - Platforms: 6

- **Insights**:
  - **Top Revenue Countries**: China, Indonesia, Russia
  - **Best-Selling Products**: Content Calendar Pro, Webinar: Launch Your First Course, Habit Tracker for Creators
  - **Top Marketing Channel**: Affiliate Marketing
  - **Top Platforms**: Teachable, Direct, Shopify
  - **Gender Breakdown**: Male and female customers are nearly equal in revenue contribution.

- **Customer Trends**:
  - Highest customer base: China, Indonesia, Russia
  - Gender distribution: Balanced between male and female; agender least represented
  - 100% conversion rate (all customers completed at least one transaction)

- **Product Performance**:
  - 10 digital products analyzed
  - Top seller: Content Calendar Pro (16,524 units)
  - Lowest seller: AI Course for Beginners (13,991 units)
  - Most products priced at $148 or $149

- **Marketing Insights**:
  - Affiliate marketing generated the highest revenue (~$1.8M)
  - Facebook Ads generated the least (~$1.58M)
  - Best-performing platform: Teachable (~$2.28M)
  - Lowest-performing platform: Gumroad (~$2.03M)

- **Revenue by Geography**:
  - China, Indonesia, Russia lead in customer base and revenue
  - Dominica is the lowest contributor

- **Customer Behavior**:
  - Multiple repeat customers indicate loyalty potential
  - Product pairs show strong cross-sell opportunities

## Entity-Relationship Design

The database uses a star schema:

| From                                          | To        | Type      |
| --------------------------------------------- | --------- | --------- |
| tbl_Customer → tbl_SalesTransaction           | 1-to-Many |
| tbl_Product → tbl_SalesTransaction            | 1-to-Many |
| tbl_MarketingChannel → tbl_SalesTransaction   | 1-to-Many |

`tbl_SalesTransaction` serves as the **Fact Table**, linking dimension tables.

-Here's a simplified ER diagram:
![ER Diagram](./Images/DigitalSalesERD.png)

## Technical Enhancements

- **Stored Procedures**: `usp_ShowSales`, `usp_RevenuePerProduct`
- **Functions**: `fn_TotalRevenue`
- **Views**: `vw_ExecutiveSummary`, `vw_ProductRevenueByCountry`
- **Indexes**: On foreign key fields for optimized query performance

## Recommendations

- **Target High-Revenue Countries**: Focus marketing and product expansion in China, Indonesia, and Russia.
- **Invest in Top Channels and Platforms**: Prioritize Affiliate Marketing and Teachable; consider reallocating budgets from underperforming platforms.
- **Introduce Loyalty Programs**: Reward repeat customers to increase retention.
- **Bundle Complementary Products**: Develop bundled offerings based on co-purchase trends.
- **Reposition Underperforming Products**: Adjust pricing or promotions for items like "AI Course for Beginners."
- **Optimize NPS Feedback Loops**: Use channel- and platform-specific NPS to guide UX improvements.
- **Expand Demographic Data**: Enrich customer profiles for advanced segmentation.

## Summary

This project demonstrates how relational databases can transform messy sales data into actionable insights. Through careful schema design, normalization, analytical reporting, and visualization, businesses gain the tools to make smarter decisions. The analysis identifies revenue drivers, customer trends, and strategies for increased engagement, optimized campaigns, and scalable growth.
