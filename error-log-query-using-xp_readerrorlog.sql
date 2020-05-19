DECLARE @ArchiveID   INT --Value of error log file you want to read: 0 = current, 1 = Archive #1, 2 = Archive #2, etc...
       ,@LogFileType INT --Log file type: 1 or NULL = error log, 2 = SQL Agent log
       ,@Filter1Text NVARCHAR(4000) --Search string 1: String one you want to search for
       ,@Filter2Text NVARCHAR(4000) --Search string 2: String two you want to search for to further refine the results
       ,@FirstEntry  DATETIME --Search from start time
       ,@LastEntry   DATETIME --Search to end time
       ,@SortOrder   NVARCHAR(4000); --Sort order for results: N'asc' = ascending, N'desc' = descending

SELECT  @ArchiveID   = 0
       ,@LogFileType = 1
       ,@Filter1Text = 'SomeText'
       ,@Filter2Text = NULL
       ,@FirstEntry  = NULL
       ,@LastEntry   = NULL
       ,@SortOrder   = N'asc';

EXEC master.sys.xp_readerrorlog @ArchiveID
                               ,@LogFileType
                               ,@Filter1Text
                               ,@Filter2Text
                               ,@FirstEntry
                               ,@LastEntry
                               ,@SortOrder;
