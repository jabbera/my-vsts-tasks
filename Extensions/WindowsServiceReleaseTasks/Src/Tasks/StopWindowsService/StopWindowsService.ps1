[CmdletBinding()]
Param()

Trace-VstsEnteringInvocation $MyInvocation

Try
{
	[string]$serviceNames = Get-VstsInput -Name serviceNames -Require
    [string]$environmentName = Get-VstsInput -Name environmentName -Require
    [string]$adminUserName = Get-VstsInput -Name adminUserName -Require
    [string]$adminPassword = Get-VstsInput -Name adminPassword -Require
	[string]$startupType = Get-VstsInput -Name startupType -Require
    [string]$protocol = Get-VstsInput -Name protocol -Require
    [string]$testCertificate = Get-VstsInput -Name testCertificate -Require
    [string]$waitTimeoutInSeconds = Get-VstsInput -Name waitTimeoutInSeconds -Require
	[string]$killIfTimedOut = Get-VstsInput -Name killIfTimedOut -Require
	[bool]$runPowershellInParallel = Get-VstsInput -Name RunPowershellInParallel -Default $true -AsBool
	
	Write-Output "Stopping Windows Service: $serviceName and setting startup type to: $startupType. Kill: $killIfTimedOut Version: {{tokens.BuildNumber}}"

	$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

	. $env:CURRENT_TASK_ROOTDIR\Utility.ps1

	$serviceNames = '"' + $serviceNames.Replace('`', '``').Replace('"', '`"').Replace('$', '`$').Replace('&', '`&').Replace('''', '`''') + '"'

	Remote-ServiceStartStop -serviceNames $serviceNames -machinesList $environmentName -adminUserName $adminUserName -adminPassword $adminPassword -startupType $startupType -protocol $protocol -testCertificate $testCertificate -waitTimeoutInSeconds $waitTimeoutInSeconds -internStringFileName "StopWindowsServiceIntern.ps1" -killIfTimedOut $killIfTimedOut	 -runPowershellInParallel $runPowershellInParallel
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}