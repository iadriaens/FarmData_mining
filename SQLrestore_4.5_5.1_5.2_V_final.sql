-- requirements input!!
-- 

------------------------------------------------ A. PREPARATION Section ----------------------------------------------------------------------------
IF OBJECT_ID ('fc_FileExists','FUNCTION') IS NOT NULL 
		DROP FUNCTION fc_FileExists;

---- This part should be the first line of your query. Execute it separately. This part should only be executed if the function does not yet exist. If it already exists, skip this part. 
create FUNCTION dbo.fc_FileExists(@path varchar(8000))
RETURNS BIT
AS
BEGIN
     DECLARE @result INT
     EXEC master.dbo.xp_fileexist @path, @result OUTPUT
     RETURN cast(@result as bit)
END;
GO

---- delete pre-existing databases
IF DB_ID ('DDM') IS NOT NULL 
		DROP DATABASE DDM
IF DB_ID ('DDMVMS') IS NOT NULL 
		DROP DATABASE DDMVMS

---- Directories:
DECLARE @DirInputData NVARCHAR(MAX) = 'C:\Users\u0132268\Box Sync\LORE\MastiManResearch\Github\FarmData_mining\1.INPUTDATA\Delaval\A2_4.5_5.1_5.2_V\'
DECLARE @DirOutput1 NVARCHAR(MAX) = 'C:\Users\u0132268\Box Sync\LORE\MastiManResearch\Github\FarmData_mining\2.OUTPUT1\'
DECLARE @DirOutput2 NVARCHAR(MAX) = 'C:\Users\u0132268\Box Sync\LORE\MastiManResearch\Github\FarmData_mining\3.OUTPUT2\'
DECLARE @DirOutput3txt NVARCHAR(MAX) = 'C:\Users\u0132268\Box Sync\LORE\MastiManResearch\Github\FarmData_mining\4.OUTPUT3txt\'
DECLARE @DirOutput3head NVARCHAR(MAX) = 'C:\Users\u0132268\Box Sync\LORE\MastiManResearch\Github\FarmData_mining\4.OUTPUT3head\'
DECLARE @DirZipExe NVARCHAR(MAX) = 'C:\"Program Files"\7-Zip\7z.exe'

------------------------------------------------ B. UNZIP BACKUP FILES ----------------------------------------------------------------------------
-- first declare all variables that are needed later on	in section B	
DECLARE @PreFilesCmdshell TABLE ( id int IDENTITY(1,1)
								,outputCmd nvarchar(512)
								,depth int
								,isfile bit)
DECLARE @PreFilesCmdshell2 TABLE (outputCmd nvarchar(512)
								,depth int
								,isfile bit) 
DECLARE @PreFilesCmdshellCursor CURSOR
DECLARE @PreFilesCmdshellOutputCmd AS NVARCHAR(255)
DECLARE @PreMapOutput NVARCHAR(MAX)

-- make a table containing a list of all zipfiles in the specified directory
INSERT @PreFilesCmdshell2 (outputCmd,depth,isfile) EXEC ('master.sys.xp_dirtree ''' +@DirInputData+''',1,1;')
INSERT INTO @PreFilesCmdshell SELECT * FROM  @PreFilesCmdshell2 WHERE isfile=1 AND RIGHT(outputCmd,4) = '.zip';


-- unzip all zip files specified in the list above
SET @PreFilesCmdshellCursor = CURSOR FOR SELECT outputCmd FROM @PreFilesCmdshell
OPEN @PreFilesCmdshellCursor
FETCH NEXT FROM @PreFilesCmdshellCursor INTO @PreFilesCmdshellOutputCmd
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @PreMapOutput = LEFT (@PreFilesCmdshellOutputCmd,(len(@PreFilesCmdshellOutputCmd)-4)); -- leave out the .zip in the new name
	EXEC ('master..xp_cmdshell '''+@DirZipExe+' e "'+@DirInputData+@PreFilesCmdshellOutputCmd+'" -o"'+@DirOutput1+''+@PreMapOutput+'"''')
	FETCH NEXT FROM @PreFilesCmdshellCursor INTO @PreFilesCmdshellOutputCmd
END

