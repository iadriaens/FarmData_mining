------------------------------------------------ A. PREPARATION Section ----------------------------------------------------------------------------
IF OBJECT_ID ('fc_FileExists','FUNCTION') IS NOT NULL 
		DROP FUNCTION fc_FileExists;

--this part should be the first line of your query. Execute it separately
create FUNCTION dbo.fc_FileExists(@path varchar(8000))
RETURNS BIT
AS
BEGIN
     DECLARE @result INT
     EXEC master.dbo.xp_fileexist @path, @result OUTPUT
     RETURN cast(@result as bit)
END;
GO

------------------------------------------------ B. CHOOSE OUTPUT TABLES Section ----------------------------------------------------------------------------
DECLARE @ListTables TABLE (TableName NVARCHAR(512))
INSERT INTO @ListTables VALUES ('BenMilkVisit')
INSERT INTO @ListTables VALUES ('HemAnimal')
INSERT INTO @ListTables VALUES ('HemBreed')
INSERT INTO @ListTables VALUES ('HemDiagnoses')
INSERT INTO @ListTables VALUES ('HemDiagnosesAction')
INSERT INTO @ListTables VALUES ('HemMedicationUsed')
INSERT INTO @ListTables VALUES ('LimActivityHours')
INSERT INTO @ListTables VALUES ('LimCalendarType')
INSERT INTO @ListTables VALUES ('LimDisease')
INSERT INTO @ListTables VALUES ('LimMedicine')
INSERT INTO @ListTables VALUES ('LimSire')
INSERT INTO @ListTables VALUES ('PrmActivityScr')
INSERT INTO @ListTables VALUES ('PrmDailyRuminationData')
INSERT INTO @ListTables VALUES ('PrmDeviceVisit')
INSERT INTO @ListTables VALUES ('PrmFatAndProtein')
INSERT INTO @ListTables VALUES ('PrmLactose')
INSERT INTO @ListTables VALUES ('PrmMilkDayProduction')
INSERT INTO @ListTables VALUES ('PrmMilkVisit')
INSERT INTO @ListTables VALUES ('RemHeat')
INSERT INTO @ListTables VALUES ('RemHeatScr')
INSERT INTO @ListTables VALUES ('RemInsemination')
INSERT INTO @ListTables VALUES ('RemLactation')
INSERT INTO @ListTables VALUES ('RemPregnancy')

--INSERT INTO @ListTables VALUES (''))
--SELECT * FROM @ListTables  -- if you want to see the table in the results section

PRINT 'END OF SECTION B'

------------------------------------------------ C. UNZIP FILES ----------------------------------------------------------------------------
-- drop databases to clear workspace
IF OBJECT_ID ('Lely','Database') IS NOT NULL 
		DROP DATABASE Lely;

-- first declare all variables that are needed later on		
DECLARE @PreFilesCmdshell TABLE ( id int IDENTITY(1,1)
      ,outputCmd nvarchar(512)
      ,depth int
      ,isfile bit)
DECLARE @PreFilesCmdshell2 TABLE (outputCmd nvarchar(512)
      ,depth int
      ,isfile bit) 
DECLARE @PreFilesCmdshellCursor CURSOR
DECLARE @PreFilesCmdshellOutputCmd AS NVARCHAR(255)
DECLARE @PreFilename NVARCHAR(MAX)
DECLARE @Prelocationinput NVARCHAR(MAX)
DECLARE @PreMapOutput NVARCHAR(MAX)
DECLARE @unzip NVARCHAR (MAX)

-- make a table containing a list of all zipfiles in the specified directory
INSERT @PreFilesCmdshell2 (outputCmd,depth,isfile) EXEC master.sys.xp_dirtree 'C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\Lely\',1,1;
INSERT INTO @PreFilesCmdshell SELECT * FROM  @PreFilesCmdshell2 WHERE isfile=1 --AND RIGHT(outputCmd,4) = '.zip';
--SELECT * FROM @PreFilesCmdshell  -- if you want to see which tables are in the list of zip files


