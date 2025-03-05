DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
		,@ColumnName AS NVARCHAR(MAX);
 
DROP TABLE IF EXISTS #CourseSales;
CREATE TABLE #CourseSales (Course VARCHAR(50), Year INT, Earning INT);
INSERT #CourseSales VALUES
('course_a',2020, 1), ('course_a',2021,2)
, ('course_b',2019,1), ('course_b',2020,2),('course_b',2021,3)
, ('course_c',2018,1), ('course_c',2019,2), ('course_c',2020,3),('course_c',2021,4)
, ('other',2019,2), ('other',2020,4), ('other',2021,6);

--Get distinct values of the PIVOT Column(s) 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') + QUOTENAME(Course)
FROM (SELECT DISTINCT Course FROM #CourseSales) AS Courses;
 
--Prepare the PIVOT query using the dynamic value(s)
SET @DynamicPivotQuery = 
  N'SELECT Year, ' + @ColumnName + '
    FROM #CourseSales
    PIVOT(SUM(Earning) 
          FOR Course IN (' + @ColumnName + ')) AS PVTTable';

--Execute the Dynamic Pivot Query
EXEC sp_executesql @DynamicPivotQuery;