-- Find Running Processes
SELECT	* 
FROM	information_schema.PROCESSLIST 
WHERE	COMMAND != 'Sleep'
ORDER BY TIME DESC;

-- End (Kill) A Running Process
-- KILL CONNECTION thread-ID;
-- CALL mysql.rds_kill(thread-ID);
-- CALL mysql.rds_kill_query(thread-ID);

-- Find Long Running Queries and Transactions
SELECT	trx.trx_id AS transaction_ID
		,trx.trx_state AS transaction_execution_state
		,trx.trx_started AS transaction_start_time
		,trx.trx_mysql_thread_id AS thread_ID
        ,trx.trx_query AS SQL_statement
FROM	information_schema.INNODB_TRX trx
		INNER JOIN INFORMATION_SCHEMA.PROCESSLIST AS pl 
			ON trx.trx_mysql_thread_id = pl.id
WHERE	trx.trx_started < CURRENT_TIMESTAMP - INTERVAL 59 SECOND
AND		pl.user <> 'system_user';

-- Find Locks and Blocking Transactions
SELECT	pl.id
		,pl.user
		,pl.state
		,it.trx_id 
		,it.trx_mysql_thread_id 
		,it.trx_query AS query
		,it.trx_id AS blocking_trx_id
		,it.trx_mysql_thread_id AS blocking_thread
		,it.trx_query AS blocking_query
FROM	information_schema.processlist AS pl 
		INNER JOIN information_schema.innodb_trx AS it
			ON pl.id = it.trx_mysql_thread_id
		INNER JOIN information_schema.innodb_lock_waits AS ilw
			ON it.trx_id = ilw.requesting_trx_id 
			AND it.trx_id = ilw.blocking_trx_id;

	

   