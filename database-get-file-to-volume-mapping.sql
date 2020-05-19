
SELECT	DatabaseName = DB_NAME(f.database_id)
		, VolumeLetter = UPPER(LEFT(f.physical_name, 3))
		, LogicalFileName = f.name
		--, FileId = f.[file_id]
		--, FilegroupId = f.data_space_id
		, PhysicalFileName = f.physical_name 
		, FileGroup = CASE WHEN f.data_space_id = 0 THEN 'LOG'
							ELSE s.name
						END
		, DefaultFilegroup = CASE WHEN s.is_default = 1 THEN 'Y'
									ELSE ''
								END
		, [Size] = CONVERT(NVARCHAR(15), CONVERT(BIGINT, f.size) * 8 / 1024) + N' MB'
		, [MaxSize] = CASE f.max_size WHEN -1 THEN N'Unlimited' 
										ELSE CONVERT(NVARCHAR(15), CONVERT(BIGINT, f.max_size) * 8 / 1024) + N' MB' 
						END
		, [Growth] = CASE f.is_percent_growth WHEN 1 THEN CONVERT(NVARCHAR(15), f.growth) + N'%' 
												ELSE CONVERT(NVARCHAR(15), CONVERT(BIGINT, f.growth) * 8 / 1024) + N' MB' 
						END
FROM	sys.master_files f
		LEFT OUTER JOIN sys.data_spaces s
			ON f.data_space_id = s.data_space_id
ORDER BY DB_NAME(f.database_id)
		, f.file_id;
