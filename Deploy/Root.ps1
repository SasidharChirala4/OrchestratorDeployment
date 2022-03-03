$orchestratorConfigurationPath = ".\OrchestratorConfiguration.json"
$copyFilesConfigurationPath = ".\CopyFilesConfiguration.json"
$configurationPath = ".\Configuration.json"

Function RemotePowerShellExecution([string]$targetServer, [string] $targetPath, [string]$script, [string]$configurationKey, [string]$configurationFilePath, [string]$remote, [PsCredential]$installationCredential, [PsCredential]$runAsCredential)
{
	Write-Host "Current user:" + $env:USERNAME	
        
	$username = $runAsCredential.UserName
	$password = $runAsCredential.GetNetworkCredential().Password

	# Start remote PowerShell session and run the script
	if($targetServer.StartsWith("AZU"))
	{
		$s = New-PSSession -ComputerName $targetServer -Authentication Kerberos -Credential $installationCredential -UseSSL -Port 5986
		Write-Host "HTTPS remote Powershell deployment to Azure NSE"
	}
	else
	{
		$s = New-PSSession -ComputerName $targetServer -Authentication Kerberos -Credential $installationCredential
		Write-Host "HTTP remote PowerShell deployment to on-premise SP"
	}	
    $scriptPath = $targetPath+$script
    $scriptBlockContent = {&$using:scriptPath $using:configurationKey $using:configurationFilePath $using:remote $using:username $using:password} 
    Invoke-Command -Session $s -ScriptBlock $scriptBlockContent
	Remove-PSSession $s
}

# Read the orchestrator configuration from the JSON file.
try 
{	
	$orchestratorConfiguration=ConvertFrom-Json -InputObject (Gc $orchestratorConfigurationPath -Raw)
	$validOrchestratorConfiguration = $TRUE;
} catch {
	Write-Host "Orchestrator Configuration is invalid!" -ForegroundColor Red
	Write-Host "Error details:" $_ -ForegroundColor Red
	throw "Orchestrator Configuration is invalid!"
}

# Read the copyFiles configuration from the JSON file.
try 
{	
	$copyFilesConfiguration=ConvertFrom-Json -InputObject (Gc $copyFilesConfigurationPath -Raw)
	$validCopyFilesConfiguration = $TRUE;
} catch {
	Write-Host "CopyFiles Configuration is invalid!" -ForegroundColor Red
	Write-Host "Error details:" $_ -ForegroundColor Red
	throw "CopyFiles Configuration is invalid!"
}

# Read the configuration from the JSON file.
try 
{	
	$configuration=ConvertFrom-Json -InputObject (Gc $configurationPath -Raw)
	$validConfiguration = $TRUE;
} catch {
	Write-Host "Configuration is invalid!" -ForegroundColor Red
	Write-Host "Error details:" $_ -ForegroundColor Red
	throw "Configuration is invalid!"
}

if( $validOrchestratorConfiguration -and $validCopyFilesConfiguration  -and $validConfiguration) 
{
	try 
	{
		# Iterate all orchestrator steps defined in the orchestrator configuration.
		foreach( $orchestratorStep in $orchestratorConfiguration.steps)
		{   
			# Write the orchestrator step description to the console to mark the start.
			Write-Host $orchestratorStep.description -ForegroundColor Yellow
	
			# Iterate all sub-steps defined in the orchestrator base step.
			foreach( $step in $orchestratorStep.steps)
			{
				# Write the sub-step description to the console to mark the start.
				Write-Host $step.description -ForegroundColor Cyan
				Write-Host $env:computername

				# Write the setting for remote execution of the script
				$remote = $step.remote
				Write-Host "Remote execution:" $remote

				# Invoke the script through remote PowerShell execution if remote is set to True
				if ($remote -eq "True")
				{
					# Read configuration values from json files
					$copyFilesConfigurationNode = $copyFilesConfiguration.configuration | where { $_.key -eq $step.configurationKey}
					$configurationNode = $configuration.configuration | where { $_.key -eq $step.configurationKey}

					# Check if the script execution is enabled
					if( $configurationNode.shouldExecute -eq "True" )
					{
						$targetServer = $copyFilesConfigurationNode.value.server
						Write-Host "Target server:" $targetServer
						$targetPath = $copyFilesConfigurationNode.value.targetPath
						Write-Host "Target path:" $targetPath

						# The installation credentials will be used to run the remote session
						Write-Host "Installation user:" $configurationNode.value.installationCredentialUserName
						$securePassword = ConvertTo-SecureString -String $configurationNode.value.installationCredentialPassword -AsPlainText -Force
						$installationCredential = New-Object System.Management.Automation.PSCredential($configurationNode.value.installationCredentialUserName, $securePassword)
						
						# The run as credentials will be passed to the script which is invoked
						Write-Host "Run as user:" $configurationNode.value.installationCredentialUserName
						$securePassword = ConvertTo-SecureString -String $configurationNode.value.installationCredentialPassword -AsPlainText -Force
						$runAsCredential = New-Object System.Management.Automation.PSCredential($configurationNode.value.installationCredentialUserName, $securePassword)

						$configurationFilePath = $targetPath + "\"+ $copyFilesConfigurationNode.value.scriptsToCopy + "\"+ $step.configurationPath.Replace("./",".\").TrimStart(".","\")
						$script = $step.script -replace "\./", "\" -replace "/", "\"

						# Invoke the script on the remote server under the installation account
						RemotePowerShellExecution -targetServer $targetServer -targetPath $targetPath -script $script -configurationKey $step.configurationKey -configurationFilePath $configurationFilePath -remote $remote -installationCredential $installationCredential -runAsCredential $runAsCredential 							
					}
					else
					{
						Write-Host $step.description + " SKIPPED by configuration" -ForegroundColor Yellow
					}
				}
				else
				{
					# Read configuration values from json files
					$configurationNode = $configuration.configuration | where { $_.key -eq $step.configurationKey}

					if( $configurationNode.shouldExecute -eq "True" )
					{
						Write-Host "Current user:" $env:USERNAME
						$username = $configurationNode.value.installationCredentialUserName
						$password = $configurationNode.value.installationCredentialPassword
						# Escape ' char by repacing with '' from Password
						$password = $password -replace "'","''"

						# Invoke the script on the local server under the installation account while passing the installation credentials
						$expression = "{0} {1} {2} {3} '{4}'" -f $step.script, $step.configurationKey, $step.configurationPath, $username, $password
						Invoke-Expression -Command $expression				
					}
					else
					{
						Write-Host $step.description + " SKIPPED by configuration" -ForegroundColor Yellow
					}
				}				

			}

			# Write the orchestrator step description to the console to mark the finish.
			Write-Host
		}

	} catch {	
		Write-Host "An error prevented the deployment to finish!" -ForegroundColor Red
		Write-Host "Error details:" $_ -ForegroundColor Red
        throw $_
	}
}