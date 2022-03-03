# This script will configure deployment role in deployment server
# History: [LV] 22/02/2019 - Creation of steps
# History: [RAK] 27/02/2019 - Implementation of steps   
# History: [Sasi] 11/02/2021 - Updated Set-ExecutionPolicy to AllSigned
###################################################################

# Parameters
param
(
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
	[string]$psRemotingServerNamesCommaSeperated
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

Try {
		# Set PowerShell Execution Policy
		# To ensure that only signed scripts can be executed, 
		# the PowerShell execution policy should be updated on the deployment machine. 
		# The following command must be executed to set the execution policy to ‘AllSigned’ for PowerShell scripts on the machine
		Write-Host "Setting PowerShell Execution Policy to AllSigned..."
		Set-ExecutionPolicy –ExecutionPolicy AllSigned
		# Enable PowerShell remoting
		# Enable remote PowerShell client credential delegation to support remote execution of PowerShell cmdlets. 
		# In order to enable remote sessions towards to other servers in the farm, the following command must be executed on the deployment machine
		Write-Host "Enabling Remoting PowerShell..."
	    $psRemotingServerNamesCommaSeperated.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
			Enable-WSManCredSSP -Role Client -DelegateComputer $_ –Force
			Write-Host "Remote powershell enabled to server: $($_)" 
		}
		
		# The settings can be verified by executing the following command
		$getRemotePowershellSetting = Get-WSManCredSSP
		if($getRemotePowershellSetting -like '*not configured to allow delegating*')
		{
		 Write-Error "Enabling remote powershell failed. Script can not continue!!!" -ErrorAction Stop
		}
		# Install SharePoint PnP PowerShell module
		# For SharePoint the Office Dev PnP PowerShell module is preferred. The Office Dev PnP PowerShell module v2.19.1710.1 is a prerequisite on this server role.
		# Installating the Office Dev PnP PowerShell module is supported via the PowerShell Gallery (https://www.powershellgallery.com/). 
		# Execute the cmdlet below to run the installation.
		Write-Host "Installing SharePoint PnP PowerShell Module..."
		$module = "SharePointPnPPowerShell2016"
		$version = "2.19.1710.1"

		Install-Module $module –requiredversion $version -SkipPublisherCheck
		# The expected output from the following command is: 
		# Name                          Version   
		# ----                          -------   
		# SharePointPnPPowerShell2016 2.19.1710.1
		# Installation of the PowerShell module can be verified by the following cmdlet
		$getModule = Get-Module SharePointPnPPowerShell* -ListAvailable | Select-Object Name,Version | Sort-Object Version -Descending
		if($getModule.Name -ne $module -or $getModule.Version -ne $version)
		{
		  Write-Error "Installing SharePoint PnP PowerShell module failed. Script can not continue!!!" -ErrorAction Stop
		}

		Write-Host "All steps are OK!" -foregroundcolor Green
}
Catch {
	Write-Error "Error Occurred: [$_.Exception.Message]"
}
#This command stops a transcript in the default file location.
Stop-Transcript
