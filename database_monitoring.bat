sqlcmd -S server -i C:\Users\schoud1\Desktop\DB_MONITORING\Database_Tables_Delete.sql -o C:\Users\schoud1\Desktop\DB_MONITORING\database_monitoring_status.txt && @echo off
Powershell.exe -executionpolicy remotesigned -File  C:\Users\schoud1\Desktop\DB_MONITORING\psemail2.ps1
