-- 1. Create the database for the project
DROP DATABASE IF EXISTS online_retail;  -- Remove existing database if any
CREATE DATABASE online_retail;           -- Create a new database named 'online_retail'
USE online_retail;                       -- Set the new database as the current working database

-- 2. Create the retail_cleaned table with proper schema
DROP TABLE IF EXISTS retail_cleaned;    -- Remove existing table if any
CREATE TABLE retail_cleaned (
    InvoiceNo VARCHAR(20),               -- Invoice number for the transaction
    StockCode VARCHAR(20),               -- Product code
    Description VARCHAR(255),            -- Product description
    Quantity INT,                       -- Quantity of product in the transaction
    InvoiceDate DATETIME,                -- Date and time of the invoice
    UnitPrice DECIMAL(10,2),             -- Price per unit of product
    CustomerID INT NULL,                 -- Customer identifier (nullable)
    Country VARCHAR(50)                  -- Country of the customer
);

-- 3. Import the data from CSV into retail_cleaned
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Online Retail.csv'  -- Path to CSV file
INTO TABLE retail_cleaned
CHARACTER SET latin1                     -- Character encoding for the data
FIELDS TERMINATED BY ','                 -- Fields separated by commas
ENCLOSED BY '"'                         -- Fields enclosed in double quotes
LINES TERMINATED BY '\n'                 -- Records separated by newline
IGNORE 1 ROWS                           -- Skip header row
(InvoiceNo, StockCode, Description, Quantity, @InvoiceDate, UnitPrice, @CustomerID, Country)
SET 
    InvoiceDate = STR_TO_DATE(@InvoiceDate, '%d/%m/%Y %H:%i'),  -- Convert string date to DateTime format
    CustomerID = NULLIF(@CustomerID, '');                      -- Convert empty CustomerID to NULL if any

-- 4. Basic Exploration

SELECT * FROM retail_cleaned LIMIT 10;  -- Show first 10 rows to see sample data

SELECT COUNT(*) AS total_rows FROM retail_cleaned;  -- Count total number of rows in dataset

SELECT MIN(InvoiceDate) AS start_date, MAX(InvoiceDate) AS end_date FROM retail_cleaned;  
-- Show earliest and latest invoice date (date range of data)

SELECT COUNT(DISTINCT Country) AS unique_countries FROM retail_cleaned;  
-- Count how many unique countries are in the dataset

-- 5. Revenue Analysis

SELECT ROUND(SUM(Quantity * UnitPrice), 2) AS total_revenue FROM retail_cleaned;  
-- Calculate total revenue generated in dataset

SELECT Country, ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM retail_cleaned 
GROUP BY Country 
ORDER BY revenue DESC 
LIMIT 10;  
-- Show top 10 countries by revenue generated

-- 6. Product Analysis

SELECT Description, SUM(Quantity) AS total_quantity 
FROM retail_cleaned
GROUP BY Description 
ORDER BY total_quantity DESC 
LIMIT 10;  
-- Top 10 products by quantity sold

SELECT Description, ROUND(SUM(Quantity * UnitPrice), 2) AS total_revenue
FROM retail_cleaned 
GROUP BY Description 
ORDER BY total_revenue DESC 
LIMIT 10;  
-- Top 10 products by revenue generated

-- 7. Customer Insights

SELECT COUNT(DISTINCT CustomerID) AS total_customers 
FROM retail_cleaned 
WHERE CustomerID IS NOT NULL;  
-- Count total number of unique customers

SELECT CustomerID, ROUND(SUM(Quantity * UnitPrice), 2) AS total_spent
FROM retail_cleaned 
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID 
ORDER BY total_spent DESC 
LIMIT 10;  
-- Show top 10 customers by total spending

-- 8. Monthly Trends

SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
       ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM retail_cleaned 
GROUP BY month 
ORDER BY month;  
-- Calculate monthly revenue to see sales trend over time

-- 9. Order Behavior

SELECT ROUND(SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value 
FROM retail_cleaned;  
-- Calculate average value per order (total revenue divided by number of unique invoices)

SELECT Country, COUNT(DISTINCT InvoiceNo) AS total_orders
FROM retail_cleaned 
GROUP BY Country 
ORDER BY total_orders DESC 
LIMIT 5;  
-- Show top 5 countries by number of orders placed

-- 10. Cancellation Analysis

SELECT COUNT(*) AS cancelled_orders 
FROM retail_cleaned 
WHERE InvoiceNo LIKE 'C%';  
-- Count number of cancelled orders (invoices starting with 'C')

SELECT ROUND(SUM(Quantity * UnitPrice), 2) AS lost_revenue 
FROM retail_cleaned 
WHERE InvoiceNo LIKE 'C%';  
-- Calculate revenue lost due to cancellations

-- 11. RFM Segmentation

SET @ref_date = (SELECT MAX(InvoiceDate) FROM retail_cleaned);  
-- Define reference date as latest invoice date in dataset

SELECT 
    CustomerID,
    DATEDIFF(@ref_date, MAX(InvoiceDate)) AS Recency,       -- Days since last purchase
    COUNT(DISTINCT InvoiceNo) AS Frequency,                 -- Number of unique purchases
    ROUND(SUM(Quantity * UnitPrice), 2) AS Monetary         -- Total money spent
FROM retail_cleaned 
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID 
ORDER BY Monetary DESC 
LIMIT 20;  
-- Compute Recency, Frequency, Monetary for top 20 customers by spending (RFM segmentation)
