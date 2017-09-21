CREATE TABLE #drives (
	drive CHAR
	, [free] INT
);
        
INSERT INTO #drives (drive, [free])
EXEC master..xp_fixeddrives;

SELECT drive
     , MB = [free] * 1.0 / 1024
     , TB = [free] * 1.0 / 1024 / 1024
FROM   #drives;

DROP TABLE #drives;

