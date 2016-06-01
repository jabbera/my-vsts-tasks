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
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $environmentName,
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
        [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
	    [string][Parameter(Mandatory=$true)][ValidateSet("Disabled", "Manual", "Automatic")] $startupType,
        [string][Parameter(Mandatory=$true)] $protocol,
        [string][Parameter(Mandatory=$true)] $testCertificate,
        [string][Parameter(Mandatory=$true)] $waitTimeoutInSeconds,
        [string][Parameter(Mandatory=$true)] $internStringFileName
    )

    Validate-WaitTime $waitTimeoutInSeconds

    $internScriptPath = "$env:CURRENT_TASK_ROOTDIR\$internStringFileName"

    $scriptToRun = [IO.File]::ReadAllText($internScriptPath)
    $scriptArguments = "-serviceNames $serviceNames -startupType $startupType -waitTimeoutInSeconds $waitTimeoutInSeconds"

    Write-Output "Invoking deployment"

    $errorMessage = Invoke-RemoteDeployment -environmentName $environmentName -tags "" -ScriptBlockContent $scriptToRun -scriptArguments $scriptArguments -runPowershellInParallel $false -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate

    if(-Not [string]::IsNullOrEmpty($errorMessage))
    {
	    $helpMessage = "Error returned from remote deployment."
	    Write-Error "$errorMessage`n$helpMessage"
	    return
    }
}