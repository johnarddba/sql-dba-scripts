SELECT
	'tablename' AS TableName,
	'columnname' AS ColumnName,
	MAX([columnname]) AS CurrentMaxValue,
	CASE
		WHEN MAX([columnname]) <= 255 AND MIN([columnname]) >= 0 THEN 'TINYINT'
		WHEN MAX([columnname]) <= 32767 AND MIN([columnname]) >= -32768 THEN 'SMALLINT'
		ELSE 'KEEP as INT'
	END AS RecommendedType
FROM [schemaname].[tablename];