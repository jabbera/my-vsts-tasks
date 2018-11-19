[CmdletBinding()]
Param()

Trace-VstsEnteringInvocation $MyInvocation

Try {
    [string]$serviceNames = Get-VstsInput -Name serviceNames -Require
    [string]$instanceName = Get-VstsInput -Name instanceName
    [string]$startupType = Get-VstsInput -Name startupType -Require
    [string]$waitTimeoutInSeconds = Get-VstsInput -Name waitTimeoutInSeconds -Require
    [string]$killIfTimedOut = Get-VstsInput -Name killIfTimedOut -Require
    [bool]$targetIsDeploymentGroup = Get-VstsInput -Name deploymentGroup -Require -AsBool

    Write-Output "Stopping Windows Service: $serviceNames and setting startup type to: $startupType. Kill: $killIfTimedOut"

    $env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

    if ($targetIsDeploymentGroup) 
    {
        . $env:CURRENT_TASK_ROOTDIR\StopWindowsServiceIntern.ps1

        $serviceNamesArray = [string[]]($serviceNames.Split(@(",", "`r", "`n"), [System.StringSplitOptions]::RemoveEmptyEntries).Trim())

        StartStopServicesArray $serviceNamesArray $instanceName $startupType $waitTimeoutInSeconds $killIfTimedOut
    }
    else
    {
        $serviceNames = '"' + $serviceNames.Replace('`', '``').Replace('"', '`"').Replace('$', '`$').Replace('&', '`&').Replace('''', '`''') + '"'

        [string]$environmentName = Get-VstsInput -Name environmentName -Require
        [string]$adminUserName = Get-VstsInput -Name adminUserName -Require
        [string]$adminPassword = Get-VstsInput -Name adminPassword -Require
        [string]$protocol = Get-VstsInput -Name protocol -Require
        [string]$testCertificate = Get-VstsInput -Name testCertificate -Require
        [bool]$runPowershellInParallel = Get-VstsInput -Name RunPowershellInParallel -Default $true -AsBool

        . $env:CURRENT_TASK_ROOTDIR\TelemetryHelper\TelemetryHelper.ps1
        . $env:CURRENT_TASK_ROOTDIR\Utility.ps1

        Remote-ServiceStartStop -serviceNames $serviceNames -instanceName $instanceName -machinesList $environmentName -adminUserName $adminUserName -adminPassword $adminPassword -startupType $startupType -protocol $protocol -testCertificate $testCertificate -waitTimeoutInSeconds $waitTimeoutInSeconds -internStringFileName "StopWindowsServiceIntern.ps1" -killIfTimedOut $killIfTimedOut	 -runPowershellInParallel $runPowershellInParallel
    }
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
