CREATE PROCEDURE usp_Top10FolderSubTreeSizeReport (@folderPath VARCHAR(80))
AS
BEGIN
   SET NOCOUNT ON

   DECLARE @curdir VARCHAR(400)
   DECLARE @line VARCHAR(400)
   DECLARE @command VARCHAR(400)
   DECLARE @cntr BIGINT
   DECLARE @filesize BIGINT

   -- Create a table that holds all directory names in sub tree
   CREATE TABLE #SubTreeDirs (
      dir_no BIGINT identity(1, 1)
      ,dirPath VARCHAR(400)
      )

   -- create table that holds all the DIR commands output executed on each directory
   CREATE TABLE #TempTB (textline VARCHAR(400))

   -- create the table that holds the output of directory name and size
   CREATE TABLE #OutReport (
      Directory VARCHAR(400)
      ,FileSizeMB BIGINT
      )

   SET @command = 'dir "' + @folderPath + '"' + ' /S/O/B/A:D'

   INSERT INTO #SubTreeDirs
   EXEC xp_cmdshell @command

   SET @cntr = (
         SELECT count(*)
         FROM #SubTreeDirs
         )

   WHILE @cntr <> 0
   BEGIN
      SET @curdir = (
            SELECT dirPath
            FROM #SubTreeDirs
            WHERE dir_no = @cntr
            )
      SET @command = 'dir "' + @curdir + '"'

      TRUNCATE table #tempTB
      INSERT INTO #tempTB
      EXEC master.dbo.xp_cmdshell @command

      SELECT @line = ltrim(replace(substring(textline, charindex(')', textline) + 1, len(textline)), ',', ''))
      FROM #tempTB
      WHERE textline LIKE '%File(s)%bytes'

      SET @filesize = Replace(@line, ' bytes', '')

      INSERT INTO #OutReport (
         directory
         ,FilesizeMB
         )
      VALUES (
         @curdir
         ,@filesize / (1024 * 1024)
         )

      SET @cntr -= 1
   END

   DELETE
   FROM #OutReport
   WHERE Directory IS NULL

   SELECT TOP 10 *
   FROM #OutReport
   ORDER BY FilesizeMB DESC

   DROP TABLE #OutReport

   DROP TABLE #TempTB

   DROP TABLE #SubTreeDirs

   SET NOCOUNT OFF
END
GO
