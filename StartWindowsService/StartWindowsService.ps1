[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $serviceName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $environmentName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
	[string][Parameter(Mandatory=$true)][ValidateSet("Manual", "Automatic")] $startupType
)

Write-Output "Starting Windows Service $serviceName and setting startup type to: $startupType"

$machines = ($environmentName -split ',').Trim()

$guid = "a" + [guid]::NewGuid().ToString().Replace("-", "")

Configuration $guid
{ 
    Node $machines
    {
        Service ServiceResource
        {
            Name = $serviceName
            State = "Running"
            StartupType = $startupType
        }
    }
}
 
Invoke-Expression $guid

$securePassword = ConvertTo-SecureString -AsPlainText $adminPassword -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $adminUserName, $securePassword


Start-DscConfiguration -Path $guid -Credential $cred -Wait -Verbose

Remove-Item -Path $guid -Recurse