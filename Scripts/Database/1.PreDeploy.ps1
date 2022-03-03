param 
( 
	[Parameter(Position=0,Mandatory=$true)]
	[string]$configurationKey,
	[Parameter(Position=1,Mandatory=$true)]
	[string]$configurationPath,	
	[Parameter(Position=2,Mandatory=$true)]
	[string]$username,
	[Parameter(Position=3,Mandatory=$true)]
	[string]$password
	
)

$PSVersion = Get-Host | Select-Object Version
Write-Host "PowerShell version: $PSVersion"
Write-Host "The following parameters are used:"
$ParameterList = (Get-Command -Name $MyInvocation.InvocationName).Parameters;
foreach ($key in $ParameterList.keys)
{
    $var = Get-Variable -Name $key -ErrorAction SilentlyContinue;
    if (($var) -and ($var.name -ne "password"))
    {
        Write-Host "`t`t -$($var.name) => [$($var.value)]"
    }
}

#Read json object
$jsonObj=ConvertFrom-Json -InputObject (Gc $configurationPath -Raw)

foreach( $configuration in $jsonObj.configuration){
	if( $configuration.key -eq $configurationKey){
		$jsonObj = $configuration.value
	}
}

#Check if the current execution policy is set to Bypass
try
{
		$executionPolicy = Get-ExecutionPolicy
		if(($executionPolicy -eq 'Bypass') -or ($executionPolicy -eq 'Unrestricted')){
			Write-Host "Execution policy is set to $executionPolicy." -ForegroundColor White
		}
		else{
			throw "Execution policy is set to {0}, it should be set to: Bypass or Unrestricted" -f $executionPolicy
		}
}
catch
{
	Write-Host $_.Exception -ForegroundColor Red
	throw "Failed to determine if the current execution policy is set to Bypass or Unrestricted"
}


#Check if SQL Server Management Objects (SMO) is installed
try
{
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
	Add-Type -path "C:\Windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo\13.0.0.0__89845dcd8080cc91\Microsoft.SqlServer.Smo.dll"
}
catch
{
	Write-Host "SQL Server Management Objects is not correctly installed, deployment cannot continue!" -ForegroundColor Red
	Write-Host $_.Exception -ForegroundColor Red
	throw
}

#Get sql server
$serverInstance = new-object ('Microsoft.SqlServer.Management.Smo.Server') $jsonObj.sqlserver.server

#Check sql instance
if($serverInstance){
	$message = "The SQL Server Instance {0} was successfully found!" -f $jsonObj.sqlserver.server
	Write-Host $message -ForegroundColor White

	#Check sql database
	$db = $serverInstance.Databases[$jsonObj.sqlserver.database]
	if ($db){
		$message = "The SQL DB {0} was successfully found!" -f $jsonObj.sqlserver.database
		Write-Host $message -ForegroundColor White
	}
	else{
		$message = "The SQL DB {0} was not found!" -f $jsonObj.sqlserver.database
		Write-Host $message -ForegroundColor Red
		Write-Host "Deployment interrupted!" -ForegroundColor Red
		throw
	}
}
else
{
	$message = "The SQL Server Instance {0} was not found!" -f $jsonObj.sqlserver.server
	Write-Host $message -ForegroundColor Red
	Write-Host "Deployment interrupted!" -ForegroundColor Red
	throw
}

function CheckFullTextSearchProperty ($Server, $Database) {
	try
	{  
		$Connection = New-Object System.Data.SQLClient.SQLConnection
		$Connection.ConnectionString = "server='$Server';database='$Database';trusted_connection=true;"
		$Connection.Open()
		$Command = New-Object System.Data.SQLClient.SQLCommand
		$Command.Connection = $Connection
		$Command.CommandText = "SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')"
		$result = $Command.ExecuteScalar()
		$Connection.Close()

        if( $result -eq 1 )
        {
            Write-host "Full-Text search supported!" -ForegroundColor Green
			Write-Host "Deployment continues..." -ForegroundColor White
        }
        else
        {
            Write-host "Full-Text search feature not installed" -ForegroundColor Red
		    Write-Host "Deployment interrupted!" -ForegroundColor Red		
		    throw
        }
	}
	catch
	{
        Write-host "Full-Text search feature not installed" -ForegroundColor Red
		Write-Host "Deployment interrupted!" -ForegroundColor Red		
		throw
	}  
}

CheckFullTextSearchProperty $($jsonObj.sqlServer.server) $($jsonObj.sqlServer.database)