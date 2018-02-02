function StartStopServicesArray(
    [string[]][Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $services,
    [string][Parameter(Mandatory=$true)][AllowEmptyString()] $instanceName,
    [string][Parameter(Mandatory = $true)][ValidateSet("Disabled", "Manual", "Automatic")] $startupType,
    [int][Parameter(Mandatory = $true)] $waitTimeoutInSeconds,
    [string][Parameter(Mandatory = $true)] $killIfTimedOut
) {
    $presentServicesArray = $null
    $services | ForEach-Object {
        $serviceName = $_

        if (-not [System.string]::IsNullOrWhiteSpace($instanceName)) {
            $serviceName += "$" + $instanceName
        }

        $matchingServices = [PSCustomObject[]] (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)

        if ($matchingServices -eq $null)
        {
            Write-Verbose "No services match the name: $serviceName"
        }
        else
        {
            $presentServicesArray += $matchingServices
        }
    }

    if ($presentServicesArray.Length -eq 0) {
        Write-Verbose "No services matching the given names were found."
        return
    }

    Write-Verbose ("The following services were found: {0}" -f ($presentServicesArray -join ','))

    try {
        $presentServicesArray | % { Set-Service -Name $_.Name -StartupType $startupType -ErrorAction SilentlyContinue }
        $presentServicesArray | Where-Object { $_.Status -ne "Stopped" } | % { $_.Stop() }
        $ErrorActionPreference = "SilentlyContinue" # I don't want the wait for status to throw in the case of a timeout
        $presentServicesArray | % { $_.WaitForStatus("Stopped", [TimeSpan]::FromSeconds($waitTimeoutInSeconds)) }
        $ErrorActionPreference = "Stop"
    }
    Catch {
        $ErrorActionPreference = "Stop"
        if ($killIfTimedOut -eq "false") {
            $errorMessage = $_.Exception.Message
            Write-Verbose $errorMessage
            throw
        }

        $nonStoppedServices = $presentServicesArray | Where-Object { $_.Status -ne "Stopped" } | % { $_.ServiceName }

        $nonStoppedServices | % { Write-Verbose "Killing service after not stopping within timeout: $_" }

        (get-wmiobject win32_Service | Where-Object { $nonStoppedServices -contains $_.Name }).ProcessID | % { Stop-Process -Force $_ }
    }
    Finally {
        $presentServicesArray | % { Set-Service -Name $_.Name -StartupType $startupType }
    }
}

function StartStopServices(
    [string][Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $serviceNames,
    [string][Parameter(Mandatory=$true)] $instanceName,
    [string][Parameter(Mandatory = $true)][ValidateSet("Disabled", "Manual", "Automatic")] $startupType,
    [int][Parameter(Mandatory = $true)] $waitTimeoutInSeconds,
    [string][Parameter(Mandatory = $true)] $killIfTimedOut
) {
    [string[]] $servicesNamesArray = ($serviceNames -split ',' -replace '"').Trim()

    return StartStopServicesArray $servicesNamesArray $startupType $waitTimeoutInSeconds $killIfTimedOut
}