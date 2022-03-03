param(
	[Parameter(Position=0,Mandatory=$true)]
	[string]$configurationKey,
	[Parameter(Position=1,Mandatory=$true)]
	[string]$configurationPath,
	[Parameter(Position=2,Mandatory=$true)]
	[string]$username,
	[Parameter(Position=3,Mandatory=$true)]
	[string]$password
)

$configurationFilePath = ".\Configuration.json"

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

# Read the configuration from the JSON file.
try {	
	$configuration=ConvertFrom-Json -InputObject (Gc $configurationFilePath -Raw)
	$configurationNode = $configuration.configuration | where { $_.key -eq $step.configurationKey}	
} catch {
	Write-Host Configuration is invalid! -ForegroundColor Red
	$exception = New-Object System.Exception ("Configuration is invalid!")
	throw $exception 
}

try {
	# Read the copy files configuration from the JSON file.
	$copyFilesConfiguration = ConvertFrom-Json -InputObject (Gc $configurationPath -Raw)
	$copyFilesConfigurationNode = $copyFilesConfiguration.configuration | where { $_.key -eq $step.configurationKey}	
	$server = $copyFilesConfigurationNode.value.server
	$targetPath = $copyFilesConfigurationNode.value.targetPath
	$configToCopy = $copyFilesConfigurationNode.value.configToCopy
	$scriptsToCopy = $copyFilesConfigurationNode.value.scriptsToCopy
	$packagesToCopy = $copyFilesConfigurationNode.value.packagesToCopy
	# $commonToCopy = $copyFilesConfigurationNode.value.commonToCopy
} catch {
	Write-Host Copy files configuration is invalid! -ForegroundColor Red
	$exception = New-Object System.Exception ("Copy files Configuration is invalid!")
	throw $exception 
}

# Get the installation credentials from the Library(Azure Key Vault Sync)
$securePassword = ConvertTo-SecureString $configurationNode.value.installationCredentialPassword -AsPlainText -Force 
$credential = New-Object System.Management.Automation.PSCredential($configurationNode.value.installationCredentialUserName, $securePassword) 
    
# Prepare the copy of the files to the target machine by creating a PowerShell drive
Write-Host Testing file share access to $targetPath drop folder on target server -foregroundcolor White
$remoteFolderOnTargetSharePointMachine = $targetPath
Try
{
	New-PSDrive -Name J -PSProvider FileSystem -Root $remoteFolderOnTargetSharePointMachine -Credential $credential
	Write-Host Drop folder $targetPath is accessible -ForegroundColor White 

	# Copy the Scripts folder and its contents to the destination
	if ([string]::IsNullOrEmpty($scriptsToCopy) -eq $false)
	{
		Write-Host Start copy scripts to $server -foregroundcolor White 
		$newFilename= $scriptsToCopy   
		$newFilePath= (join-path $remoteFolderOnTargetSharePointMachine -childpath $newFilename)
		if (-not(Test-Path $newFilePath)){
			Copy-Item $scriptsToCopy -Destination $newFilePath
		}
		Copy-Item $scriptsToCopy\* -Destination $newFilePath -Force -Recurse
	}

	# Copy the Packages folder and its contents to the destination
	if ([string]::IsNullOrEmpty($packagesToCopy) -eq $false)
	{
		Write-Host Start copy packages to $server -foregroundcolor White 
		$newFilename= $packagesToCopy   
		$newFilePath= (join-path $remoteFolderOnTargetSharePointMachine -childpath $newFilename)
		if (-not(Test-Path $newFilePath)){
			Copy-Item $packagesToCopy -Destination $newFilePath
		} 
		Copy-Item $packagesToCopy\* -Destination $newFilePath -Force -Recurse
	}

	if ($configToCopy -ne $null)
	{
		# Copy the configuration JSON file to the destination
		$newFilename= $scriptsToCopy  
		$newFilePath= (join-path $remoteFolderOnTargetSharePointMachine -childpath $newFilename)
		foreach ($configFile in $configToCopy)
		{
			Copy-Item $configToCopy $newFilePath -Force
		}
	} 
}
Catch
{
	$ErrorMessage = $_.Exception.Message
	Write-Host "ERROR [$ErrorMessage]" -ForegroundColor Red
	Write-Host "Deployment interrupted!" -ForegroundColor Red
	throw
}
Finally
{
	# Remove the PowerShell drive
	Remove-PSDrive J
}

Write-Host Files successfully copied to $server! -ForegroundColor White