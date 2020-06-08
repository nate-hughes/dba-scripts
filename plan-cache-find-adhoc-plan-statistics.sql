
SELECT	T.AdHoc_Plan_MB
		,T.Total_Cache_MB,
        T.AdHoc_Plan_MB * 100.0 / T.Total_Cache_MB AS 'AdHoc %'
FROM	(
			SELECT	SUM(
						CASE
							WHEN objtype = 'adhoc' THEN TRY_CONVERT(BIGINT,size_in_bytes)
							ELSE 0
						END
					) / 1048576.0 AS AdHoc_Plan_MB
					,SUM(
						TRY_CONVERT(BIGINT,size_in_bytes)
					) / 1048576.0 AS Total_Cache_MB
			FROM sys.dm_exec_cached_plans
		) T;

SELECT	objtype AS [CacheType]
		,COUNT_BIG(*) AS [Total Plans]
		,SUM(
			CAST(size_in_bytes AS DECIMAL(18, 2))
		) / 1024 / 1024 AS [Total MBs]
		,AVG(usecounts) AS [Avg Use Count]
		,SUM(
			CAST((	CASE
						WHEN usecounts = 1 THEN size_in_bytes
						ELSE 0
					END) AS DECIMAL(18, 2))
		) / 1024 / 1024 AS [Total MBs – USE Count 1]
		,SUM(
			CASE
				WHEN usecounts = 1 THEN 1
				ELSE 0
			END) AS [Total Plans – USE Count 1]
FROM	sys.dm_exec_cached_plans
GROUP BY objtype
ORDER BY [Total MBs – USE Count 1] DESC;

