/****************************************
*                                       *
*    SQL SELECT Basics - Part 1         *
*    Part of "SQL In 30" Series         *
*                                       *
****************************************/

-- ============================================
-- SECTION 0: INTRODUCTION
-- ============================================

USE AdventureWorks2025;
GO

-- ============================================
-- SECTION 1: BASIC SELECT & COLUMNS 
-- ============================================

-- 1.1 The Simplest SELECT - Get ALL data
-- WARNING: Avoid SELECT * in production code
SELECT *
FROM Person.Person;

-- Check row count
SELECT COUNT(*) AS TotalRows
FROM Person.Person;
-- Result: 19,972 rows

-- 1.2 Selecting Specific Columns
-- Better performance, clearer intent, future-proof
 SELECT BusinessEntityID
        , FirstName
        , LastName
        , ModifiedDate
  FROM Person.Person;

-- 1.3 Column Aliases
-- more readable, required for expressions
SELECT BusinessEntityID AS ID
       , FirstName AS First
       , LastName AS Last
       , ModifiedDate AS Modified
  FROM Person.Person;

-- Alternative alias syntax (without AS keyword)
SELECT BusinessEntityID ID
       , FirstName First
       , LastName Last
       , ModifiedDate Modified
  FROM Person.Person;

-- 1.4 Using Expressions in SELECT
SELECT BusinessEntityID ID
       , FirstName + ' ' + LastName AS FullName
       , YEAR(ModifiedDate) AS ModifiedYear
  FROM Person.Person;

-- BEST PRACTICE: Format code for readability - one column per line, aligned

-- ============================================
-- SECTION 2: SORTING RESULTS
-- ============================================

/*
ORDER BY Syntax:
SELECT columns
FROM table
ORDER BY column1 [ASC|DESC], column2 [ASC|DESC]...
*/

-- 2.1 Sort by Single Column (Ascending - Default)
  SELECT BusinessEntityID
         , FirstName
         , LastName
         , ModifiedDate
    FROM Person.Person
   ORDER BY LastName;  -- ASC is default, can be omitted

-- Same as above (explicit ASC)
  SELECT BusinessEntityID
         , FirstName
         , LastName
         , ModifiedDate
    FROM Person.Person
   ORDER BY LastName ASC;

-- 2.2 Sort in Descending Order
-- Most recent dates first, highest values first
  SELECT BusinessEntityID
         , FirstName
         , LastName
         , ModifiedDate
    FROM Person.Person
   ORDER BY ModifiedDate DESC;

-- 2.3 Multi-Column Sorting
-- Secondary sort breaks ties in primary sort
SELECT BusinessEntityID
       , FirstName
       , LastName
       , ModifiedDate
    FROM Person.Person
   ORDER BY LastName ASC      -- Primary sort
         , FirstName ASC;     -- Secondary sort (for same LastName)

-- 2.4 Mixed Sorting Directions
-- Each column can have its own sort direction
  SELECT BusinessEntityID
         , FirstName
         , LastName
         , ModifiedDate
    FROM Person.Person
   ORDER BY ModifiedDate DESC  -- Newest first
         , LastName ASC       -- Then alphabetically by last name
         , FirstName ASC;      -- Then by first name

-- 2.5 Sorting by Column Position (Not Recommended)
-- Works but fragile - column order changes break query
  SELECT BusinessEntityID
         , FirstName
         , LastName
         , ModifiedDate
    FROM Person.Person
   ORDER BY 4 DESC
         , 3 ASC;  -- 4=ModifiedDate, 3=LastName

-- BEST PRACTICE: Always use column names, not positions

-- ============================================
-- SECTION 3: LIMITING RESULTS
-- ============================================

-- 3.1 Using TOP to Limit Rows
-- Returns first N rows (after ORDER BY if specified)
  SELECT TOP (10)
         BusinessEntityID
         , FirstName
         , LastName
         , ModifiedDate
    FROM Person.Person
   ORDER BY ModifiedDate DESC;

-- 3.2 TOP without ORDER BY
-- Returns arbitrary rows - not guaranteed order
SELECT TOP (10)
       BusinessEntityID
       , FirstName
       , LastName
  FROM Person.Person
 ORDER BY NEWID();
