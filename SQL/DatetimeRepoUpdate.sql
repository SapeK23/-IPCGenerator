select * 
FROM [dbo].[DataFlowDefinition] dfd
LEFT JOIN [dbo].[TableStmt] ts
    ON dfd.id = ts.DataFlowDefinitionId
LEFT JOIN [dbo].[DeltaConditions] dc
    ON ts.id = dc.TableStmtId
/*
JOIN ipc.Metadata AS m
    ON dfd.SourceSchema = m.SchemaName
    AND dfd.SourceTable  = m.TableName
*/
WHERE 1=1 
AND dfd.ETLGenerateVersion = 'MS_GenV4'

SELECT * FROM ipc.Metadata


UPDATE dc
    SET dc.ColumnName = 'CreateDate'
    , dc.ColumnType = 'datetime'
FROM [dbo].[DataFlowDefinition] dfd
LEFT JOIN [dbo].[TableStmt] ts
    ON dfd.id = ts.DataFlowDefinitionId
LEFT JOIN [dbo].[DeltaConditions] dc
    ON ts.id = dc.TableStmtId
/*
JOIN ipc.Metadata AS m
    ON dfd.SourceSchema = m.SchemaName
    AND dfd.SourceTable  = m.TableName
*/
WHERE 1=1 
AND dfd.ETLGenerateVersion = 'MS_GenV4'

SELECT * 
    FROM ETLRepoDB.ipc.Metadata AS tgt 
    JOIN ETLRepoDB.dbo.DataFlowDefinition AS dfd
	   ON tgt.SchemaName = dfd.SourceSchema
	   AND tgt.TableName = dfd.SourceTable
