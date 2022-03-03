@echo off
REM psRemotingServerNamesCommaSeperated - Specify remote server names comma separated to which we need to enable remote powershell

powershell -Command "& {.\ConfigureDeploymentRole.ps1 -psRemotingServerNamesCommaSeperated 'RemoteServerNamesCommaSeperated'}" -NoExit
PAUSE
