SELECT  CONCAT(S.name, '.', O.name)   AS BaseTable
       ,C.name                        AS BaseColumn
       ,CONCAT(S2.name, '.', O2.name) AS ReferenceTable
       ,CONCAT(
                  'alter table ', S.name, '.', O.name, ' with check  add constraint FK_', O.name, '_', O2.name
                 ,'  foreign key (', C.name, ') references ', S2.name, '.', O2.name, '(' + IDC.name + ')'
              )                       AS FKCreateStatement
FROM    sys.columns                       C
        INNER JOIN sys.identity_columns   IDC
            ON  (IDC.name = C.name OR   C.name = OBJECT_NAME(IDC.object_id) + IDC.name)
            AND C.object_id <> IDC.object_id
            AND C.is_identity = 0 --exlude Columns which are identities
        INNER JOIN sys.objects            O
            ON  O.object_id = C.object_id
            AND O.is_ms_shipped = 0
            AND O.type = 'u'
        INNER JOIN sys.schemas            S
            ON S.schema_id = O.schema_id
        INNER JOIN sys.objects            O2
            ON  O2.object_id = IDC.object_id
            AND O2.is_ms_shipped = 0
            AND O2.type = 'u'
        INNER JOIN sys.schemas            S2
            ON S2.schema_id = O2.schema_id
        LEFT JOIN sys.foreign_key_columns FKC
            ON  IDC.object_id = FKC.referenced_object_id
            AND FKC.referenced_column_id = IDC.column_id
        INNER JOIN
        (
            SELECT  I.object_id
                   ,IC.index_id
            FROM    sys.index_columns      IC
                    INNER JOIN sys.indexes I
                        ON  I.object_id = IC.object_id
                        AND I.index_id = IC.index_id
            WHERE  I.is_primary_key = 1
            GROUP BY I.object_id
                    ,IC.index_id
            HAVING COUNT(*) = 1
        )                                 SingleColumnPK
            ON IDC.object_id = SingleColumnPK.object_id
WHERE   FKC.referenced_object_id IS NULL
AND     C.name <> 'ID'
ORDER BY 1;


SELECT  (S.name + '.' + O.name)   AS BaseTable
       ,C.name                    AS BaseColumn
       ,(S2.name + '.' + O2.name) AS ReferenceTable
       ,('alter table ' + S.name + '.' + O.name + ' with check add constraint FK_' + O.name + '_' + O2.name
         + ' foreign key (' + C.name + ') references ' + S2.name + '.' + O2.name + '(' + IDC.name + ')'
        )                         AS FKCreateStatement
FROM    sys.columns                       C
        INNER JOIN sys.identity_columns   IDC
            ON  (IDC.name = C.name OR   C.name = OBJECT_NAME(IDC.object_id) + IDC.name)
            AND C.object_id <> IDC.object_id
            AND C.is_identity = 0 --exlude Columns which are identities
        INNER JOIN sys.objects            O
            ON  O.object_id = C.object_id
            AND O.is_ms_shipped = 0
            AND O.type = 'u'
        INNER JOIN sys.schemas            S
            ON S.schema_id = O.schema_id
        INNER JOIN sys.objects            O2
            ON  O2.object_id = IDC.object_id
            AND O2.is_ms_shipped = 0
            AND O2.type = 'u'
        INNER JOIN sys.schemas            S2
            ON S2.schema_id = O2.schema_id
        LEFT JOIN sys.foreign_key_columns FKC
            ON  IDC.object_id = FKC.referenced_object_id
            AND FKC.referenced_column_id = IDC.column_id
        INNER JOIN
        (
            SELECT  I.object_id
                   ,IC.index_id
            FROM    sys.index_columns      IC
                    INNER JOIN sys.indexes I
                        ON  I.object_id = IC.object_id
                        AND I.index_id = IC.index_id
            WHERE  I.is_primary_key = 1
            GROUP BY I.object_id
                    ,IC.index_id
            HAVING COUNT(*) = 1
        )                                 SingleColumnPK
            ON IDC.object_id = SingleColumnPK.object_id
WHERE   FKC.referenced_object_id IS NULL
AND     C.name <> 'ID'
ORDER BY 1;