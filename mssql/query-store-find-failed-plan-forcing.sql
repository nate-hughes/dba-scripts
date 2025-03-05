-- Retrieve forced Query Store plans that failed to apply

SELECT	qsqt.query_sql_text,
		OBJECT_NAME(qsq.object_id) AS ProcedureName,
		qsq.query_id,
		qsp.query_plan_hash,
		CAST(qsp.query_plan AS XML) AS query_plan,
		qsp.is_forced_plan,
		qsp.is_natively_compiled,
		qsp.force_failure_count,
		qsp.last_force_failure_reason_desc
FROM	sys.query_store_query qsq 
		INNER JOIN sys.query_store_query_text qsqt ON qsqt.query_text_id = qsq.query_text_id
		INNER JOIN sys.query_store_plan qsp ON qsp.query_id = qsq.query_id
WHERE	qsp.is_forced_plan = 1
AND		qsp.force_failure_count > 0
ORDER BY qsp.query_plan_hash
		,qsq.last_execution_time DESC;

