USE ETLRepoDB
GO

/***************************************************************
** Change History
***************************************************************
** PR	Date			Author		Description		
---------------------------------------------------------------
** 1		10/05/2018	MS			

***************************************************************/

ALTER PROCEDURE ipc.usp_GenerateAllXML (@p_SchemaName VARCHAR(50) = NULL, @p_TableName VARCHAR(50) = NULL, @p_ETLGenerateVersion VARCHAR(125))
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
	   , @XML varchar(max)
	   , @Set varchar(MAX)
	   , @i int = 0

    SELECT @IPC_RepoName = cp.IPC_RepoName
	   , @IPC_Folder = cp.IPC_Folder
	   , @IPC_Owner = cp.IPC_Owner
	   , @IPC_XML_Encoding = cp.IPC_XML_Encoding 
	   , @IPC_RepoCodepage = cp.IPC_RepoCodepage
	   , @SourceDBType = cp.SourceDBType
	   , @TargetDBType = cp.TargetDBType
    FROM ipc.ConfigProperties AS cp 
    WHERE 1=1 
	   AND cp.ETLGenerateVersion = @ETLGenerateVersion

    /* Prepare metadata */
    EXEC ipc.usp_PrepareMetadata @p_SchemaName = @SchemaName, @p_TableName = @TableName, @p_ETLGenerateVersion = @ETLGenerateVersion
    

    IF OBJECT_ID('tempdb..#Metadata') IS NOT NULL
	   DROP TABLE #Metadata

    SELECT DISTINCT ROW_NUMBER() OVER(ORDER BY mtd.SchemaName, mtd.TableName) AS Rn
	   , mtd.SchemaName
	   , mtd.TableName 
	   , cast(0 AS BIT) AS IsGenerated
    INTO #Metadata
    FROM (SELECT DISTINCT m.SchemaName, m.TableName FROM ipc.Metadata AS m) AS mtd (SchemaName, TableName)
    /* debug 
    WHERE 1=1
	   AND mtd.SchemaName = @SchemaName
	   AND mtd.TableName = @TableName
    */

    -- SELECT * FROM #Metadata m

    SET @XML = ''
    --SET @XML = '<?xml version="1.0" encoding="' + @IPC_XML_Encoding + '"?>'
    --SET @XML = @XML + nchar(10) + '<!DOCTYPE POWERMART SYSTEM "powrmart.dtd">'
    SET @XML = @XML + nchar(10) + '<POWERMART CREATION_DATE="" REPOSITORY_VERSION="">'

    /* Generate Designer object */
    WHILE EXISTS (SELECT 1 FROM #Metadata WHERE 1=1 AND #Metadata.IsGenerated = 0)
    BEGIN 
	   SELECT @i = MIN(m.Rn)
	   FROM #Metadata AS m
	   WHERE 1=1 
		  AND m.IsGenerated = 0

	   SELECT @SchemaName = m.SchemaName
		  , @TableName = m.TableName
	   FROM #Metadata AS m
	   WHERE 1=1 
		  AND m.Rn = @i

	   -- source 
	   SET @Set = ''
	   exec ipc.usp_GenerateSource @p_SchemaName = @SchemaName, @p_TableName = @TableName, @p_ETLGenerateVersion = @ETLGenerateVersion, @OutXML = @Set OUT
	   SET @XML = @XML + nchar(10) + @Set
	   IF @XML IS null
		  select @SchemaName, @TableName, 'Source NULL'

	   
	   -- target
	   SET @Set = ''
	   exec ipc.usp_GenerateTarget @p_SchemaName = @SchemaName, @p_TableName = @TableName, @p_ETLGenerateVersion = @ETLGenerateVersion, @OutXML = @Set OUT
	   SET @XML = @XML + nchar(10) + @Set
	   IF @XML IS null
		  select @SchemaName, @TableName, 'Target NULL'



	   -- mapping
	   SET @Set = ''
	   exec ipc.usp_GenerateMapping @p_SchemaName = @SchemaName, @p_TableName = @TableName, @p_ETLGenerateVersion = @ETLGenerateVersion, @OutXML = @Set OUT
	   SET @XML = @XML + nchar(10) + @Set
	   IF @XML IS null
		  select @SchemaName, @TableName, 'Mapping NULL'

	   UPDATE m
		  SET m.IsGenerated = 1 
	   FROM #Metadata m
	   WHERE 1=1 
		  AND m.Rn = @i
    END

    /* Generate workflow object */
    SET @Set = ''
    exec ipc.usp_GenerateWorkflow @p_ETLGenerateVersion = @ETLGenerateVersion, @OutXML = @Set OUT
    SET @XML = @XML + nchar(10) + @Set
    SET @XML = @XML + nchar(10) + '</POWERMART>'
    
    /* Create Connection */
    exec ipc.usp_GenConnection @p_ETLGenerateVersion = @ETLGenerateVersion 

    /* Print XML */
    SET @Set = ''
    SET @Set = '<?xml version="1.0" encoding="' + @IPC_XML_Encoding + '"?>'
    SET @Set = @Set + nchar(10) + '<!DOCTYPE POWERMART SYSTEM "powrmart.dtd">'

    SELECT  @Set AS HeaderXML, CONVERT(xml, @XML, 2) AS RootXML

    /* Import to repo */
    SELECT 'pmrep ObjectImport -i "c:\informatica\TgtFiles\standard.output.XML" -c "c:\informatica\parms\import_control_file.txt"' AS ImportCmd
    
END 