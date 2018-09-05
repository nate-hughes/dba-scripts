SET NOCOUNT ON;

/*
-- CHECK ON/OFF STATUS OF TRACE FLAG 3226 --
-- SUPPRESSES BACKUP SUCCESS MESSAGES TO ERRORLOG AND SYSTEM EVENT LOG --
DBCC TRACESTATUS (3226, -1) WITH NO_INFOMSGS;

-- ENABLE TRACE FLAG 3226
DBCC TRACEON(3226,-1) 

-- DISABLE TRACE FLAG 3226
DBCC TRACEOFF (3226,-1)
*/

DECLARE @RunDate DATETIME = GETDATE();

-- RETRIEVE BACKUP INFO --
WITH BackupInfo (backup_start_date, backup_finish_date, backup_type, backup_size, database_name, has_backup_checksums
                ,is_damaged, compressed_backup_size, logical_device_name, physical_device_name, device_type
) AS (
    SELECT  bs.backup_start_date
           ,bs.backup_finish_date
           ,CASE bs.type
                 WHEN 'D' THEN 'Full backup'
                 WHEN 'I' THEN 'Differential'
                 WHEN 'L' THEN 'Log'
                 WHEN 'F' THEN 'File/Filegroup'
                 WHEN 'G' THEN 'Differential file'
                 WHEN 'P' THEN 'Partial'
                 WHEN 'Q' THEN 'Differential partial'
                 WHEN NULL THEN 'No backups'
                 ELSE 'Unknown (' + bs.type + ')'
            END
           ,bs.backup_size
           ,bs.database_name
           ,bs.has_backup_checksums
           ,bs.is_damaged
           ,bs.compressed_backup_size
           ,bmf.logical_device_name
           ,bmf.physical_device_name
           ,CASE WHEN bmf.device_type IN (2, 102) THEN 'DISK'
                 WHEN bmf.device_type IN (5, 105) THEN 'TAPE'
            END
    FROM    msdb..backupset                         bs
            LEFT OUTER JOIN msdb..backupmediafamily bmf
                ON bs.media_set_id = bmf.media_set_id
)

-- REPORT ON DATABASE / BACKUP INFO --
SELECT  d.database_id                                                                                            AS DatabaseId
       ,d.name                                                                                                   AS DatabaseName
       ,CASE d.compatibility_level
             WHEN 70 THEN '7'
             WHEN 80 THEN '2000'
             WHEN 90 THEN '2005'
             WHEN 100 THEN '2008'
             WHEN 110 THEN '2012'
             WHEN NULL THEN 'OFFLINE'
        END                                                                                                      AS SQLVersion
       ,d.recovery_model_desc                                                                                    AS RecoveryModel
       ,d.state_desc                                                                                             AS DatabaseState
       ,CASE d.state
             WHEN 0 THEN 'N/A'
             ELSE CASE d.is_cleanly_shutdown
                       WHEN 1 THEN 'NO RECOVERY'
                       WHEN 0 THEN 'RECOVERY'
                  END
        END                                                                                                      AS RecoveryState
       ,mx.backup_last_30                                                                                        AS BackupsLast30Days
       ,bak.backup_start_date                                                                                    AS MostRecentBackup
       ,bak.backup_type                                                                                          AS MostRecentType
       ,SUM(CONVERT(INT, bak.compressed_backup_size / 1024 /*KB*/ / 1024 /*MB*/))                                AS MostRecentSize_MB
       ,AVG(CONVERT(NUMERIC(4, 1), (1 - (bak.compressed_backup_size * 1.0 / NULLIF(bak.backup_size, 0))) * 100)) AS CompressionRatio
       ,SUM(CONVERT(INT, mx.backup_avg_size / 1024 /*KB*/ / 1024 /*MB*/))                                        AS Last30AvgSize_MB
       ,DATEDIFF(SS, bak.backup_start_date, bak.backup_finish_date)                                              AS MostRecentDuration_sec
       ,mx.backup_avg_duration                                                                                   AS Last30AvgDuration_sec
       ,bak.logical_device_name                                                                                  AS MostRecentLogicalDevice
       ,CASE WHEN COUNT(bak.physical_device_name) > 1 THEN 'MULTIPLE'
             ELSE MAX(bak.physical_device_name)
        END                                                                                                      AS MostRecentPhysicalDevice
       ,bak.device_type                                                                                          AS MostRecentDeviceType
       ,bak.has_backup_checksums                                                                                 AS UsedCHECKSUM
       ,bak.is_damaged                                                                                           AS BackupDamaged
       ,CASE WHEN d.recovery_model = 3 /*SIMPLE*/ THEN 0
             ELSE 1
        END                                                                                                      AS LogBackupCheck
FROM    sys.databases              d
        LEFT OUTER JOIN (
                            SELECT  DB_ID(BackupInfo.database_name)                                                AS database_id
                                   ,BackupInfo.backup_type
                                   ,MAX(BackupInfo.backup_start_date)                                              AS backup_start_date
                                   ,SUM(   CASE WHEN BackupInfo.backup_start_date BETWEEN DATEADD(DD, -30, @RunDate) AND @RunDate THEN
                                                    1
                                                ELSE 0
                                           END
                                       )                                                                           AS backup_last_30
                                   ,AVG(DATEDIFF(SS, BackupInfo.backup_start_date, BackupInfo.backup_finish_date)) AS backup_avg_duration
                                   ,AVG(BackupInfo.compressed_backup_size)                                         AS backup_avg_size
                            FROM    BackupInfo
                            GROUP BY DB_ID(BackupInfo.database_name)
                                    ,BackupInfo.backup_type
                        )          mx
            ON d.database_id = mx.database_id
        LEFT OUTER JOIN BackupInfo bak
            ON  mx.database_id = DB_ID(bak.database_name)
            AND mx.backup_start_date = bak.backup_start_date
GROUP BY d.database_id
        ,d.name
        ,CASE d.compatibility_level
              WHEN 70 THEN '7'
              WHEN 80 THEN '2000'
              WHEN 90 THEN '2005'
              WHEN 100 THEN '2008'
              WHEN 110 THEN '2012'
              WHEN NULL THEN 'OFFLINE'
         END
        ,d.recovery_model_desc
        ,d.state_desc
        ,CASE d.state
              WHEN 0 THEN 'N/A'
              ELSE CASE d.is_cleanly_shutdown
                        WHEN 1 THEN 'NO RECOVERY'
                        WHEN 0 THEN 'RECOVERY'
                   END
         END
        ,mx.backup_last_30
        ,bak.backup_start_date
        ,bak.backup_type
        ,DATEDIFF(SS, bak.backup_start_date, bak.backup_finish_date)
        ,mx.backup_avg_duration
        ,bak.logical_device_name
        ,bak.device_type
        ,bak.has_backup_checksums
        ,bak.is_damaged
        ,CASE WHEN d.recovery_model = 3 /*SIMPLE*/ THEN 0
              ELSE 1
         END
ORDER BY d.name;
