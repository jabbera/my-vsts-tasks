function StartStopServicesArray(
    [string[]][Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $services,
    [string][Parameter(Mandatory=$true)][AllowEmptyString()] $instanceName,
    [string][Parameter(Mandatory = $true)][ValidateSet("Manual", "Automatic")] $startupType,
    [int][Parameter(Mandatory = $true)] $waitTimeoutInSeconds
) {
    [bool] $atLeastOneServiceWasNotFound = $false
    $presentServicesArray = $null
    $services | ForEach-Object {
        $serviceName = $_
        if (-not [System.string]::IsNullOrWhiteSpace($instanceName)) {
            $serviceName += "$" + $instanceName
        }

        $matchingServices = [PSCustomObject[]] (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)

        if ($matchingServices -eq $null) {
            Write-Error "No services match the name: $serviceName"
            $atLeastOneServiceWasNotFound = $true
        }
        else {
            $presentServicesArray += $matchingServices
        }
    }

    if ($atLeastOneServiceWasNotFound) {
        return -1;
    }

    Write-Verbose ("The following services were found: {0}" -f ($presentServicesArray -join ','))

    $presentServicesArray | % { Set-Service -Name $_.Name -StartupType $startupType }
    $presentServicesArray | Where-Object { $_.Status -ne "Running" } | % { $_.Start() }
    $presentServicesArray | % { $_.WaitForStatus("Running", [TimeSpan]::FromSeconds($waitTimeoutInSeconds)) }
}

function StartStopServices(
    [string][Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $serviceNames,
    [string][Parameter(Mandatory=$true)][AllowEmptyString()] $instanceName,
    [string][Parameter(Mandatory = $true)][ValidateSet("Manual", "Automatic")] $startupType,
    [int][Parameter(Mandatory = $true)] $waitTimeoutInSeconds,
    [string][Parameter(Mandatory = $true)] $killIfTimedOut
) {
    [string[]] $servicesNamesArray = ($serviceNames -split ',' -replace '"').Trim()

    return StartStopServicesArray $servicesNamesArray $instanceName $startupType $waitTimeoutInSeconds
}