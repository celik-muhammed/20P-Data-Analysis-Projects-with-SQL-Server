USE master;
GO

--SHOW DATABASES
EXEC sp_databases
GO

CREATE DATABASE eCommerceData;
GO

USE eCommerceData;
GO

--import each file from MMSQL OR AZURE DATA STUDIO
--import data(mssql)(exel and csv) - rename from exel data
--[dbo].[cust_dimen], [dbo].[market_fact$], [dbo].[orders_dimen], [dbo].[prod_dimen$], [dbo].[shipping_dimen]

--or wizard(azure data studio)(csv)
--[dbo].[cust_dimen], [dbo].[market_fact], [dbo].[orders_dimen], [dbo].[prod_dimen], [dbo].[shipping_dimen]

--Check each table name 
--then if neccessary chanhange name
--RENAME Table Name [sample_table] to [new_name_table]
/*
--SYNTAX
EXEC sp_rename @objname = N'index_name', @newname = N'new_index_name', @objtype = N'INDEX';
*/
EXEC sp_rename 'market_fact$', 'market_fact';
EXEC sp_rename 'prod_dimen$', 'prod_dimen';
GO

--Look Tables and Diagrams
SELECT * FROM market_fact
SELECT * FROM cust_dimen
SELECT * FROM orders_dimen
SELECT * FROM prod_dimen
SELECT * FROM shipping_dimen
GO

----each id update
--SELECT SUBSTRING('cust_1', 6, LEN('cust_1'));

--cust_dimen with replace
--Check id table cust_dimen, market_fact 
--then if neccessary chanhange data
UPDATE cust_dimen
SET Cust_id=REPLACE(Cust_id, 'Cust_', '')
GO
UPDATE market_fact
SET Cust_id=REPLACE(Cust_id, 'Cust_', '')
GO

--Ord_id with substring
--Check id table orders_dimen, market_fact 
--then if neccessary chanhange data
UPDATE orders_dimen
SET Ord_id=SUBSTRING(Ord_id, 5, LEN(Ord_id))
GO
UPDATE market_fact
SET Ord_id=SUBSTRING(Ord_id, 5, LEN(Ord_id))
GO

--Prod_id
--Check id table prod_dimen, market_fact 
--then if neccessary chanhange data
UPDATE prod_dimen
SET Prod_id=REPLACE(Prod_id, 'Prod_', '')
GO
UPDATE market_fact
SET Prod_id=REPLACE(Prod_id, 'Prod_', '')
GO

--Ship_id
--Check id table shipping_dimen, market_fact 
--then if neccessary chanhange data
UPDATE shipping_dimen
SET Ship_id=REPLACE(Ship_id, 'SHP_', '')
GO
UPDATE market_fact
SET Ship_id=REPLACE(Ship_id, 'SHP_', '')
GO


--CHECK DAY 
--table orders_dimen, shipping_dimen 
--then if neccessary chanhange data

----CHECK DATE
--SELECT ISDATE('28-12-1990');
--SELECT ISDATE('1990-12-28');
--ISDATE(STRING)
SELECT TOP 1 ISDATE(Order_Date) FROM orders_dimen;
SELECT TOP 1 ISDATE(Ship_Date) FROM shipping_dimen;

--CHANGE datedateformat 
--set dateformat ymd
set dateformat dmy
GO

--UPDATE DAY
UPDATE orders_dimen
SET Order_Date=CONVERT(DATE, Order_Date)
GO
ALTER TABLE orders_dimen 
ALTER COLUMN Order_Date DATE
GO

UPDATE shipping_dimen
SET Ship_Date=CAST(Ship_Date as DATE)
GO
ALTER TABLE shipping_dimen 
ALTER COLUMN Ship_Date DATE
GO


--optional code or via visual programme assign pk, fk, not null, identity
--example Cust_id
--first assign Cust_id - not null
ALTER TABLE cust_dimen 
ALTER COLUMN Cust_id INT NOT NULL
GO
ALTER TABLE market_fact 
ALTER COLUMN Cust_id INT NOT NULL
GO

--pk and fk
--first assign Cust_id - pk
ALTER TABLE cust_dimen
ADD CONSTRAINT pk_1 PRIMARY KEY CLUSTERED (Cust_id)
GO
--assign CONSTRAINT
ALTER TABLE market_fact
ADD CONSTRAINT fk_1 FOREIGN KEY (Cust_id) REFERENCES cust_dimen (Cust_id)


--example Ord_id
--first assign Ord_id - not null
ALTER TABLE orders_dimen 
ALTER COLUMN Ord_id INT NOT NULL

ALTER TABLE market_fact 
ALTER COLUMN Ord_id INT NOT NULL
GO

--pk and fk
--first assign Cust_id - pk
ALTER TABLE orders_dimen
ADD CONSTRAINT pk_2 PRIMARY KEY CLUSTERED (Ord_id)
GO
--assign CONSTRAINT
ALTER TABLE market_fact
ADD CONSTRAINT fk_2 FOREIGN KEY (Ord_id) REFERENCES orders_dimen (Ord_id)


--example Prod_id
--first assign Prod_id - not null
ALTER TABLE prod_dimen 
ALTER COLUMN Prod_id INT NOT NULL

ALTER TABLE market_fact 
ALTER COLUMN Prod_id INT NOT NULL
GO

--pk and fk
--first assign Prod_id - pk
ALTER TABLE prod_dimen
ADD CONSTRAINT pk_3 PRIMARY KEY CLUSTERED (Prod_id)
GO
--assign CONSTRAINT
ALTER TABLE market_fact
ADD CONSTRAINT fk_3 FOREIGN KEY (Prod_id) REFERENCES prod_dimen (Prod_id)


--example Ship_id
--first assign Ship_id - not null
ALTER TABLE shipping_dimen 
ALTER COLUMN Ship_id INT NOT NULL

ALTER TABLE market_fact 
ALTER COLUMN Ship_id INT NOT NULL
GO

--pk and fk
--first assign Ship_id - pk
ALTER TABLE shipping_dimen
ADD CONSTRAINT pk_4 PRIMARY KEY CLUSTERED (Ship_id)
GO
--assign CONSTRAINT
ALTER TABLE market_fact
ADD CONSTRAINT fk_4 FOREIGN KEY (Ship_id) REFERENCES shipping_dimen (Ship_id)

--Return the current Primary Key, Foreign Key and Check constraints for the table.  
--https://docs.microsoft.com/en-us/sql/relational-databases/system-compatibility-views/sys-sysobjects-transact-sql?view=sql-server-ver16
SELECT	name, type_desc
		,SCHEMA_NAME(schema_id) AS schema_name		
FROM	sys.objects  
WHERE	parent_object_id = (OBJECT_ID('market_fact'))   
		AND type IN ('C','F', 'PK', 'UQ', 'D'); 


--CREATE CLUSTERED INDEX market_fact-Cust_id
CREATE CLUSTERED INDEX CLS_INX_1 ON market_fact (Cust_id);

--SEE KEYs in TABLE
EXECUTE sp_helpindex market_fact;
GO

--SEE SIZEs in TABLE
EXEC Sp_spaceused market_fact;
GO


--CHECK Tables and Diagrams
SELECT * FROM market_fact
SELECT * FROM cust_dimen
SELECT * FROM orders_dimen
SELECT * FROM prod_dimen
SELECT * FROM shipping_dimen