-- unzip all zip files specified in the list above
SET @PreFilesCmdshellCursor = CURSOR FOR SELECT outputCmd FROM @PreFilesCmdshell
OPEN @PreFilesCmdshellCursor
FETCH NEXT FROM @PreFilesCmdshellCursor INTO @PreFilesCmdshellOutputCmd
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @Prelocationinput = 'C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\Lely\'+@PreFilesCmdshellOutputCmd
	SET @PreMapOutput = LEFT (@PreFilesCmdshellOutputCmd,(len(@PreFilesCmdshellOutputCmd)-4)); -- leave out the .zip in the new name
	SET @unzip = 'master..xp_cmdshell ''C:\"Program Files"\7-Zip\7z.exe e "'+@Prelocationinput+'" -o"C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT1\'+@PreMapOutput+'"'''
	EXEC (@unzip)
	FETCH NEXT FROM @PreFilesCmdshellCursor INTO @PreFilesCmdshellOutputCmd
END
-- puts farmsfiles in the farmfile directory!

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
DECLARE @sqlRestore NVARCHAR(MAX)
DECLARE @SelectedTable NVARCHAR(MAX)
-----DECLARE @ListTablesCursor CURSOR
DECLARE @locationoutputtxt NVARCHAR(MAX)
DECLARE @locationoutputcsv NVARCHAR(MAX)
DECLARE @locationoutputheadertxt NVARCHAR(MAX)
DECLARE @sqlsave NVARCHAR(MAX)


-- search for files in the farmfiles directory (defined in the unzip section) that end with .bak, put them in a list
INSERT @FilesCmdshell2 (outputCmd,depth,isfile) EXEC master.sys.xp_dirtree 'C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT1\',1,1;
INSERT INTO @FilesCmdshell SELECT * FROM  @FilesCmdshell2 WHERE isfile=0 --AND RIGHT(outputCmd,4) = '.bak'; -- and right 
SELECT * FROM @FilesCmdshell -- if you want to see the list of farmfiles

SET @FilesCmdshellCursor = CURSOR FOR SELECT outputCmd FROM @FilesCmdshell
-----SET @ListTablesCursor = CURSOR FOR SELECT TableName FROM @ListTables

EXEC master.dbo.sp_configure 'show advanced options', 1
RECONFIGURE
EXEC master.dbo.sp_configure 'xp_cmdshell', 1
RECONFIGURE 

-- start for loop, for every file in the farmfiles folder that ends with .bak
-----OPEN @ListTablesCursor
OPEN @FilesCmdshellCursor
FETCH NEXT FROM @FilesCmdshellCursor INTO @FilesCmdshellOutputCmd
WHILE @@FETCH_STATUS = 0
BEGIN
    USE [master]
	DECLARE @locationinput NVARCHAR(MAX) = 'C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT1\'+@FilesCmdshellOutputCmd
	IF RIGHT(@FilesCmdshellOutputCmd,4) = '.bak'
		SET @filename = LEFT (@FilesCmdshellOutputCmd,(len(@FilesCmdshellOutputCmd)-4));	
	ELSE
		SET @filename = LEFT (@FilesCmdshellOutputCmd,len(@FilesCmdshellOutputCmd));
	PRINT @filename

