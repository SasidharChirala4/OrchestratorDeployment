param 
( 
	[Parameter(Position=0,Mandatory=$true)]
	[string]$configurationKey,
	[Parameter(Position=1,Mandatory=$true)]
	[string]$configurationPath,
	[Parameter(Position=2,Mandatory=$true)]
	[string]$remote,
	[Parameter(Position=3,Mandatory=$true)]
	[string]$username,
	[Parameter(Position=4,Mandatory=$true)]
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

#Check if the current execution policy is set to AllSigned
try
{
	if ($remote -eq "True")
	{
		$executionPolicy = Get-ExecutionPolicy
		if($executionPolicy -eq 'RemoteSigned'){
			Write-Host "Execution policy is set to RemoteSigned." -ForegroundColor White
		}
		else{
			throw "Execution policy is set to {0}, it should be set to: RemoteSigned" -f $executionPolicy
		}
	}
}
catch
{
	throw "Failed to determine if the current execution policy is set to RemoteSigned"
}

#Read JSON object
$jsonObj=ConvertFrom-Json -InputObject (Gc $configurationPath -Raw)

foreach( $configuration in $jsonObj.configuration)
{
	if( $configuration.key -eq $configurationKey)
	{
		$jsonObj = $configuration.value
	}
}

try
{
	# Check service
	$serviceName = $jsonObj.service.name;
	$windowsService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
	if( $windowsService )
	{
		$service = Get-WmiObject -Class Win32_Service -Filter "Name='$($serviceName)'"
		if($service)
		{
			Write-Host STOPPING SERVICE $serviceName
			Stop-Service $serviceName
		}
		if ($windowsService.Status -eq "Running")
		{
			Write-Host "$serviceName service is already running"
		}
		else
		{
			Write-Host "$serviceName service is not yet running"
		}
	}
	else
	{
		Write-Host "$serviceName service is not installed"
	}
}
catch
{
	Write-Host $_.Exception
}
