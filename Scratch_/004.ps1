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
N'$u = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_update_job @job_name=@n, @enabled=1\", $cn); ($u.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128)).Value = $j; $u.ExecuteNonQuery() | Out-Null; ' +
N'$s = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_start_job @job_name=@n\", $cn); ($s.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128)).Value = $j; $s.ExecuteNonQuery() | Out-Null; ' +
N'Write-Host (\"Enabled and started: \" + $server + \" : \" + $j) } $cn.Close(); }; ' +
N'Start-Job -ScriptBlock $sb -ArgumentList $primary,$pat1,$pat2 | Out-Null; ' +
N'Start-Job -ScriptBlock $sb -ArgumentList $secondary,$pat1,$pat2 | Out-Null; ' +
N'Wait-Job | Receive-Job"';



Wait-Job : Cannot process command because of one or more missing mandatory parameters: Id.
At line:1 char:1344
+ ... $sb -ArgumentList $secondary,$pat1,$pat2 | Out-Null; Wait-Job | Recei ...
+                                                          ~~~~~~~~
    + CategoryInfo          : InvalidArgument: (:) [Wait-Job], ParameterBindingException
    + FullyQualifiedErrorId : MissingMandatoryParameter,Microsoft.PowerShell.Commands.WaitJobCommand
 
NULL


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
N'$u = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_update_job @job_name=@n, @enabled=1\", $cn); ($u.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128)).Value = $j; $u.ExecuteNonQuery() | Out-Null; ' +
N'$s = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_start_job @job_name=@n\", $cn); ($s.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128)).Value = $j; $s.ExecuteNonQuery() | Out-Null; ' +
N'Write-Host (\"Enabled and started: \" + $server + \" : \" + $j) } $cn.Close(); }; ' +
N'$j1 = Start-Job -ScriptBlock $sb -ArgumentList $primary,$pat1,$pat2; ' +
N'$j2 = Start-Job -ScriptBlock $sb -ArgumentList $secondary,$pat1,$pat2; ' +
N'Wait-Job -Id $j1.Id,$j2.Id | Receive-Job"';


N'powershell -NoProfile -ExecutionPolicy Bypass -Command "' +
N'$primary = ''' + REPLACE(@primaryFull,'''','''''') + N'''; ' +
N'$secondary = ''' + REPLACE(@secondaryFull,'''','''''') + N'''; ' +
N'$pat1 = ''' + REPLACE(@Pattern1,'''','''''') + N'''; ' +
N'$pat2 = ''' + REPLACE(@Pattern2,'''','''''') + N'''; ' +
N'$sb = { param($server,$pat1,$pat2) ' +
N'$cn = New-Object System.Data.SqlClient.SqlConnection(\"Server=$server;Integrated Security=true;\"); ' +
N'$cn.Open(); ' +
N'$cmd = New-Object System.Data.SqlClient.SqlCommand(\"SELECT name FROM msdb.dbo.sysjobs WHERE name LIKE @p1 OR name LIKE @p2\", $cn); ' +
N'($cmd.Parameters.Add(\"@p1\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat1; ' +
N'($cmd.Parameters.Add(\"@p2\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat2; ' +
N'$cmd.CommandText = \"SELECT name, enabled FROM msdb.dbo.sysjobs WHERE name LIKE @p1 OR name LIKE @p2\"; ' +
N'$r = $cmd.ExecuteReader(); $jobs = @(); while ($r.Read()) { $jobs += [pscustomobject]@{ Name = $r.GetString(0); Enabled = ([int]$r.GetByte(1)) } } $r.Close(); ' +
N'foreach ($j in $jobs) { ' +
N'if ($j.Enabled -eq 1) { Write-Host (\"Already enabled: \" + $server + \" : \" + $j.Name) } else { ' +
N'$u = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_update_job @job_name=@n, @enabled=1\", $cn); ($u.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128)).Value = $j.Name; $u.ExecuteNonQuery() | Out-Null; ' +
N'Write-Host (\"Enabled: \" + $server + \" : \" + $j.Name) } } $cn.Close(); }; ' +
N'$j1 = Start-Job -ScriptBlock $sb -ArgumentList $primary,$pat1,$pat2; ' +
N'$j2 = Start-Job -ScriptBlock $sb -ArgumentList $secondary,$pat1,$pat2; ' +
N'Wait-Job -Id $j1.Id,$j2.Id | Receive-Job"';




N'powershell -NoProfile -ExecutionPolicy Bypass -Command "' +
N'$primary = ''' + REPLACE(@primaryFull,'''','''''') + N'''; ' +
N'$secondary = ''' + REPLACE(@secondaryFull,'''','''''') + N'''; ' +
N'$pat1 = ''' + REPLACE(@Pattern1,'''','''''') + N'''; ' +
N'$pat2 = ''' + REPLACE(@Pattern2,'''','''''') + N'''; ' +
N'$sb = { param($server,$pat1,$pat2) ' +
N'$cn = New-Object System.Data.SqlClient.SqlConnection(\"Server=$server;Integrated Security=true;\"); ' +
N'$cn.Open(); ' +
N'$cmd1 = New-Object System.Data.SqlClient.SqlCommand(\"SELECT name, enabled FROM msdb.dbo.sysjobs WHERE name LIKE @p\", $cn); ' +
N'($cmd1.Parameters.Add(\"@p\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat1; ' +
N'$r = $cmd1.ExecuteReader(); $jobs1 = @(); while ($r.Read()) { $jobs1 += [pscustomobject]@{ Name = $r.GetString(0); Enabled = ([int]$r.GetByte(1)) } } $r.Close(); ' +
N'$cmd2 = New-Object System.Data.SqlClient.SqlCommand(\"SELECT name, enabled FROM msdb.dbo.sysjobs WHERE name LIKE @p\", $cn); ' +
N'($cmd2.Parameters.Add(\"@p\", [System.Data.SqlDbType]::VarChar, 256)).Value = $pat2; ' +
N'$r = $cmd2.ExecuteReader(); $jobs2 = @(); while ($r.Read()) { $jobs2 += [pscustomobject]@{ Name = $r.GetString(0); Enabled = ([int]$r.GetByte(1)) } } $r.Close(); ' +
N'Write-Host (\"Pattern1 jobs on \" + $server + \": \" + (($jobs1 | ForEach-Object {$_.Name}) -join \",\")); ' +
N'Write-Host (\"Pattern2 jobs on \" + $server + \": \" + (($jobs2 | ForEach-Object {$_.Name}) -join \",\")); ' +
N'$jobs = @(); $seen = @{}; foreach ($j in ($jobs1 + $jobs2)) { if (-not $seen.ContainsKey($j.Name)) { $seen[$j.Name] = $true; $jobs += $j } } ' +
N'foreach ($j in $jobs) { ' +
N'if ($j.Enabled -eq 1) { Write-Host (\"Already enabled: \" + $server + \" : \" + $j.Name) } else { ' +
N'$u = New-Object System.Data.SqlClient.SqlCommand(\"EXEC msdb.dbo.sp_update_job @job_name=@n, @enabled=1\", $cn); ($u.Parameters.Add(\"@n\", [System.Data.SqlDbType]::VarChar, 128)).Value = $j.Name; $u.ExecuteNonQuery() | Out-Null; ' +
N'Write-Host (\"Enabled: \" + $server + \" : \" + $j.Name) } } $cn.Close(); }; ' +
N'& $sb $primary $pat1 $pat2; ' +
N'& $sb $secondary $pat1 $pat2"';