USE [tempdb]
GO
CREATE TABLE dbo.TestDesc (
	SomeId INT NOT NULL IDENTITY(1,1)
	, SomeValue NUMERIC(19,5) NULL
	, SomeChars NVARCHAR(250) NULL
);
GO
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Identity column - Autonumber' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestDesc', @level2type=N'COLUMN',@level2name=N'SomeId';
EXEC sys.sp_addextendedproperty @name=N'Internal', @value=N'Identity column - Autonumber???' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestDesc', @level2type=N'COLUMN',@level2name=N'SomeId';
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Some Random Value...out to 5 decimal places' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestDesc', @level2type=N'COLUMN',@level2name=N'SomeValue';
EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Some Random String...250 characters' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestDesc', @level2type=N'COLUMN',@level2name=N'SomeChars';
GO
SELECT	d.value, c.*
FROM	sys.columns c
		LEFT OUTER JOIN fn_listextendedproperty(default, 'schema', 'dbo', 'table', 'TestDesc', 'column', default) d
			ON c.name = d.objname COLLATE Latin1_General_CI_AS
WHERE	object_id = OBJECT_ID('TestDesc');
GO
DROP TABLE dbo.TestDesc;
GO

