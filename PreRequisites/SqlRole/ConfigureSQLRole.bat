@echo off
REM $sqlServerVersion - Specify the version of SQL server (2016, 2017, 2019) - SQL Server 2016 is default
REM $sqlServerName - Specify sql server name in which databases to be created.
REM $adaptorDatabaseName - Specify adaptor database name
REM $adminConsultDatabaseName - Specify admin consult database name

powershell -Command "& {.\ConfigureSQLRole.ps1 -sqlServerVersion '2019' -sqlServerName 'sqlServerName' -adaptorDatabaseName 'adaptorDatabaseName' -adminConsultDatabaseName 'adminConsultDatabaseName' -loggingDatabaseName 'loggingDatabaseName'}" -NoExit
PAUSE
