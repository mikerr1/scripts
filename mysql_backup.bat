@echo off

REM Backup settings
set "MYSQL_USER=root"          REM MySQL username
set "MYSQL_PASSWORD=xx"        REM MySQL password
set "BACKUP_DIR=C:\mysql_backups"  REM Directory to store backups
set "MYSQL_PATH=C:\Program Files\MySQL\MySQL Server 8.4\bin" REM Path to MySQL binaries

REM Create the static backup directory (no date)
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
)

echo Starting database backup process... > "%BACKUP_DIR%\error.log"

REM Fetch database list and process it
echo Fetching database list...
"%MYSQL_PATH%\mysql.exe" -u"%MYSQL_USER%" -p"%MYSQL_PASSWORD%" -e "SHOW DATABASES;" > "%BACKUP_DIR%\database_list.txt" 2>> "%BACKUP_DIR%\error.log"

REM Ensure the database list was successfully fetched
if not exist "%BACKUP_DIR%\database_list.txt" (
    echo Database list retrieval failed. Aborting. Check error.log for details.
    exit /b 1
)

REM Read and process the database list
for /f "skip=1 tokens=*" %%I in (%BACKUP_DIR%\database_list.txt) do (
    REM Check for blank lines or system databases
    if not "%%I"=="" if /i not "%%I"=="information_schema" if /i not "%%I"=="performance_schema" if /i not "%%I"=="mysql" if /i not "%%I"=="sys" (
        echo Backing up database: %%I...
        "%MYSQL_PATH%\mysqldump.exe" -u"%MYSQL_USER%" -p"%MYSQL_PASSWORD%" --databases %%I > "%BACKUP_DIR%\%%I.sql" 2>> "%BACKUP_DIR%\error.log"
        if errorlevel 1 (
            echo Failed to back up database: %%I. Check error.log for details. >> "%BACKUP_DIR%\error.log"
        ) else (
            echo Successfully backed up database: %%I >> "%BACKUP_DIR%\error.log"
        )
    )
)

REM Backup users and privileges
echo Backing up users and privileges...
"%MYSQL_PATH%\mysqldump.exe" -u"%MYSQL_USER%" -p"%MYSQL_PASSWORD%" mysql --no-create-info --tables user db proxies_priv > "%BACKUP_DIR%\mysql_users_privileges.sql" 2>> "%BACKUP_DIR%\error.log"

REM Completion message
echo Backup complete. Files are located in: %BACKUP_DIR%
pause
