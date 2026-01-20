DECLARE
	@myDate1 as datetime = getdate(),
	@myDate2 as datetime2 = getdate(),
	@myDate3 as date = getdate(),
	@myDate4 as time = getdate()

SELECT @myDate1 'datetime'
SELECT @myDate2 'datetime2'
SELECT @myDate3 'date'
SELECT @myDate4 'time'