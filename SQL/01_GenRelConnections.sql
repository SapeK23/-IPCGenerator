USE ETLRepoDB
GO 

/***************************************************************
** Change History
***************************************************************
** PR	Date			Author		Description		
---------------------------------------------------------------
** 1		10/05/2018	MS			Add header and logging 

***************************************************************/

ALTER PROCEDURE ipc.usp_GenConnection (@p_ETLGenerateVersion varchar(125) = NULL)
AS
BEGIN
    SET NOCOUNT ON;

    /* create relational connection */
    DECLARE @ETLGenerateVersion varchar(125)
	   , @IPC_UserName varchar(30)
	   , @IPC_UserPass varchar(30)
	   , @ConnUserName varchar(30)
	   , @ConnUserPass varchar(30)
	   , @IPC_BinPath varchar(255)
	   , @Cmd varchar(max)

    SET @ETLGenerateVersion = @p_ETLGenerateVersion
    SELECT @IPC_UserName = 'Administrator' 
	   , @IPC_UserPass = 'admin'
	   , @ConnUserName = 'usr_mig'
	   , @ConnUserPass = 'migrator!2'
	   , @IPC_BinPath = 'C:\Informatica\9.6.1\server\bin'
	   , @Cmd = ''

    /* Go to IPC bin directory */
    SET @Cmd = 'cd "' + @IPC_BinPath + '"' + char(10)

    /* Connect to repo */
    select @Cmd = @Cmd + 'pmrep connect -r "' + cp.IPC_RepoName + '" -d "' + cp.IPC_DomainName + '" -n "' + @IPC_UserName + '" -x "' + @IPC_UserPass + '"' + char(10)
    from ipc.ConfigProperties cp
    WHERE 1=1 
	   AND cp.ETLGenerateVersion = @ETLGenerateVersion
    
    SET @Cmd = @Cmd + char(10) 

    /* For each pair Server Database */
    ; WITH CTE (ServerName, DatabaseName) AS 
    (
    SELECT DISTINCT dfd.SourceServerName
	   , dfd.SourceDatabaseName
    FROM dbo.DataFlowDefinition dfd 
    WHERE 1=1 
    AND dfd.IsActive = '1'
    AND dfd.ETLGenerateVersion = @ETLGenerateVersion
    UNION 
    SELECT DISTINCT dfd.TargetServerName
	   , dfd.TargetDatabaseName 
    FROM dbo.DataFlowDefinition dfd 
    WHERE 1=1 
    AND dfd.IsActive = '1'
    AND dfd.ETLGenerateVersion = @ETLGenerateVersion
    ) 
    SELECT @Cmd = @Cmd + 'pmrep createconnection -s "Microsoft SQL Server" '
	   + '-n "SQL_' + CASE WHEN CHARINDEX('\', ServerName) > 0 THEN SUBSTRING(ServerName, 1, CHARINDEX('\', ServerName) -1 ) ELSE '' END + '_' + DatabaseName + '" '
	   + '-u "' + @ConnUserName + '" '
	   + '-p "' + @ConnUserPass + '" '
	   + '-l MS1252 '
	   + '-v "' + ServerName  + '" '
	   + '-b "' + DatabaseName + '" ' + char(10)
    FROM CTE as c

    --  pmrep createconnection -s "Microsoft SQL Server" -n "SQL_MALTAVM1_AdventureWorks2012" -u "usr_mig" -p "migrator!2" -l MS1252 -v "MALTAVM1\SQLSERVER" -b "AdventureWorks2012"
   SELECT @Cmd AS Cmd
END 



