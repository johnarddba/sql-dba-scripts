/****************************************
*                                       *
*    SQL SELECT Basics - Part 2         *
*    Working with Multiple Tables       *
*                                       *
****************************************/

-- ============================================
-- SECTION 0: INTRODUCTION
-- ============================================

USE AdventureWorks2025;
GO

-- Let's explore our tables first
SELECT COUNT(*) AS PersonCount 
  FROM Person.Person;
-- 19,972 persons

SELECT COUNT(*) AS EmployeeCount
  FROM HumanResources.Employee;
-- 290 employees

-- ============================================
-- SECTION 1: INNER JOIN
-- ============================================

/*
INNER JOIN Syntax:
SELECT columns
FROM Table1
INNER JOIN Table2
  ON Table1.Column = Table2.Column
*/

-- 1.1 Basic INNER JOIN - All Columns
-- EXPLAIN: Returns only rows where BusinessEntityID exists in BOTH tables
    SELECT *
      FROM Person.Person
INNER JOIN HumanResources.Employee
        ON Employee.BusinessEntityID = Person.BusinessEntityID;

-- Check result count
    SELECT COUNT(*) AS MatchedRows
      FROM Person.Person
INNER JOIN HumanResources.Employee
        ON Employee.BusinessEntityID = Person.BusinessEntityID;
-- 290 rows (only employees)

-- 1.2 Using Table Aliases
-- EXPLAIN: Aliases make queries shorter and more readable
    SELECT *
      FROM Person.Person AS p
INNER JOIN HumanResources.Employee AS e
        ON e.BusinessEntityID = p.BusinessEntityID;

-- Even shorter (AS keyword optional)
    SELECT *
      FROM Person.Person p
INNER JOIN HumanResources.Employee e
        ON e.BusinessEntityID = p.BusinessEntityID;

-- 1.3 Selecting Specific Columns
-- EXPLAIN: Always prefix columns with table alias
    SELECT p.BusinessEntityID
           , p.FirstName 
           , p.LastName
           , e.JobTitle
           , e.HireDate
           , e.BirthDate
      FROM Person.Person p
INNER JOIN HumanResources.Employee e
        ON e.BusinessEntityID = p.BusinessEntityID;

-- 1.4 Handling Duplicate Column Names
-- EXPLAIN: BusinessEntityID exists in both tables
    SELECT p.BusinessEntityID AS PersonID
           , e.BusinessEntityID AS EmployeeID
           , p.FirstName
           , p.LastName
           , e.JobTitle
           , e.HireDate
      FROM Person.Person p
INNER JOIN HumanResources.Employee e
        ON e.BusinessEntityID = p.BusinessEntityID;

-- 1.5 Adding WHERE Clause
-- EXPLAIN: Filter AFTER join
    SELECT p.BusinessEntityID
           , p.FirstName
           , p.LastName
           , e.JobTitle
           , e.HireDate
      FROM Person.Person p
INNER JOIN HumanResources.Employee e
        ON e.BusinessEntityID = p.BusinessEntityID
     WHERE e.HireDate >= '2009-01-01' AND e.HireDate < '2010-01-01'
  ORDER BY e.HireDate;

-- 1.6 Joining Multiple Tables
-- EXPLAIN: Chain JOINs together, JOIN order important 
    SELECT p.FirstName
           , p.LastName
           , e.JobTitle
           , d.Name AS DepartmentName
           , d.GroupName
      FROM Person.Person p
INNER JOIN HumanResources.Employee e
        ON e.BusinessEntityID = p.BusinessEntityID
INNER JOIN HumanResources.EmployeeDepartmentHistory edh
        ON edh.BusinessEntityID = e.BusinessEntityID
INNER JOIN HumanResources.Department d
        ON d.DepartmentID = edh.DepartmentID
     WHERE edh.EndDate IS NULL  -- Current department only
  ORDER BY d.Name, p.LastName;

