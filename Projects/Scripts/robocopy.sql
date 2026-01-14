-- copy latest backup files to shared
-- Explanation of the following lines:
-- 1) @src            => Source folder root containing LiteSpeed backups
-- 2) @dst            => Destination folder to copy files to
-- 3) @pattern        => File pattern used to match backup files
-- 4) @ps             => Holds the PowerShell script to run (built below)
-- 5) @cmd            => Final command string to execute via xp_cmdshell
-- 6) IF EXISTS ...   => Checks if xp_cmdshell is enabled on the server
-- 7) SET @ps         => Builds a PowerShell one-liner to find top N newest files and call robocopy
-- 8) SET @cmd        => Wraps the PowerShell script into a shell command
-- 9) PRINT @cmd      => Prints the command for debugging/dry-run
-- 10) EXEC xp_cmdshell=> Runs the command (invokes PowerShell and then robocopy)
-- 11) ELSE branch    => Fallback behavior when xp_cmdshell is disabled
-- 12) Fallback @cmd  => Uses robocopy /maxage:1 to copy recent files (less precise for multi-part sets)

DECLARE
	@src nvarchar(4000) = N'\\source_server\shared\DR_Sync\', -- Source folder root containing LiteSpeed backups
	@dst nvarchar(4000) = N'\\dest_server\shared\DR_Sync\', -- Destination folder to copy files to
	@pattern nvarchar(200) = N'*.LBK', -- File search pattern used to match backup files
	@ps varchar(8000), -- PowerShell script to run (built below)
	@cmd varchar(8000) -- Final command string to execute via xp_cmdshell

IF EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'xp_cmdshell' AND VALUE = 1)
BEGIN
	PRINT '' -- Blank line for readability in output
	SET @ps = N'Get-ChildItem -Path ''' + @src + N''' -Filter ''' + @pattern + N''' | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object { robocopy $_.DirectoryName ''' + @dst + N''' $_.Name /r:5 /w:1 /xo /tee }'; -- PowerShell: find top 5 newest files and robocopy each
	SET @cmd = N'powershell -NoProfile -ExecutionPolicy Bypass -Command "' + REPLACE(@ps, '"', '\"') + N'"'; -- Wrap the PowerShell script into a shell command
	PRINT @cmd;
	EXEC xp_cmdshell @cmd;
	
END
ELSE
BEGIN
	PRINT 'xp_cmdshell is disabled' -- xp_cmdshell not available on this instance
	SET @cmd = N'robocopy.exe "' + @src + N'" "' + @dst + N'" /r:5 /w:1 /xo /maxage:1 /tee'; -- Fallback robocopy: copy files modified in the last day
	PRINT @cmd;
	EXEC xp_cmdshell @cmd;
	
END