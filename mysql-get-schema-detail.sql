-- Find DB Size
SELECT	table_schema AS Database_Name
		,ROUND(SUM(data_length) / 1024 / 1024, 2) AS TableSizeInMB
		,ROUND(SUM(index_length) / 1024 / 1024, 2) AS IndexSizeInMB
		,ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS UsedSizeInMB
        ,ROUND(SUM(data_free) / 1024 / 1024, 2) AS FreeSpaceInMB 
FROM	information_schema.tables
WHERE	table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys', 'tmp')
GROUP BY table_schema;

-- Find Table Size
SET @Database_NAME = null;
SET @Table_NAME = null;
SELECT	table_name AS TableName
		,ROUND((data_length) / 1024 / 1024, 2) AS TableSizeInMB
		,ROUND((index_length) / 1024 / 1024, 2) AS IndexSizeInMB
		,ROUND(((data_length + index_length) / 1024 / 1024), 2) AS UsedSizeInMB
        ,ROUND((data_free) / 1024 / 1024, 2) AS FreeSpaceInMB 
FROM	information_schema.tables
WHERE	(@Database_NAME IS NULL OR table_schema = @Database_NAME)
AND		(@Table_Name IS NULL OR table_name = @Table_NAME)
AND		table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys', 'tmp');

-- Find Tables without a PK
SET @Database_NAME = null;
SELECT	table_schema
		,table_name
FROM	information_schema.columns
WHERE	(@Database_NAME IS NULL OR table_schema = @Database_NAME)
AND		table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys', 'tmp')
GROUP BY table_schema
		,table_name
HAVING SUM(IF(column_key IN('PRI', 'UNI'), 1, 0)) = 0;

-- Find Missing Indexes (for columns ending with 'id')
SET @Database_NAME = null;
SELECT	t.TABLE_SCHEMA
		,t.TABLE_NAME
		,c.COLUMN_NAME
		,IFNULL(kcu.CONSTRAINT_NAME, 'Not indexed') AS Indexed
FROM	information_schema.tables t
		INNER JOIN information_schema.columns c
			ON c.TABLE_SCHEMA = t.TABLE_SCHEMA
			AND c.TABLE_NAME = t.TABLE_NAME
			AND c.COLUMN_NAME LIKE '%_id'
		LEFT JOIN information_schema.key_column_usage kcu
			ON kcu.TABLE_SCHEMA = t.TABLE_SCHEMA
			AND kcu.TABLE_NAME = t.TABLE_NAME
			AND kcu.COLUMN_NAME = c.COLUMN_NAME
			AND kcu.ORDINAL_POSITION = 1
WHERE	(@Database_NAME IS NULL OR t.table_schema = @Database_NAME)
AND		kcu.TABLE_SCHEMA IS NULL
AND		t.TABLE_SCHEMA NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys', 'tmp');

-- Find FK References
SET @Database_NAME = null;
SELECT	referenced_table_name AS ParentTable
		,table_name AS ChildTable
		,constraint_name AS ConstraintName
FROM	information_schema.KEY_COLUMN_USAGE
WHERE	(@Database_NAME IS NULL OR table_schema = @Database_NAME)
AND		referenced_table_name IS NOT NULL
ORDER BY referenced_table_name;

-- Find Table Last Updated Time
SET @Database_NAME = null;
SET @Table_NAME = null;
SELECT	TABLE_SCHEMA
		,TABLE_NAME
		,UPDATE_TIME
FROM	information_schema.tables
WHERE	(@Database_NAME IS NULL OR TABLE_SCHEMA = @Database_NAME)
AND		(@Table_Name IS NULL OR TABLE_NAME = @Table_NAME)
AND		TABLE_SCHEMA NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys', 'tmp');

SHOW TABLE STATUS FROM Database_Name LIKE 'Table_Name';

-- Find Index Details
SET @Database_NAME = null;
SELECT	TABLE_SCHEMA
		,TABLE_NAME
        ,NON_UNIQUE
		,INDEX_NAME
		,SEQ_IN_INDEX
		,COLUMN_NAME
        ,COLLATION
		,CARDINALITY
        ,NULLABLE
		,INDEX_TYPE    
FROM	information_schema.STATISTICS 
WHERE	(@Database_NAME IS NULL OR TABLE_SCHEMA = @Database_NAME);

-- Find Table Dependencies in FK Constraints
SET @Database_NAME = null;
SET @Table_NAME = null;
SELECT	Constraint_Type
		,Constraint_Name
		,Table_Schema
		,Table_Name
FROM	information_schema.table_constraints
WHERE	Constraint_Type = 'FOREIGN KEY'
AND		(@Database_NAME IS NULL OR Table_Schema = @Database_NAME)
AND		(@Table_Name IS NULL OR Table_Name = @Table_NAME);

-- Find Table Dependencies in Views
SELECT	TABLE_SCHEMA
		,TABLE_NAME
        ,VIEW_DEFINITION
        ,CHECK_OPTION
        ,IS_UPDATABLE
FROM	information_schema.views 
WHERE	(@Database_NAME IS NULL OR Table_Schema = @Database_NAME)
AND		(@Table_Name IS NULL OR Table_Name = @Table_NAME);
  
-- Find Table Dependencies in Stored Procedures
SELECT	Table_Schema
		,Table_Name
		,Table_Type
		,Engine
		,Routine_Name
		,Routine_Schema
		,Routine_Type
        ,Routine_Definition
        ,Last_Altered
FROM	information_schema.tables
		INNER JOIN information_schema.routines
			ON routines.routine_definition LIKE CONCAT('%', tables.table_name, '%')
WHERE	(@Database_NAME IS NULL OR Table_Schema = @Database_NAME)
AND		(@Table_Name IS NULL OR Table_Name = @Table_NAME);


