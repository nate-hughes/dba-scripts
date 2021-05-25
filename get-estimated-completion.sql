DECLARE @SPID INT = <SPID>;

SELECT	command
		,percent_complete
		,estimated_completion_time / 1000 AS estimated_completion_time_sec
FROM	sys.dm_exec_requests
WHERE	session_id = @SPID;

SELECT   
       node_id,
       physical_operator_name, 
       SUM(row_count) row_count, 
       SUM(estimate_row_count) AS estimate_row_count,
       CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count)  as estimate_percent_complete
FROM sys.dm_exec_query_profiles   
WHERE session_id=@SPID  
GROUP BY node_id,physical_operator_name  
ORDER BY node_id desc;

