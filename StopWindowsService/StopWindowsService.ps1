[CmdletBinding(DefaultParameterSetName = 'None')]
param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $serviceName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $environmentName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminUserName,
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $adminPassword,
	[string][Parameter(Mandatory=$true)][ValidateSet("Manual", "Automatic", "Disabled")] $startupType
)

Write-Output "Disabling Windows Service $serviceName"

$machines = ($environmentName -split ',').Trim()

$machines = $machines | ForEach-Object { Get-Service -ComputerName $_ | Where-Object { $_.Name -eq $serviceName } | % { $_.MachineName }}

if ($machines.Length -eq 0)
{
    Write-Output "No servers have service installed. Exiting."
    return;
}

$guid = "a" + [guid]::NewGuid().ToString().Replace("-", "")

Configuration $guid
{ 
    Node $machines
    {
        Service ServiceResource
        {
            Name = $serviceName
            State = "Stopped"
            StartupType = $startupType
        }
    }
}
 
Invoke-Expression $guid

$securePassword = ConvertTo-SecureString -AsPlainText $adminPassword -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $adminUserName, $securePassword

Start-DscConfiguration -Path $guid -Credential $cred -Wait -Verbose

Remove-Item -Path $guid -Recurse