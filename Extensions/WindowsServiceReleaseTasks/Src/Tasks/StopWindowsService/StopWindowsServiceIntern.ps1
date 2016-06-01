param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $serviceNames,
	[string][Parameter(Mandatory=$true)][ValidateSet("Disabled", "Manual", "Automatic")] $startupType,
	[int][Parameter(Mandatory=$true)] $waitTimeoutInSeconds
)

[string[]] $servicesNamesArray = ($serviceNames -split ',').Trim()
$presentServicesArray = Get-Service | Where-Object { $servicesNamesArray -contains $_.Name }

if ($servicesNamesArray.Length -ne $presentServicesArray.Length)
{
    $missingServiceNames = $servicesNamesArray | Where-Object { $presentServicesArrayNames -notcontains $_ }
    Write-Error "No such services: $missingServiceNames."
    return -1;
}

$presentServicesArray | % { Set-Service -Name $_.Name -StartupType $startupType }
$presentServicesArray | Where-Object { $_.Status -ne "Stopped" } | % { $_.Stop() }
$presentServicesArray | % { $_.WaitForStatus("Stopped", [TimeSpan]::FromSeconds($waitTimeoutInSeconds)) }