-- Get number of open connections
SHOW STATUS WHERE `variable_name` = 'Threads_connected';

-- Find Running Processes
SELECT	* 
FROM	information_schema.PROCESSLIST 
WHERE	COMMAND != 'Sleep'
ORDER BY TIME DESC;

-- Find Running Transactions
SELECT	*
FROM	information_schema.innodb_trx;

-- End (Kill) A Running Process
-- KILL CONNECTION 16;
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
-- MySQL 5.7
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
-- MySQL 8.0
SELECT	r.trx_id waiting_trx_id
		,r.trx_mysql_thread_id waiting_thread
        ,r.trx_query waiting_query
		,b.trx_id blocking_trx_id
        ,b.trx_mysql_thread_id blocking_thread
        ,b.trx_query blocking_query
FROM	performance_schema.data_lock_waits w
		INNER JOIN information_schema.innodb_trx b
			ON b.trx_id = w.blocking_engine_transaction_id
		INNER JOIN information_schema.innodb_trx r
			ON r.trx_id = w.requesting_engine_transaction_id;
  

   