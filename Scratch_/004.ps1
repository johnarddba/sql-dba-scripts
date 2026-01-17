N'powershell -NoProfile -ExecutionPolicy Bypass -Command "' +
N'$primary = ''' + REPLACE(@primaryBase,'''','''''') + N'''; ' +
N'$secondary = ''' + REPLACE(@secondaryBase,'''','''''') + N'''; ' +
N'$pat1 = ''' + REPLACE(@Pattern1,'''','''''') + N'''; ' +
N'$pat2 = ''' + REPLACE(@Pattern2,'''','''''') + N'''; ' +
N'$sb = { param($server,$pat1,$pat2) ' +
N'$cn = New-Object System.Data.SqlClient.SqlConnection(\"Server=$server;Integrated Security=true;\"); ' +
N'$cn.Open(); ' +
N'$cmd = New-Object System.Data.SqlClient.SqlCommand(\"SELECT name FROM msdb.dbo.sysjobs WHERE name LIKE @p1 OR name LIKE @p2\", $cn); ' +
N'[void]$cmd.Parameters.Add(\"@p1\", [System.Data.SqlDbType]::VarChar, 256).Value = $pat1; ' +
N'[void]$cmd.Parameters.Add(\"@p2\", [System.Data.SqlDbType]::VarChar, 256).Value = $pat2; ' +
N'$r = $cmd.ExecuteReader(); $jobs = @(); while ($r.Read()) { $jobs += $r.GetString(0) } $r.Close(); ' +
N'foreach ($j in $jobs) { ' +
N'$u = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_update_job @job_name=@n, @enabled=1\", $cn); [void]$u.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128).Value = $j; $u.ExecuteNonQuery() | Out-Null; ' +
N'$s = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_start_job @job_name=@n\", $cn); [void]$s.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128).Value = $j; $s.ExecuteNonQuery() | Out-Null; ' +
N'Write-Host (\"Enabled and started: \" + $server + \" : \" + $j) } $cn.Close(); }; ' +
N'Start-Job -ScriptBlock $sb -ArgumentList $primary,$pat1,$pat2 | Out-Null; ' +
N'Start-Job -ScriptBlock $sb -ArgumentList $secondary,$pat1,$pat2 | Out-Null; ' +
N'Wait-Job | Receive-Job"';



At line:1 char:398
+ ... o.sysjobs WHERE name LIKE @p1 OR name LIKE @p2", $cn); [void]$cmd.Par ...
+                                                            ~~~~~~
[void] cannot be used as a parameter type, or on the left side of an assignment.
At line:1 char:485
+ ...  [System.Data.SqlDbType]::VarChar, 256).Value = $pat1; [void]$cmd.Par ...
+                                                            ~~~~~~
[void] cannot be used as a parameter type, or on the left side of an assignment.
At line:1 char:806
+ ... sdb.dbo.sp_update_job @job_name=@n, @enabled=1", $cn); [void]$u.Param ...
+                                                            ~~~~~~
[void] cannot be used as a parameter type, or on the left side of an assignment.
At line:1 char:1018
+ ... mmand("EXEC msdb.dbo.sp_start_job @job_name=@n", $cn); [void]$s.Param ...
+                                                            ~~~~~~
[void] cannot be used as a parameter type, or on the left side of an assignment.
    + CategoryInfo          : ParserError: (:) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : VoidTypeConstraintNotAllowed
 
NULL



--

DECLARE @PS NVARCHAR(MAX) =
N'powershell -NoProfile -ExecutionPolicy Bypass -Command "' +
N'$primary = ''' + REPLACE(@primaryBase,'''','''''') + N'''; ' +
N'$secondary = ''' + REPLACE(@secondaryBase,'''','''''') + N'''; ' +
N'$pat1 = ''' + REPLACE(@Pattern1,'''','''''') + N'''; ' +
N'$pat2 = ''' + REPLACE(@Pattern2,'''','''''') + N'''; ' +
N'$sb = { param($server,$pat1,$pat2) ' +
N'$cn = New-Object System.Data.SqlClient.SqlConnection(\"Server=$server;Integrated Security=true;\"); ' +
N'$cn.Open(); ' +
N'$cmd = New-Object System.Data.SqlClient.SqlCommand(\"SELECT name FROM msdb.dbo.sysjobs WHERE name LIKE @p1 OR name LIKE @p2\", $cn); ' +
N'($cmd.Parameters.Add(\"@p1\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat1; ' +
N'($cmd.Parameters.Add(\"@p2\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat2; ' +
N'$r = $cmd.ExecuteReader(); $jobs = @(); while ($r.Read()) { $jobs += $r.GetString(0) } $r.Close(); ' +
N'foreach ($j in $jobs) { ' +
N'$u = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_update_job @job_name=@n, @enabled=1\", $cn); [void]$u.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128).Value = $j; $u.ExecuteNonQuery() | Out-Null; ' +
N'$s = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_start_job @job_name=@n\", $cn); [void]$s.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128).Value = $j; $s.ExecuteNonQuery() | Out-Null; ' +
N'Write-Host (\"Enabled and started: \" + $server + \" : \" + $j) } $cn.Close(); }; ' +
N'Start-Job -ScriptBlock $sb -ArgumentList $primary,$pat1,$pat2 | Out-Null; ' +
N'Start-Job -ScriptBlock $sb -ArgumentList $secondary,$pat1,$pat2 | Out-Null; ' +
N'Wait-Job | Receive-Job"';
