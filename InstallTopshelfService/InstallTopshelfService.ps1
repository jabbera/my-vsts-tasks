[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $topshelfExePath,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $environmentName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
    [string][Parameter(Mandatory=$true)] $protocol,
    [string][Parameter(Mandatory=$true)] $testCertificate,
	[string][Parameter(Mandatory=$true)][ValidateSet("custom", "localsystem", "localservice", "networkservice")] $specialUser,
	[string] $serviceUsername,
    [string] $servicePassword,
    [string] $instanceName
)

Write-Verbose "Installing TopShelf service: $topshelfExeName with instanceName $instanceName"

$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

. $env:CURRENT_TASK_ROOTDIR\DeploymentSDK\InvokeRemoteDeployment.ps1

$cmd = "& ""$topshelfExePath"" install "
if (-Not [string]::IsNullOrWhiteSpace($serviceUsername))
{
    $cmd += "-username:$serviceUsername -password:$servicePassword"
}
else
{
    $cmd += "--$specialUser"
}

if (-Not [string]::IsNullOrWhiteSpace($instanceName))
{
    $cmd += " -instance:$instanceName"
}

Write-Verbose "Invoking deployment"

$errorMessage = Invoke-RemoteDeployment $environmentName $cmd $adminUserName $adminPassword $protocol $false

if(-Not [string]::IsNullOrEmpty($errorMessage))
{
	$helpMessage = "For more info please google."
	Write-Error "$errorMessage`n$helpMessage"
	return
}