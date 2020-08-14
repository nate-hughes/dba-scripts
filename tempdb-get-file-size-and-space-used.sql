USE tempdb;

--------- Show current size of TempDB files -----------
SELECT  name
        ,CONVERT(BIGINT,size*8.0/1024) 'Current Size in MB' 
		,CONVERT(BIGINT,FILEPROPERTY(name,'SpaceUsed')*8.0/1024) 'Used Size in MB'
FROM    sys.database_files;
--------- Show Iniial size of TempDB files -----------
SELECT  name
        ,CONVERT(BIGINT,size*8.0/1024)  'Initial Size in MB'
		,'DBCC SHRINKFILE (N''' + name + ''' , ' + CONVERT(VARCHAR(50),CONVERT(INT,size*8.0/1024)) + ')' AS 'Shrinkfile Cmd'
FROM	master.sys.sysaltfiles
WHERE	dbid = 2;
