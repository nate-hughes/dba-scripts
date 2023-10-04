-- 1.1 Ensure Latest SQL Server Cumulative and Security Updates are Installed
SELECT 'Latest SQL Server Cumulative and Security Updates' AS Benchmark
	,SERVERPROPERTY('ProductLevel') AS SP_installed
	,SERVERPROPERTY('ProductVersion') AS VERSION
	,SERVERPROPERTY('ProductUpdateLevel') AS 'ProductUpdate_Level'
	,SERVERPROPERTY('ProductUpdateReference') AS 'KB_Number';

-- 2.1 Ensure 'Ad Hoc Distributed Queries' Server Configuration Option is set to '0'
-- Both value columns must show 0.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'Ad Hoc Distributed Queries';

-- 2.2 Ensure 'CLR Enabled' Server Configuration Option is set to '0'
-- If both values are 1, this recommendation is Not Applicable.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'clr strict security';
-- Otherwise, run the following T-SQL command:
-- Both value columns must show 0 to be compliant.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'clr enabled';

-- 2.3 Ensure 'Cross DB Ownership Chaining' Server Configuration Option is set to '0'
-- Both value columns must show 0 to be compliant.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'cross db ownership chaining';

-- 2.4 Ensure 'Database Mail XPs' Server Configuration Option is set to '0'
-- Both value columns must show 0 to be compliant.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'Database Mail XPs';

-- 2.5 Ensure 'Ole Automation Procedures' Server Configuration Option is set to '0'
-- Both value columns must show 0 to be compliant.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'Ole Automation Procedures';

-- 2.6 Ensure 'Remote Access' Server Configuration Option is set to '0'
-- Both value columns must show 0.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'remote access';

-- 2.7 Ensure 'Remote Admin Connections' Server Configuration Option is set to '0'
-- If no data is returned, the instance is a cluster and this recommendation is not applicable. If data is returned, then both the value columns must show 0 to be compliant.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'remote admin connections' AND SERVERPROPERTY('IsClustered') = 0;

-- 2.8 Ensure 'Scan For Startup Procs' Server Configuration Option is set to '0'
-- Both value columns must show 0.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'scan for startup procs';

-- 2.9 Ensure 'Trustworthy' Database Property is set to 'Off'
-- No rows should be returned.
SELECT [name] AS 'Trustworthy Database' FROM [sys].[databases] WHERE [is_trustworthy_on] = 1 AND [name] != 'msdb';

-- 2.11 Ensure SQL Server is configured to use non-standard ports
-- A value of 0 implies a pass.
SELECT COUNT(*) FROM [sys].[dm_server_registry] WHERE [value_name] LIKE '%Tcp%' AND [value_data]='1433';

-- 2.12 Ensure 'Hide Instance' option is set to 'Yes' for Production SQL Server instances
-- A value of 1 should be returned to be compliant.
DECLARE @getValue INT;
EXECUTE master.[sys].xp_instance_regread @rootkey = N'HKEY_LOCAL_MACHINE', @key = N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib', @value_name = N'HideInstance', @value = @getValue OUTPUT;
SELECT @getValue AS Compliant;

-- 2.13 Ensure the 'sa' Login Account is set to 'Disabled'
-- No rows should be returned to be compliant.
SELECT [name], [is_disabled] FROM [sys].[server_principals] WHERE [sid] = 0x01 AND [is_disabled] = 0;

-- 2.14 Ensure the 'sa' Login Account has been renamed
-- A name of sa indicates the account has not been renamed and therefore needs remediation.
SELECT name FROM sys.server_principals WHERE sid = 0x01;

-- 2.15 Ensure 'AUTO_CLOSE' is set to 'OFF' on contained databases
-- No rows should be returned.
SELECT [name] AS 'contained database', [containment], [containment_desc], [is_auto_close_on] FROM [sys].[databases] WHERE [containment] <> 0 AND [is_auto_close_on] = 1;

-- 2.16 Ensure no login exists with the name 'sa'
-- No rows should be returned.
SELECT [principal_id], [name] FROM [sys].[server_principals] WHERE [name] = 'sa';

-- 2.17 Ensure 'clr strict security' Server Configuration Option is set to '1'
-- Both value columns must show 1 to be compliant.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'clr strict security';

-- 3.1 Ensure 'Server Authentication' Property is set to 'Windows Authentication Mode'
-- A login_mode of 1 indicates the Server Authentication property is set to Windows Authentication Mode. A login_mode of 0 indicates mixed mode authentication.
SELECT 'Authentication Mode' AS Benchmark, CASE SERVERPROPERTY('IsIntegratedSecurityOnly') WHEN 1 THEN 'Windows' ELSE 'Mixed Mode' END AS [login_mode];

