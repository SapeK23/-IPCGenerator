USE ETLRepoDB
GO 

-- CREATE SCHEMA ipc AUTHORIZATION dbo

/* 
IF OBJECT_ID('ipc.ConfigProperties') IS NOT NULL
    DROP TABLE ipc.ConfigProperties

CREATE TABLE ipc.ConfigProperties (
    Id                 BIGINT IDENTITY(1, 1) NOT NULL,
    Name               VARCHAR(255) NOT NULL,
    Value              VARCHAR(MAX) NOT NULL,
    Description        VARCHAR(255) NULL,
    ETLGenerateVersion VARCHAR(125),
    CreateDatetime     DATETIME DEFAULT GETDATE()
)
ALTER TABLE ipc.ConfigProperties
ADD CONSTRAINT PK_ipc_ConfigProperties PRIMARY KEY (Id);

DECLARE @ETLGenerateVersion varchar(125), @InsertDatetime datetime 
SELECT @ETLGenerateVersion = 'MS_GenV3'
    , @InsertDatetime = GETDATE()

INSERT INTO ipc.ConfigProperties (Name, Value, Description, ETLGenerateVersion, CreateDatetime) 
VALUES ('IPC_Folder', 'Generator', 'Nazwa folderu w IPC', @ETLGenerateVersion, @InsertDatetime)
    , ('IPC_RepoName', 'INFA_REP_DEV', 'Nazwa repozytorium IPC', @ETLGenerateVersion, @InsertDatetime)
    , ('IPC_OwnerName', 'Administrator', 'Wlasciciel obiektu w IPC', @ETLGenerateVersion, @InsertDatetime)
    , ('DATABASETYPE_MSSQL', 'Microsoft SQL Server', 'Typ MSSQL', @ETLGenerateVersion, @InsertDatetime)
*/

IF OBJECT_ID('ipc.ConfigProperties') IS NOT NULL
    DROP TABLE ipc.ConfigProperties

CREATE TABLE ipc.ConfigProperties (
    Id                 BIGINT IDENTITY(1, 1) NOT NULL,
    IPC_ISServerName   VARCHAR(30)  NOT NULL, 
    IPC_DomainName	   VARCHAR(30)  NOT NULL, 
    IPC_RepoName	   VARCHAR(125) NOT NULL,
    IPC_RepoDBType	   VARCHAR(30)  NOT NULL, 
    IPC_RepoCodepage   VARCHAR(30)  NOT NULL,
    IPC_Folder         VARCHAR(125) NOT NULL,
    IPC_Owner          VARCHAR(125) NOT NULL,
    IPC_XML_Encoding   VARCHAR(30)  NOT NULL,
    SourceDBType       VARCHAR(125) NOT NULL,
    TargetDBType       VARCHAR(125) NOT NULL,
    WorkflowPrefix	   VARCHAR(5) NOT NULL, 
    WorkfletPrefix	   VARCHAR(5) NOT NULL, 
    SessionPrefix	   VARCHAR(5) NOT NULL, 
    MappingPrefix	   VARCHAR(5) NOT NULL, 
    ETLGenerateVersion VARCHAR(125) NOT NULL,
    CreateDatetime     DATETIME DEFAULT GETDATE()
)

ALTER TABLE ipc.ConfigProperties
ADD CONSTRAINT PK_ipc_ConfigProperties PRIMARY KEY(Id);
ALTER TABLE ipc.ConfigProperties
ADD CONSTRAINT UQ_ipc_ConfigProperties UNIQUE (ETLGenerateVersion);


DECLARE @ETLGenerateVersion varchar(125), @InsertDatetime datetime 
SELECT @ETLGenerateVersion = 'MS_GenV3'
    , @InsertDatetime = GETDATE()

INSERT INTO ipc.ConfigProperties (IPC_ISServerName, IPC_DomainName, IPC_RepoName, IPC_RepoDBType, IPC_RepoCodepage, IPC_Folder, IPC_Owner, IPC_XML_Encoding , SourceDBType, TargetDBType, WorkflowPrefix, WorkfletPrefix, SessionPrefix, MappingPrefix, ETLGenerateVersion)
VALUES ('IS_INFA_DEV', 'Domain_Virtual-PC', 'INFA_REP_DEV', 'Oracle', 'MS1252', 'Generator', 'Administrator', 'windows-1252', 'Microsoft SQL Server', 'Microsoft SQL Server', 'wkf_', 'wkl_', 'ses_', 'm_', @ETLGenerateVersion)

SELECT *
FROM ipc.ConfigProperties


IF OBJECT_ID('ipc.Metadata') IS NOT NULL
    DROP TABLE ipc.Metadata 

CREATE TABLE ipc.Metadata (
    Id             BIGINT IDENTITY(1, 1) NOT NULL,
    ObjectId       INT NOT NULL,
    SchemaName     VARCHAR(125) NOT NULL,
    TableName      VARCHAR(125) NOT NULL,
    ColumnName     VARCHAR(125) NULL,
    ColumnId       INT NOT NULL,
    UserTypeId     INT NOT NULL,
    TypeName       VARCHAR(35) NOT NULL,
    MaxLenght      SMALLINT NOT NULL,
    Precision      TINYINT NOT NULL,
    Scale          TINYINT NOT NULL,
    IsNullable     BIT NULL,
    IsIdentity     BIT NOT NULL,
    IsComputed     BIT NOT NULL,
    IsPK           BIT NULL,
    IndexColumnId  INT NULL,
    Pattern        VARCHAR(63) NULL,
    INF_TableName  VARCHAR(125) NULL,
    INF_ColumnName VARCHAR(125) NULL,
    INF_Datatype   VARCHAR(30) NULL,
    INF_Precision  VARCHAR(30) NULL,
    INF_Scale      VARCHAR(30) NULL
)

ALTER TABLE ipc.Metadata
ADD CONSTRAINT PK_ipc_Metadata PRIMARY KEY(Id)