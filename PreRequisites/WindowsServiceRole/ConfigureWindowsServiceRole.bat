@echo off
REM $binariesShareName - Specify binaries share name where installation binaries copied
REM $binariesSharePath - Specify binaries share path
REM $binariesShareFullAccessUsersCommaSeperated - Non-mandatory field. Specify comma separated users including domain name to whom you want to grant full access on the share
REM $binariesShareChangeAccessUsersCommaSeperated - Specify comma separated users including domain name to whom you want to grant change access on the share
REM $binariesShareReadAccessUsersCommaSeperated - Non-mandatory field. Specify comma separated users including domain name to whom you want to grant read access on the share

powershell -Command "& {.\ConfigureWindowsServiceRole.ps1 -binariesShareName 'binariesShareName' -binariesSharePath 'binariesSharePath' -binariesShareFullAccessUsersCommaSeperated 'binariesShareFullAccessUsersCommaSeperated' -binariesShareChangeAccessUsersCommaSeperated 'binariesShareChangeAccessUsersCommaSeperated' -binariesShareReadAccessUsersCommaSeperated 'binariesShareReadAccessUsersCommaSeperated' }" -NoExit
PAUSE