PRINT 'END OF SECTION B'
------------------------------------------------ C. CHOOSE OUTPUT TABLES Section (A2_4.5_5.1_5.2_V)----------------------------------------------------------------------------
DECLARE @ListTables TABLE (TableName NVARCHAR(512))
INSERT INTO @ListTables VALUES ('BasicAnimal')
INSERT INTO @ListTables VALUES ('AnimalLactationSummary')
INSERT INTO @ListTables VALUES ('HistoryAnimal')
INSERT INTO @ListTables VALUES ('HistoryAnimalDailyData')
INSERT INTO @ListTables VALUES ('HistoryAnimalLactationInfo')
INSERT INTO @ListTables VALUES ('SessionMilkYield')
INSERT INTO @ListTables VALUES ('VoluntarySessionMilkYield')
INSERT INTO @ListTables VALUES ('EventAnimalNumberChanged')
INSERT INTO @ListTables VALUES ('PedigreeInfo')
INSERT INTO @ListTables VALUES ('EventInsemination')
INSERT INTO @ListTables VALUES ('Diagnosis')
INSERT INTO @ListTables VALUES ('HistoryAnimalReproductionInfo')
INSERT INTO @ListTables VALUES ('AnimalReproductionInfo')
INSERT INTO @ListTables VALUES ('HistoryAnimalTreatment')
INSERT INTO @ListTables VALUES ('ActivityLevelData')
INSERT INTO @ListTables VALUES ('ActivityDataDaily')
--SELECT * FROM @ListTables  -- if you want to see the table in the results section

PRINT 'END OF SECTION C'

------------------------------------------------ D. RESTORE AND SAVE Section ----------------------------------------------------------------------------
-- declare all variables that are needed later on
DECLARE @FilesCmdshell TABLE ( id int IDENTITY(1,1)
		,outputCmd nvarchar(512)
		,depth int
		,isfile bit)
DECLARE @FilesCmdshell2 TABLE (outputCmd nvarchar(512)
		,depth int
		,isfile bit) 
DECLARE @FilesCmdshellCursor CURSOR
DECLARE @FilesCmdshellOutputCmd AS NVARCHAR(255)
DECLARE @Filename NVARCHAR(MAX)
DECLARE @Table TABLE (LogicalName varchar(128),
					[PhysicalName] varchar(128), 
					[Type] varchar, 
					[FileGroupName] varchar(128), 
					[Size] varchar(128),
					[MaxSize] varchar(128), 
					[FileId]varchar(128), 
					[CreateLSN]varchar(128), 
					[DropLSN]varchar(128), 
					[UniqueId]varchar(128), 
					[ReadOnlyLSN]varchar(128), 
					[ReadWriteLSN]varchar(128),
					[BackupSizeInBytes]varchar(128), 
					[SourceBlockSize]varchar(128), 
					[FileGroupId]varchar(128), 
					[LogGroupGUID]varchar(128), 
					[DifferentialBaseLSN]varchar(128), 
					[DifferentialBaseGUID]varchar(128), 
					[IsReadOnly]varchar(128), 
					[IsPresent]varchar(128), 
					[TDEThumbprint]varchar(128),
					[SnapshotUrl]varchar(128))
DECLARE @PathToBackup NVARCHAR(MAX)
DECLARE @LogicalNameData varchar(128),@LogicalNameLog varchar(128)
DECLARE @sqlRestore NVARCHAR(MAX)
DECLARE @SelectedTable NVARCHAR(MAX)
DECLARE @locationoutputtxt NVARCHAR(MAX)
DECLARE @locationoutputcsv NVARCHAR(MAX)
DECLARE @locationoutputheadertxt NVARCHAR(MAX)
DECLARE @sqlsave NVARCHAR(MAX)


