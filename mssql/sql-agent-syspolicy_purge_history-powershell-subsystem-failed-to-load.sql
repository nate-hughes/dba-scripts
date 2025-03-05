--SOURCE: http://www.sqlservercentral.com/Forums/Topic772839-146-1.aspx
--SUBJECT: "syspolicy_purge_history" "PowerShell subsystem failed to load"

--Procedure to trouble shoot the job ‘syspolicy_purge_history’ on SQL server

--Sometimes job syspolicy_purge_history will fail with the below error message
-- Unable to start execution of step 3 (reason: The PowerShell subsystem failed to load [see the SQLAGENT.OUT file for details]; 
--The job has been suspended). The step failed.

--Cause of the failure : invalid location of SQLPS.exe file

--To troubleshoot the issue please follow the below steps.

--1.	Using the below script check the location of SQLPS.exe file.
SELECT * FROM msdb.dbo.syssubsystems WHERE start_entry_point ='PowerShellStart'

--2.	Go to the server and check whether the file ‘SQLPS.exe’ is located in the path as per step 1.
--3.	In this case normally the two paths will be different.
--4.	Enable updates using the below script
Use msdb
go
sp_configure 'allow updates', 1 
RECONFIGURE WITH OVERRIDE 

--5. Update the correct path
--Execute the following script after necessary modification (if required) in msdb database.
UPDATE msdb.dbo.syssubsystems SET agent_exe='E:\Server_apps\x86\MSSQL\100\Tools\Binn\SQLPS.exe' WHERE start_entry_point ='PowerShellStart'

--6. Disable updates using the below script
sp_configure 'allow updates', 0 
RECONFIGURE WITH OVERRIDE 

--7. Confirm that SQLPS.exe file path has changed by running the below script once again
SELECT * FROM msdb.dbo.syssubsystems WHERE start_entry_point ='PowerShellStart'

--8. Restart the respective SQL agent ( if it is clustered then restart it from the clusadmin )
--9. Re run the job.
