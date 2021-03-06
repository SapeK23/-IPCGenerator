USE ETLRepoDB
GO

/***************************************************************
** Change History
***************************************************************
** PR	Date			Author		Description		
---------------------------------------------------------------
** 1		10/05/2018	MS			Add header and logging 

***************************************************************/

ALTER PROCEDURE ipc.usp_PrepareMetadata (@p_SchemaName VARCHAR(50) = NULL, @p_TableName VARCHAR(50) = NULL, @p_ETLGenerateVersion VARCHAR(125))
AS
BEGIN
    SET NOCOUNT ON;
    
    
    /* Region 1 - Prepare */
    DECLARE @SchemaName VARCHAR(50), @TableName VARCHAR(50), @ETLGenerateVersion VARCHAR(125)

    SELECT @SchemaName = @p_SchemaName
	   , @TableName = @p_TableName
	   , @ETLGenerateVersion = @p_ETLGenerateVersion
    
    DECLARE  @InsertDatetime DATETIME
	   , @TargetDatabaseName VARCHAR(50)
	   , @SourceSchemaName VARCHAR(50)
	   , @SQL nvarchar(max) 

    SELECT @TargetDatabaseName = TargetDatabaseName
	   , @SourceSchemaName = dfd.SourceSchema
    FROM ETLRepoDB.dbo.DataFlowDefinition AS dfd
    WHERE 1=1 
	   AND dfd.ETLGenerateVersion = @ETLGenerateVersion

    TRUNCATE TABLE ETLRepoDB.ipc.Metadata

    /* Region 2 - Initinal insert based on created tables */
    SELECT @SQL = 'SELECT t.object_id AS ObjectId
	    , ''' + @SourceSchemaName + ''' /* s.name */ AS SchemaName 
	    , t.name AS TableName
	    , c.name AS ColumnName
	    , c.column_id AS ColumnId
	    , c.user_type_id AS UserTypeId
	    , t2.name AS TypeName
	    , c.max_length AS MaxLenght
	    , c.precision AS Precision
	    , c.scale AS Scale
	    , c.is_nullable AS IsNullable
	    , c.is_identity AS IsIdentity
	    , c.is_computed AS IsComputed
	    , CASE
			WHEN kc.type = ''PK'' THEN 1
			ELSE 0
		 END AS IsPK
	    , ic.index_column_id AS IndexColumnId
    FROM ' + @TargetDatabaseName + '.sys.schemas AS s
    JOIN ' + @TargetDatabaseName + '.sys.tables AS t
	    ON s.schema_id = t.schema_id
    JOIN ' + @TargetDatabaseName + '.sys.columns AS c
	    ON t.object_id = c.object_id
    JOIN ' + @TargetDatabaseName + '.sys.types AS t2
	    ON c.system_type_id = t2.user_type_id
    LEFT JOIN ' + @TargetDatabaseName + '.sys.index_columns AS ic
	    ON c.object_id = ic.object_id
		  AND c.column_id = ic.column_id
		  AND ic.is_included_column = 0
    LEFT JOIN ' + @TargetDatabaseName + '.sys.key_constraints AS kc
	    ON c.object_id = kc.parent_object_id
		  AND ic.index_id = kc.unique_index_id
    WHERE 1 = 1
		AND EXISTS (
					SELECT 1
					FROM ETLRepoDB.dbo.DataFlowDefinition AS dfd
					WHERE 1 = 1
						 AND dfd.TargetSchema = s.name
						 AND dfd.TargetTable = t.name
						 AND ETLGenerateVersion = ''' + @ETLGenerateVersion + '''
				 )
		/*AND c.name NOT LIKE ''AUD_%''*/
    ORDER BY SchemaName, TableName, ColumnId'

    INSERT INTO ETLRepoDB.ipc.Metadata ( ObjectId
					    , SchemaName
					    , TableName
					    , ColumnName
					    , ColumnId
					    , UserTypeId
					    , TypeName
					    , MaxLenght
					    , Precision
					    , Scale
					    , IsNullable
					    , IsIdentity
					    , IsComputed
					    , IsPK
					    , IndexColumnId
					    )
    EXECUTE (@SQL)
    
    /* Delete all without selected */
    IF (@SchemaName IS NOT NULL AND @TableName IS NOT NULL)
    BEGIN 
	   DELETE FROM m
	   FROM ETLRepoDB.ipc.Metadata AS m
	   WHERE 1=1 
	   AND NOT EXISTS (
		  SELECT 1 
		  FROM ETLRepoDB.ipc.Metadata AS m2 
		  WHERE 1=1 
			 AND m.SchemaName = m2.SchemaName 
			 AND m.TableName = m2.TableName
			 AND m2.SchemaName = @SchemaName
			 AND m2.TableName = @TableName
	   )
    END


    /* Region 3 - Update load type */    
    UPDATE tgt 
	   SET tgt.Pattern = CASE 
					   WHEN dfd.IsDeltaLoad = 1 THEN 'Increment' 
					   WHEN dfd.IsDeltaLoad = 0 THEN 'Full' 
				    END 
    FROM ETLRepoDB.ipc.Metadata AS tgt 
    JOIN ETLRepoDB.dbo.DataFlowDefinition AS dfd
	   ON tgt.SchemaName = dfd.SourceSchema
	   AND tgt.TableName = dfd.SourceTable

    /* DEBUG
    SELECT DISTINCT src.type_name, src.max_length, src.precision, scale, src.INF_DataType, src.INF_Precision, src.INF_Scale
    FROM [ETLGenDEV_Core].[dbo].[gg_Metadane_Informatica] AS src 
    SELECT * from ETLRepoDB.ipc.Metadata 
    */

    /* Region 4 - Mapping SQL Server to Informatica PowerCenter data types
    based on https://kb.informatica.com/faq/1/Pages/18452.aspx 
    diff (SQL -> IPC):
    ++ bit -> string 
    ++ datetime(23,3) -> date/time (29,9)
    ++ datetime2 -> date/time (29,9)
    ++ decimal(38,38) -> decimal precision(28,28)
    ++ float -> double precision(15,15)
    ++ int -> integer
    ++ money -> decimal
    ++ nchar -> nstring
    ++ numeric -> decimal
    ++ nvarchar -> nstring
    ++ smalldatetime -> date/time (29,9)
    ++ smallint -> small integer 
    ++ smallmoney -> decimal precision(28,28)
    ++ sysname -> nstring
    ++ timestamp -> binary
    ++ tinyint -> small integer(5,0)
    ++ varbinary -> binary
    ++ varchar -> string
    ++ uniqueidentifier (varchar(38)) -> string(38,0)
    */

    UPDATE tgt
	   SET tgt.INF_TableName = tgt.TableName
		  ,tgt.INF_ColumnName = tgt.ColumnName
		  ,tgt.INF_DataType = CASE 
						    WHEN tgt.TypeName = 'bit' THEN 'string'
						    WHEN tgt.TypeName = 'int' THEN 'integer'
						    WHEN tgt.TypeName = 'tinyint' THEN 'small integer'
						    WHEN tgt.TypeName IN ('smallmoney', 'decimal','money', 'numeric') THEN 'decimal'
						    WHEN tgt.TypeName = 'float' THEN 'double precision'
						    WHEN tgt.TypeName = 'smallint' THEN 'small integer'
						    WHEN tgt.TypeName IN ('date', 'datetime', 'datetime2', 'smalldatetime') THEN 'date/time'
						    WHEN tgt.TypeName IN ('nchar', 'nvarchar') THEN 'nstring'
						    WHEN tgt.TypeName IN ('char', 'varchar', 'uniqueidentifier') THEN 'string'
						    WHEN tgt.TypeName IN ('timestamp', 'varbinary') THEN 'binary'
						    ELSE tgt.TypeName
						  END 
    FROM ETLRepoDB.ipc.Metadata AS tgt

    UPDATE tgt
	   SET
		  tgt.INF_Precision = CASE 
							 WHEN tgt.INF_DataType = 'string' AND tgt.TypeName = 'uniqueidentifier' THEN 38
							 WHEN tgt.INF_DataType IN ('string', 'nstring', 'binary') THEN tgt.MaxLenght
							 WHEN tgt.INF_DataType = 'date/time' THEN 29
							 WHEN tgt.INF_DataType = 'decimal precision' THEN 28
							 WHEN tgt.INF_DataType = 'double precision' THEN 15
							 WHEN tgt.INF_DataType = 'small integer' THEN 5
							 ELSE tgt.Precision
						  END 
		  ,tgt.INF_Scale = CASE
						  WHEN tgt.INF_DataType = 'string' AND tgt.TypeName = 'uniqueidentifier' THEN 0
						  WHEN tgt.INF_DataType IN ('string', 'nstring') THEN 0
						  WHEN tgt.INF_DataType = 'date/time' THEN 9
						  WHEN tgt.INF_DataType = 'decimal precision' THEN 28
						  WHEN tgt.INF_DataType = 'double precision' THEN 15
						  WHEN tgt.INF_DataType = 'small integer' THEN 0
						  ELSE tgt.Scale
					   END 
    FROM ETLRepoDB.ipc.Metadata AS tgt

    UPDATE tgt
	   SET
		  /* Origin values: uniqueidentifier	16 */
		  tgt.TypeName = 'varchar'
		  , tgt.MaxLenght = 38
    FROM ETLRepoDB.ipc.Metadata AS tgt
    WHERE 1=1
	   AND tgt.TypeName = 'uniqueidentifier'

END