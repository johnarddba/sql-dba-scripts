--Firstly to report on whether there are any orphaned users present for a database, run the following query against the DB;

EXEC sp_change_users_login 'Report'

--Then to fix any identified orphaned queries, you can either attempt to fix this automatically via:

EXEC sp_change_users_login 'Auto_Fix', 'user'

--… or manually (with more control) via the following query:

sp_change_users_login 'update_one', 'dbUser', 'sqlLogin'

--Alternatively

EXEC sp_change_users_login 'Auto_Fix', 'user', 'login', 'password'