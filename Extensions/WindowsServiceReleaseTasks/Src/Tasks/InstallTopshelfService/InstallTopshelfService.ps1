[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $topshelfExePaths,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $environmentName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
    [string][Parameter(Mandatory=$true)] $protocol,
    [string][Parameter(Mandatory=$true)] $testCertificate,
	[string][Parameter(Mandatory=$true)][ValidateSet("custom", "localsystem", "localservice", "networkservice")] $specialUser,
	[string] $serviceUsername,
    [string] $servicePassword,
    [string] $instanceName,
	[string] $uninstallFirst,
	[string] $killMmcTaskManager
)

Write-Output "Installing TopShelf service: $topshelfExePaths with instanceName: $instanceName. Version: {{tokens.BuildNumber}}"

$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

[string[]] $topshelfExePathsArray = ($topshelfExePaths -split ',').Trim()

$servicePassword = $servicePassword.Replace('`', '``').Replace('"', '`"').Replace('$', '`$').Replace('&', '`&').Replace("'", "`'")

Write-Host ("##vso[task.setvariable variable=E34A69771F47424D9217F3A4D6BCDC94;issecret=true;]$servicePassword") # Make sure the password doesn't show up in the log.

$instanceName = $instanceName.Replace('`', '``').Replace('"', '`"').Replace('$', '`$').Replace('&', '`&')

$additionalArguments = ""
if (-Not [string]::IsNullOrWhiteSpace($serviceUsername))
{
	$additionalArguments += " -username:$serviceUsername -password:$servicePassword"
}
else
{
	$additionalArguments += " --$specialUser"
}

if (-Not [string]::IsNullOrWhiteSpace($instanceName))
{
	$additionalArguments += " -instance:$instanceName"
}

$cmd = "`$env:DT_DISABLEINITIALLOGGING='true'`n"
$cmd += "`$env:DT_LOGLEVELCON='NONE'`n"

if ($killMmcTaskManager -eq "true")
{
	$cmd += "Stop-Process -name mmc,taskmgr -Force -ErrorAction SilentlyContinue`n"
}

foreach($topShelfExe in $topshelfExePathsArray)
{
	if ($uninstallFirst -eq "true")
	{
		$cmd += "& ""$topShelfExe"" uninstall $additionalArguments`n"
	}
	
	$cmd += "& ""$topShelfExe"" install $additionalArguments`n"
}

$santizedCmd = $cmd -replace "-password:$servicePassword", "-password:**********"

Write-Output "CMD: $santizedCmd"

$errorMessage = Invoke-RemoteDeployment -environmentName $environmentName -tags "" -ScriptBlockContent $cmd -scriptArguments "" -runPowershellInParallel $false -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate

if(-Not [string]::IsNullOrEmpty($errorMessage))
{
	$helpMessage = "For more info please google."
	Write-Error "$errorMessage`n$helpMessage"
	return
}