----------------------------------------------------------------------------
-- Create temp table, variables
----------------------------------------------------------------------------
-- Create a temp table to hold the view/table hierarchy
CREATE TABLE #viewHierarchy
( id INT IDENTITY(1,1)
, parent_view_id INT
, referenced_schema_name NVARCHAR(255)
, referenced_entity_name NVARCHAR(255)
, join_clause NVARCHAR(MAX)
, [LEVEL] TINYINT
, lineage NVARCHAR(MAX)
);
DECLARE @count INT -- Current ID
, @viewname NVARCHAR(1000);
-- Set the name of the top level view you want to detangle
SET @viewName = N'<ViewName>'
SET @count = 1;
----------------------------------------------------------------------------
-- Seed the table with the root view, and the root view's referenced tables.
----------------------------------------------------------------------------
INSERT INTO #viewHierarchy
SELECT NULL parent_view_id
, 'dbo' referenced_schema_name
, @viewName referenced_entity_name
, NULL join_clause
, 0 [LEVEL]
, '/' lineage;
INSERT INTO #viewHierarchy
SELECT DISTINCT @count parent_view_id
, referenced_schema_name
, referenced_entity_name
, '' join_clause
, 1 [LEVEL]
, '/1/' lineage
FROM sys.dm_sql_referenced_entities(@viewName,'OBJECT');
GO
----------------------------------------------------------------------------
-- Loop through the nested views.
----------------------------------------------------------------------------
DECLARE @count INT -- Current ID
, @maxCount INT -- Max ID of the temp table
, @viewname NVARCHAR(1000)
SET @count = 1;
SELECT @maxCount = MAX(id)
FROM #viewHierarchy;
WHILE (@count < @maxCount) -- While there are still rows to process...
BEGIN
SET @count = @count + 1;
    -- Get the name of the current view (that we'd like references for)
SELECT @viewName = referenced_entity_name
FROM #viewHierarchy
WHERE id = @count;
    -- If it's a view (not a table), insert referenced objects into temp table.
IF (EXISTS (SELECT name FROM sys.objects WHERE name = @viewName AND TYPE = 'v')
OR EXISTS (SELECT name FROM sys.objects WHERE name = @viewName AND TYPE = 'TF')
OR EXISTS (SELECT name FROM sys.objects WHERE name = @viewName AND TYPE = 'FN')) 
AND @viewName NOT IN ('Geography','Geography_to_Company','StatisticalArea','StatisticalArea_to_Company')
BEGIN
SET @viewName = N'dbo.' + @viewName;
INSERT INTO #viewHierarchy
SELECT DISTINCT @count parent_view_id
, referenced_schema_name
, referenced_entity_name
, '' join_clause
, NULL [LEVEL]
, '' lineage
FROM sys.dm_sql_referenced_entities(@viewName,'OBJECT');
SELECT @maxCount = MAX(id)
FROM #viewHierarchy;
END
END
--------------------------------------
--------------------------------------
WHILE EXISTS (SELECT 1 FROM #viewHierarchy WHERE [LEVEL] IS NULL)
UPDATE T
SET T.[Level] = P.[Level] + 1,
T.Lineage = P.Lineage + LTRIM(STR(T.parent_view_id,6,0)) + '/'
FROM #viewHierarchy AS T
INNER JOIN #viewHierarchy AS P ON (T.parent_view_id=P.ID)
WHERE P.[Level]>=0
AND P.Lineage IS NOT NULL
AND T.[Level] IS NULL
SELECT       parent.*
,child.id
,child.referenced_entity_name ChildName
FROM #viewHierarchy parent
RIGHT OUTER JOIN #viewHierarchy child ON child.parent_view_id = parent.id
ORDER BY parent.id, child.id

--SELECT * FROM #viewHierarchy

drop table #viewHierarchy