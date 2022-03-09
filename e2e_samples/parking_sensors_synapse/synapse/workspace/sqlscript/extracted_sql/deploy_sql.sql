IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[parking_bay_ext]') AND type in (N'U'))
    DROP EXTERNAL TABLE [dbo].[parking_bay_ext]
/****** Object:  ExternalDataSource [tpcds_msi]    Script Date: 24/08/2021 10:20:34 ******/
IF  EXISTS (Select * from sys.external_data_sources WHERE name = 'INTERIM_Zone')
    DROP EXTERNAL DATA SOURCE [INTERIM_Zone]
IF  EXISTS (Select * from sys.database_credentials WHERE name = 'SynapseIdentity')
    DROP DATABASE SCOPED CREDENTIAL SynapseIdentity

IF  EXISTS (Select * from sys.database_credentials WHERE name = 'WorkspaceIdentity')
    DROP DATABASE SCOPED CREDENTIAL WorkspaceIdentity
IF  EXISTS (Select * from sys.external_file_formats WHERE name = 'SynapseParquetFormat')
    DROP EXTERNAL FILE FORMAT [SynapseParquetFormat]
USE external_db
-- Create MASTER KEY 
IF NOT EXISTS
    (SELECT * FROM sys.symmetric_keys
        WHERE symmetric_key_id = 101)
BEGIN
    CREATE MASTER KEY
END
GO
-- Create Database Scope Credential [Managed Identity]
IF NOT EXISTS
    (SELECT * FROM sys.database_scoped_credentials
         WHERE name = 'SynapseIdentity')
    CREATE DATABASE SCOPED CREDENTIAL SynapseIdentity
    WITH IDENTITY = 'Managed Identity'
GO
IF NOT EXISTS
    (SELECT * FROM sys.database_scoped_credentials
         WHERE name = 'WorkspaceIdentity')
    CREATE DATABASE SCOPED CREDENTIAL WorkspaceIdentity
    WITH IDENTITY = 'Managed Identity'
GO
-- DROP EXTERNAL DATA SOURCE INTERIM_Zone
-- Create External Data Source
--https://mdwdopsstdevimops.dfs.core.windows.net/datalake/data/interim/
--declare @ADLSLocation varchar(300)
--set @ADLSLocation = 'https://mdwdopsstdevimops.dfs.core.windows.net/datalake/data/interim/'

IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'INTERIM_Zone')
	CREATE EXTERNAL DATA SOURCE INTERIM_Zone
	WITH (  LOCATION   =  N'$(ADLSLocation)'
    ,CREDENTIAL = WorkspaceIdentity )
Go
-- Create Parquet Format [SynapseParquetFormat]
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseParquetFormat')
	CREATE EXTERNAL FILE FORMAT [SynapseParquetFormat]
	WITH ( FORMAT_TYPE = parquet)
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE EXTERNAL TABLE [dbo].[parking_bay_ext]
(
 [bay_id] BIGINT
,[last_edit] VARCHAR(50)
,[marker_id] VARCHAR(50)
,[meter_id] VARCHAR(50)
,[rd_seg_dsc] VARCHAR(500)
,[rd_seg_id] VARCHAR(50)
,[the_geom] VARCHAR(MAX)
,[load_id] VARCHAR(50)
,[loaded_on] VARCHAR(50)
)
WITH (DATA_SOURCE = [INTERIM_Zone],LOCATION = N'interim.parking_bay/*.parquet',FILE_FORMAT = [SynapseParquetFormat])
GO
-- Create parking_bay View 
IF EXISTS(select * FROM sys.views where name = 'parking_bay_view')
    DROP VIEW IF EXISTS parking_bay_view;
GO
CREATE VIEW parking_bay_view AS
SELECT * 
FROM OPENROWSET(
        BULK 'interim.parking_bay/*.parquet',
        DATA_SOURCE = 'INTERIM_Zone',
        FORMAT = 'PARQUET'
    )
WITH ( 
 [bay_id] BIGINT
,[last_edit] VARCHAR(50)
,[marker_id] VARCHAR(50)
,[meter_id] VARCHAR(50)
,[rd_seg_dsc] VARCHAR(500)
,[rd_seg_id] VARCHAR(50)
,[the_geom] VARCHAR(MAX)
,[load_id] VARCHAR(50)
,[loaded_on] VARCHAR(50))
AS [r];
GO
-- Create sensor View now with variables
IF EXISTS(select * FROM sys.views where name = 'sensor_view')
    DROP VIEW IF EXISTS sensor_view;
GO
CREATE VIEW sensor_view AS
SELECT * 
FROM OPENROWSET(
        BULK 'interim.sensor/*.parquet',
        DATA_SOURCE = 'INTERIM_Zone',
        FORMAT = 'PARQUET'
    )
WITH (
    [bay_id] BIGINT 
    ,[st_marker_id] VARCHAR(100)
    ,[lat] REAL
    ,[lon] REAL
    ,[location] VARCHAR(300)
    ,[status] VARCHAR(10)
    ,[load_id] VARCHAR(100)
    ,[loaded_on] VARCHAR(200)
)
AS [r];
GO
