function GrantLogonAsService(
    [string][Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $userNames
) {
    function New-TemporaryDirectory {
        $parent = [System.IO.Path]::GetTempPath()
        [string] $name = [System.Guid]::NewGuid()
        New-Item -ItemType Directory -Path (Join-Path $parent $name)
    }

    [string[]] $userNamesArray = ($userNames -split ',').Trim()

    foreach ($userName in $userNamesArray) {
        $tempDir = New-TemporaryDirectory
        #Get list of currently used SIDs 
        secedit /export /cfg $tempDir\tempexport.inf 
        $curSIDs = Select-String $tempDir\tempexport.inf -Pattern "SeServiceLogonRight" 
        $Sids = $curSIDs.line 
        $sidstring = ""

        $objUser = New-Object System.Security.Principal.NTAccount($userName)
        $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        if (!$Sids.Contains($strSID) -and !$sids.Contains($userName)) {
            $sidstring += ",*$strSID"
        }
        if ($sidstring) {
            $newSids = $sids + $sidstring
            Write-Verbose "New Sids: $newSids"
            $tempinf = Get-Content $tempDir\tempexport.inf
            $tempinf = $tempinf.Replace($Sids, $newSids)
            Add-Content -Path $tempDir\tempimport.inf -Value $tempinf
            secedit /import /db $tempDir\secedit.sdb /cfg "$tempDir\tempimport.inf" 
            secedit /configure /db $tempDir\secedit.sdb 
        }
        else {
            Write-Verbose "No new sids"
        }

        del "$tempDir" -Recurse -force -ErrorAction SilentlyContinue
    }
}