-- WARNING: Without ORDER BY, results are unpredictable.
-- The behavior is undefined, but it often looks predictable, therefore we use the NEWID() function which introduces a non-deterministic sort 

-- 3.3 TOP with PERCENT
-- Returns top N% of rows
SELECT TOP (1) PERCENT
       BusinessEntityID
       , FirstName
       , LastName
       , ModifiedDate
  FROM Person.Person
 ORDER BY ModifiedDate DESC;

-- Calculate what 1% means
SELECT COUNT(*) * 0.01 AS OnePercentRows
  FROM Person.Person;  -- Approximately 200 rows

-- 3.4 TOP with TIES
-- Includes all rows with same value as last row
  SELECT TOP (20) WITH TIES
         FirstName
         , LastName
         , ModifiedDate
    FROM Person.Person
   ORDER BY ModifiedDate DESC;

 SELECT COUNT(*)
   FROM Person.Person
  WHERE ModifiedDate = '2025-06-29'

-- Compare without WITH TIES
  SELECT TOP (20)
         FirstName
         , LastName
         , ModifiedDate
    FROM Person.Person
   ORDER BY ModifiedDate DESC;

-- ============================================
-- SECTION 4: FILTERING DATA
-- ============================================

/*
WHERE Clause Syntax:
SELECT columns
FROM table
WHERE condition;

Common Operators:
=  (equal)
<> or != (not equal)
>  (greater than)
<  (less than)
>= (greater than or equal)
<= (less than or equal)
*/

-- 4.1 Exact Match Filter
SELECT BusinessEntityID
       , FirstName
       , LastName
       , ModifiedDate
  FROM Person.Person
 WHERE FirstName = 'Rob';

-- Show count
SELECT COUNT(*) AS RobCount
  FROM Person.Person
 WHERE FirstName = 'Rob';

-- 4.2 Numeric Comparisons
-- Equal to
SELECT BusinessEntityID
       , FirstName
       , LastName
  FROM Person.Person
 WHERE BusinessEntityID = 130;

-- Greater than
  SELECT BusinessEntityID
         , FirstName
         , LastName
    FROM Person.Person
   WHERE BusinessEntityID > 130
   ORDER BY BusinessEntityID;

-- Less than
  SELECT TOP (10)
         BusinessEntityID
         , FirstName
         , LastName
    FROM Person.Person
   WHERE BusinessEntityID < 130;

-- 4.3 Pattern Matching with LIKE
-- % = any characters, _ = single character
SELECT BusinessEntityID
       , FirstName
       , LastName
  FROM Person.Person 
 WHERE FirstName LIKE 'Rob%';  -- Starts with "Rob"
--WHERE FirstName LIKE '[R-z]%' 

-- Other LIKE patterns
WHERE FirstName LIKE '%Rob%'   -- Contains "Rob" anywhere
WHERE FirstName LIKE '%Rob'    -- Ends with "Rob"
WHERE FirstName LIKE 'R_b'     -- R, any char, b (like "Rob")
WHERE FirstName LIKE '[A-C]%'  -- Starts with A, B, or C

-- 4.4 Using Functions in WHERE
-- Extract year from date column
SELECT BusinessEntityID
       , FirstName
       , LastName
       , ModifiedDate
  FROM Person.Person
 WHERE YEAR(ModifiedDate) = 2022;

 SELECT BusinessEntityID
       , FirstName
       , LastName
       , ModifiedDate
  FROM Person.Person
 --WHERE YEAR(ModifiedDate) = 2022;
 WHERE ModifiedDate >= '2022-01-01'
 AND ModifiedDate < '2023-01-01'


-- WARNING: Functions on columns prevent index usage
-- Better approach when possible:
WHERE ModifiedDate >= '2011-01-01' 
  AND ModifiedDate < '2012-01-01'

-- 4.5 Combining Conditions with AND
-- ALL conditions must be true
SELECT BusinessEntityID
       , FirstName
       , LastName
       , ModifiedDate
  FROM Person.Person
 WHERE FirstName = 'Rob'
   AND ModifiedDate >= '2022-01-01' 
   AND ModifiedDate < '2023-01-01'


-- Multiple AND conditions
SELECT BusinessEntityID
       , FirstName
       , LastName
       , ModifiedDate
  FROM Person.Person
 WHERE FirstName LIKE 'A%'
   AND LastName LIKE 'A%'
   AND ModifiedDate >= '2022-01-01' 

