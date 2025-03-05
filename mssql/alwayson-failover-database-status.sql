/*
Always On Secondary Database in Reverting/In Recovery
https://bahtisametcoban.home.blog/2019/02/07/always-on-secondary-database-in-reverting-in-recovery/
*/

DEcLARE @DatabaseName SYSNAME = NULL;

/*
There will be 3 phases of secondary database replica state during undo process:
	Synchronization State: “NOT SYNCHRONIZING” ; Database State: ONLINE
	Synchronization State: “NOT SYNCHRONIZING” ; Database State: RECOVERING
	Synchronization State: “REVERTING” ; Database State: RECOVERING
*/
SELECT	DB_NAME(database_id) as DatabaseName
		,synchronization_state_desc
		,database_state_desc
FROM	sys.dm_hadr_database_replica_states
WHERE	is_local=1
AND		is_primary_replica=0
AND		(@DatabaseName IS NULL OR DB_NAME(database_id) = @DatabaseName);

-- SQLServer:Database Replica: Log remaining for undo
SELECT	[object_name]
		,[counter_name]
		,[cntr_value] -- the amount of log in kb remaining to complete the undo phase
		,instance_name
FROM	sys.dm_os_performance_counters
WHERE	[object_name] LIKE '%Database Replica%'
AND		[counter_name] = 'Log remaining for undo'
AND		(@DatabaseName IS NULL OR [instance_name] = @DatabaseName);
