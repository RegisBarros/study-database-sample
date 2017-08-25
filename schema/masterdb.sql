select * from sys.sql_logins
select * from sys.database_principals
select * from sys.databases
select * from sys.elastic_pool_resource_stats

EXEC('create database DB09 as copy of LabModel')
-- select * from sys.dm_database_copies

DECLARE @pwd VARCHAR(100)
EXEC('create login u08 with password=''' + @pwd + '''')

-- MASTERDB
CREATE DATABASE MASTERDB
ALTER DATABASE MASTERDB
modify (SERVICE_OBJECTIVE=ELASTIC_POOL(NAME=DBS))

CREATE MASTER KEY;
CREATE DATABASE SCOPED CREDENTIAL LabDataCredential
...

drop PROC setupDataSource
go
CREATE PROC setupDataSource(@servername VARCHAR(30), @dbname VARCHAR(30))
AS
DECLARE @server VARCHAR(30) = @servername;
DECLARE @db VARCHAR(30) =  @dbname;

	EXEC('
	CREATE EXTERNAL DATA SOURCE LabData
	WITH (
		TYPE = RDBMS, 
		LOCATION = ''' + @server + '.database.windows.net'', 
		DATABASE_NAME = ''' + @db + ''', 
		CREDENTIAL = LabDataCredential
		)'
	);
GO

EXEC setupDataSource 'sqlfcatae', 'DB08'
drop external data source LabData

select * from sys.external_data_sources

-- setup user with low privilege
sp_execute_remote N'LabData', 
		N'setupUser @loginname, @username', 
		N'@loginname VARCHAR(50), @username VARCHAR(50)',
		'u04',
		'dev'

-- List visible objects
sp_execute_remote N'LabData', 
		N'select * from sys.objects'

-- List visible objects
sp_execute_remote N'LabData', 
		N'setupUser @loginname, @username', 
		N'@loginname VARCHAR(50), @username VARCHAR(50)',
		'u08',
		'u08'

sp_execute_remote N'LabData', 
		N'setupRunAs @username',
		N'@username VARCHAR(50)',
		'dev'

CREATE PROC setupRunAs(@username VARCHAR(50))
WITH EXECUTE AS OWNER
AS
EXEC('EXEC(''setup'') AS USER=''' + @username + '''');

-- fix permission
sp_execute_remote N'LabData', 
		N'grant showplan to u08'