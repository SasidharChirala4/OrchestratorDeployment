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

#Read json object
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
	
			Write-Host $jsonObj.service.name "will be installed on this server!"
			$serviceName = $jsonObj.service.name;
			$displayName = $jsonObj.service.displayName
			$description = $jsonObj.service.description						

			#Uninstall service
			$windowsService = Get-WmiObject -Class Win32_Service -Filter "Name='$($serviceName)'"
			if($windowsService)
			{
				Write-Host STOPPING SERVICE $serviceName
				if( $jsonObj.service.startup.ToLower() -eq "disabled")
				{
					Write-Host "$serviceName service is set to disabled in configuration so, no need to stop the service!"
				}
				else
				{				
					Stop-Service $serviceName
				}
			
				Write-Host REMOVING SERVICE $serviceName
				Remove-WmiObject -InputObject $windowsService
			}

			#Get packages location
			$destinationPath = $jsonObj.publishPackage.publishDestination	
			new-item -Path $destinationPath -ItemType directory -Force
			$packagesPath =  $jsonObj.publishPackage.packageSource
			$sourcePath = Convert-Path $packagesPath
			$sourceDirectory = Split-Path -Path $sourcePath

			#Create temp folder
			$sourceDirectory = "$($sourceDirectory)\temp"

			#Remove exisitng item from temp folder		
			Remove-Item $sourceDirectory -Recurse -Force -ErrorAction Ignore
			#Bulk copy
			robocopy $sourcePath $sourceDirectory /s
				
		    if( Test-Path "$($sourceDirectory)\appsettings.deploy.json" )
			{
				$configContent = Get-Content "$($sourceDirectory)\appsettings.deploy.json"
			}

			$configContent = $configContent.replace('#{collector.edreams.importurl}#', $jsonObj.configuration.edreamsimporturl)
			$configContent = $configContent.replace('#{collector.edreams.sample.token}#', $jsonObj.configuration.edreamstokenSample)
			$configContent = $configContent.replace('#{collector.edreams.staffing.token}#', $jsonObj.configuration.edreamstokenStaffing)
			$configContent = $configContent.replace('#{collector.edreams.customerchange.token}#', $jsonObj.configuration.edreamstokenCustomerChange)
			$configContent = $configContent.replace('#{collector.edreams.projectchange.token}#', $jsonObj.configuration.edreamstokenProjectChange)
			$configContent = $configContent.replace('#{collector.edreams.userchange.token}#', $jsonObj.configuration.edreamstokenUserChange)
			$configContent = $configContent.replace('#{collector.edreams.adminconsult.token}#', $jsonObj.configuration.edreamstokenAdminConsult)
			$configContent = $configContent.replace('#{collector.mulesoft.resource}#', $jsonObj.configuration.mulesoftresource)
			$configContent = $configContent.replace('#{collector.mulesoft.tenantid}#', $jsonObj.configuration.mulesofttenantid)
			$configContent = $configContent.replace('#{collector.mulesoft.authorisationtokenclientid}#', $jsonObj.configuration.mulesoftauthorisationtokenclientid)
			$configContent = $configContent.replace('#{collector.mulesoft.authorisationtokenclientsecret}#', $jsonObj.configuration.mulesoftauthorisationtokenclientsecret)
			$configContent = $configContent.replace('#{collector.mulesoft.apiclientid}#', $jsonObj.configuration.mulesoftapiclientid)
			$configContent = $configContent.replace('#{collector.mulesoft.apiclientsecret}#', $jsonObj.configuration.mulesoftapiclientsecret)
			$configContent = $configContent.replace('#{collector.mulesoft.country}#', $jsonObj.configuration.mulesoftcountry)
			$configContent = $configContent.replace('#{collector.connectionstring.edreamsadaptor}#', $jsonObj.configuration.connectionstringedreamsadaptor)
			$configContent = $configContent.replace('#{collector.connectionstring.edreamsadaptorlogging}#', $jsonObj.configuration.connectionstringedreamsadaptorlogging)
			$configContent = $configContent.replace('#{collector.connectionstring.adminconsultcache}#', $jsonObj.configuration.connectionstringadminconsultcache)
			$configContent = $configContent.replace('#{collector.sample.enabled}#', $jsonObj.configuration.samplecollectorenabled)
			$configContent = $configContent.replace('#{collector.sample.interval}#', $jsonObj.configuration.samplecollectorinterval)
			$configContent = $configContent.replace('#{collector.sample.exampleoption}#', $jsonObj.configuration.samplecollectorexampleoption)
			$configContent = $configContent.replace('#{collector.sample.mulesoftpagesize}#', $jsonObj.configuration.samplecollectormulesoftpagesize)
			$configContent = $configContent.replace('#{collector.sample.lastprocessed}#', $jsonObj.configuration.samplecollectorlastprocessed)
			$configContent = $configContent.replace('#{collector.sample.wbsdetails}#', $jsonObj.configuration.samplecollectorwbsdetails)
			$configContent = $configContent.replace('#{collector.staffing.enabled}#', $jsonObj.configuration.staffingcollectorenabled)
			$configContent = $configContent.replace('#{collector.staffing.interval}#', $jsonObj.configuration.staffingcollectorinterval)
            $configContent = $configContent.replace('#{collector.staffing.wbsdetailrequestbatchsize}#', $jsonObj.configuration.staffingcollectorwbsdetailrequestbatchsize)
	        $configContent = $configContent.replace('#{collector.staffing.mulesoftpagesize}#', $jsonObj.configuration.staffingcollectormulesoftpagesize)
	        $configContent = $configContent.replace('#{collector.staffing.ensuredependantobjectsfordeStaffings}#', $jsonObj.configuration.staffingcollectorensuredependantobjectsfordeStaffings)
			$configContent = $configContent.replace('#{collector.edreams.auditconfirmationletteremail}#', $jsonObj.configuration.edreamsauditconfirmationletteremail)
			$configContent = $configContent.replace('#{collector.customer.enabled}#', $jsonObj.configuration.customercollectorenabled)
			$configContent = $configContent.replace('#{collector.customer.interval}#', $jsonObj.configuration.customercollectorinterval)
			$configContent = $configContent.replace('#{collector.customer.mulesoftpagesize}#', $jsonObj.configuration.customercollectormulesoftpagesize)
			$configContent = $configContent.replace('#{collector.project.enabled}#', $jsonObj.configuration.projectcollectorenabled)
			$configContent = $configContent.replace('#{collector.project.interval}#', $jsonObj.configuration.projectcollectorinterval)
            $configContent = $configContent.replace('#{collector.project.wbsdetailrequestbatchsize}#', $jsonObj.configuration.projectcollectorwbsdetailrequestbatchsize)
			$configContent = $configContent.replace('#{collector.project.mulesoftpagesize}#', $jsonObj.configuration.projectcollectormulesoftpagesize)
			$configContent = $configContent.replace('#{collector.user.enabled}#', $jsonObj.configuration.usercollectorenabled)
			$configContent = $configContent.replace('#{collector.user.interval}#', $jsonObj.configuration.usercollectorinterval)
			$configContent = $configContent.replace('#{collector.user.mulesoftpagesize}#', $jsonObj.configuration.usercollectormulesoftpagesize)
			$configContent = $configContent.replace('#{collector.adminconsult.enabled}#', $jsonObj.configuration.adminconsultcollectorenabled)
			$configContent = $configContent.replace('#{collector.adminconsult.interval}#', $jsonObj.configuration.adminconsultcollectorinterval)
			$configContent = $configContent.replace('#{collector.adminconsult.connectionstring}#', $jsonObj.configuration.adminconsultcollectorconnectionstring)
			
			if( Test-Path "$($sourceDirectory)\appsettings.deploy.json" )
			{
				Write-Host "$($sourceDirectory)\appsettings.json"
				Set-Content "$($sourceDirectory)\appsettings.json" $configContent
				Remove-Item -Force "$($sourceDirectory)\appsettings.deploy.json"
			}

			#Copy files to destination
			robocopy $sourceDirectory $destinationPath /s
			#Remove temp folder
			Remove-Item -Recurse -Force $sourceDirectory

			#Install Service
			$binaryPath = Join-Path $destinationPath $jsonObj.service.binaryPath
	
			Write-Host $env:UserName
			Write-Host $env:UserDomain
			Write-Host $env:ComputerName
			$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
			$credentials = New-Object System.Management.Automation.PSCredential ($username, $securePassword)
			Write-Host CREATING SERVICE $serviceName
			New-Service -Name $serviceName -DisplayName $displayName -Description $description -BinaryPathName $binaryPath -StartupType $jsonObj.service.startup -Credential $credentials
		
			if( $jsonObj.service.enabled -eq "True")
			{
				Write-Host STARTING SERVICE $serviceName
				if( $jsonObj.service.startup.ToLower() -eq "disabled")
				{
					Write-Host "$serviceName service is set to disabled in configuration so, no need to start the service!"
				}
				else
				{				
					Start-Service $serviceName
				}
			}
			Write-Host $serviceName STATUS
			Get-Service $serviceName

}
catch
{
	Write-Host $_.Exception
	throw
}