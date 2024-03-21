-- create table
CREATE TABLE asussales (
    ProductID INTEGER,
    Date TIMESTAMP,
    CustomerID INTEGER,
    CampaignID INTEGER,
    Units INTEGER,
    Product VARCHAR(30),
    Category VARCHAR(30),
    Segment VARCHAR(20),
    ManufacturerID INTEGER,
    Manufacturer VARCHAR(255),
    UnitCost NUMERIC(12, 6), -- Adjust precision and scale as needed
    UnitPrice NUMERIC(12, 6), -- Adjust precision and scale as needed
    ZipCode VARCHAR(10),
    EmailName VARCHAR(255),
    City VARCHAR(255),
    State VARCHAR(20),
    Region VARCHAR(30),
    District VARCHAR(30),
    Country VARCHAR(30)
);

-- check the table
SELECT * FROM asussales;

-- focus on our sales
SELECT productid, date, units, unitcost, unitprice
FROM asussales;

-- lets make it as our fact table
CREATE TABLE FactSales AS
SELECT customerid, productid, date, units, unitcost, unitprice
FROM asussales;

-- focus on our first dimension, customer
SELECT customerid, emailname from asussales;

-- try to separate both the email and full name
SELECT 
    SUBSTRING(emailname, POSITION('(' IN emailname) + 1, POSITION(')' IN emailname) - POSITION('(' IN emailname) - 1) AS email,
    SUBSTRING(emailname, POSITION('(' IN emailname) + 1, POSITION('.' IN emailname) - POSITION('(' IN emailname) - 1) AS first_name,
    SUBSTRING(emailname, POSITION('.' IN emailname) + 1, POSITION('@' IN emailname) - POSITION('.' IN emailname) - 1) AS last_name 
FROM asussales;

-- put it all at once, combine both the first and last name into full name and order it by customer id
SELECT DISTINCT customerid, zipcode,
       SUBSTRING(emailname, POSITION('(' IN emailname) + 1, POSITION(')' IN emailname) - POSITION('(' IN emailname) - 1) AS email,
   CONCAT(
        SUBSTRING(emailname, POSITION('(' IN emailname) + 1, POSITION('.' IN emailname) - POSITION('(' IN emailname) - 1),
        ' ', -- This will add a space
	   SUBSTRING(emailname, POSITION('.' IN emailname) + 1, POSITION('@' IN emailname) - POSITION('.' IN emailname) - 1)
    ) AS full_name
FROM asussales
ORDER BY customerid;

-- create our first dimension table
CREATE TABLE DimCustomer AS
SELECT DISTINCT customerid, zipcode,
   SUBSTRING(emailname, POSITION('(' IN emailname) + 1, POSITION(')' IN emailname) - POSITION('(' IN emailname) - 1) AS email,
   CONCAT(
        SUBSTRING(emailname, POSITION('(' IN emailname) + 1, POSITION('.' IN emailname) - POSITION('(' IN emailname) - 1),
        ' ', -- This will add a space here
        SUBSTRING(emailname, POSITION('.' IN emailname) + 1, POSITION('@' IN emailname) - POSITION('.' IN emailname) - 1)
    ) AS full_name
FROM asussales
ORDER BY customerid;

--focus on second dimension, product
SELECT DISTINCT productid, units, product, category, segment, manufacturerid, manufacturer, unitcost, unitprice
FROM asussales;

CREATE TABLE Dimproduct AS
SELECT DISTINCT productid, units, product, category, segment, manufacturerid, manufacturer, unitcost, unitprice
FROM asussales;

-- focus on our third dimension table, Geography
SELECT DISTINCT city, state, region, zipcode, district, country
FROM asussales;

CREATE TABLE DimGeography AS
SELECT DISTINCT city, state, region, zipcode, district, country
FROM asussales;

-- lastly lets do our date dimension
CREATE TABLE DimDate AS
SELECT 
	DISTINCT Date,
	EXTRACT(YEAR FROM date) AS Year,
    EXTRACT(QUARTER FROM date) AS Quarter,
    EXTRACT(MONTH FROM date) AS Month,
    TO_CHAR(date, 'Month') AS MonthName,
    EXTRACT(WEEK FROM date) AS WeekNumber,
    TO_CHAR(date, 'Day') AS DayOfWeek
FROM 
    asussales
ORDER BY Date;

-- lets do a category dimension
select category, segment FROM asussales
GROUP BY category, segment;

CREATE TABLE DimCatSeg AS
select category, segment FROM asussales
GROUP BY category, segment;

ALTER TABLE DimCatSeg
ADD COLUMN surrogate_key SERIAL;

-- create new product dimension table 
select productid, product, manufacturerid, manufacturer, unitcost, unitprice, surrogate_key FROM Dimproduct
INNER JOIN DimCatSeg ON Dimproduct.segment = DimCatSeG.segment AND Dimproduct.category = DimCatSeg.category
GROUP BY productid,product, manufacturerid, manufacturer, unitcost, unitprice, surrogate_key
ORDER BY productid;

CREATE TABLE DimProductNew AS
select productid, product, manufacturerid, manufacturer, unitcost, unitprice, surrogate_key FROM Dimproduct
INNER JOIN DimCatSeg ON Dimproduct.segment = DimCatSeG.segment AND Dimproduct.category = DimCatSeg.category
GROUP BY productid,product, manufacturerid, manufacturer, unitcost, unitprice, surrogate_key
ORDER BY productid;


-- create table for our another fact table, budget
CREATE TABLE FactBudget
 (
	 Category VARCHAR(30),
	 Segment VARCHAR(30),
	 Scenario VARCHAR(30),
	 Date	TIMESTAMP,
	 Value  NUMERIC(12,2)
);

-- now we put the surrogate key to FactBudget and make it as our new table
SELECT scenario, date, value, SURROGATE_KEY 
FROM factbudget 
LEFT JOIN DimCatSeg
	ON factbudget.segment = DimCatSeg.segment
	AND factbudget.category = DimCatSeg.category
ORDER BY date;
	
CREATE TABLE FactBudgetNew AS
SELECT scenario, date, value, SURROGATE_KEY 
FROM factbudget 
LEFT JOIN DimCatSeg
	ON factbudget.segment = DimCatSeg.segment
	AND factbudget.category = DimCatSeg.category
ORDER BY date;

-- next we import all the table to PowerBi