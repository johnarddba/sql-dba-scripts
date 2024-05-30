SET NOCOUNT ON

DECLARE @String VARCHAR(100) = 'Hello World';

PRINT '                      -- String Functions --'
PRINT '---------------------------------------------------------------------'
PRINT 'Original String				: ' + @String;
PRINT 'Length						: ' + CAST(LEN(@String) AS VARCHAR(10));
PRINT 'Upper Case					: ' + UPPER(@String);
PRINT 'Lower Case					: ' + LOWER(@String);
PRINT 'Substring (2, 5)			: ' + SUBSTRING(@String, 2,5);
PRINT 'Replace "Hello" with "Hi"	: ' + REPLACE(@String, 'Hello', 'Hi');
PRINT 'Left 5 Characters			: ' + LEFT(@String, 5);
PRINT 'Right 6 Characters			: ' + RIGHT(@String, 5);
PRINT '---------------------------------------------------------------------'

DECLARE @Number INT = 12345;

PRINT '                      -- Number Functions --'
PRINT '---------------------------------------------------------------------'
PRINT 'Original Number						: ' + CAST(@Number AS VARCHAR(10));
PRINT 'Absolute Number						: ' + CAST(ABS(@Number) AS VARCHAR(10));
PRINT 'Square Root							: ' + CAST(SQRT(@Number) AS VARCHAR(10));
PRINT 'Power of 2							: ' + CAST(POWER(@Number, 2) AS VARCHAR(10));
PRINT 'Random Number (Between 1 and 100)	: ' + CAST(ROUND(RAND() * 100, 0) AS VARCHAR(10));
PRINT '---------------------------------------------------------------------'

DECLARE @Date DATE = GETDATE();
PRINT '                   -- Date and Time Functions --'
PRINT '---------------------------------------------------------------------'
PRINT 'Current Date						: ' + CAST(@Date AS VARCHAR(12));
PRINT 'Day								: '