-- 4.6 Combining Conditions with OR
-- ANY condition can be true
  SELECT BusinessEntityID
         , FirstName
         , LastName
         , ModifiedDate
    FROM Person.Person
   WHERE FirstName = 'Rob'
      OR FirstName = 'Robert'
   ORDER BY FirstName;

-- 4.7 Using IN for Multiple Values
-- Cleaner than multiple OR conditions
  SELECT BusinessEntityID
         , FirstName
         , LastName
    FROM Person.Person
   WHERE FirstName IN ('Rob', 'Robert', 'Roberto', 'Robin')
   ORDER BY FirstName;

-- 4.8 Combining AND/OR with Parentheses
-- Parentheses control evaluation order
SELECT BusinessEntityID
       , FirstName
       , LastName
       , ModifiedDate
  FROM Person.Person
 WHERE FirstName IN ('Rob', 'Robert')
   AND ModifiedDate >= '2022-01-01';

-- 4.9 NULL Handling
-- NULL requires special operators
SELECT BusinessEntityID
       , FirstName
       , MiddleName
       , LastName
  FROM Person.Person
 WHERE MiddleName IS NULL;

-- Has middle name
WHERE MiddleName IS NOT NULL;

-- ============================================
-- SECTION 5: GROUPING & AGGREGATION 
-- ============================================

/*
Common Aggregate Functions:
- COUNT(): Number of rows
- SUM(): Total of numeric values
- AVG(): Average of numeric values
- MIN(): Minimum value
- MAX(): Maximum value
*/

-- 5.1 Simple Aggregation (No GROUP BY needed)
SELECT COUNT(BusinessEntityID) AS TotalPersons
       , MAX(BusinessEntityID)
  FROM Person.Person;

SELECT COUNT(MiddleName) AS PersonsWithMiddleName
       , COUNT(*) AS TotalPersons
       , COUNT(*) - COUNT(MiddleName) AS PersonsWithoutMiddleName
  FROM Person.Person;
-- COUNT(column) excludes NULLs, COUNT(*) includes all rows

-- 5.2 Aggregation with GROUP BY
-- One row per unique FirstName
  SELECT FirstName
         , COUNT(*) AS NameCount
    FROM Person.Person
   WHERE FirstName LIKE 'Rob%'
   GROUP BY FirstName
   ORDER BY NameCount DESC;

-- 5.3 Multiple Aggregations
  SELECT FirstName
         , COUNT(*) AS NameCount
         , MIN(BusinessEntityID) AS FirstID
         , MAX(BusinessEntityID) AS LastID
    FROM Person.Person
   WHERE FirstName LIKE 'Rob%'
   GROUP BY FirstName
   ORDER BY NameCount DESC;

-- 5.4 Grouping by Multiple Columns
  SELECT YEAR(ModifiedDate) AS ModifiedYear
         , MONTH(ModifiedDate) AS ModifiedMonth
         , COUNT(*) AS PersonCount
    FROM Person.Person
   GROUP BY YEAR(ModifiedDate)
         , MONTH(ModifiedDate)
   ORDER BY ModifiedYear DESC
         , ModifiedMonth DESC;

-- 5.5 HAVING Clause - Filtering Groups
-- WHERE filters rows, HAVING filters groups
  SELECT FirstName
         , COUNT(*) AS NameCount
    FROM Person.Person
   WHERE FirstName LIKE 'Rob%'
   GROUP BY FirstName
  HAVING COUNT(*) >= 20  -- Only show names with 20+ occurrences
   ORDER BY NameCount DESC;

-- 5.6 WHERE vs HAVING
-- This query demonstrates the order of operations:
 SELECT FirstName
       , COUNT(*) AS NameCount
    FROM Person.Person
   WHERE LEN(FirstName) >= 4        -- Filter rows before grouping
   GROUP BY FirstName
  HAVING COUNT(*) > 90             -- Filter groups after aggregation
   ORDER BY NameCount DESC;

-- Execution order:
-- 1. FROM - Get table
-- 2. WHERE - Filter rows
-- 3. GROUP BY - Create groups
-- 4. HAVING - Filter groups
-- 5. SELECT - Choose columns
-- 6. ORDER BY - Sort results