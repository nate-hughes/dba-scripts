
SELECT  
    OBJECT_NAME(s.object_id) AS TableName,
    s.name AS StatisticName,
    STATS_DATE(s.object_id, s.stats_id) AS LastUpdatedDate,
    sp.modification_counter AS RowsModifiedSinceLastUpdate
FROM  
    sys.stats s
CROSS APPLY  
    sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
WHERE  
    OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1  -- Filter for user tables
ORDER BY  
    TableName, StatisticName;
