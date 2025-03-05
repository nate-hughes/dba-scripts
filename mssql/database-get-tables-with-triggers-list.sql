--http://www.sqlfingers.com/2018/05/which-sql-server-tables-have-triggers.html

SELECT
    so.name TriggerName,
    SCHEMA_NAME(so.schema_id) TableSchema,
    OBJECT_NAME(so.parent_object_id) TableName,
    OBJECTPROPERTY( so.object_id, 'ExecIsUpdateTrigger') IsUpdate,
    OBJECTPROPERTY( so.object_id, 'ExecIsDeleteTrigger') IsDelete,
    OBJECTPROPERTY( so.object_id, 'ExecIsInsertTrigger') IsInsert,
    OBJECTPROPERTY( so.object_id, 'ExecIsAfterTrigger') IsAfter,
    OBJECTPROPERTY( so.object_id, 'ExecIsInsteadOfTrigger') IsInsteadOf,
    OBJECTPROPERTY( so.object_id, 'ExecIsTriggerDisabled') IsDisabled
FROM
       sys.objects so
WHERE
       so.type = 'TR'