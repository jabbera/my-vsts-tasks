[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $serviceNames,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $environmentName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
	[string][Parameter(Mandatory=$true)][ValidateSet("Manual", "Automatic")] $startupType,
    [string][Parameter(Mandatory=$true)] $protocol,
    [string][Parameter(Mandatory=$true)] $testCertificate,
    [string][Parameter(Mandatory=$true)] $waitTimeoutInSeconds = 120
)

Write-Output "Starting Windows Services $serviceNames and setting startup type to: $startupType"

$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

. $env:CURRENT_TASK_ROOTDIR\Utility.ps1

Validate-WaitTime $waitTimeoutInSeconds

$internScriptPath = "$env:CURRENT_TASK_ROOTDIR\StartWindowsServiceIntern.ps1"

$scriptToRun = [IO.File]::ReadAllText($internScriptPath)
$scriptArguments = "-serviceNames $serviceNames -startupType $startupType -waitTimeoutInSeconds $waitTimeoutInSeconds"

$serviceNames = $serviceNames -replace '\s','' # no spaces allows in argument lists

Write-Output "Invoking deployment"

$errorMessage = Invoke-RemoteDeployment -environmentName $environmentName -tags "" -ScriptBlockContent $scriptToRun -scriptArguments $scriptArguments -runPowershellInParallel $false -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate

if(-Not [string]::IsNullOrEmpty($errorMessage))
{
	$helpMessage = "Error returned from remote deployment."
	Write-Error "$errorMessage`n$helpMessage"
	return
}