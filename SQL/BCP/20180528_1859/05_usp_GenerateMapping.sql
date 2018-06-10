USE ETLRepoDB
GO

/***************************************************************
** Change History
***************************************************************
** PR	Date			Author		Description		
---------------------------------------------------------------
** 1		10/05/2018	MS			 

***************************************************************/

ALTER PROCEDURE ipc.usp_GenerateMapping (@p_SchemaName VARCHAR(50), @p_TableName VARCHAR(50), @p_ETLGenerateVersion VARCHAR(125), @OutXML nvarchar(max) OUT)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SchemaName VARCHAR(50), @TableName VARCHAR(50), @ETLGenerateVersion VARCHAR(125)

    --/*
    SELECT @SchemaName = @p_SchemaName
	   , @TableName = @p_TableName
	   , @ETLGenerateVersion = @p_ETLGenerateVersion
    --*/
    /*
    SELECT @SchemaName = 'Sales'
	   , @TableName = 'CreditCard'
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
	   , @SourceSchema VARCHAR(50)
	   , @TargetDBType VARCHAR(125)
	   , @TargetServerName VARCHAR(50)
	   , @TargetDBName VARCHAR(50)
	   , @TargetSchema VARCHAR(50)
	   , @INF_TableName VARCHAR(125)
	   , @Pattern VARCHAR(63)
	   , @DeltaColumnName VARCHAR(255)
	   , @DeltaColumnType VARCHAR(20)
	   , @DeltaColumnPrecision tinyint
	   , @DeltaColumnScale tinyint
	   , @DeltaMergeTableDiffSQL VARCHAR(max)
   	   , @MappingPrefix VARCHAR(5)
	   , @SQL NVARCHAR(max)
	   , @Set NVARCHAR(max)

    SELECT @IPC_RepoName = cp.IPC_RepoName
	   , @IPC_Folder = cp.IPC_Folder
	   , @IPC_Owner = cp.IPC_Owner
	   , @IPC_XML_Encoding = cp.IPC_XML_Encoding 
	   , @IPC_RepoCodepage = cp.IPC_RepoCodepage
	   , @SourceDBType = cp.SourceDBType
	   , @TargetDBType = cp.TargetDBType
   	   , @MappingPrefix = cp.MappingPrefix
    FROM ipc.ConfigProperties cp 
    WHERE 1=1 
	   AND cp.ETLGenerateVersion = @ETLGenerateVersion

    IF ( (@IPC_RepoName IS NULL) OR (@IPC_Folder IS NULL) OR (@IPC_Owner IS NULL))
    BEGIN
	   RAISERROR ('Missing config in ConfigProperties table!', 16, 1);
    END 

    SELECT @SourceServerName = 'SQL_' + CASE WHEN CHARINDEX('\', dfd.SourceServerName) > 0 THEN SUBSTRING(dfd.SourceServerName, 1, CHARINDEX('\', dfd.SourceServerName) -1 ) ELSE '' END + '_' + dfd.SourceDatabaseName
	   , @SourceDBName = dfd.SourceDatabaseName
	   , @SourceSchema = dfd.SourceSchema
	   , @TargetServerName = 'SQL_' + CASE WHEN CHARINDEX('\', dfd.TargetServerName) > 0 THEN SUBSTRING(dfd.TargetServerName, 1, CHARINDEX('\', dfd.TargetServerName) -1 ) ELSE '' END + '_' + dfd.TargetDatabaseName
	   , @TargetDBName = dfd.TargetDatabaseName
	   , @TargetSchema = dfd.TargetSchema
	   , @DeltaColumnName = dc.ColumnName
	   , @DeltaMergeTableDiffSQL = 'BEGIN ' + char(10) + REPLACE(ts.MergeTableDiffSQL, ';', '\;') + char(10) + 'END;' /* https://kb.informatica.com/solution/23/Pages/2/150064.aspx */
    FROM [dbo].[DataFlowDefinition] dfd
    LEFT JOIN [dbo].[TableStmt] ts
	   ON dfd.id = ts.DataFlowDefinitionId
    LEFT JOIN [dbo].[DeltaConditions] dc
	   ON ts.id = dc.TableStmtId
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

    /* Delta INF metadata */
    SELECT @DeltaColumnType = m.INF_Datatype
	   , @DeltaColumnPrecision = m.INF_Precision
	   , @DeltaColumnScale = m.INF_Scale
    FROM ipc.Metadata m
    WHERE 1=1 
	   AND m.SchemaName = @SchemaName
	   AND m.TableName = @TableName
	   AND m.ColumnName = @DeltaColumnName


    SET @SQL = ''
    SET @SQL = @SQL + nchar(10) + N'<REPOSITORY NAME="' + @IPC_RepoName + '" VERSION="" CODEPAGE="' + @IPC_RepoCodepage + '" DATABASETYPE="">'
    SET @SQL = @SQL + nchar(10) + N'<FOLDER NAME="' + @IPC_Folder + '" GROUP="" OWNER="' + @IPC_Owner + '" SHARED="NOTSHARED" DESCRIPTION="" PERMISSIONS="" UUID="">'

    /* wygenerowanie mappingu */
    SET @sql = @sql + nchar(10) + N'<MAPPING DESCRIPTION ="" ISVALID ="YES" NAME ="' + @MappingPrefix + @INF_TableName + '" OBJECTVERSION ="1" VERSIONNUMBER ="1">'

    /* transformacja SQ */
    SET @sql = @sql + nchar(10) + N'<TRANSFORMATION DESCRIPTION ="" NAME ="SQ_' + @INF_TableName + '" OBJECTVERSION ="1" REUSABLE ="NO" TYPE ="Source Qualifier" VERSIONNUMBER ="1">'
    SET @set = ''
		
    SELECT @set = @set + 
    '<TRANSFORMFIELD DATATYPE ="' + m.INF_Datatype +'" DEFAULTVALUE ="" DESCRIPTION ="' + m.SchemaName + '.' + m.TableName+ '.' + m.ColumnName + '" '
    + 'NAME ="' + m.INF_ColumnName + '" PICTURETEXT ="" PORTTYPE ="INPUT/OUTPUT" PRECISION ="' + CAST(m.INF_Precision AS VARCHAR)+ '" SCALE ="' +  CAST(m.INF_Scale AS VARCHAR) +'"/>'
    + nchar(10)				
    FROM ipc.Metadata m
    WHERE 1=1
    	   AND m.ColumnName NOT LIKE 'AUD_%'
	   AND m.SchemaName = @SchemaName
	   AND m.TableName = @TableName
    ORDER BY m.ColumnId
			
    SET @sql = @sql + nchar(10) + @set
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Sql Query" VALUE =""/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="User Defined Join" VALUE =""/>'

    IF @Pattern = 'Full' SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Source Filter" VALUE =""/>'
    IF @Pattern  = 'Increment' SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Source Filter" VALUE ="' + @DeltaColumnName + ' &gt; $$v_Last' + @DeltaColumnName + '"/>' /* TODO: obsluga typu timestamp na podstawie @DeltaColumnType */

    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Number Of Sorted Ports" VALUE ="0"/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Tracing Level" VALUE ="Normal"/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Select Distinct" VALUE ="NO"/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Is Partitionable" VALUE ="NO"/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Pre SQL" VALUE =""/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Post SQL" VALUE =""/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Output is deterministic" VALUE ="NO"/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Output is repeatable" VALUE ="Never"/>'
    SET @sql = @sql + N'</TRANSFORMATION>'

    /* transformacja EXP */	
    SET @sql = @sql + nchar(10) + N'<TRANSFORMATION DESCRIPTION ="" NAME ="EXP_' + @INF_TableName + '" OBJECTVERSION ="1" REUSABLE ="NO" TYPE ="Expression" VERSIONNUMBER ="1">'
    SET @set = ''
		
    SELECT @set = @set + 
	   '<TRANSFORMFIELD DATATYPE ="' + m.INF_Datatype +'" DEFAULTVALUE ="" DESCRIPTION ="" '
	   + 'NAME ="' + m.INF_ColumnName + '"' 
	   + CASE 
		  WHEN m.INF_ColumnName LIKE 'AUD_%Datetime' AND m.INF_Datatype = 'Date/time' THEN ' EXPRESSION ="SESSSTARTTIME" EXPRESSIONTYPE ="GENERAL"'
		  WHEN m.INF_ColumnName LIKE 'AUD_isDeleted%' THEN ' EXPRESSION ="0" EXPRESSIONTYPE ="GENERAL"'
		  ELSE ''
		END
	   + ' PICTURETEXT ="" PORTTYPE ="' + CASE WHEN m.INF_ColumnName LIKE 'AUD_%' THEN 'OUTPUT' ELSE 'INPUT/OUTPUT' END + '"'
	   + ' PRECISION ="' +  CAST(m.INF_Precision AS VARCHAR) + '" SCALE ="' +  CAST(m.INF_Scale AS VARCHAR) +'"/>'
	   + nchar(10)				
    FROM ipc.Metadata m
    WHERE 1=1
    	   -- AND m.UserTypeId <>  189 -- timestamp
	   AND m.SchemaName = @SchemaName
	   AND m.TableName = @TableName
    ORDER BY m.ColumnId
    SET @sql = @sql + nchar(10) + @set

    -- SELECT @sql, len(@sql), @INF_TableName, @Pattern , @TableName, @TargetSchema, @SourceSchema, @INF_TableName, @SourceDBName

    IF @Pattern = 'Increment' 
	   SET @sql = @sql + N'<TRANSFORMFIELD DATATYPE ="' + @DeltaColumnType + '" DEFAULTVALUE ="" DESCRIPTION ="" '
	   + 'EXPRESSION ="SETMAXVARIABLE($$v_Last' + @DeltaColumnName + ', ' + @DeltaColumnName + ')" EXPRESSIONTYPE ="GENERAL" NAME ="v_Last' + @DeltaColumnName + '" PICTURETEXT ="" PORTTYPE ="LOCAL VARIABLE" PRECISION ="' + cast(@DeltaColumnPrecision as varchar) +'" SCALE ="' + cast(@DeltaColumnScale as varchar) + '"/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Tracing Level" VALUE ="Normal"/>'
    SET @sql = @sql + N'</TRANSFORMATION>' + nchar(10)

    /*instancje widgetow (klockow)*/
    DECLARE @TargerInstanceName varchar(250)
    SET @TargerInstanceName = CASE WHEN @Pattern = 'Increment' THEN @INF_TableName + '_diff' ELSE @INF_TableName END 

    SET @sql = @sql + N'<INSTANCE DESCRIPTION ="" NAME ="' + @TargerInstanceName  + '" TRANSFORMATION_NAME ="' + @TargerInstanceName  +'" TRANSFORMATION_TYPE ="Target Definition" TYPE ="TARGET">'
    IF @Pattern  = 'Increment' 
	   SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Post SQL" VALUE ="' + @DeltaMergeTableDiffSQL + '"/>'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Target Table Name" VALUE ="' + @TargetSchema + '.' + @TableName + '_diff' + '"/>'
    SET @sql = @sql + N'</INSTANCE>' + nchar(10)
    SET @sql = @sql + N'<INSTANCE DESCRIPTION ="" NAME ="SQ_' + @INF_TableName +'" REUSABLE ="NO" TRANSFORMATION_NAME ="SQ_' + @INF_TableName + '" TRANSFORMATION_TYPE ="Source Qualifier" TYPE ="TRANSFORMATION">'
    SET @sql = @sql + N'<ASSOCIATED_SOURCE_INSTANCE NAME ="' + @INF_TableName + '"/>'
    SET @sql = @sql + N'</INSTANCE>' + nchar(10)
    SET @sql = @sql + N'<INSTANCE DESCRIPTION ="" NAME ="EXP_' + @INF_TableName + '" REUSABLE ="NO" TRANSFORMATION_NAME ="EXP_' + @INF_TableName + '" TRANSFORMATION_TYPE ="Expression" TYPE ="TRANSFORMATION"/>' + nchar(10)
    SET @sql = @sql + N'<INSTANCE DBDNAME ="' + @SourceServerName +'" DESCRIPTION ="" NAME ="' + @INF_TableName + '" TRANSFORMATION_NAME ="' + @INF_TableName + '" TRANSFORMATION_TYPE ="Source Definition" TYPE ="SOURCE">'
    SET @sql = @sql + N'<TABLEATTRIBUTE NAME ="Source Table Name" VALUE ="' + @SourceSchema + '.' + @TableName + '"/>'
    SET @sql = @sql + N'</INSTANCE>' + nchar(10)

    -- SELECT @sql, @INF_TableName, @Pattern, @TargerInstanceName , @TableName, @TargetSchema, @SourceSchema, @INF_TableName, @SourceDBName

    /* polaczenie miedzy widgetami */
    SET @set = ''
		
    SELECT @set = @set + 
	   '<CONNECTOR FROMFIELD ="' + m.INF_ColumnName +'" FROMINSTANCE ="SQ_' + @INF_TableName + '" FROMINSTANCETYPE ="Source Qualifier" TOFIELD ="' + m.INF_ColumnName + '" TOINSTANCE ="EXP_' + @INF_TableName + '" TOINSTANCETYPE ="Expression"/> ' + nchar(10)
	   + '<CONNECTOR FROMFIELD ="' + m.ColumnName +'" FROMINSTANCE ="' + @TableName + '" FROMINSTANCETYPE ="Source Definition" TOFIELD ="' + m.INF_ColumnName + '" TOINSTANCE ="SQ_' + @INF_TableName + '" TOINSTANCETYPE ="Source Qualifier"/>' 
	   + nchar(10)				
    FROM ipc.Metadata m
    WHERE 1=1
    	   -- AND m.UserTypeId <>  189 -- timestamp
	   AND m.ColumnName NOT LIKE 'AUD_%'
	   AND m.SchemaName = @SchemaName
	   AND m.TableName = @TableName
    ORDER BY m.ColumnId			
    SET @sql = @sql + nchar(10) + @set

    SET @set = ''
    SELECT @set = @set + 
	   '<CONNECTOR FROMFIELD ="' + m.INF_ColumnName +'" FROMINSTANCE ="EXP_' + @INF_TableName + '" FROMINSTANCETYPE ="Expression" TOFIELD ="' + m.ColumnName + '" TOINSTANCE ="' + @TargerInstanceName + '" TOINSTANCETYPE ="Target Definition"/> ' 
	   + nchar(10)				
    FROM ipc.Metadata m
    WHERE 1=1
    	   -- AND m.UserTypeId <>  189 -- timestamp
	   AND m.SchemaName = @SchemaName
	   AND m.TableName = @TableName
    ORDER BY m.ColumnId			
    SET @sql = @sql + nchar(10) + @set


    SET @sql = @sql + N'<TARGETLOADORDER ORDER ="1" TARGETINSTANCE ="'+ @TargerInstanceName +'"/>'
    IF @Pattern  = 'Increment' 
	   SET @sql = @sql + N'<MAPPINGVARIABLE AGGFUNCTION ="MAX" DATATYPE ="' + @DeltaColumnType + '" DEFAULTVALUE ="0" DESCRIPTION ="" ISEXPRESSIONVARIABLE ="NO" ISPARAM ="NO" NAME ="$$v_Last' + cast(@DeltaColumnName as varchar) + '" PRECISION ="' + cast(@DeltaColumnPrecision as varchar) + '" SCALE ="' + cast(@DeltaColumnScale as varchar) + '" USERDEFINED ="YES"/>' + nchar(10)
    SET @sql = @sql + N'<ERPINFO/>' + nchar(10)
    SET @sql = @sql + N'</MAPPING>' + nchar(10)

    SET @sql = @sql + nchar(10) + N'</FOLDER>'
    SET @sql = @sql + nchar(10) + N'</REPOSITORY>'
    SET @OutXML = @sql


END 