DECLARE @SPID INT = <SPID>;

SELECT	r.Command
		,r.start_time AS [Start Time]
		,r.percent_complete AS [% Complete]
		, DATEDIFF(MINUTE, r.start_time, GETDATE()) AS [Age in Minutes]
		,r.estimated_completion_time / 1000 AS [Est. Completion Time (s)]
		,SUBSTRING (
			st.text,(r.statement_start_offset/2) + 1
			,((CASE
				WHEN r.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2
				ELSE r.statement_end_offset
			END - r.statement_start_offset)/2) + 1
		) AS [Query]
		,st.Text AS [Parent Query]
		,DB_NAME(r.database_id) AS [Database]
		,r.Status
FROM	sys.dm_exec_requests r
		CROSS APPLY sys.dm_exec_sql_text (r.sql_handle) st
WHERE	r.session_id = @SPID;

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

