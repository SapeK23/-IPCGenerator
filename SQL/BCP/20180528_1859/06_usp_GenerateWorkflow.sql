USE ETLRepoDB
GO

/***************************************************************
** Change History
***************************************************************
** PR	Date			Author		Description		
---------------------------------------------------------------
** 1		10/05/2018	MS			

***************************************************************/

ALTER PROCEDURE ipc.usp_GenerateWorkflow (@p_ETLGenerateVersion VARCHAR(125), @OutXML nvarchar(max) OUT)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ETLGenerateVersion VARCHAR(125)

    --SET @ETLGenerateVersion = @p_ETLGenerateVersion
    SET @ETLGenerateVersion = 'MS_GenV3'

    DECLARE @IPC_ISServerName VARCHAR(30)
	   , @IPC_DomainName VARCHAR(30)
	   , @IPC_RepoName VARCHAR(125)
        , @IPC_Folder VARCHAR(125)
	   , @IPC_Owner VARCHAR(125)
	   , @IPC_XML_Encoding VARCHAR(30)
	   , @IPC_RepoCodepage VARCHAR(30)
	   , @SourceDBType VARCHAR(125)
	   , @SourceConnName VARCHAR(50)
	   , @SourceDBName VARCHAR(50)
	   , @SourceSchema VARCHAR(50)
	   , @TargetDBType VARCHAR(125)
	   , @TargetConnName VARCHAR(50)
	   , @TargetDBName VARCHAR(50)
	   , @TargetSchema VARCHAR(50)
	   , @INF_TableName VARCHAR(125)
	   , @WorkflowPrefix VARCHAR(5)
	   , @WorkfletPrefix VARCHAR(5)
	   , @SessionPrefix VARCHAR(5)
	   , @MappingPrefix VARCHAR(5)
	   , @SQL NVARCHAR(max)
	   , @Set NVARCHAR(max)
    
    SELECT @IPC_ISServerName = cp.IPC_ISServerName
	   , @IPC_DomainName = cp.IPC_DomainName
	   , @IPC_RepoName = cp.IPC_RepoName
	   , @IPC_Folder = cp.IPC_Folder
	   , @IPC_Owner = cp.IPC_Owner
	   , @IPC_XML_Encoding = cp.IPC_XML_Encoding 
	   , @IPC_RepoCodepage = cp.IPC_RepoCodepage
	   , @SourceDBType = cp.SourceDBType
	   , @TargetDBType = cp.TargetDBType
   	   , @WorkflowPrefix = cp.WorkflowPrefix
	   , @WorkfletPrefix = cp.WorkfletPrefix
	   , @SessionPrefix = cp.SessionPrefix
	   , @MappingPrefix = cp.MappingPrefix
    FROM ipc.ConfigProperties cp 
    WHERE 1=1 
	   AND cp.ETLGenerateVersion = @ETLGenerateVersion

    IF ( (@IPC_RepoName IS NULL) OR (@IPC_Folder IS NULL) OR (@IPC_Owner IS NULL))
    BEGIN
	   RAISERROR ('Missing config in ConfigProperties table!', 16, 1);
    END 

    IF OBJECT_ID('tempdb..#MetadataSet') IS NOT NULL
	   DROP TABLE #MetadataSet

    SELECT 'SQL_' + CASE WHEN CHARINDEX('\', dfd.SourceServerName) > 0 THEN SUBSTRING(dfd.SourceServerName, 1, CHARINDEX('\', dfd.SourceServerName) -1 ) ELSE '' END + '_' + dfd.SourceDatabaseName AS SourceConnName
	   , dfd.SourceDatabaseName AS SourceDBName 
	   , dfd.SourceSchema AS SourceSchema 
	   , 'SQL_' + CASE WHEN CHARINDEX('\', dfd.TargetServerName) > 0 THEN SUBSTRING(dfd.TargetServerName, 1, CHARINDEX('\', dfd.TargetServerName) -1 ) ELSE '' END + '_' + dfd.TargetDatabaseName AS TargetConnName 
	   , dfd.TargetDatabaseName AS TargetDBName 
	   , dfd.TargetSchema AS TargetSchema
	   , CASE WHEN mtd.Pattern = 'Increment' THEN mtd.INF_TableName + '_diff' ELSE mtd.INF_TableName END AS TargetName
	   , mtd.INF_TableName AS INF_TableName
	   , mtd.Pattern AS Pattern
    INTO #MetadataSet
    FROM [dbo].[DataFlowDefinition] dfd
    JOIN (SELECT DISTINCT m.SchemaName, m.TableName, m.Pattern, m.INF_TableName FROM ipc.Metadata AS m) AS mtd(SchemaName, TableName, Pattern, INF_TableName) 
	   ON dfd.SourceSchema = mtd.SchemaName 
	   AND dfd.SourceTable = mtd.TableName
    WHERE 1=1 
	   AND dfd.ETLGenerateVersion = @ETLGenerateVersion

    SET @SQL = ''
    SET @SQL = @SQL + nchar(10) + N'<REPOSITORY NAME="' + @IPC_RepoName + '" VERSION="" CODEPAGE="' + @IPC_RepoCodepage + '" DATABASETYPE="">'
    SET @SQL = @SQL + nchar(10) + N'<FOLDER NAME="' + @IPC_Folder + '" GROUP="" OWNER="' + @IPC_Owner + '" SHARED="NOTSHARED" DESCRIPTION="" PERMISSIONS="" UUID="">'

    /* Default session config */
   
    SET @SQL = @SQL + N'<CONFIG DESCRIPTION ="Default session configuration object" ISDEFAULT ="YES" NAME ="default_session_config" VERSIONNUMBER ="1">' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Advanced" VALUE =""/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Constraint based load ordering" VALUE ="NO"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Cache LOOKUP() function" VALUE ="YES"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Default buffer block size" VALUE ="Auto"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Line Sequential buffer length" VALUE ="1024"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Maximum Memory Allowed For Auto Memory Attributes" VALUE ="512MB"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Maximum Percentage of Total Memory Allowed For Auto Memory Attributes" VALUE ="5"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Additional Concurrent Pipelines for Lookup Cache Creation" VALUE ="Auto"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Custom Properties" VALUE =""/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Pre-build lookup cache" VALUE ="Auto"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Optimization Level" VALUE ="Medium"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="DateTime Format String" VALUE ="MM/DD/YYYY HH24:MI:SS.US"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Pre 85 Timestamp Compatibility" VALUE ="NO"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Log Options" VALUE ="0"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Save session log by" VALUE ="Session runs"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Save session log for these runs" VALUE ="0"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Session Log File Max Size" VALUE ="0"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Session Log File Max Time Period" VALUE ="0"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Maximum Partial Session Log Files" VALUE ="1"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Writer Commit Statistics Log Frequency" VALUE ="1"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Writer Commit Statistics Log Interval" VALUE ="0"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Error handling" VALUE =""/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Stop on errors" VALUE ="0"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Override tracing" VALUE ="None"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="On Stored Procedure error" VALUE ="Stop"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="On Pre-session command task error" VALUE ="Stop"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="On Pre-Post SQL error" VALUE ="Stop"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Enable Recovery" VALUE ="NO"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Error Log Type" VALUE ="None"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Error Log Table Name Prefix" VALUE =""/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Error Log File Name" VALUE ="PMError.log"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Log Source Row Data" VALUE ="NO"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Data Column Delimiter" VALUE ="|"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Partitioning Options" VALUE =""/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Dynamic Partitioning" VALUE ="Disabled"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Number of Partitions" VALUE ="1"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Multiplication Factor" VALUE ="Auto"/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Session on Grid" VALUE =""/>' + nchar(10)
    SET @SQL = @SQL + N'<ATTRIBUTE NAME ="Is Enabled" VALUE ="NO"/>' + nchar(10)
    SET @SQL = @SQL + N'</CONFIG>' + nchar(10)

    /* Workflow part */

    SET @SQL = @SQL + nchar(10) + N'<WORKFLOW DESCRIPTION ="" ISENABLED ="YES" ISRUNNABLESERVICE ="NO" ISSERVICE ="NO" ISVALID ="YES" NAME ="' + @WorkflowPrefix + 'StagingLoad" REUSABLE_SCHEDULER ="NO" SCHEDULERNAME ="Scheduler" SERVERNAME ="' + @IPC_ISServerName + '" SERVER_DOMAINNAME ="' + @IPC_DomainName + '" SUSPEND_ON_ERROR ="NO" TASKS_MUST_RUN_ON_SERVER ="NO" VERSIONNUMBER ="1">'
    SET @SQL = @SQL + nchar(10) + N'<SCHEDULER DESCRIPTION ="" NAME ="Scheduler" REUSABLE ="NO" VERSIONNUMBER ="1">' 
    SET @SQL = @SQL + nchar(10) + N'<SCHEDULEINFO SCHEDULETYPE ="ONDEMAND"/>'
    SET @SQL = @SQL + nchar(10) + N'</SCHEDULER>'
    SET @SQL = @SQL + nchar(10) + N'<TASK DESCRIPTION ="" NAME ="Start" REUSABLE ="NO" TYPE ="Start" VERSIONNUMBER ="1"/>'

    SET @Set =''
    SELECT @Set = @Set 
	   + nchar(10) + N'<SESSION DESCRIPTION ="" ISVALID ="YES" MAPPINGNAME ="' + @MappingPrefix + m.INF_TableName + '" NAME ="' + @SessionPrefix + m.INF_TableName + '" REUSABLE ="NO" SORTORDER ="Binary" VERSIONNUMBER ="1">'
	   + nchar(10) + N'<SESSTRANSFORMATIONINST ISREPARTITIONPOINT ="YES" PARTITIONTYPE ="PASS THROUGH" PIPELINE ="1" SINSTANCENAME ="' + m.TargetName + '" STAGE ="1" TRANSFORMATIONNAME ="' + m.TargetName + '" TRANSFORMATIONTYPE ="Target Definition"/>'
	   + nchar(10) + N'<SESSTRANSFORMATIONINST ISREPARTITIONPOINT ="NO" PIPELINE ="0" SINSTANCENAME ="' + m.INF_TableName + '" STAGE ="0" TRANSFORMATIONNAME ="' + m.INF_TableName + '" TRANSFORMATIONTYPE ="Source Definition"/>'
	   + nchar(10) + N'<SESSTRANSFORMATIONINST ISREPARTITIONPOINT ="YES" PARTITIONTYPE ="PASS THROUGH" PIPELINE ="1" SINSTANCENAME ="SQ_' + m.INF_TableName + '" STAGE ="2" TRANSFORMATIONNAME ="SQ_' + m.INF_TableName + '" TRANSFORMATIONTYPE ="Source Qualifier"/>'
	   + nchar(10) + N'<SESSTRANSFORMATIONINST ISREPARTITIONPOINT ="NO" PIPELINE ="1" SINSTANCENAME ="EXP_' + m.INF_TableName + '" STAGE ="2" TRANSFORMATIONNAME ="EXP_' + m.INF_TableName + '" TRANSFORMATIONTYPE ="Expression"><PARTITION DESCRIPTION ="" NAME ="Partition #1"/></SESSTRANSFORMATIONINST>'
	   + nchar(10) + N'<CONFIGREFERENCE REFOBJECTNAME ="default_session_config" TYPE ="Session config"/>'
	   + nchar(10) + N'<SESSIONEXTENSION NAME ="Relational Writer" SINSTANCENAME ="' + m.TargetName + '" SUBTYPE ="Relational Writer" TRANSFORMATIONTYPE ="Target Definition" TYPE ="WRITER">'
	   + nchar(10) + N'<CONNECTIONREFERENCE CNXREFNAME ="DB Connection" CONNECTIONNAME ="' + m.TargetConnName + '" CONNECTIONNUMBER ="1" CONNECTIONSUBTYPE ="' + @TargetDBType + '" CONNECTIONTYPE ="Relational" VARIABLE =""/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Target load type" VALUE ="Bulk"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Insert" VALUE ="YES"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Update as Update" VALUE ="YES"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Update as Insert" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Update else Insert" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Delete" VALUE ="YES"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Truncate target table option" VALUE ="YES"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Reject file directory" VALUE ="$PMBadFileDir&#x5c;"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Reject filename" VALUE ="' + m.TargetName + '1.bad"/>'
	   + nchar(10) + N'</SESSIONEXTENSION>'
	   + nchar(10) + N'<SESSIONEXTENSION DSQINSTNAME ="SQ_' + m.INF_TableName + '" DSQINSTTYPE ="Source Qualifier" NAME ="Relational Reader" SINSTANCENAME ="' + m.INF_TableName + '" SUBTYPE ="Relational Reader" TRANSFORMATIONTYPE ="Source Definition" TYPE ="READER"/>'
	   + nchar(10) + N'<SESSIONEXTENSION NAME ="Relational Reader" SINSTANCENAME ="SQ_' + m.INF_TableName + '" SUBTYPE ="Relational Reader" TRANSFORMATIONTYPE ="Source Qualifier" TYPE ="READER">'
	   + nchar(10) + N'<CONNECTIONREFERENCE CNXREFNAME ="DB Connection" CONNECTIONNAME ="' + m.SourceConnName + '" CONNECTIONNUMBER ="1" CONNECTIONSUBTYPE ="' + @SourceDBType + '" CONNECTIONTYPE ="Relational" VARIABLE =""/>'
	   + nchar(10) + N'</SESSIONEXTENSION>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="General Options" VALUE =""/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Write Backward Compatible Session Log File" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Session Log File Name" VALUE ="' + @SessionPrefix + m.INF_TableName + '.log"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Session Log File directory" VALUE ="$PMSessionLogDir&#x5c;"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Parameter Filename" VALUE =""/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Enable Test Load" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="$Source connection value" VALUE =""/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="$Target connection value" VALUE =""/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Treat source rows as" VALUE ="Insert"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Commit Type" VALUE ="Target"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Commit Interval" VALUE ="10000"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Commit On End Of File" VALUE ="YES"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Rollback Transactions on Errors" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Recovery Strategy" VALUE ="Fail task and continue workflow"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Java Classpath" VALUE =""/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Performance" VALUE =""/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="DTM buffer size" VALUE ="Auto"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Collect performance data" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Write performance data to repository" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Incremental Aggregation" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Enable high precision" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Session retry on deadlock" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Pushdown Optimization" VALUE ="None"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Allow Temporary View for Pushdown" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Allow Temporary Sequence for Pushdown" VALUE ="NO"/>'
	   + nchar(10) + N'<ATTRIBUTE NAME ="Allow Pushdown for User Incompatible Connections" VALUE ="NO"/>'
	   + nchar(10) + N'</SESSION>'
    FROM #MetadataSet AS m 
    
    SET @sql = @sql + nchar(10) + @set
    SET @SQL = @SQL + nchar(10) + N'<TASKINSTANCE DESCRIPTION ="" ISENABLED ="YES" NAME ="Start" REUSABLE ="NO" TASKNAME ="Start" TASKTYPE ="Start"/>'

    SET @Set =''
    SELECT @Set = @Set 
	   + nchar(10) + N'<TASKINSTANCE DESCRIPTION ="" FAIL_PARENT_IF_INSTANCE_DID_NOT_RUN ="NO" FAIL_PARENT_IF_INSTANCE_FAILS ="YES" ISENABLED ="YES" NAME ="' + @SessionPrefix + m.INF_TableName + '" REUSABLE ="NO" TASKNAME ="' + @SessionPrefix + m.INF_TableName + '" TASKTYPE ="Session" TREAT_INPUTLINK_AS_AND ="YES"/>'
	   + nchar(10) + N'<WORKFLOWLINK CONDITION ="" FROMTASK ="Start" TOTASK ="' + @SessionPrefix + m.INF_TableName + '"/>'
    FROM #MetadataSet AS m 
    SET @sql = @sql + nchar(10) + @set
    
    SET @SQL = @SQL + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="date/time" DEFAULTVALUE ="" DESCRIPTION ="The time this task started" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$Start.StartTime" USERDEFINED ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="date/time" DEFAULTVALUE ="" DESCRIPTION ="The time this task completed" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$Start.EndTime" USERDEFINED ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Status of this task&apos;s execution" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$Start.Status" USERDEFINED ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Status of the previous task that is not disabled" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$Start.PrevTaskStatus" USERDEFINED ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Error code for this task&apos;s execution" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$Start.ErrorCode" USERDEFINED ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="string" DEFAULTVALUE ="" DESCRIPTION ="Error message for this task&apos;s execution" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$Start.ErrorMsg" USERDEFINED ="NO"/>'

    SET @Set =''
    SELECT @Set = @Set 
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="date/time" DEFAULTVALUE ="" DESCRIPTION ="The time this task started" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.StartTime" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="date/time" DEFAULTVALUE ="" DESCRIPTION ="The time this task completed" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.EndTime" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Status of this task&apos;s execution" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.Status" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Status of the previous task that is not disabled" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.PrevTaskStatus" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Error code for this task&apos;s execution" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.ErrorCode" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="string" DEFAULTVALUE ="" DESCRIPTION ="Error message for this task&apos;s execution" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.ErrorMsg" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Rows successfully read" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.SrcSuccessRows" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Rows failed to read" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.SrcFailedRows" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Rows successfully loaded" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.TgtSuccessRows" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Rows failed to load" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.TgtFailedRows" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="Total number of transformation errors" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.TotalTransErrors" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="integer" DEFAULTVALUE ="" DESCRIPTION ="First error code" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.FirstErrorCode" USERDEFINED ="NO"/>'
	   + nchar(10) + N'<WORKFLOWVARIABLE DATATYPE ="string" DEFAULTVALUE ="" DESCRIPTION ="First error message" ISNULL ="NO" ISPERSISTENT ="NO" NAME ="$' + @SessionPrefix + m.INF_TableName + '.FirstErrorMsg" USERDEFINED ="NO"/>'
    FROM #MetadataSet AS m 

    SET @sql = @sql + nchar(10) + @set
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Parameter Filename" VALUE =""/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Write Backward Compatible Workflow Log File" VALUE ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Workflow Log File Name" VALUE ="' + @WorkflowPrefix + 'StagingLoad.log"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Workflow Log File Directory" VALUE ="$PMWorkflowLogDir&#x5c;"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Save Workflow log by" VALUE ="By runs"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Save workflow log for these runs" VALUE ="0"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Service Name" VALUE =""/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Service Timeout" VALUE ="0"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Is Service Visible" VALUE ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Is Service Protected" VALUE ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Fail task after wait time" VALUE ="0"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Enable HA recovery" VALUE ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Automatically recover terminated tasks" VALUE ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Service Level Name" VALUE ="Default"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Allow concurrent run with unique run instance name" VALUE ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Allow concurrent run with same run instance name" VALUE ="NO"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Maximum number of concurrent runs" VALUE ="0"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Assigned Web Services Hubs" VALUE =""/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Maximum number of concurrent runs per Hub" VALUE ="1000"/>'
    SET @SQL = @SQL + nchar(10) + N'<ATTRIBUTE NAME ="Expected Service Time" VALUE ="1"/>'
    SET @SQL = @SQL + nchar(10) + N'</WORKFLOW>'

    SET @SQL = @SQL + nchar(10) + N'</FOLDER>'
    SET @SQL = @SQL + nchar(10) + N'</REPOSITORY>'
    SET @OutXML = @SQL

END 