-- search for files in the farmfiles directory (defined in the unzip section) that end with .bak, put them in a list
INSERT @FilesCmdshell2 (outputCmd,depth,isfile) EXEC ('master.sys.xp_dirtree '''+@DirOutput1+''',1,1;')
INSERT INTO @FilesCmdshell SELECT * FROM  @FilesCmdshell2 WHERE isfile=0 --AND RIGHT(outputCmd,4) = '.bak'; -- and right 

SET @FilesCmdshellCursor = CURSOR FOR SELECT outputCmd FROM @FilesCmdshell

EXEC master.dbo.sp_configure 'show advanced options', 1
RECONFIGURE
EXEC master.dbo.sp_configure 'xp_cmdshell', 1
RECONFIGURE 

-- start for loop, for every file in the farmfiles folder that ends with .bak
OPEN @FilesCmdshellCursor
FETCH NEXT FROM @FilesCmdshellCursor INTO @FilesCmdshellOutputCmd
WHILE @@FETCH_STATUS = 0
BEGIN
    USE [master]
	IF RIGHT(@FilesCmdshellOutputCmd,4) = '.bak'
		SET @filename = LEFT (@FilesCmdshellOutputCmd,(len(@FilesCmdshellOutputCmd)-4));	
	ELSE
		SET @filename = LEFT (@FilesCmdshellOutputCmd,len(@FilesCmdshellOutputCmd));
	
	-- if delpro file exists
	IF dbo.fc_FileExists(''+@DirOutput1+'' + SUBSTRING(@FilesCmdshellOutputCmd, 0, len(@FilesCmdshellOutputCmd)+1)+'\DelPro.bak') = 1
	BEGIN
---- RESTORE DATABASES
		-- Detect the name of the new database (DDM or DDMVMS)
		DELETE FROM @Table;
		SET @PathToBackup = ''+@DirOutput1+'' + SUBSTRING(@FilesCmdshellOutputCmd, 0, len(@FilesCmdshellOutputCmd)+1)+'\DelPro.bak'
		INSERT INTO @Table
			EXEC('RESTORE FILELISTONLY FROM DISK=''' +@PathToBackup+ '''')
		SET @LogicalNameData=(SELECT LogicalName FROM @Table WHERE Type='D')
		SET @LogicalNameLog=(SELECT LogicalName FROM @Table WHERE Type='L')

		--command to restore new database
		SET @sqlRestore  = 'RESTORE DATABASE [' +@LogicalNameData +'] 
			FROM  DISK = N'''+@DirOutput1+'' + SUBSTRING(@FilesCmdshellOutputCmd, 0, len(@FilesCmdshellOutputCmd)+1)+'\DelPro.bak'' WITH  REPLACE,
			MOVE N'''+@LogicalNameData+''' TO N'''+@DirOutput2+'' + SUBSTRING(@FilesCmdshellOutputCmd, 0, len(@FilesCmdshellOutputCmd)+1)+ '.mdf'', 
			MOVE N'''+@LogicalNameLog+''' TO N'''+@DirOutput2+'' + SUBSTRING(@FilesCmdshellOutputCmd, 0, len(@FilesCmdshellOutputCmd)+1) + '_log.ldf'', NOUNLOAD,  STATS = 10'
		EXEC(@sqlRestore)
			

			
---- EXPORT TABLES OF THE RESTORED DATABASE AND SAVE IN TXT OR CSV
		DECLARE @ListTablesCursor CURSOR
		SET @ListTablesCursor = CURSOR FOR SELECT TableName FROM @ListTables
		OPEN @ListTablesCursor

		-- start for loop to go through all of the tables defined in section C
		FETCH NEXT FROM @ListTablesCursor INTO @SelectedTable
		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- define the directory of the output files
			SET @locationoutputtxt = ''+@DirOutput3txt+''+@filename+'_'+@SelectedTable+'.txt'
				--SET @locationoutputcsv = 'C:\Users\u0132268\Documents\LORE\MastiManResearch\Github\FarmData_mining\OUTPUT3csv\'+@filename+'_'+@SelectedTable+'.csv'
			SET @locationoutputheadertxt  = ''+@DirOutput3head+''+@filename+'_'+@SelectedTable+'_headers.txt'
				
			-- DATA TABLE: Export tables without header names
			SET @sqlsave = 'master.sys.xp_cmdshell ''bcp "SELECT * FROM '+@LogicalNameData+'.dbo.'+@SelectedTable+'" queryout "'+@locationoutputtxt+'" -c -T -t; -S localhost\SQLEXPRESS'''
				--SET @sqlsave = 'master.sys.xp_cmdshell ''bcp "SELECT * FROM '+@LogicalNameData+'.dbo.'+@SelectedTable+'" queryout "'+@locationoutputcsv+'" -c -T -t; -S localhost\SQLEXPRESS'''
			EXEC (@sqlsave);

			-- HEADER NAMES: Make a temporary table containing the headernames of the selected data table (Can not be in a variable since bcp needs to access it.)
			DROP TABLE IF EXISTS HeaderNamesTmp
			CREATE TABLE HeaderNamesTmp(headerName VARCHAR(max))
			INSERT INTO HeaderNamesTmp EXEC ('SELECT COLUMN_NAME from '+@LogicalNameData+'.INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='''+@SelectedTable+'''')


			--Export data table to a txt file (or csv file)
			SET @sqlsave = 'master.sys.xp_cmdshell ''bcp "SELECT * from master.dbo.HeaderNamesTmp" queryout "'+@locationoutputheadertxt+'" -c -T -t; -S localhost\SQLEXPRESS'''
				-- SET @sqlsave = 'master.sys.xp_cmdshell ''bcp "SELECT * from master.dbo.HeaderNamesTmp" queryout "'+@locationoutputheadercsv+'" -c -T -t; -S localhost\SQLEXPRESS'''
			EXEC (@sqlsave);
					
			-- Go to the next iteration: delete table with header names, and select a new data table to export within the same database
			DROP TABLE HeaderNamesTmp
			FETCH NEXT FROM @ListTablesCursor INTO @SelectedTable
		END

		CLOSE @ListTablesCursor
		DEALLOCATE @ListTablesCursor
	END  -- Go to the next table within this database


---- END OF ITERATION, PREPARE FOR NEXT DATABASE
	-- Drop database for the next iteration
	IF DB_ID (@LogicalNameData) IS NOT NULL 
			EXEC ('DROP DATABASE '+@LogicalNameData)

	-- Next iteration: new database
	FETCH NEXT FROM @FilesCmdshellCursor INTO @FilesCmdshellOutputCmd
END

PRINT 'END OF SECTION D'
