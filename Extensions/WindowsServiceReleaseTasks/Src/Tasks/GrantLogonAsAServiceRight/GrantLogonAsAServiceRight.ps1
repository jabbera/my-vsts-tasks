[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $userNames,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $environmentName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
    [string][Parameter(Mandatory=$true)] $protocol,
    [string][Parameter(Mandatory=$true)] $testCertificate
)

Write-Output "Granting LogonAsAService to $userNames. Version: {{tokens.BuildNumber}}"

$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

. $env:CURRENT_TASK_ROOTDIR\Utility.ps1

$userNames = $userNames -replace '\s','' # no spaces allows in argument lists

$scriptArguments = "-userNames $userNames"

Remote-RunScript -machinesList $environmentName -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate -internStringFileName "GrantLogonAsAServiceRightIntern.ps1" -scriptEntryPoint "GrantLogonAsService" -scriptArguments $scriptArguments