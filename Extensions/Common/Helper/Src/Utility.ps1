Import-Module $env:CURRENT_TASK_ROOTDIR\DeploymentSDK\InvokeRemoteDeployment.ps1

Write-Verbose "Entering script Utility.ps1"

function Validate-WaitTime()
{
	[CmdletBinding()]
    Param
    (
        [Parameter(mandatory=$true)]
        [string[]]$runLockTimeoutString
    )

	$parsedRunLockTimeout = $null
	if([int32]::TryParse($runLockTimeoutString , [ref]$parsedRunLockTimeout))
	{
		if($parsedRunLockTimeout -gt 0)
		{
			return
		}
	}

    throw "Please provide a valid timeout input in seconds. It should be an integer greater than 0"
}

function Remote-ServiceStartStop()
{
    [CmdletBinding()]
    Param
    (
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $serviceNames,
        [string][Parameter(Mandatory=$true)][AllowEmptyString()] $instanceName,
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $machinesList,
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
	    [string][Parameter(Mandatory=$true)][ValidateSet("Disabled", "Manual", "Automatic")] $startupType,
        [string][Parameter(Mandatory=$true)] $protocol,
        [string][Parameter(Mandatory=$true)] $testCertificate,
        [string][Parameter(Mandatory=$true)] $waitTimeoutInSeconds,
        [string][Parameter(Mandatory=$true)] $internStringFileName,
		[string][Parameter(Mandatory=$true)] $killIfTimedOut,
		[bool]$runPowershellInParallel
    )

    Validate-WaitTime $waitTimeoutInSeconds
	
    $scriptArguments = "-serviceNames $serviceNames -instanceName `"$instanceName`" -startupType $startupType -waitTimeoutInSeconds $waitTimeoutInSeconds -killIfTimedOut $killIfTimedOut"
	
	Write-Host "ScriptArguments: $scriptArguments"
	
	Remote-RunScript -machinesList $machinesList -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate -internStringFileName $internStringFileName -scriptEntryPoint "StartStopServices" -scriptArguments $scriptArguments -runPowershellInParallel $runPowershellInParallel
}

function Remote-RunScript()
{
    [CmdletBinding()]
    Param
    (
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $machinesList,
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
        [string][Parameter(Mandatory=$true)] $protocol,
        [string][Parameter(Mandatory=$true)] $testCertificate,
        [string][Parameter(Mandatory=$true)] $internStringFileName,
		[string][Parameter(Mandatory=$true)] $scriptEntryPoint,
		[string][Parameter(Mandatory=$true)] $scriptArguments,
		[bool]$runPowershellInParallel
    )
	
    $internScriptPath = "$env:CURRENT_TASK_ROOTDIR\$internStringFileName"

	$scriptToRun = Get-Content $internScriptPath | Out-String
     
    $scriptToRun = [string]::Format("{0} {1} {2} {3} ", $scriptToRun,  [Environment]::NewLine, $scriptEntryPoint, $scriptArguments)

    Write-Output "Invoking deployment"
	
	Write-Output "Script Body: $scriptToRun"

    $errorMessage = Invoke-RemoteDeployment -machinesList $machinesList -scriptToRun  $scriptToRun -deployInParallel  $runPowershellInParallel -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate

    if(-Not [string]::IsNullOrEmpty($errorMessage))
    {
	    $helpMessage = "Error returned from remote deployment."
	    Write-Error "$errorMessage`n$helpMessage"
	    return
    }
}