-- 3.2 Ensure CONNECT permissions on the 'guest' user is Revoked within all SQL Server databases
-- No rows should be returned.
DECLARE @command VARCHAR(1000); 
SELECT @command = 'USE ? SELECT DB_NAME() AS [DatabaseName], ''guest'' AS Database_User, [permission_name], [state_desc] FROM [sys].[database_permissions] WHERE [grantee_principal_id] = DATABASE_PRINCIPAL_ID(''guest'') AND [state_desc] LIKE ''GRANT%'' AND [permission_name] = ''CONNECT'' AND DB_NAME() NOT IN (''master'',''tempdb'',''msdb'');';
EXECUTE sp_MSforeachdb @command; 
GO

-- 3.3 Ensure 'Orphaned Users' are Dropped From SQL Server Databases
-- No rows should be returned.
DECLARE @command VARCHAR(1000); 
SELECT @command = 'USE ? EXECUTE sp_change_users_login @Action=''Report'';';
EXECUTE sp_MSforeachdb @command; 
GO

-- 3.4 Ensure SQL Authentication is not used in contained databases
-- Identify contained databases
SELECT [name] AS 'contained database' FROM [sys].[databases] WHERE [containment] <> 0;
-- Execute the following T-SQL in each contained database to find database users that are using SQL authentication:
SELECT [name] AS DBUser FROM [sys].[database_principals] WHERE [name] NOT IN ('dbo','Information_Schema','sys','guest') AND TYPE IN ('U','S','G') AND [authentication_type] = 2;

-- 3.8 Ensure only the default permissions specified by Microsoft are granted to the public server role
-- This query should not return any rows.
SELECT * FROM master.[sys].[server_permissions] WHERE ([grantee_principal_id] = SUSER_SID(N'public') AND [state_desc] LIKE 'GRANT%') AND NOT ([state_desc] = 'GRANT' AND [permission_name] = 'VIEW ANY DATABASE' AND [class_desc] = 'SERVER') AND NOT ([state_desc] = 'GRANT' AND [permission_name] = 'CONNECT' AND [class_desc] = 'ENDPOINT' AND [major_id] = 2) AND NOT ([state_desc] = 'GRANT' AND [permission_name] = 'CONNECT' AND [class_desc] = 'ENDPOINT' AND [major_id] = 3) AND NOT ([state_desc] = 'GRANT' AND [permission_name] = 'CONNECT' AND [class_desc] = 'ENDPOINT' AND [major_id] = 4) AND NOT ([state_desc] = 'GRANT' AND [permission_name] = 'CONNECT' AND [class_desc] = 'ENDPOINT' AND [major_id] = 5);

-- 3.9 Ensure Windows BUILTIN groups are not SQL Logins
-- This query should not return any rows.
SELECT pr.[name], pe.[permission_name], pe.[state_desc] FROM [sys].[server_principals] pr JOIN [sys].[server_permissions] pe ON pr.[principal_id] = pe.[grantee_principal_id] WHERE pr.[name] LIKE 'BUILTIN%';

-- 3.10 Ensure Windows local groups are not SQL Logins
-- This query should not return any rows.
USE [master]; SELECT pr.[name] AS LocalGroupName, pe.[permission_name], pe.[state_desc] FROM [sys].[server_principals] pr JOIN [sys].[server_permissions] pe ON pr.[principal_id] = pe.[grantee_principal_id] WHERE pr.[type_desc] = 'WINDOWS_GROUP' AND pr.[name] LIKE CAST(SERVERPROPERTY('MachineName') AS NVARCHAR) + '%';

-- 3.11 Ensure the public role in the msdb database is not granted access to SQL Agent proxies
-- This query should not return any rows.
USE [msdb] ; SELECT sp.[name] AS proxyname FROM [dbo].sysproxylogin spl JOIN [sys].[database_principals] dp ON dp.[sid] = spl.[sid] JOIN sysproxies sp ON sp.[proxy_id] = spl.[proxy_id] WHERE [principal_id] = USER_ID('public');

-- 4.2 Ensure 'CHECK_EXPIRATION' Option is set to 'ON' for All SQL Authenticated Logins Within the Sysadmin Role
-- No rows should be returned.
SELECT l.[name], 'sysadmin membership' AS 'Access_Method' FROM [sys].[sql_logins] AS l WHERE IS_SRVROLEMEMBER('sysadmin',[name]) = 1 AND l.[is_expiration_checked] <> 1 UNION ALL SELECT l.[name], 'CONTROL SERVER' AS 'Access_Method' FROM [sys].[sql_logins] AS l JOIN [sys].[server_permissions] AS p ON l.[principal_id] = p.[grantee_principal_id] WHERE p.TYPE = 'CL' AND p.STATE IN ('G', 'W') AND l.[is_expiration_checked] <> 1;

-- 4.3 Ensure 'CHECK_POLICY' Option is set to 'ON' for All SQL Authenticated Logins
-- If no rows are returned then either no SQL Authenticated logins exist or they all have CHECK_POLICY ON.
SELECT [name], [is_disabled] FROM [sys].[sql_logins] WHERE [is_policy_checked] = 0;

