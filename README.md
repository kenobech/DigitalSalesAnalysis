# Digital Sales Database Project

## Project Overview

This project demonstrates the end-to-end design and implementation of a digital sales database solution to support product performance analysis, customer segmentation, and marketing impact assessment. The core objective is to **derive actionable business insights from digital sales data** that can inform product strategy, optimize marketing, and improve customer experience.

## Project Objectives

* Identify high-value markets and marketing platforms to guide product and marketing strategies.
* Analyze product performance by sales volume and revenue.
* Identify high-performing and underperforming marketing platforms and channels.
* Understand geographic trends in customer acquisition and revenue generation.
* Enable data-driven decisions to improve product, marketing, and customer strategies.

## Data Pipeline

1. **Raw Data Ingestion**: A staging table (`tbl_stgRawData`) is used to bulk-import unstructured CSV sales data.
2. **Data Profiling**: SQL queries are used to detect data anomalies like duplicated customers, pricing inconsistencies, and repeated marketing values.
3. **Normalization**: The raw data is decomposed into four main normalized entities:
   
   * Customers
   * Products
   * Marketing Channels
   * Transactions
5. **Referential Integrity**: Keys are introduced for data relationships, ensuring consistency and supporting complex joins.

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
