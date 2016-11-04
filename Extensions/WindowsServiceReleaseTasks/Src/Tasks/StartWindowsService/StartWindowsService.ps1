[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $serviceNames,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $environmentName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
	[string][Parameter(Mandatory=$true)][ValidateSet("Manual", "Automatic")] $startupType,
    [string][Parameter(Mandatory=$true)] $protocol,
    [string][Parameter(Mandatory=$true)] $testCertificate,
    [string][Parameter(Mandatory=$true)] $waitTimeoutInSeconds
)

Write-Output "Starting Windows Services $serviceNames and setting startup type to: $startupType. Version: {{tokens.BuildNumber}}"

$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

. $env:CURRENT_TASK_ROOTDIR\Utility.ps1

$serviceNames = '"' + $serviceNames + '"'

Remote-ServiceStartStop -serviceNames $serviceNames -machinesList $environmentName -adminUserName $adminUserName -adminPassword $adminPassword -startupType $startupType -protocol $protocol -testCertificate $testCertificate -waitTimeoutInSeconds $waitTimeoutInSeconds -internStringFileName "StartWindowsServiceIntern.ps1" -killIfTimedOut "false"