-- RESTORE DATABASES
	-- if Lely file exists
	IF dbo.fc_FileExists('C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT1\' + SUBSTRING(@FilesCmdshellOutputCmd, 0, len(@FilesCmdshellOutputCmd)+1)+'\Lely.bak') = 1
		BEGIN
			-- drop existing databases
			IF OBJECT_ID ('Lely','Database') IS NOT NULL 
				BEGIN
					DROP DATABASE Lely
					PRINT 'DATABASE DELETED';
				END

			--command to restore new database
			SET @sqlRestore  = 'RESTORE DATABASE [Lely] 
				FROM  DISK = N''C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT1\' + SUBSTRING(@FilesCmdshellOutputCmd, 0, len(@FilesCmdshellOutputCmd)+1)+'\Lely.bak'' WITH  REPLACE,
				MOVE N''LELY_Data'' TO N''C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT2\' + SUBSTRING(@FilesCmdshellOutputCmd, 0, len(@FilesCmdshellOutputCmd)+1)+ '.mdf'', 
				MOVE N''LELY_log'' TO N''C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT2\' + SUBSTRING(@FilesCmdshellOutputCmd, 0, len(@FilesCmdshellOutputCmd)+1) + '_log.ldf'', NOUNLOAD,  STATS = 5'
			EXEC(@sqlRestore)
			-- get all the tables out
			
-- EXPORT TABLES OF THE RESTORED DATABASE

				DECLARE @ListTablesCursor CURSOR
				SET @ListTablesCursor = CURSOR FOR SELECT TableName FROM @ListTables
				OPEN @ListTablesCursor

				FETCH NEXT FROM @ListTablesCursor INTO @SelectedTable
				WHILE @@FETCH_STATUS = 0
				BEGIN
					-- define the directory of the output files
					SET @locationoutputtxt = 'C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT_Lelytxt\'+@filename+'_'+@SelectedTable+'.txt'
					-----SET @locationoutputcsv = 'C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT3csv\'+@filename+'_'+@SelectedTable+'.csv'
					SET @locationoutputheadertxt  = 'C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Data\Data sets\Backup files\testSQLOUTPUT_Lelyhead\'+@filename+'_'+@SelectedTable+'_headers.txt'
					-- Export tables without header names
					SET @sqlsave = 'master.sys.xp_cmdshell ''bcp "SELECT * FROM Lely.dbo.'+@SelectedTable+'" queryout "'+@locationoutputtxt+'" -c -T -t; -S localhost\SQLEXPRESS'''
					EXEC (@sqlsave);
					-----SET @sqlsave = 'master.sys.xp_cmdshell ''bcp "SELECT * FROM DDMVMS.dbo.'+@SelectedTable+'" queryout "'+@locationoutputcsv+'" -c -T -t; -S localhost\SQLEXPRESS'''
					-----EXEC (@sqlsave);

					
					--Make a temporary table for headernames (Can not be in a variable since bcp needs to access it.)
					DROP TABLE IF EXISTS HeaderNamesTmp
					
					CREATE TABLE HeaderNamesTmp(headerName VARCHAR(max))
					--Fill table with column names
					INSERT INTO HeaderNamesTmp
					SELECT COLUMN_NAME from Lely.INFORMATION_SCHEMA.COLUMNS where TABLE_NAME=@SelectedTable;
					select * from HeaderNamesTmp
					--Export table
					SET @sqlsave = 'master.sys.xp_cmdshell ''bcp "SELECT * from master.dbo.HeaderNamesTmp" queryout "'+@locationoutputheadertxt+'" -c -T -t; -S localhost\SQLEXPRESS'''
					EXEC (@sqlsave);
					--Drop table for next iteration
					DROP TABLE HeaderNamesTmp

					-- go to the next iteration: new table to export within the same database
					FETCH NEXT FROM @ListTablesCursor INTO @SelectedTable
				END

				CLOSE @ListTablesCursor
				DEALLOCATE @ListTablesCursor


		END

-- NEXT ITERATION, NEXT DATABASE
	-- Drop database for the next iteration
	-----IF OBJECT_ID ('DDMVMS','Database') IS NOT NULL 
		-----DROP DATABASE DDMVMS
	IF OBJECT_ID ('Lely','Database') IS NOT NULL 
		DROP DATABASE Lely

	-- Next iteration: new database
	FETCH NEXT FROM @FilesCmdshellCursor INTO @FilesCmdshellOutputCmd
END
--PRINT 'END OF SECTION D'

