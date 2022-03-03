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

#Get Sql server
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
Add-Type -path "C:\Windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo\13.0.0.0__89845dcd8080cc91\Microsoft.SqlServer.Smo.dll"
$server = new-object ('Microsoft.SqlServer.Management.Smo.Server') $jsonObj.sqlServer.server

#Check database exists or not
$getDatabase = $server.Databases[$jsonObj.sqlServer.database] 
if($getDatabase)
{
write-host "Database already exists"
} 
else
{
write-host "Database does not exists"
}

#Function to execute sql query
function ExecuteSqlSelectQuery ($Server, $Database, $Table) {
	try
	{
		$Datatable = New-Object System.Data.DataTable
    
		$Connection = New-Object System.Data.SQLClient.SQLConnection
		$Connection.ConnectionString = "server='$Server';database='$Database';trusted_connection=true;"
		$Connection.Open()
		$Command = New-Object System.Data.SQLClient.SQLCommand
		$Command.Connection = $Connection
		$Command.CommandText = "SELECT TOP(1) * From $($Table)"
		$Reader = $Command.ExecuteReader()
		$Datatable.Load($Reader)
		$Connection.Close()
		Write-host "Table exists"
	}
	catch
	{
		$exceptionMessage = $_.Exception.Message
		Write-host "Table [$Table] does not exists on Database[$Database] Server[$Server]! ExceptionMessage[$exceptionMessage]" -ForegroundColor Red
		Write-Host "Deployment interrupted!" -ForegroundColor Red		
		throw
	}
   
}

#Call Method to execute sql query
ExecuteSqlSelectQuery $($jsonObj.sqlServer.server) $($jsonObj.sqlServer.database) $($jsonObj.sqlServer.table)