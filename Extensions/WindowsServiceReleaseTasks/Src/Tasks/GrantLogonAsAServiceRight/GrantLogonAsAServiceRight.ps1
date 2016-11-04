[CmdletBinding()]
Param()

Trace-VstsEnteringInvocation $MyInvocation

Try
{
    [string]$userNames = Get-VstsInput -Name userNames -Require
    [string]$environmentName = Get-VstsInput -Name environmentName -Require
    [string]$adminUserName = Get-VstsInput -Name adminUserName -Require
    [string]$adminPassword = Get-VstsInput -Name adminPassword -Require
    [string]$protocol = Get-VstsInput -Name protocol -Require
    [string]$testCertificate = Get-VstsInput -Name testCertificate -Require

	Write-Output "Granting LogonAsAService to $userNames. Version: {{tokens.BuildNumber}}"

	$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

	. $env:CURRENT_TASK_ROOTDIR\Utility.ps1

	$userNames = $userNames -replace '\s','' # no spaces allows in argument lists

	$scriptArguments = "-userNames $userNames"

	Remote-RunScript -machinesList $environmentName -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate -internStringFileName "GrantLogonAsAServiceRightIntern.ps1" -scriptEntryPoint "GrantLogonAsService" -scriptArguments $scriptArguments
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}