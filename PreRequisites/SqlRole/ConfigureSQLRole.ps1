# This script will configure sql role in sql server
# This script also configure eDReaMS databases for e.g. core, logging and audit

        #This script has to be executed in Sql Server(s) only
		#The execution account should have priviliges to create and configure database(s) 
		#for e.g. ServerRoles => sysadmin and UserMapping => db_owner.
# History: [RAK] 11/11/2020 - Creation of steps   
###################################################################

# Parameters
param(
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
	[string]$sqlServerVersion,	
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
    [string]$sqlServerName,
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
	[string]$adaptorDatabaseName,
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
	[string]$adminConsultDatabaseName
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
	[string]$loggingDatabaseName
	
)

#This command starts a transcript in the default file location.
Start-Transcript

#Validation
[string]$result = "$(Read-Host 'Are you sure you have modified the BAT file prior to execution of this script and it can be launched with the parameters provided?(Y/N)')"
if ([string]::Compare($result, 'Y', $True))
{
      throw "Make sure you have modified the BAT file prior to execution of this script and provide paramaters, script cannot continue !!!"
}
$result = "$(Read-Host 'Are you sure of running script as administrator?(Y/N)')"
if ([string]::Compare($result, 'Y', $True))
{
      throw "Make sure to run script as administrator, script cannot continue !!!"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Function: Validate input user against null, empty string and white space.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
Function ValidateInputUser($user)
{  
  return  @{$true = $true; $false = $false }[-not [string]::IsNullOrEmpty($user) -Or -not [string]::IsNullOrWhiteSpace($user)]    
}


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Function: Check sql instance existance.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Function CheckSqlInstance()
{
	#Check sql instance
	if($serverInstance){
		$message = "The SQL Server Instance {0} was successfully found!" -f $sqlServerName
		Write-Host $message
		Write-Host "Deployment continues..." -ForegroundColor White
	}
	else
	{
		$message = "The SQL Server Instance {0} was not found!" -f $sqlServerName
		Write-Host $message -ForegroundColor Red
		Write-Error "Deployment interrupted!" -ErrorAction Stop
	}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Function: Creation database. Configuration to be included later e.g. Sizing, user roles etc..
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Function ConfigureDatabase([string]$databaseName)
{
	Try
	{
		$databaseToEnsure = $serverInstance.Databases[$databaseName]
		if($databaseToEnsure -eq $null)  
			{
				$databaseToEnsure = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database($serverInstance, $databaseName)
				$databaseToEnsure.Create()
				Write-Host "$databaseToEnsure is created."
			}
		else{
			Write-Host "$databaseToEnsure is already exists."
		}
				
	}  
	Catch {
		throw "Error Occurred: [$_.Exception.Message]"
	}
}

Try {
		# Set PowerShell Execution Policy
		# To ensure that only signed scripts downloaded from an external source can be executed, 
		# the PowerShell execution policy should be ensured on the deployment machine. 
		# The following command must be executed to set the execution policy to ‘RemoteSigned’ for PowerShell scripts on the machine
		Write-Host "Setting PowerShell Execution Policy to RemoteSigned..."
		Set-ExecutionPolicy –ExecutionPolicy RemoteSigned

	    # Create e-DReaMS custom databases
		# Get sql server: To be added here since instance will be used in below methods
	    Write-Host "Checking sql instance..."
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
		if($sqlServerVersion.Equals('2016')){
			Add-Type -path "C:\Windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo\13.0.0.0__89845dcd8080cc91\Microsoft.SqlServer.Smo.dll"
		} 
		elseif($sqlServerVersion.Equals('2017')){
			Add-Type -path "C:\Windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo\14.0.0.0__89845dcd8080cc91\Microsoft.SqlServer.Smo.dll"
		}
		elseif($sqlServerVersion.Equals('2019')){
			# No need for Add-Type for 2019 versions
		}
		else{
			throw "Please specify a correct version of SQL server to execute this script"
		}
		$serverInstance = new-object ('Microsoft.SqlServer.Management.Smo.Server') $sqlServerName
	    # Check sql insatnce
	    CheckSqlInstance
	    # Configure databases 
	    Write-Host "Creating databases..."
	    ConfigureDatabase $adaptorDatabaseName
		ConfigureDatabase $adminConsultDatabaseName
		ConfigureDatabase $loggingDatabaseName	

	   Write-Host "All steps are OK!" -foregroundcolor Green
}
Catch {
	throw "Error Occured: [$_.Exception.Message]"
}

#This command stops a transcript in the default file location.
Stop-Transcript