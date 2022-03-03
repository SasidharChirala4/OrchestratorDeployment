# This script will configure windows service role in windows service server
# History: [LV] 22/02/2019 - Creation of steps
# History: [RAK] 27/02/2019 - Implementation of steps       
###################################################################

# Parameters
param(	
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
	[string] $binariesShareName,
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
	[string] $binariesSharePath,
	[Parameter(Mandatory=$false)]
	[string] $binariesShareFullAccessUsersCommaSeperated,
	[Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
	[string] $binariesShareChangeAccessUsersCommaSeperated,
	[Parameter(Mandatory=$false)]
	[string] $binariesShareReadAccessUsersCommaSeperated
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
# Function: Set file share with access(Full/Change/Read).
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
Function SetFileShare([string]$shareName, [string]$sharePath, [string]$shareFullAccessUsersCommaSeperated, [string]$shareChangeAccessUsersCommaSeperated, [string]$shareReadAccessUsersCommaSeperated)
{
	Try
    {
        Write-Host "Setting file share with name '$($shareName)' at '$($sharePath)'..." 
		#Check if share already exists. Sometimes folder won't available but sharing is still available
		$existingShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue
		#Remove share if already exists
		 if($existingShare -ne $null) {
			 Write-Host "Removing share '$($shareName)' at '$($sharePath)'"
			 Remove-SmbShare -Name $shareName -Force
		 }
		
        #Ensure folder created first
        New-Item $sharePath –type directory -force

		# Create share. By default it gives access to EveryOne if we do not specify any access(Full/Change/Read) so setting NoAccess to Everyone
		# –ContinuouslyAvailable Parameter => Whether to keep the share after the next reboot.
		# script is failing when using –ContinuouslyAvailable Parameter so removed it. TODO: Double check if it really needed or not
		New-SMBShare –Name $shareName –Path $sharePath -NoAccess EveryOne

		# Full Access
		if(ValidateInputUser $shareFullAccessUsersCommaSeperated) {
			$shareFullAccessUsersCommaSeperated.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
			Grant-SmbShareAccess -Name $shareName -AccountName $_ -AccessRight Full -Force
			Write-Host "Full Share Access provided to $($_)" 
			}
		}

		# Change Access
		if(ValidateInputUser $shareChangeAccessUsersCommaSeperated) {
			$shareChangeAccessUsersCommaSeperated.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
			Grant-SmbShareAccess -Name $shareName -AccountName $_ -AccessRight Change -Force
			Write-Host "Change Share Access provided to $($_)" 
			}
		}

		# Read Access
		if(ValidateInputUser $shareReadAccessUsersCommaSeperated) {
			$shareReadAccessUsersCommaSeperated.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
			Grant-SmbShareAccess -Name $shareName -AccountName $_ -AccessRight Read -Force
			Write-Host "Read Share Access provided to $($_)"
			}
		}
	    Write-Host "Completed file share with name '$($shareName)' at '$($sharePath)'..." 
		
	}
	Catch
	{
		throw "Error Occurred: [$_.Exception.Message]"
	}
} 

Try {
		# Set PowerShell Execution Policy
		# To ensure that non-signed scripts are not blocked and can be executed without warnings or prompts, 
		# the PowerShell execution policy should be updated on the deployment machine. 
		# The following command must be executed to set the execution policy to ‘Bypass’ for PowerShell scripts on the machine
		Write-Host "Setting PowerShell Execution Policy..."
		Set-ExecutionPolicy –ExecutionPolicy Bypass
		# Enable PowerShell remoting
		# Enable remote PowerShell client credential delegation to support remote execution of PowerShell cmdlets. 
		# In order to enable remote sessions towards to other servers in the farm, the following command must be executed on the deployment machine
		Write-Host "Enabling Remoting PowerShell..."
		Enable-WSManCredSSP -Role Server –Force
		# The settings can be verified by executing the following command
		$getRemotePowershellSetting = Get-WSManCredSSP
		if($getRemotePowershellSetting -like '*not configured to receive credentials*')
		{
		 Write-Error "Enabling remote powershell failed. Script can not continue!!!" -ErrorAction Stop
		}
		# Create binaries file share
	    # During installation a number of files are copied from the Deployment machine server role to this server role. 
	    # To support the copy process a file share needs to be available on this server role.
	    SetFileShare $binariesShareName $binariesSharePath $binariesShareFullAccessUsersCommaSeperated $binariesShareChangeAccessUsersCommaSeperated $binariesShareReadAccessUsersCommaSeperated

	    Write-Host "All steps are OK!" -foregroundcolor Green
}
Catch {
	throw "Error Occured: [$_.Exception.Message]"
}

#This command stops a transcript in the default file location.
Stop-Transcript