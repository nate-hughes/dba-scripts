WITH tmp AS(
SELECT
	distPkgs.*,
	ex.[folder_name],
	ex.[project_name],
	ex.[package_name],
	ex.[object_id] as project_id,
	ex.[status] AS lastStatus,
	CONVERT (DATETIME, ex.[start_time]) AS lastStart,--5. each package's last execution's first message, if any
	CONVERT( FLOAT,DATEDIFF(MILLISECOND, ex.[start_time], ISNULL(ex.[end_time], SYSDATETIMEOFFSET())))/1000 AS lastDur,
	--use TOP(1) since there's at most 1 message given the message id
  (SELECT TOP (1) 
    CASE WHEN LEN([message]) <= 4096 THEN [message] ELSE LEFT([message], 1024) + '...' END AS [message]
  FROM [SSISDB].[catalog].[event_messages] WHERE [operation_id] = distPkgs.[lastId] AND [event_message_id] IN
		--4. each operation's first errormessage id 
		(SELECT MIN([event_message_id])
		FROM [SSISDB].[catalog].[event_messages]
		WHERE [message_type] = 120
		GROUP BY [operation_id])
		) AS msg
FROM
--3. distinct packages, their last execution's full info
	(SELECT --2. distinct packages, their last execution id, nExecution, nFails
		DISTINCT([folder_name] + '\' + [project_name] + '\' + [package_name]) AS distPkg,
		MAX([execution_id]) AS lastId,
		COUNT(1) AS nEx,
		SUM([isFail]) AS nFail
	FROM 
	--1. derived column "isFail", for "nFail"
		(SELECT *, [isFail] = CASE WHEN [status] = 4 THEN 1 ELSE 0 END
		FROM [SSISDB].[catalog].[executions]) AS e
	WHERE CONVERT (DATETIME, [start_time]) >= DATEADD(HOUR, -24, GETDATE())
	GROUP BY ([folder_name] + '\' + [project_name] + '\' + [package_name])
	) distPkgs
	INNER JOIN
	[SSISDB].[catalog].[executions] ex ON distPkgs.[lastId] = ex.[execution_id]
),
tmp2 AS(
SELECT * FROM tmp LEFT JOIN--8. packages in 24 hours may *not* have successful duration in 3 months
		(SELECT--7. for packages in 24 hours, their average duration in 3 months
			[pkg], 
			CONVERT(FLOAT,ROUND(AVG([dur]),3)) AS refDur
		FROM
		--6. distint packages and their successful duration in last 3 months
			(SELECT ([folder_name] + '\' + [project_name] + '\' + [package_name]) AS pkg, 
      CONVERT( FLOAT, DATEDIFF(MILLISECOND, [start_time], ISNULL([end_time], SYSDATETIMEOFFSET())))/1000 AS dur
			FROM [SSISDB].[catalog].[executions] WHERE [status] = 7 AND CONVERT (DATETIME, [start_time]) >= DATEADD(MONTH, -3, GETDATE())) AS successEx3month
		WHERE [pkg] IN (SELECT [distPkg] FROM tmp)
		GROUP BY [pkg]
		) pkgAvgDur
		ON tmp.[distPkg] = pkgAvgDur.[pkg]
)
SELECT 
	tmp2.*, 
	CONVERT (DATETIME, ps.[last_deployed_time]) as last_deployed_time
FROM tmp2, [SSISDB].[catalog].[projects] ps
WHERE tmp2.project_id = ps.project_id
ORDER BY [lastStart] DESC

