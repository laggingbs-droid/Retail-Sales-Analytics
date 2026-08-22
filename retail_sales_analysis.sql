-- ============================================================
-- RETAIL SALES ANALYTICS PROJECT
-- Tools: Excel | MySQL
-- ============================================================
-- Objective:
-- Analyze retail sales data to identify trends in revenue,
-- profitability, customer behavior, store performance,
-- payment methods, and product performance.
-- ============================================================

USE retail_sales_db;


-- ============================================================
-- 1. DATA QUALITY VALIDATION
-- ============================================================

-- Check total number of transactions
SELECT COUNT(*) AS Total_Transactions
FROM transactions;


-- Check for missing values in the transaction table
SELECT
    SUM(TransactionID IS NULL) AS Null_TransactionID,
    SUM(Date IS NULL) AS Null_Date,
    SUM(CustomerID IS NULL) AS Null_CustomerID,
    SUM(ProductID IS NULL) AS Null_ProductID,
    SUM(StoreID IS NULL) AS Null_StoreID,
    SUM(Quantity IS NULL) AS Null_Quantity,
    SUM(Discount IS NULL) AS Null_Discount,
    SUM(PaymentMethod IS NULL) AS Null_PaymentMethod
FROM transactions;


-- Check for duplicate Transaction IDs
SELECT
    TransactionID,
    COUNT(*) AS Occurrence_Count
FROM transactions
GROUP BY TransactionID
HAVING COUNT(*) > 1;


-- Validate quantity and discount ranges
SELECT
    MIN(Quantity) AS Min_Quantity,
    MAX(Quantity) AS Max_Quantity,
    MIN(Discount) AS Min_Discount,
    MAX(Discount) AS Max_Discount
FROM transactions;


-- Check the analysis period
SELECT
    MIN(Date) AS Start_Date,
    MAX(Date) AS End_Date
FROM transactions;
-- ============================================================
-- 2. CATEGORY PERFORMANCE
-- ============================================================

-- Compare revenue, net revenue, profit, and profit margin
-- across product categories.

SELECT
    p.Category,

    ROUND(
        SUM(t.Quantity * p.UnitPrice), 2
    ) AS Gross_Revenue,

    ROUND(
        SUM(t.Quantity * p.UnitPrice * (1 - t.Discount)), 2
    ) AS Net_Revenue,

    ROUND(
        SUM(
            (t.Quantity * p.UnitPrice * (1 - t.Discount))
            - (t.Quantity * p.CostPrice)
        ), 2
    ) AS Net_Profit,

    ROUND(
        SUM(
            (t.Quantity * p.UnitPrice * (1 - t.Discount))
            - (t.Quantity * p.CostPrice)
        )
        /
        SUM(t.Quantity * p.UnitPrice * (1 - t.Discount))
        * 100,
        2
    ) AS Profit_Margin_Percent

FROM transactions t

JOIN products p
    ON t.ProductID = p.ProductID

GROUP BY p.Category

ORDER BY Net_Profit DESC;
-- ============================================================
-- 3. MONTHLY SALES TREND
-- ============================================================

-- Analyze monthly gross revenue across the full dataset.

SELECT
    YEAR(t.Date) AS Sales_Year,
    MONTH(t.Date) AS Sales_Month,

    ROUND(
        SUM(t.Quantity * p.UnitPrice), 2
    ) AS Gross_Revenue

FROM transactions t

JOIN products p
    ON t.ProductID = p.ProductID

GROUP BY
    YEAR(t.Date),
    MONTH(t.Date)

ORDER BY
    Sales_Year,
    Sales_Month;


-- Compare only complete months.
-- Sep-2023 and Sep-2025 are excluded because the dataset
-- contains only partial data for these months.

SELECT
    YEAR(t.Date) AS Sales_Year,
    MONTH(t.Date) AS Sales_Month,

    ROUND(
        SUM(t.Quantity * p.UnitPrice), 2
    ) AS Gross_Revenue

FROM transactions t

JOIN products p
    ON t.ProductID = p.ProductID

WHERE t.Date >= '2023-10-01'
  AND t.Date < '2025-09-01'

GROUP BY
    YEAR(t.Date),
    MONTH(t.Date)

ORDER BY Gross_Revenue DESC;
-- ============================================================
-- 4. STORE PERFORMANCE
-- ============================================================

-- Compare store revenue, profit, transaction volume,
-- and units sold.

