USE master;
GO

/*
Suspend an Availability Database
https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/suspend-an-availability-database-sql-server

The effect of a suspend command depends on whether you suspend a secondary database or a primary database, as follows:

Secondary database:	Only the local secondary database is suspended and its synchronization state becomes NOT SYNCHRONIZING. Other secondary databases
					are not affected. The suspended database stops receiving and applying data (log records) and begins to fall behind the primary
					database. Existing connections on the readable secondary remain usable. New connections to the suspended database on the readable
					secondary are not allowed until data movement is resumed.

					The primary database remains available. If you suspend each of the corresponding secondary databases, the primary database runs exposed.

					** Important ** While a secondary database is suspended, the send queue of the corresponding primary database will accumulate unsent
					transaction log records. Connections to the secondary replica return data that was available at the time the data movement was suspended.

Primary database:	The primary database stops data movement to every connected secondary database. The primary database continues running, in an exposed
					mode. The primary database remains available to clients, and existing connections on a readable secondary remain usable and new connections
					can be made.
*/

SELECT  database_name
       ,'ALTER DATABASE ' + database_name + ' SET HADR SUSPEND;' AS PauseStmt
       ,'ALTER DATABASE ' + database_name + ' SET HADR RESUME;'  AS ResumeStmt
FROM    sys.availability_databases_cluster
ORDER BY database_name;
GO

