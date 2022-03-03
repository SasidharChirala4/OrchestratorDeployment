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

#Username and password are currently not used, Publish towards the database is always done under the installation account

#Read json object
$jsonObj=ConvertFrom-Json -InputObject (Gc $configurationPath -Raw)

foreach( $configuration in $jsonObj.configuration){
	if( $configuration.key -eq $configurationKey){
		$jsonObj = $configuration.value
	}
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
	param([string]$zipfile, [string]$outpath)

	$archive = [System.IO.Compression.ZipFile]::OpenRead($zipfile)
	foreach ($entry in $archive.Entries)
	{
		$entryTargetFilePath = [System.IO.Path]::Combine($outpath, $entry.FullName)
		$entryDir = [System.IO.Path]::GetDirectoryName($entryTargetFilePath)
        
		#Ensure the directory of the archive entry exists
		if(!(Test-Path $entryDir )){
			New-Item -ItemType Directory -Path $entryDir | Out-Null 
		}
        
		#If the entry is not a directory entry, then extract entry
		if($entry.Length -gt 0){
			[System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryTargetFilePath, $true);
		}      
	}
}

try
{
	#Get assenbly location
	$currentPath = $(Split-Path -Parent $MyInvocation.MyCommand.Definition)
	$separator = [string[]]@("Scripts")
	$scriptPath= $currentPath.split($separator,[System.StringSplitOptions]::RemoveEmptyEntries)
	$assemblyPath = $scriptPath[0] + $jsonObj.entityFramework.migrationsAssembly
	Write-Host $assemblyPath
	$artifactPath = Split-Path $assemblyPath
	Write-Host $artifactPath

	Get-ChildItem $artifactPath | 
		Foreach-Object {
			#Looping through the each UI React Component
			if($_.Name.EndsWith('.zip',"CurrentCultureIgnoreCase")) {
				$artifact = Join-Path $artifactPath -ChildPath $_
				Write-Host "Unzipping component '$artifact' to '$artifactPath'"
				Unzip $artifact $artifactPath
			}
		}

	#Import assembly
	Import-Module $assemblyPath

	#Publish Database
	$expression = "{0} -ConnectionString 'Data Source={1};Initial Catalog={2};Integrated Security=True'" -f $jsonObj.entityFramework.command, $jsonObj.sqlServer.server, $jsonObj.sqlServer.database
	#Publish-EdreamsCoreDatabase -ConnectionString "Data Source=$($jsonObj.sqlServer.server);Initial Catalog=$($jsonObj.sqlServer.database);Integrated Security=True"
	Invoke-Expression -Command $expression
}
catch
{
	Write-Host $_.Exception
	throw
}