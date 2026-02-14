IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'AutomationDB')

BEGIN
    CREATE DATABASE AutomationDB;
END
