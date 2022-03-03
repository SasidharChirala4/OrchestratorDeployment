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
			Write-Host $jsonObj.service.name $postfixName "will be installed on this server!"
			$serviceName = $jsonObj.service.name;			

			if( $jsonObj.service.startup.ToLower() -eq "disabled" )
			{
				Write-Host "$serviceName service is set to disabled in configuration so, no further checks are required!"
			}
			else
			{
				$windowsService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
				if( $windowsService )
				{
					if ($windowsService.Status -eq "Running")
					{
						Write-Host "$serviceName service is successfully installed and running"
					}
					else
					{
						throw "$serviceName service is successfully installed but NOT running"
					}
				}
				else
				{
					throw "$serviceName service is not installed"
				}
			}			
		
}
catch
{
	Write-Host $_.Exception.Message -ForegroundColor Red
	Write-Host "Deployment interrupted!" -ForegroundColor Red
	throw
}