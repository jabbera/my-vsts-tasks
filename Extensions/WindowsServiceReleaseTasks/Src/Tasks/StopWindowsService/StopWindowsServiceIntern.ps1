param(
    [string][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] $serviceNames,
	[string][Parameter(Mandatory=$true)][ValidateSet("Disabled", "Manual", "Automatic")] $startupType,
	[int][Parameter(Mandatory=$true)] $waitTimeoutInSeconds,
	[string][Parameter(Mandatory=$true)] $killIfTimedOut
)

[string[]] $servicesNamesArray = ($serviceNames -split ',' -replace '"').Trim()
$presentServicesArray = Get-Service | Where-Object { $servicesNamesArray -contains $_.Name }

if ($servicesNamesArray.Length -ne $presentServicesArray.Length)
{
    $missingServiceNames = $servicesNamesArray | Where-Object { $presentServicesArrayNames -notcontains $_ }
    Write-Verbose "No such services: $missingServiceNames."
}

if ($presentServicesArray.Length -eq 0)
{
	return
}

try
{
    $presentServicesArray | % { Set-Service -Name $_.Name -StartupType $startupType -ErrorAction SilentlyContinue }
    $presentServicesArray | Where-Object { $_.Status -ne "Stopped" } | % { $_.Stop() }
    $ErrorActionPreference = "SilentlyContinue" # I don't want the wait for status to throw in the case of a timeout
    $presentServicesArray | % { $_.WaitForStatus("Stopped", [TimeSpan]::FromSeconds($waitTimeoutInSeconds)) }
    $ErrorActionPreference = "Stop"
}
Catch
{
    $ErrorActionPreference = "Stop"
    if ($killIfTimedOut -eq "false")
    {
		$errorMessage = $_.Exception.Message
		Write-Verbose $errorMessage		
        throw
    }

    $nonStoppedServices = $presentServicesArray | Where-Object { $_.Status -ne "Stopped" } | % { $_.ServiceName }

    $nonStoppedServices | % { Write-Verbose "Killing service after not stopping within timeout: $_" }

    (get-wmiobject win32_Service | Where-Object { $nonStoppedServices -contains $_.Name }).ProcessID | % { Stop-Process -Force $_ }
}
Finally
{
    $presentServicesArray | % { Set-Service -Name $_.Name -StartupType $startupType }
}