-- Get secondary server by incrementing the LAST numeric sequence (e.g., TRND52MSSQL5161 -> TRND52MSSQL5162)
DECLARE @CurrentServer NVARCHAR(255) = LEFT(@@SERVERNAME, CHARINDEX('\', @@SERVERNAME + '\') - 1),
        @LastNumberStart INT,
        @LastNumberEnd INT,
        @CurrentNumber INT,
        @SecondaryNumber INT,
        @Prefix NVARCHAR(255),
        @SecondaryServer NVARCHAR(255);

-- Find the position of the last numeric sequence
SET @LastNumberEnd = LEN(@CurrentServer);
WHILE @LastNumberEnd > 0 AND SUBSTRING(@CurrentServer, @LastNumberEnd, 1) NOT LIKE '[0-9]'
    SET @LastNumberEnd = @LastNumberEnd - 1;

-- Find the start of the last numeric sequence
SET @LastNumberStart = @LastNumberEnd;
WHILE @LastNumberStart > 0 AND SUBSTRING(@CurrentServer, @LastNumberStart - 1, 1) LIKE '[0-9]'
    SET @LastNumberStart = @LastNumberStart - 1;

-- Extract and increment
SET @CurrentNumber = CAST(SUBSTRING(@CurrentServer, @LastNumberStart, @LastNumberEnd - @LastNumberStart + 1) AS INT);
SET @SecondaryNumber = @CurrentNumber + 1;
SET @Prefix = LEFT(@CurrentServer, @LastNumberStart - 1);

-- Build secondary server name
SET @SecondaryServer = @Prefix + CAST(@SecondaryNumber AS NVARCHAR(10));

SELECT 
    @CurrentServer AS CurrentServer,
    @SecondaryServer AS SecondaryServer;


GO

