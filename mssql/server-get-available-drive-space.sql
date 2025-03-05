DECLARE @drives TABLE (
	drive CHAR
	, [free] INT
);
        
INSERT INTO @drives (drive, [free])
EXEC master..xp_fixeddrives;

SELECT drive
     , [free] * 1.0 / 1024 AS MB
     , [free] * 1.0 / 1024 / 1024 AS TB
FROM   @drives;


--/*
--https://blog.sqlauthority.com/2017/09/22/sql-server-new-dmv-sql-server-2017-sys-dm_os_enumerate_fixed_drives-replacement-xp_fixeddrives/
--*/
--SELECT  fixed_drive_path
--       ,free_space_in_bytes / (1024 * 1024) AS MB
--       ,drive_type_desc
--FROM    sys.dm_os_enumerate_fixed_drives;