-- 5.1 Ensure 'Maximum number of error log files' is set to greater than or equal to '12'
-- The NumberOfLogFiles returned should be greater than or equal to 12.
-- Value of -1 is default: 6 error log files in addition to the current error log file.
DECLARE @NumErrorLogs INT;
EXECUTE master.[sys].xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', @NumErrorLogs OUTPUT;
SELECT ISNULL(@NumErrorLogs, -1) AS [NumberOfLogFiles];
GO

-- 5.2 Ensure 'Default Trace Enabled' Server Configuration Option is set to '1'
-- Both value columns must show 1.
SELECT [name] AS Benchmark, CAST(VALUE AS INT) AS value_configured, CAST([value_in_use] AS INT) AS [value_in_use] FROM [sys].[configurations] WHERE [name] = 'default trace enabled';

-- 5.3 Ensure 'Login Auditing' is set to 'failed logins'
-- A config_value of failure indicates a server login auditing setting of Failed logins only. If a config_value of all appears, then both failed and successful logins are being logged. Both settings should also be considered valid.
EXEC xp_loginconfig 'audit level';

-- 5.4 Ensure 'SQL Server Audit' is set to capture both 'failed' and 'successful logins'
-- The result set should contain the following rows, one for each of the following audit_action_names:
-- • AUDIT_CHANGE_GROUP
-- • FAILED_LOGIN_GROUP
-- • SUCCESSFUL_LOGIN_GROUP
-- Both the Audit and Audit specification should be enabled and the audited_result should include both success and failure.
SELECT S.[name] AS 'Audit Name' , CASE S.[is_state_enabled] WHEN 1 THEN 'Y' WHEN 0 THEN 'N' END AS 'Audit Enabled' , S.[type_desc] AS 'Write Location' , SA.[name] AS 'Audit Specification Name' , CASE SA.[is_state_enabled] WHEN 1 THEN 'Y' WHEN 0 THEN 'N' END AS 'Audit Specification Enabled' , SAD.[audit_action_name] , SAD.[audited_result] FROM [sys].[server_audit_specification_details] AS SAD JOIN [sys].[server_audit_specifications] AS SA ON SAD.[server_specification_id] = SA.[server_specification_id] JOIN [sys].[server_audits] AS S ON SA.[audit_guid] = S.[audit_guid] WHERE SAD.[audit_action_id] IN ('CNAU', 'LGFL', 'LGSD') OR (SAD.[audit_action_id] IN ('DAGS', 'DAGF') AND (SELECT COUNT(*) FROM [sys].[databases] WHERE [containment]=1) > 0);

-- 6.2 Ensure 'CLR Assembly Permission Set' is set to 'SAFE_ACCESS' for All CLR Assemblies
-- All the returned assemblies should show SAFE_ACCESS in the permission_set_desc column.
DECLARE @command VARCHAR(1000); 
SELECT @command = 'USE ? SELECT DB_NAME() AS [DatabaseName], [name], [permission_set_desc] FROM [sys].[assemblies] WHERE [is_user_defined] = 1 AND [name] <> ''Microsoft.SqlServer.Types'';';
EXECUTE sp_MSforeachdb @command; 
GO

-- 7.1 Ensure 'Symmetric Key encryption algorithm' is set to 'AES_128' or higher in non-system databases
-- For compliance, no rows should be returned.
DECLARE @command VARCHAR(1000); 
SELECT @command = 'USE ? SELECT DB_NAME() AS [database_name], [name] AS [key_name] FROM [sys].[symmetric_keys] WHERE [algorithm_desc] NOT IN (''AES_128'',''AES_192'',''AES_256'') AND DB_ID() > 4;';
EXECUTE sp_MSforeachdb @command; 
GO

-- 7.2 Ensure Asymmetric Key Size is set to 'greater than or equal to 2048' in non-system databases
-- For compliance, no rows should be returned.
DECLARE @command VARCHAR(1000); 
SELECT @command = 'USE ? SELECT DB_NAME() AS [database_name], [name] AS [key_name] FROM [sys].[asymmetric_keys] WHERE [key_length] < 2048 AND DB_ID() > 4;';
EXECUTE sp_MSforeachdb @command; 
GO

-- 7.3 Ensure Database Backups are Encrypted
-- No rows should be returned by the query
SELECT b.[key_algorithm], b.[encryptor_type], d.[is_encrypted], b.[database_name], b.[server_name] FROM msdb.[dbo].[backupset] b INNER JOIN [sys].[databases] d ON b.[database_name] = d.[name] WHERE b.[key_algorithm] IS NULL AND b.[encryptor_type] IS NULL AND d.[is_encrypted] = 0;

-- 7.4 Ensure Network Encryption is Configured and Enabled
-- A response of TRUE implies a pass.
USE [master]; SELECT DISTINCT([encrypt_option]) FROM [sys].[dm_exec_connections]; 

-- 7.5 Ensure Databases are Encrypted with TDE
-- The query should return no rows
SELECT [database_id], [name], [is_encrypted] FROM [sys].[databases] WHERE [database_id] > 4 AND [is_encrypted] != 1;
