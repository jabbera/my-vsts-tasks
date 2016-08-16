param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $serviceNames,
	[string][Parameter(Mandatory=$true)][ValidateSet("Manual", "Automatic")] $startupType,
	[int][Parameter(Mandatory=$true)] $waitTimeoutInSeconds,
	[string][Parameter(Mandatory=$true)] $killIfTimedOut
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
$presentServicesArray | Where-Object { $_.Status -ne "Running" } | % { $_.Start() }
$presentServicesArray | % { $_.WaitForStatus("Running", [TimeSpan]::FromSeconds($waitTimeoutInSeconds)) }