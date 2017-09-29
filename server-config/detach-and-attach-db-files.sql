USE master;
GO

-- create detach statements
SELECT  'ALTER DATABASE ' + name + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; EXEC sys.sp_detach_db ''' + name + ''', ''true'';' AS DetachScript
FROM    sys.databases
WHERE   name NOT IN ('master', 'model', 'msdb', 'tempdb', 'Resource', 'distribution', 'reportserver'
                    ,'reportservertempdb'
                    );

-- create attach statements
DECLARE	@tmp_AttachScript TABLE (
	DBName sysname
	,AttachScript VARCHAR(MAX)
	,Processed BIT DEFAULT 0
);

INSERT @tmp_AttachScript (DBName, AttachScript)
SELECT	name AS DBName
		,'EXEC sys.sp_attach_db @dbname = ''' + name + ''''
FROM    sys.databases
WHERE   name NOT IN ('master', 'model', 'msdb', 'tempdb', 'Resource', 'distribution', 'reportserver'
                    ,'reportservertempdb'
                    );

DECLARE @sql NVARCHAR(MAX)
		,@DBName sysname;

DECLARE @tmp_DBFiles TABLE (
	data_space_id INT
	,physical_name NVARCHAR(260)
);

WHILE EXISTS (SELECT 1 FROM @tmp_AttachScript WHERE Processed = 0)
BEGIN
	SELECT	@DBName = DBName
	FROM	@tmp_AttachScript
	WHERE	Processed = 0;
	
	DELETE	
	FROM	@tmp_DBFiles;

    SET @sql = N'SELECT	data_space_id, physical_name FROM ' + @DBName + '.sys.database_files;'

	INSERT @tmp_DBFiles (data_space_id, physical_name)
	EXEC sys.sp_executesql @sql;

	UPDATE	upd
	SET		upd.AttachScript = upd.AttachScript + f.filelist + ';'
	FROM	@tmp_AttachScript upd
			INNER JOIN (
				SELECT	src.DBName
					,STUFF((
					SELECT	',@filename' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT 100)) AS VARCHAR(10)) + ' = N''' + physical_name + ''''
					FROM	@tmp_DBFiles tbl
					FOR XML PATH(''),TYPE).value('.','VARCHAR(MAX)'),1,0,'') AS filelist
				FROM	(
							SELECT	*
							FROM	@tmp_AttachScript
							WHERE	DBName = @DBName
						) src
			) f ON upd.DBName = f.DBName;	

	UPDATE	@tmp_AttachScript
	SET		Processed = 1
	WHERE	DBName = @DBName;
END;

SELECT	AttachScript
FROM	@tmp_AttachScript;

