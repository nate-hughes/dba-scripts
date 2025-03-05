
DECLARE @l_tblname    NVARCHAR(128) = N''
       ,@l_FillFactor NUMERIC(5, 1) = 100
       ,@l_tblid      INT;

SELECT  @l_tblid = object_id
FROM    sys.tables
WHERE   name = @l_tblname;

SELECT  x.Fixed_Data_Size + x.Variable_Data_Size + x.Null_Bitmap + 4                                                AS Row_Size
       ,8096 / ((x.Fixed_Data_Size + x.Variable_Data_Size + x.Null_Bitmap + 4) + 2)                                 AS Rows_Per_Page
       ,8096 * ((100 - @l_FillFactor) / 100) / ((x.Fixed_Data_Size + x.Variable_Data_Size + x.Null_Bitmap + 4) + 2) AS Free_Rows_Per_Page
FROM
(
    SELECT  COUNT(c.column_id)                                                                              AS Num_Cols
           ,SUM(CASE WHEN t.precision > 0 THEN t.max_length
                    WHEN t.name IN ('CHAR', 'NCHAR') THEN c.max_length
                END
            )                                                                                               AS Fixed_Data_Size
           ,COUNT(CASE WHEN t.precision = 0 AND t.name NOT IN ('CHAR', 'NCHAR') THEN 1 END)                 AS Num_Variable_Cols
           ,SUM(CASE WHEN t.precision = 0 AND  t.name NOT IN ('CHAR', 'NCHAR') THEN c.max_length END)       AS Max_Var_Size
           ,2 + (COUNT(CASE WHEN t.precision = 0 AND t.name NOT IN ('CHAR', 'NCHAR') THEN 1 END) * 2)
				+ SUM(CASE WHEN t.precision = 0 AND  t.name NOT IN ('CHAR', 'NCHAR') THEN c.max_length END) AS Variable_Data_Size
           ,2 + ((COUNT(c.column_id) + 7) / 8)											                    AS Null_Bitmap
    FROM    sys.columns c
            INNER JOIN sys.types t
                ON c.system_type_id = t.system_type_id
    WHERE   c.object_id = @l_tblid
) x;