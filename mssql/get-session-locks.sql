
declare @spid int = 55
		,@captures int = 10
		,@loop int = 1
		,@delay varchar(10) = '0:00:03';

drop table if exists #lock_detail;

create table #lock_detail (spid int, dbid int, objid bigint, indid int, type varchar(10), resource varchar(50), mode varchar(50), status varchar(50));

while @loop <= @captures
begin
	waitfor delay @delay;
	
	insert #lock_detail
	exec sp_lock @spid;

	set @loop += 1;
end;

select	spid
		,db_name(dbid) as db
		,objid
		,indid
		,type
		,resource
		,mode
		,status
from	#lock_detail
where	1=1
--and		type <> 'db'
--and		db_name(dbid) = 'tempdb'