SELECT
    s.StoreID,
    s.StoreName,
    s.City,
    s.Region,

    ROUND(
        SUM(t.Quantity * p.UnitPrice), 2
    ) AS Gross_Revenue,

    ROUND(
        SUM(
            (t.Quantity * p.UnitPrice * (1 - t.Discount))
            - (t.Quantity * p.CostPrice)
        ), 2
    ) AS Net_Profit,

    COUNT(*) AS Transaction_Count,

    SUM(t.Quantity) AS Units_Sold

FROM transactions t

JOIN products p
    ON t.ProductID = p.ProductID

JOIN stores s
    ON t.StoreID = s.StoreID

GROUP BY
    s.StoreID,
    s.StoreName,
    s.City,
    s.Region

ORDER BY Gross_Revenue DESC;


-- Average Order Value (AOV) by store

SELECT
    s.StoreID,
    s.StoreName,

    COUNT(DISTINCT t.TransactionID) AS Total_Orders,

    ROUND(
        SUM(t.Quantity * p.UnitPrice)
        / COUNT(DISTINCT t.TransactionID),
        2
    ) AS Average_Order_Value

FROM transactions t

JOIN products p
    ON t.ProductID = p.ProductID

JOIN stores s
    ON t.StoreID = s.StoreID

GROUP BY
    s.StoreID,
    s.StoreName

ORDER BY Average_Order_Value DESC;
-- ============================================================
-- 5. CUSTOMER ANALYSIS
-- ============================================================

-- Compare sales performance by customer gender.

SELECT
    c.Gender,

    COUNT(*) AS Transactions,

    ROUND(
        SUM(t.Quantity * p.UnitPrice), 2
    ) AS Gross_Revenue,

    ROUND(
        SUM(
            (t.Quantity * p.UnitPrice * (1 - t.Discount))
            - (t.Quantity * p.CostPrice)
        ), 2
    ) AS Net_Profit

FROM transactions t

JOIN customers c
    ON t.CustomerID = c.CustomerID

JOIN products p
    ON t.ProductID = p.ProductID

GROUP BY c.Gender

ORDER BY Gross_Revenue DESC;


-- Analyze sales performance across customer age groups.
-- The dataset end date (2025-09-09) is used as the fixed
-- reference date for age calculation to ensure reproducibility.

SELECT
    CASE
        WHEN TIMESTAMPDIFF(
            YEAR, c.BirthDate, '2025-09-09'
        ) BETWEEN 18 AND 25 THEN '18-25'

        WHEN TIMESTAMPDIFF(
            YEAR, c.BirthDate, '2025-09-09'
        ) BETWEEN 26 AND 35 THEN '26-35'

        WHEN TIMESTAMPDIFF(
            YEAR, c.BirthDate, '2025-09-09'
        ) BETWEEN 36 AND 50 THEN '36-50'

        ELSE '50+'
    END AS Age_Group,

    COUNT(*) AS Transactions,

    ROUND(
        SUM(t.Quantity * p.UnitPrice), 2
    ) AS Gross_Revenue,

    ROUND(
        SUM(
            (t.Quantity * p.UnitPrice * (1 - t.Discount))
            - (t.Quantity * p.CostPrice)
        ), 2
    ) AS Net_Profit

FROM transactions t

JOIN customers c
    ON t.CustomerID = c.CustomerID

JOIN products p
    ON t.ProductID = p.ProductID

GROUP BY Age_Group

ORDER BY Gross_Revenue DESC;
-- ============================================================
-- 6. PAYMENT METHOD ANALYSIS
-- ============================================================

-- Compare transaction volume, revenue, and profit
-- across different payment methods.

SELECT
    t.PaymentMethod,

    COUNT(*) AS Transactions,

    ROUND(
        SUM(t.Quantity * p.UnitPrice), 2
    ) AS Gross_Revenue,

    ROUND(
        SUM(
            (t.Quantity * p.UnitPrice * (1 - t.Discount))
            - (t.Quantity * p.CostPrice)
        ), 2
    ) AS Net_Profit

FROM transactions t

JOIN products p
    ON t.ProductID = p.ProductID

GROUP BY t.PaymentMethod

ORDER BY Gross_Revenue DESC;
-- ============================================================
-- 7. PRODUCT REVENUE RANKING
-- ============================================================

-- Rank products based on total gross revenue generated.

SELECT
    p.ProductID,
    p.ProductName,
    p.Category,

    ROUND(
        SUM(t.Quantity * p.UnitPrice), 2
    ) AS Gross_Revenue,

    RANK() OVER (
        ORDER BY SUM(t.Quantity * p.UnitPrice) DESC
    ) AS Revenue_Rank

FROM transactions t

JOIN products p
    ON t.ProductID = p.ProductID

GROUP BY
    p.ProductID,
    p.ProductName,
    p.Category

ORDER BY Revenue_Rank;
