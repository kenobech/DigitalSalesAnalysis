# Digital Sales Database Project

## Project Overview

This project  demonstrates the end-to-end design and implementation of a digital sales database solution to support product performance analysis, customer segmentation, and marketing impact assessment. The core objective is to **derive actionable business insights from digital sales data** that can inform product strategy, optimize marketing, and improve customer experience.

## Project Features
**TransactionDate**
**FirstName**
**Gender**
**ProductName**
**Category**
**Price**
**Quantity**
**Revenue**
**Country**
**Platform**
**MarketingChannel**
**NPS Score**

## Project Objectives

* Identify high-value markets and marketing platforms to guide product and marketing strategies.
* Analyze product performance by sales volume and revenue.
* Identify high-performing and underperforming marketing platforms and channels.
* Understand geographic trends in customer acquisition and revenue generation.
* Enable data-driven decisions to improve product, marketing, and customer strategies.

## Project Structure
* README.MD
* DigitalSales_Analysis.sql
* DigitalSalesCardinality.sql
* Digital Sales - Customer Data.csv

## Set Up and Requirements

* **SQL Server**

* **Git for Version Control**

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



## Key Analytical Findings

* **Customer Trends**:

  * Highest customer base: China, Indonesia, and Russia.
  * Gender: Males and females were nearly equally distributed. Agender customers were least represented.
  * All customers completed at least one transaction, indicating 100% conversion.

* **Product Performance**:

  * 10 digital products analyzed.
  * Top seller by volume: "Content Calendar Pro" (16,524 units).
  * Lowest seller: "AI Course for Beginners" (13,991 units).
  * Most products priced uniformly at 148 or 149.

* **Marketing Insights**:

  * Affiliate marketing drove the highest revenue (\~1.8M).
  * Facebook Ads generated the least (\~1.58M).
  * Best-performing platform: Teachable (\~2.28M).
  * Lowest-performing platform: Gumroad (\~2.03M).

* **Revenue by Geography**:

  * China, Indonesia, and Russia led in customer base and revenue.
  * Dominica was the lowest revenue contributor.

* **Customer Behavior**:

  * Multiple repeat customers indicate loyalty potential.
  * Product pairs showed strong cross-sell potential.

## KPIs and Reports

* **Executive Summary View**: Combines key metrics — revenue, transactions, NPS, customers, countries, and platforms.

* **Revenue Metrics**:

  * Time-based metrics: daily, weekly, monthly, quarterly, and yearly.
  * Country and product revenue rankings.
  * Repeat purchase and customer lifetime value metrics.

* **Advanced Reports**:

  * Product lifecycle trends (monthly sales and revenue).
  * Co-purchase analysis for cross-sell opportunities.
  * Highest-spending customers.

## Entity-Relationship Design

The database follows a star schema:

| From                                          | To        | Type |
| --------------------------------------------- | --------- | ---- |
| tbl\_Customer → tbl\_SalesTransaction         | 1-to-Many |      |
| tbl\_Product → tbl\_SalesTransaction          | 1-to-Many |      |
| tbl\_MarketingChannel → tbl\_SalesTransaction | 1-to-Many |      |

`tbl_SalesTransaction` acts as the **Fact Table**, centralizing metrics and linking dimension tables.

## Technical Enhancements

* **Stored Procedures**: `usp_ShowSales`, `usp_RevenuePerProduct`
* **Functions**: `fn_TotalRevenue`
* **Views**: `vw_ExecutiveSummary`, `vw_ProductRevenueByCountry`
* **Indexes**: On foreign key fields for optimized query performance

## Real-World Applications

This database solution provides a template for companies that sell digital products (e.g., via Teachable, Gumroad) and want to:

* Identify which products to promote or retire.
* Discover loyal customer segments for targeted campaigns.
* Evaluate ROI of marketing platforms and channels.
* Tailor marketing by country and platform for better conversion.
* Analyze product pairings to inform bundling strategies.

## Recommendations

* **Target High-Revenue Countries**: Focus marketing and product expansion in China, Indonesia, and Russia, as they have the largest customer bases and revenue potential.
* **Invest in Top Channels and Platforms**: Prioritize Affiliate marketing and Teachable for campaigns due to their superior performance. Consider reallocating budgets away from underperforming platforms like Facebook Ads and Gumroad.
* **Introduce Loyalty Programs**: Engage repeat customers through loyalty rewards or exclusive offers to increase retention and advocacy.
* **Bundle Complementary Products**: Use co-purchase trends to develop bundled offerings (e.g., Content Calendar Pro + Productivity Booster Pack).
* **Explore Underperforming Products**: Reposition or improve lower-selling items like "AI Course for Beginners" through pricing adjustments or targeted promotions.
* **Optimize NPS Feedback Loops**: Leverage channel- and platform-specific NPS to prioritize UX improvements and boost satisfaction.
* **Expand Demographic Data**: Enrich customer profiles with behavioral or demographic information to power advanced segmentation.

## Summary

This project demonstrates how relational databases can transform messy sales data into clear, powerful insights. Through careful schema design, normalization, and analytical reporting, businesses gain the tools to make smarter decisions. The analysis not only identifies revenue drivers and customer trends but also offers strategies for increased engagement, optimized campaigns, and scalable growth.
