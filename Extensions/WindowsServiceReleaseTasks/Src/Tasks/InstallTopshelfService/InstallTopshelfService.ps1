[CmdletBinding()]
Param()

Trace-VstsEnteringInvocation $MyInvocation

Try {

    [string]$topshelfExePaths = Get-VstsInput -Name topshelfExePaths -Require
    [string]$specialUser = Get-VstsInput -Name specialUser -Require
    [string]$instanceName = Get-VstsInput -Name instanceName
    [string]$serviceName = Get-VstsInput -Name serviceName
    [string]$displayName = Get-VstsInput -Name displayName
    [string]$description = Get-VstsInput -Name description
    [string]$startupType = Get-VstsInput -Name startupType -Default "default"
    [string]$uninstallFirst = Get-VstsInput -Name uninstallFirst
    [string]$killMmcTaskManager = Get-VstsInput -Name killMmcTaskManager
    [bool]$targetIsDeploymentGroup = Get-VstsInput -Name deploymentGroup -Require -AsBool

    Write-Output "Installing TopShelf service: $topshelfExePaths with instanceName: $instanceName. Version: {{tokens.BuildNumber}}"

    $env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

    [string[]] $topshelfExePathsArray = ($topshelfExePaths -split ',').Trim()

    Write-Host ("##vso[task.setvariable variable=E34A69771F47424D9217F3A4D6BCDC94;issecret=true;]$servicePassword") # Make sure the password doesn't show up in the log.

    $instanceName = $instanceName.Replace('`', '``').Replace('"', '`"').Replace('$', '`$').Replace('&', '`&')

    $additionalSharedArguments = ""
    if ($specialUser -eq "custom") {
        [string]$serviceUsername = Get-VstsInput -Name serviceUsername -Require
        [string]$servicePassword = Get-VstsInput -Name servicePassword
        
        $servicePassword = $servicePassword.Replace('`', '``').Replace('"', '`"').Replace('$', '`$').Replace('&', '`&').Replace('''', '`''').Replace('(', '`(').Replace(')', '`)').Replace('@', '`@').Replace('}', '`}').Replace('{', '`{')

        $additionalSharedArguments += " -username:$serviceUsername"
        if (-Not [string]::IsNullOrWhiteSpace($servicePassword)) {
            $additionalSharedArguments += " -password:""$servicePassword"""
        }
    }
    else {
        $additionalSharedArguments += " --$specialUser"
    }

    if (-Not [string]::IsNullOrWhiteSpace($instanceName)) {
        $additionalSharedArguments += " -instance:$instanceName"
    }
    if (-Not [string]::IsNullOrWhiteSpace($serviceName)) {
        $additionalSharedArguments += " -servicename:$serviceName"
    }
    if (-Not [string]::IsNullOrWhiteSpace($displayName)) {
        $additionalSharedArguments += " -displayname ""$displayName"""
    }
    if (-Not [string]::IsNullOrWhiteSpace($description)) {
        $additionalSharedArguments += " -description ""$description"""
    }

    $additonalInstallArguments = ""
    if ($startupType -ne "default") {
        $additonalInstallArguments = "--$startupType"
    }

    $cmd = "`$env:DT_DISABLEINITIALLOGGING='true'`n"
    $cmd += "`$env:DT_LOGLEVELCON='NONE'`n"

    if ($killMmcTaskManager -eq "true") {
        $cmd += "Stop-Process -name mmc,taskmgr -Force -ErrorAction SilentlyContinue`n"
    }

    foreach ($topShelfExe in $topshelfExePathsArray) {
        if ($uninstallFirst -eq "true") {
            $cmd += "& ""$topShelfExe"" uninstall $additionalSharedArguments`n"
        }

        $cmd += "& ""$topShelfExe"" install $additionalSharedArguments $additonalInstallArguments`n"
    }

    Write-Output "CMD: $cmd"

    if ($targetIsDeploymentGroup)
    {
        Invoke-Expression $cmd
    }
    else
    
        . $env:CURRENT_TASK_ROOTDIR\TelemetryHelper\TelemetryHelper.ps1
        Import-Module $env:CURRENT_TASK_ROOTDIR\DeploymentSDK\InvokeRemoteDeployment.ps1

        [string]$environmentName = Get-VstsInput -Name environmentName -Require
        [string]$adminUserName = Get-VstsInput -Name adminUserName -Require
        [string]$adminPassword = Get-VstsInput -Name adminPassword -Require
        [string]$protocol = Get-VstsInput -Name protocol -Require
        [string]$testCertificate = Get-VstsInput -Name testCertificate -Require
        [bool]$runPowershellInParallel = Get-VstsInput -Name RunPowershellInParallel -Default $true -AsBool
    
    
        $errorMessage = Invoke-RemoteDeployment -machinesList $environmentName -scriptToRun $cmd -deployInParallel $runPowershellInParallel -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate
    
        if (-Not [string]::IsNullOrEmpty($errorMessage)) {
            $helpMessage = "For more info please google."
            Write-Error "$errorMessage`n$helpMessage"
            return
        }
    }
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}