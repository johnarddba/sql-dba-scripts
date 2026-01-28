SELECT
	'fds_gl_posting' AS TableName,
	'id' AS ColumnName,
	MAX([id]) AS CurrentMaxValue,
	CASE
		WHEN MAX([id]) <= 255 AND MIN([id]) >= 0 THEN 'TINYINT'
		WHEN MAX([id]) <= 32767 AND MIN([id]) >= -32768 THEN 'SMALLINT'
		ELSE 'KEEP as INT'
	END AS RecommendedType
FROM [dbo].[fds_gl_posting];