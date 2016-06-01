[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $topshelfExePath,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $environmentName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
    [string][Parameter(Mandatory=$true)] $protocol,
    [string][Parameter(Mandatory=$true)] $testCertificate,
	[string][Parameter(Mandatory=$true)][ValidateSet("custom", "localsystem", "localservice", "networkservice")] $specialUser,
	[string] $serviceUsername,
    [string] $servicePassword,
    [string] $instanceName
)

Write-Verbose "Installing TopShelf service: $topshelfExeName with instanceName $instanceName. Version: {{tokens.BuildNumber}}"

$env:CURRENT_TASK_ROOTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path

$cmd = "& ""$topshelfExePath"" install "
if (-Not [string]::IsNullOrWhiteSpace($serviceUsername))
{
    $cmd += "-username:$serviceUsername -password:$servicePassword"
}
else
{
    $cmd += "--$specialUser"
}

if (-Not [string]::IsNullOrWhiteSpace($instanceName))
{
    $cmd += " -instance:$instanceName"
}

Write-Verbose "Invoking deployment"

$errorMessage = Invoke-RemoteDeployment -environmentName $environmentName -tags "" -ScriptBlockContent $cmd -scriptArguments "" -runPowershellInParallel $false -adminUserName $adminUserName -adminPassword $adminPassword -protocol $protocol -testCertificate $testCertificate

if(-Not [string]::IsNullOrEmpty($errorMessage))
{
	$helpMessage = "For more info please google."
	Write-Error "$errorMessage`n$helpMessage"
	return
}