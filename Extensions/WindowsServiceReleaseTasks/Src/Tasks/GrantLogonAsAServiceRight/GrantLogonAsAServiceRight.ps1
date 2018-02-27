[CmdletBinding()]
Param()

Trace-VstsEnteringInvocation $MyInvocation

Try {
    [string]$userNames = Get-VstsInput -Name userNames -Require
    [bool]$targetIsDeploymentGroup = Get-VstsInput -Name deploymentGroup -Require -AsBool

    $env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

    $userNames = $userNames -replace '\s', '' # no spaces allows in argument lists

    $scriptArguments = "-userNames $userNames"

    if ($targetIsDeploymentGroup)
    {
        . $env:CURRENT_TASK_ROOTDIR\GrantLogonAsAServiceRightIntern.ps1

        $userNamesArray = [string[]]($userNames.Split(@(",", "`r", "`n"), [System.StringSplitOptions]::RemoveEmptyEntries).Trim())

        GrantLogonAsServiceArray $userNamesArray;
    }
    else
    {
        . $env:CURRENT_TASK_ROOTDIR\Utility.ps1

        [string]$environmentName = Get-VstsInput -Name environmentName -Require
        [string]$adminUserName = Get-VstsInput -Name adminUserName -Require
        [string]$adminPassword = Get-VstsInput -Name adminPassword -Require
        [string]$protocol = Get-VstsInput -Name protocol -Require
        [string]$testCertificate = Get-VstsInput -Name testCertificate -Require
        [bool]$runPowershellInParallel = Get-VstsInput -Name RunPowershellInParallel -Default $true -AsBool
    
        Remote-RunScript -machinesList $environmentName -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate -internStringFileName "GrantLogonAsAServiceRightIntern.ps1" -scriptEntryPoint "GrantLogonAsService" -scriptArguments $scriptArguments -runPowershellInParallel $runPowershellInParallel
    }
    
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}