-- 1.7 JOIN with Aggregation
-- EXPLAIN: Count employees per department
    SELECT d.Name AS DepartmentName
           , d.GroupName
           , COUNT(*) AS EmployeeCount
      FROM HumanResources.Employee e
INNER JOIN HumanResources.EmployeeDepartmentHistory edh
        ON edh.BusinessEntityID = e.BusinessEntityID
INNER JOIN HumanResources.Department d
        ON d.DepartmentID = edh.DepartmentID
     WHERE edh.EndDate IS NULL
  GROUP BY d.Name, d.GroupName
  ORDER BY EmployeeCount DESC;

-- ============================================
-- SECTION 2: LEFT/RIGHT OUTER JOIN
-- ============================================

/*
LEFT OUTER JOIN:
- Returns ALL rows from LEFT table
- Matching rows from RIGHT table
- NULL for right table columns when no match
*/

-- 2.1 LEFT OUTER JOIN Example
-- EXPLAIN: Get ALL persons, show employee data if they are employees
         SELECT p.BusinessEntityID
                , p.FirstName
                , p.LastName
                , e.JobTitle
                , e.HireDate
           FROM Person.Person p
LEFT OUTER JOIN HumanResources.Employee e
             ON e.BusinessEntityID = p.BusinessEntityID
       ORDER BY p.BusinessEntityID;

-- Check count
         SELECT COUNT(*) AS TotalRows
           FROM Person.Person p
LEFT OUTER JOIN HumanResources.Employee e
             ON e.BusinessEntityID = p.BusinessEntityID;
-- 19,972 rows (all persons)

-- 2.2 Finding Non-Employees
-- EXPLAIN: LEFT JOIN + WHERE IS NULL = rows only in left table
         SELECT p.BusinessEntityID
                , p.FirstName
                , p.LastName
                , e.JobTitle
           FROM Person.Person p
LEFT OUTER JOIN HumanResources.Employee e
             ON e.BusinessEntityID = p.BusinessEntityID
          WHERE e.BusinessEntityID IS NULL;  -- No employee record

-- Count non-employees
         SELECT COUNT(*) AS NonEmployeeCount
           FROM Person.Person p
LEFT OUTER JOIN HumanResources.Employee e
             ON e.BusinessEntityID = p.BusinessEntityID
          WHERE e.BusinessEntityID IS NULL;
-- 19,682 (19,972 - 290)

-- 2.3 LEFT JOIN with Aggregation
-- EXPLAIN: Count orders per customer (including customers with no orders)
         SELECT c.CustomerID
                , p.FirstName
                , p.LastName
                , COUNT(soh.SalesOrderID) AS OrderCount
                , ISNULL(SUM(soh.TotalDue), 0) AS TotalSales
           FROM Sales.Customer c
LEFT OUTER JOIN Person.Person p
             ON p.BusinessEntityID = c.PersonID
LEFT OUTER JOIN Sales.SalesOrderHeader soh
             ON soh.CustomerID = c.CustomerID
       GROUP BY c.CustomerID, p.FirstName, p.LastName
       ORDER BY OrderCount DESC;

-- 2.4 RIGHT OUTER JOIN
-- EXPLAIN: Opposite of LEFT JOIN - all rows from right table
-- Same result as LEFT JOIN with tables reversed
          SELECT p.BusinessEntityID
                 , p.FirstName
                 , p.LastName
                 , e.JobTitle
                 , e.HireDate
            FROM HumanResources.Employee e
RIGHT OUTER JOIN Person.Person p
              ON e.BusinessEntityID = p.BusinessEntityID
        ORDER BY p.BusinessEntityID;

-- BEST PRACTICE: Use LEFT JOIN instead of RIGHT JOIN
-- Just reverse the table order for better readability

-- 2.5 Practical Example: Find Customers Without Orders
         SELECT c.CustomerID
                , p.FirstName
                , p.LastName
                , soh.TotalDue
           FROM Sales.Customer c
