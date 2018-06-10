USE ETLRepoDB
GO

/***************************************************************
** Change History
***************************************************************
** PR	Date			Author		Description		
---------------------------------------------------------------
** 1		10/05/2018	MS			Add header and logging 

***************************************************************/

ALTER PROCEDURE ipc.usp_GenerateTarget (@p_SchemaName VARCHAR(50), @p_TableName VARCHAR(50), @p_ETLGenerateVersion VARCHAR(125), @OutXML nvarchar(max) OUT)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SchemaName VARCHAR(50), @TableName VARCHAR(50), @ETLGenerateVersion VARCHAR(125)

    --/*
    SELECT @SchemaName = @p_SchemaName
	   , @TableName = @p_TableName
	   , @ETLGenerateVersion = @p_ETLGenerateVersion
    /*
    SELECT @SchemaName = 'Sales'
	   , @TableName = 'CountryRegionCurrency'
	   , @ETLGenerateVersion = 'MS_GenV3'
    --*/
    DECLARE @IPC_RepoName VARCHAR(125)
        , @IPC_Folder VARCHAR(125)
	   , @IPC_Owner VARCHAR(125)
	   , @IPC_XML_Encoding VARCHAR(30)
	   , @IPC_RepoCodepage VARCHAR(30)
	   , @SourceDBType VARCHAR(125)
	   , @SourceServerName VARCHAR(50)
	   , @SourceDBName VARCHAR(50)
	   , @TargetDBType VARCHAR(125)
	   , @TargetDBName VARCHAR(50)
	   , @TargetServerName VARCHAR(50)
	   , @INF_TableName VARCHAR(125)
	   , @Pattern VARCHAR(63) 
	   , @SQL nvarchar(MAX)
	   , @Set nvarchar(MAX)

    SELECT @IPC_RepoName = cp.IPC_RepoName
	   , @IPC_Folder = cp.IPC_Folder
	   , @IPC_Owner = cp.IPC_Owner
	   , @IPC_XML_Encoding = cp.IPC_XML_Encoding 
	   , @IPC_RepoCodepage = cp.IPC_RepoCodepage
	   , @SourceDBType = cp.SourceDBType
	   , @TargetDBType = cp.TargetDBType
    FROM ipc.ConfigProperties cp 
    WHERE 1=1 
	   AND cp.ETLGenerateVersion = @ETLGenerateVersion

    IF ( (@IPC_RepoName IS NULL) OR (@IPC_Folder IS NULL) OR (@IPC_Owner IS NULL))
    BEGIN
	   RAISERROR ('Missing config in ConfigProperties table!', 16, 1);
    END 

    SELECT @SourceServerName = 'SQL_' + CASE WHEN CHARINDEX('\', dfd.SourceServerName) > 0 THEN SUBSTRING(dfd.SourceServerName, 1, CHARINDEX('\', dfd.SourceServerName) -1 ) ELSE '' END + '_' + dfd.SourceDatabaseName
	   , @SourceDBName = dfd.SourceDatabaseName
	   , @TargetServerName = 'SQL_' + CASE WHEN CHARINDEX('\', dfd.TargetServerName) > 0 THEN SUBSTRING(dfd.TargetServerName, 1, CHARINDEX('\', dfd.TargetServerName) -1 ) ELSE '' END + '_' + dfd.TargetDatabaseName
	   , @TargetDBName = dfd.TargetDatabaseName
    FROM dbo.DataFlowDefinition dfd 
    WHERE 1=1 
	   AND dfd.SourceSchema = @SchemaName
	   AND dfd.SourceTable = @TableName
	   AND dfd.ETLGenerateVersion = @ETLGenerateVersion
    
    SELECT @INF_TableName = m.INF_TableName
	   , @Pattern = m.Pattern	   	
    FROM ipc.Metadata m
    WHERE 1=1 
	   AND m.SchemaName = @SchemaName
	   AND m.TableName = @TableName
    ORDER BY m.ColumnId

    SET @SQL = ''
    SET @SQL = @SQL + nchar(10) + N'<REPOSITORY NAME="' + @IPC_RepoName + '" VERSION="" CODEPAGE="' + @IPC_RepoCodepage + '" DATABASETYPE="">'
    SET @SQL = @SQL + nchar(10) + N'<FOLDER NAME="' + @IPC_Folder + '" GROUP="" OWNER="' + @IPC_Owner + '" SHARED="NOTSHARED" DESCRIPTION="" PERMISSIONS="" UUID="">'
    SET @SQL = @SQL + nchar(10) + N'<TARGET BUSINESSNAME ="" CONSTRAINT ="" DATABASETYPE ="' + @TargetDBType +'" DESCRIPTION ="" ' 
				+ 'NAME ="' + @INF_TableName + CASE WHEN @Pattern = 'Increment' THEN '_diff' ELSE '' END + '" OBJECTVERSION ="1" TABLEOPTIONS ="" VERSIONNUMBER ="1">'
    SET @set = ''
		
    SELECT @set = @set + 
	   '<TARGETFIELD BUSINESSNAME ="" DATATYPE ="' 
	   + CASE 
		  WHEN m.TypeName = 'timestamp' THEN 'binary' 
		  WHEN m.TypeName = 'date' THEN 'datetime' 
		  ELSE m.TypeName 
	   END +'" DESCRIPTION ="" FIELDNUMBER ="' + CAST(m.ColumnId AS VARCHAR) + '" '
	   + 'KEYTYPE ="' + CASE WHEN m.IsPK = 1 THEN 'PRIMARY KEY' ELSE 'NOT A KEY' END + '" NAME ="' + m.INF_ColumnName + '" ' 
	   + 'NULLABLE ="' + CASE WHEN m.IsNullable = 1 THEN 'NULL' ELSE 'NOTNULL' END + '" PICTURETEXT ="" '
	   + 'PRECISION ="' +  CAST(	 CASE 
								WHEN m.TypeName = 'date' THEN '23'
								WHEN m.TypeName = 'timestamp' THEN '8'
								WHEN m.TypeName IN ('nchar', 'nvarchar', 'char', 'varchar', 'uniqueidentifier') THEN m.MaxLenght
								ELSE m.Precision 
							END AS VARCHAR) + '" '
	   + 'SCALE ="' + CAST(CASE WHEN m.TypeName = 'date' THEN '3' ELSE m.Scale END AS VARCHAR) + '" />'
	   + nchar(10)				
    FROM ipc.Metadata m
    WHERE 1=1
    	   -- AND m.UserTypeId <>  189 -- timestamp
	   AND m.SchemaName = @SchemaName
	   AND m.TableName = @TableName
    ORDER BY m.ColumnId

			
    SET @SQL = @SQL + nchar(10) + @set
    SET @SQL = @SQL + N'</TARGET>'


    /* SELECT @IPC_RepoName, @IPC_Folder, @IPC_Owner, @SourceDBType, @SourceDBName, @TargetDBType, @TargetDBName, @INF_TableName, @Pattern, @SQL, @Set */
	SET @SQL = @SQL + nchar(10) + N'</FOLDER>'
	SET @SQL = @SQL + nchar(10) + N'</REPOSITORY>'
	-- PRINT @SQL
	SET @OutXML = @SQL
END