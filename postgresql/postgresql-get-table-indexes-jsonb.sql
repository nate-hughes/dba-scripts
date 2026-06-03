-- Replace :schema_name with your schema (e.g. 'customer')
WITH idx AS (
  SELECT
      n.nspname                              AS schema_name
    , t.relname                              AS table_name
    , i.relname                              AS index_name
    , am.amname                              AS index_method
    , pg_get_indexdef(i.oid)                 AS index_def
    , pg_get_expr(x.indexprs, t.oid)         AS index_expr
    , x.indkey                               AS indkey
    , x.indclass                             AS indclass
    , t.oid                                  AS table_oid
  FROM pg_index x
  JOIN pg_class        i ON i.oid = x.indexrelid
  JOIN pg_class        t ON t.oid = x.indrelid
  JOIN pg_namespace    n ON n.oid = t.relnamespace
  JOIN pg_am          am ON am.oid = i.relam
  -- WHERE n.nspname = :schema_name
)
SELECT
    schema_name
  , table_name
  , index_name
  , index_method
  , index_def
  , CASE
      WHEN index_expr IS NOT NULL THEN 'expression'
      ELSE 'column'
    END AS index_key_kind
FROM idx
WHERE
  -- Case 1: any indexed column is JSONB
  EXISTS (
    SELECT 1
    FROM unnest(indkey) WITH ORDINALITY AS k(attnum, ord)
    JOIN pg_attribute a
      ON a.attrelid = table_oid
     AND a.attnum   = k.attnum
    WHERE a.atttypid = 'jsonb'::regtype
  )
  OR
  -- Case 2: opclass indicates JSONB (covers jsonb_ops / jsonb_path_ops)
  EXISTS (
    SELECT 1
    FROM unnest(indclass) WITH ORDINALITY AS oc(opclass, ord)
    JOIN pg_opclass opc ON opc.oid = oc.opclass
    JOIN pg_type    tp  ON tp.oid  = opc.opcintype
    WHERE tp.typname = 'jsonb'
  )
  OR
  -- Case 3: expression index extracts from JSON (operators ->, ->>, #>, #>>)
  (index_expr IS NOT NULL AND index_expr ~ '(->>|->|#>>|#>)');
