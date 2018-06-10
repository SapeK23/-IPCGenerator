use testdb
go 

if object_id('dbo.RowVersionTable') is not null
    drop table [dbo].[RowVersionTable]

create table dbo.RowVersionTable
(
    id int not null,
    RowVer rowversion
)

insert into dbo.RowVersionTable (id)
select Id
from (values (1), (2), (3), (4)) as src(id)

select * from dbo.RowVersionTable




if object_id('dbo.RowVersionTableIPC') is not null
    drop table [dbo].[RowVersionTableIPC]

CREATE TABLE [dbo].[RowVersionTableIPC](
	[id] [int] NOT NULL,
	[RowVer] binary(8) NOT NULL
) ON [PRIMARY]

GO

insert into [dbo].[RowVersionTableIPC] (id, [RowVer])
select *
from [dbo].[RowVersionTable]

select * from [dbo].[RowVersionTableIPC]

truncate table [dbo].[RowVersionTableIPC]

select * from [dbo].[RowVersionTableIPC] where rowVer > '0x000000000000000'

select convert(binary(8), 0)

select convert(bigint, 0x00000000000000032, 1)
0x0000000000000000

SELECT RowVersionTable.id, RowVersionTable.RowVer FROM RowVersionTable WHERE RowVersionTable.RowVer > convert(varbinary(256), '0x0000000000000000', 1)
SELECT RowVersionTable.id, cast(cast(RowVersionTable.RowVer as binary(8)) as varchar(max)) as RowVer FROM RowVersionTable WHERE RowVersionTable.RowVer > convert(varbinary(256), '0x0000000000000000', 1)
SELECT RowVersionTable.id
    , RowVersionTable.RowVer
    , cast(RowVersionTable.RowVer as binary(8)) as RowVerBIN
    , convert(varchar(max), cast(RowVersionTable.RowVer as binary(8)), 1) as RowVerCHAR 
FROM RowVersionTable WHERE RowVersionTable.RowVer > convert(varbinary(256), '0x0000000000000000', 1)

SELECT RowVersionTable.id, RowVersionTable.RowVer, convert(int, RowVersionTable.RowVer)
FROM RowVersionTable WHERE RowVersionTable.RowVer > 0x0000000000004652

declare @b varbinary(max)
set @b = 0x5468697320697320612074657374

select cast(@b as varchar(max)) /*Returns "This is a test"*/