LEFT OUTER JOIN Person.Person p
             ON p.BusinessEntityID = c.CustomerID
LEFT OUTER JOIN Sales.SalesOrderHeader soh
             ON soh.CustomerID = c.CustomerID
          WHERE soh.SalesOrderID IS NULL;  -- No orders

-- ============================================
-- SECTION 3: FULL/CROSS JOIN
-- ============================================

/*
FULL OUTER JOIN:
- ALL rows from BOTH tables
- NULL where no match exists on either side
*/

-- 3.1 Create Sample Tables for Demonstration
CREATE TABLE #Employees (
    EmployeeID INT,
    EmployeeName VARCHAR(50)
);

CREATE TABLE #Projects (
    ProjectID INT,
    EmployeeID INT,
    ProjectName VARCHAR(50)
);

INSERT INTO #Employees VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie');

INSERT INTO #Projects VALUES
(101, 1, 'Website Redesign'),
(102, 2, 'Mobile App'),
(103, 4, 'Data Migration'),    -- EmployeeID 4 doesn't exist
(104, 5, 'Cloud Migration');   -- EmployeeID 5 doesn't exist

-- 3.2 FULL OUTER JOIN Example
-- EXPLAIN: Shows all employees AND all projects
         SELECT e.EmployeeID
                , e.EmployeeName
                , p.ProjectID
                , p.ProjectName
           FROM #Employees e
FULL OUTER JOIN #Projects p
             ON e.EmployeeID = p.EmployeeID;

         SELECT e.EmployeeID
                , e.EmployeeName
                , p.ProjectID
                , p.ProjectName
           FROM #Employees e
           INNER JOIN #Projects p
             ON e.EmployeeID = p.EmployeeID;

/*
Results show:
- Alice with her project
- Bob with his project
- Charlie with no project (NULL)
- Two projects with no employee (NULL)
*/

-- 3.3 Real-World FULL OUTER JOIN
-- EXPLAIN: Find all employees and job candidates
         SELECT p.FirstName
                , p.LastName
                , p.BusinessEntityID AS PersonID
                , e.BusinessEntityID AS EmployeeID
                , jc.BusinessEntityID AS CandidateID
                , e.HireDate
                , jc.JobCandidateID
           FROM Person.Person p
     INNER JOIN HumanResources.Employee e
             ON p.BusinessEntityID = e.BusinessEntityID
FULL OUTER JOIN HumanResources.JobCandidate jc
             ON p.BusinessEntityID = jc.BusinessEntityID;

-- 3.4 CROSS JOIN (Cartesian Product)
-- EXPLAIN: Every row from table1 Ã— every row from table2
-- WARNING: Can create massive result sets!

-- Small example
    SELECT e.EmployeeName
           , p.ProjectName
      FROM #Employees e
CROSS JOIN #Projects p;
-- 3 employees Ã— 4 projects = 12 rows

-- Count potential combinations
SELECT 
    (SELECT COUNT(*) FROM Person.Person) AS PersonCount,
    (SELECT COUNT(*) FROM HumanResources.Employee) AS EmployeeCount,
    (SELECT COUNT(*) FROM HumanResources.Employee) * (SELECT COUNT(*) FROM Person.Person) AS CrossJoinRows;

-- PRACTICAL USE: Generate date ranges, all combinations of options
-- Example: All days in a year for all employees
DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate DATE = '2024-12-31';

;WITH DateRange AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateRange
    WHERE DateValue < @EndDate
)
--SELECT * FROM DateRange
--OPTION (MAXRECURSION 366)

    SELECT --TOP 100
           e.BusinessEntityID
           , d.DateValue
      FROM HumanResources.Employee e
CROSS JOIN DateRange d
   ORDER BY e.BusinessEntityID
     OPTION (MAXRECURSION 366);

