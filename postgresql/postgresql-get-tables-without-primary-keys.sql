/*
tables_without_primary_key.sql
Lists schema-qualified tables that have NO primary key
*/
SELECT
    n.nspname      AS schema_name,
    c.relname      AS table_name,
    pg_total_relation_size(c.oid) AS table_bytes -- optional: size visibility
FROM
    pg_class      c
JOIN
    pg_namespace  n ON n.oid = c.relnamespace
WHERE
    c.relkind IN ('r', 'p')               -- ordinary tables and partitioned tables
    AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
    AND NOT EXISTS (                       -- no PK constraint found
        SELECT 1
        FROM   pg_constraint con
        WHERE  con.conrelid = c.oid
          AND  con.contype  = 'p'          -- ‘p’ = primary key
    )
ORDER BY
    n.nspname,
    c.relname;


/*
tables_without_pk_and_unique_check.sql
Lists every table that lacks a PRIMARY KEY and indicates whether a UNIQUE index exists.
*/
WITH    tables AS (
        SELECT c.oid                  AS relid,
               n.nspname              AS schema_name,
               c.relname              AS table_name
        FROM   pg_class     c
        JOIN   pg_namespace n ON n.oid = c.relnamespace
        WHERE  c.relkind IN ('r','p')                      -- ordinary & partitioned tables
          AND  n.nspname NOT IN ('pg_catalog',
                                 'information_schema',
                                 'pg_toast')               -- skip system schemas
          AND NOT EXISTS (                                 -- table has *no* PRIMARY KEY
                SELECT 1
                FROM   pg_constraint con
                WHERE  con.conrelid = c.oid
                  AND  con.contype  = 'p'                  -- 'p' = primary key
          )
),    uniq AS (
        /* Gather non-PK UNIQUE indexes per table */
        SELECT i.indrelid                               AS relid,
               bool_or(i.indisunique)                   AS has_unique_index,
               string_agg(ci.relname, ', ' ORDER BY ci.relname) AS unique_indexes
        FROM   pg_index  i
        JOIN   pg_class  ci ON ci.oid = i.indexrelid
        WHERE  i.indisunique
          AND  NOT i.indisprimary                       -- ignore the PK itself
        GROUP  BY i.indrelid
)
SELECT  t.schema_name,
        t.table_name,
        COALESCE(u.has_unique_index, FALSE) AS has_unique_index,
        u.unique_indexes                     AS unique_index_names
FROM    tables t
LEFT    JOIN uniq u ON u.relid = t.relid      -- NULL → no UNIQUE index found
ORDER BY t.schema_name, t.table_name;
