--http://www.sqlfingers.com/2018/05/which-sql-server-tables-have-triggers.html

SELECT
    so.name TriggerName,
    USER_NAME(so.uid) TriggerOwner,
    USER_NAME(so2.uid) TableSchema,
    OBJECT_NAME(so.parent_obj) TableName,
    OBJECTPROPERTY( so.id, 'ExecIsUpdateTrigger') IsUpdate,
    OBJECTPROPERTY( so.id, 'ExecIsDeleteTrigger') IsDelete,
    OBJECTPROPERTY( so.id, 'ExecIsInsertTrigger') IsInsert,
    OBJECTPROPERTY( so.id, 'ExecIsAfterTrigger') IsAfter,
    OBJECTPROPERTY( so.id, 'ExecIsInsteadOfTrigger') IsInsteadOf,
    OBJECTPROPERTY(so.id, 'ExecIsTriggerDisabled') IsDisabled
FROM
       sysobjects so INNER JOIN sysobjects so2
        ON so.parent_obj = so2.Id
WHERE
       so.type = 'TR'