-- Cleanup
DROP TABLE #Employees;
DROP TABLE #Projects;

-- ============================================
-- SECTION 4: ADVANCED JOIN SCENARIOS 
-- ============================================

-- 4.1 Self JOIN
-- EXPLAIN: Table joined to itself, useful for hierarchies
    SELECT emp.BusinessEntityID
           , emp_person.FirstName + ' ' + emp_person.LastName AS EmployeeName
           , emp.JobTitle
           , mgr_person.FirstName + ' ' + mgr_person.LastName AS ManagerName
           , mgr.JobTitle AS ManagerTitle
      FROM HumanResources.Employee emp
INNER JOIN Person.Person emp_person
        ON emp.BusinessEntityID = emp_person.BusinessEntityID
 LEFT JOIN HumanResources.Employee mgr
        ON emp.OrganizationNode.GetAncestor(1) = mgr.OrganizationNode
 LEFT JOIN Person.Person mgr_person
        ON mgr.BusinessEntityID = mgr_person.BusinessEntityID
  ORDER BY ManagerName
           , EmployeeName;


-- 4.2 Multiple Join Conditions
-- EXPLAIN: AND in ON clause for complex relationships
    SELECT pv.ProductID
           , p.ProductID
           , p.Name AS ProductName
           , p.ProductNumber
           , pv.BusinessEntityID AS VendorName
      FROM Production.Product p
INNER JOIN Purchasing.ProductVendor pv
        ON pv.ProductID = p.ProductID
       AND pv.AverageLeadTime < 15  -- Additional condition in JOIN
     WHERE p.MakeFlag = 0  -- Buy (not make)
  ORDER BY p.Name;

-- 4.3 JOIN with Subquery
-- EXPLAIN: Join to a derived table
    SELECT e.JobTitle
           , AVG(DATEDIFF(YEAR, e.BirthDate, GETDATE())) AS AvgAge
           , dept_counts.DepartmentCount
      FROM HumanResources.Employee e
INNER JOIN (
      SELECT JobTitle
             , COUNT(edh.DepartmentID) AS DepartmentCount
        FROM HumanResources.Employee emp
  INNER JOIN HumanResources.EmployeeDepartmentHistory edh
          ON emp.BusinessEntityID = edh.BusinessEntityID
       WHERE edh.EndDate IS NULL
    GROUP BY JobTitle
) dept_counts ON dept_counts.JobTitle = e.JobTitle
        GROUP BY e.JobTitle, dept_counts.DepartmentCount
          HAVING COUNT(*) > 1
        ORDER BY DepartmentCount ;

/*
SELECT TOP (1000) [BusinessEntityID]
      ,[DepartmentID]
      ,[ShiftID]
      ,[StartDate]
      ,[EndDate]
      ,[ModifiedDate]
  FROM [AdventureWorks2025].[HumanResources].[EmployeeDepartmentHistory]
  where DepartmentID = 7
*/


-- 4.4 Using APPLY (Advanced)
-- EXPLAIN: Like JOIN but right side can reference left side
SELECT TOP 12
            p.FirstName
            , p.LastName
            , recent_orders.OrderDate
            , recent_orders.TotalDue
       FROM Person.Person p
CROSS APPLY (
    SELECT TOP 3
               soh.OrderDate
               , soh.TotalDue
          FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.Customer c
            ON c.CustomerID = soh.CustomerID
         WHERE c.PersonID = p.BusinessEntityID
      ORDER BY soh.OrderDate DESC
) recent_orders
ORDER BY p.BusinessEntityID;

/*
VISUAL DIAGRAM:
===============
INNER JOIN:     [====]        (intersection)
LEFT JOIN:      [========]    (all left + matching right)
RIGHT JOIN:         [========] (all right + matching left)
FULL OUTER:     [============] (everything from both)
CROSS JOIN:     [==] Ã— [==]   (all combinations)
*/