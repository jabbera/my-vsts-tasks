[CmdletBinding()]
Param()

Trace-VstsEnteringInvocation $MyInvocation

Try
{

    [string]$topshelfExePaths = Get-VstsInput -Name topshelfExePaths -Require
    [string]$environmentName = Get-VstsInput -Name environmentName -Require
    [string]$adminUserName = Get-VstsInput -Name adminUserName -Require
    [string]$adminPassword = Get-VstsInput -Name adminPassword -Require
    [string]$protocol = Get-VstsInput -Name protocol -Require
    [string]$testCertificate = Get-VstsInput -Name testCertificate -Require
	[string]$specialUser = Get-VstsInput -Name specialUser -Require
	[string]$serviceUsername = Get-VstsInput -Name serviceUsername
    [string]$servicePassword = Get-VstsInput -Name servicePassword
    [string]$instanceName = Get-VstsInput -Name instanceName
	[string]$uninstallFirst = Get-VstsInput -Name uninstallFirst
	[string]$killMmcTaskManager = Get-VstsInput -Name killMmcTaskManager

	$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

	Import-Module $env:CURRENT_TASK_ROOTDIR\DeploymentSDK\InvokeRemoteDeployment.ps1

	Write-Output "Installing TopShelf service: $topshelfExePaths with instanceName: $instanceName. Version: {{tokens.BuildNumber}}"

	$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

	[string[]] $topshelfExePathsArray = ($topshelfExePaths -split ',').Trim()

	$servicePassword = $servicePassword.Replace('`', '``').Replace('"', '`"').Replace('$', '`$').Replace('&', '`&').Replace('''', '`''')

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

	Write-Output "CMD: $cmd"

	$errorMessage = Invoke-RemoteDeployment -machinesList $environmentName -scriptToRun $cmd -deployInParallel $false -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate

	if(-Not [string]::IsNullOrEmpty($errorMessage))
	{
		$helpMessage = "For more info please google."
		Write-Error "$errorMessage`n$helpMessage"
		return
	}
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}