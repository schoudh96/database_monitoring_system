
-------------------------------------------------------------------------------------------------------------------------------------------------------
--RUN THIS SCRIPT TO OBTAIN OLD TABLES LAST UPDATED MORE THAN 180 DAYS AGO AND WHICH CAN BE DELETED SUBJECT TO REVIEW
-------------------------------------------------------------------------------------------------------------------------------------------------------


SET NOCOUNT ON
SET ANSI_WARNINGS OFF
DECLARE @SQL VARCHAR(5000)

IF EXISTS (SELECT NAME FROM tempdb..sysobjects WHERE NAME = '##Results')    
   BEGIN    
       DROP TABLE ##Results    
   END   

CREATE TABLE ##Results([Database Name] sysname,
[File Name] sysname,
[Physical Name] NVARCHAR(260),
[File Type] VARCHAR(4),
[Total Size in Mb] INT,
[Available Space in Mb] INT,
[Growth Units] VARCHAR(15),
[Max File Size in Mb] INT)

IF EXISTS (SELECT name FROM tempdb.sys.tables WHERE name like '##tm%')    
    BEGIN    
       DROP TABLE ##tmp_db_table    
    END   

CREATE TABLE ##tmp_db_table([Database] sysname, 
TableName sysname,
SchemaName NVARCHAR(20),
TotalSpaceMB FLOAT,
[Database Space Used %]FLOAT)

SELECT @SQL = 
' USE [?] INSERT INTO ##Results([Database Name], [File Name], [Physical Name],
[File Type], [Total Size in Mb], [Available Space in Mb],
[Growth Units], [Max File Size in Mb])
SELECT DB_NAME(),
[name] as [File Name],
physical_name as [Physical Name],
[File Type] =    
CASE type   
WHEN 0 THEN ''Data'''    
+   
           'WHEN 1 THEN ''Log'''   
+   
       'END,
[Total Size in Mb] =   
CASE ceiling([size]/128)    
WHEN 0 THEN 1   
ELSE ceiling([size]/128)   
END,   
[Available Space in Mb] =    
CASE ceiling([size]/128)   
WHEN 0 THEN (1 - CAST(FILEPROPERTY([name], ''SpaceUsed''' + ') as int) /128)   
ELSE (([size]/128) - CAST(FILEPROPERTY([name], ''SpaceUsed''' + ') as int) /128)   
END,   
[Growth Units]  =    
CASE [is_percent_growth]    
WHEN 1 THEN CAST(growth AS varchar(20)) + ''%'''   
+   
           'ELSE CAST(growth*8/1024 AS varchar(20)) + ''Mb'''   
+   
       'END,   
[Max File Size in Mb] =    
CASE [max_size]   
WHEN -1 THEN NULL   
WHEN 268435456 THEN NULL   
ELSE [max_size]   
END   
FROM sys.database_files   
ORDER BY [File Type], [file_id]'


EXEC sp_MSforeachdb @SQL  

ALTER TABLE ##Results
ADD [Free Space %] decimal(5,2)

ALTER TABLE ##Results
ADD [Used Space %] decimal(5,2)

UPDATE ##Results 
SET [Free Space %] = (CAST([Available Space in Mb] as decimal(10,1))/CAST([Total Size in Mb] as decimal(10,1)) * 100)

UPDATE ##Results
SET [Used Space %] = 100 - [Free Space %]

-------------------------------Showing space used by F:\ disk drive and E:\ disk drive---------------------------------------------------------------------

DECLARE @F_disk_space_used FLOAT

SELECT @F_disk_space_used = (SELECT SUM([Total Size in Mb]) FROM ##Results
WHERE [Physical Name] like 'F%') --and [File Type] = 'Data'
--[Database Name] = 'tempdb'
--SUM([Total Size in Mb])
PRINT '
'
PRINT 'The total space used in F:\ disk by all databases is ' + CAST(@F_disk_space_used as NVARCHAR(30)) + ' MB.'
DECLARE @F_disk_space_max FLOAT = 151000 
PRINT 'The total space used in F:\ disk is only ' + CAST((@F_disk_space_used*100/@F_disk_space_max) AS NVARCHAR(20)) + '% of total disk space. Please start clearing if more than 95%.'

DECLARE @E_disk_space_used FLOAT = (SELECT SUM([Available Space in Mb]) FROM ##Results
WHERE [Physical Name] like 'E%')

DECLARE @E_disk_space_max FLOAT = (SELECT SUM([Total Size in Mb]) FROM ##Results
WHERE [Physical Name] like 'E%') + 236610

PRINT '
'
PRINT 'The total space used in E:\ disk by all databases is ' + CAST(@E_disk_space_used as NVARCHAR(30)) + ' MB.'
PRINT 'The total space used in E:\ disk is only ' + CAST((@E_disk_space_used*100/@E_disk_space_max) AS NVARCHAR(20)) + '% of total disk space. 
E:\ is the disk drive where all our databases reside.
'
PRINT '
'

------------------------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @tmp_databases TABLE
(
 DB VARCHAR(20)
)

DECLARE @var_database NVARCHAR(128)

INSERT INTO @tmp_databases(DB) 
SELECT DISTINCT temp.[Database Name] --, (CAST([Available Space in Mb] as decimal(10,1))/CAST([Total Size in Mb] as decimal(10,1)) * 100) as Free_Space_pct
FROM ##Results temp
WHERE [Database Name] in ('Playground', 'StagingData', 'DirtyData') and [File Type] = 'Data' --and [Used Space %]>75.0

-- pass @sum_size 

DECLARE @sum_size FLOAT
DECLARE @used_size FLOAT

WHILE EXISTS (SELECT DB FROM @tmp_databases)
BEGIN
	
	
	SELECT  @sum_size =	    (SELECT top 1 temp.[Total Size in Mb] 
							 FROM ##Results temp
							 INNER JOIN @tmp_databases tmp_dbs
							 ON temp.[Database Name] = tmp_dbs.DB
							 WHERE [File Type] = 'Data')
							

	SELECT @used_size =	    (SELECT top 1 CAST(temp.[Used Space %]*@sum_size/100 AS FLOAT) AS [Used Space MB] 
							 FROM ##Results temp
							 INNER JOIN @tmp_databases tmp_dbs
							 ON temp.[Database Name] = tmp_dbs.DB
							 WHERE [File Type] = 'Data')
							
	

	SELECT @var_database =  (SELECT TOP 1 DB 
						    FROM @tmp_databases)

	IF @var_database = 'StagingData'
		BEGIN
			EXEC StagingData.dbo.DATABASE_CLEANING @sum_space = @sum_size, @db_name = @var_database, @used_space = @used_size;
		END
	ELSE 
		BEGIN
			IF @var_database = 'Playground'
				EXEC Playground.dbo.DATABASE_CLEANING @sum_space = @sum_size, @db_name = @var_database, @used_space = @used_size;
			ELSE
				BEGIN
					IF @var_database = 'DirtyData'
						EXEC DirtyData.dbo.DATABASE_CLEANING @sum_space = @sum_size, @db_name = @var_database, @used_space = @used_size;
				END
		END



	-- send @sum_size as total size of database and @var_database as name of database in the stored procedure 
	-- execute database_cleaning stored proc with @sum_size as parameter 
	
	DELETE FROM @tmp_databases where DB = @var_database
	PRINT '
	'

	
END

SELECT * FROM ##tmp_db_table

DROP TABLE ##Results
DROP TABLE ##tmp_db_table

