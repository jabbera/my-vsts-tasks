[CmdletBinding()]
Param()

Trace-VstsEnteringInvocation $MyInvocation

Try {
    [string]$serviceNames = Get-VstsInput -Name serviceNames -Require
    [string]$instanceName = Get-VstsInput -Name instanceName
    [string]$waitTimeoutInSeconds = Get-VstsInput -Name waitTimeoutInSeconds -Require
    [string]$startupType = Get-VstsInput -Name startupType -Require
    [bool]$targetIsDeploymentGroup = Get-VstsInput -Name deploymentGroup -Require -AsBool

    Write-Output "Starting Windows Services $serviceNames and setting startup type to: $startupType. Version: {{tokens.BuildNumber}}"

    $env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

    if ($targetIsDeploymentGroup)
    {
        . $env:CURRENT_TASK_ROOTDIR\StartWindowsServiceIntern.ps1

        $serviceNamesArray = [string[]]($serviceNames.Split(@(",", "`r", "`n"), [System.StringSplitOptions]::RemoveEmptyEntries).Trim())

        StartStopServicesArray $serviceNamesArray $instanceName $startupType $waitTimeoutInSeconds
    }
    else
    {
        $serviceNames = '"' + $serviceNames.Replace('`', '``').Replace('"', '`"').Replace('$', '`$').Replace('&', '`&').Replace('''', '`''') + '"'
        . $env:CURRENT_TASK_ROOTDIR\Utility.ps1

        [string]$environmentName = Get-VstsInput -Name environmentName -Require
        [string]$adminUserName = Get-VstsInput -Name adminUserName -Require
        [string]$adminPassword = Get-VstsInput -Name adminPassword -Require
        [string]$protocol = Get-VstsInput -Name protocol -Require
        [string]$testCertificate = Get-VstsInput -Name testCertificate -Require
        [bool]$runPowershellInParallel = Get-VstsInput -Name RunPowershellInParallel -Default $true -AsBool

        Remote-ServiceStartStop -serviceNames $serviceNames -machinesList -instanceName $instanceName $environmentName -adminUserName $adminUserName -adminPassword $adminPassword -startupType $startupType -protocol $protocol -testCertificate $testCertificate -waitTimeoutInSeconds $waitTimeoutInSeconds -internStringFileName "StartWindowsServiceIntern.ps1" -killIfTimedOut "false" -runPowershellInParallel $runPowershellInParallel
    }
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}