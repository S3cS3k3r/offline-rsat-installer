# Run this script in PowerShell as Administrator

$ErrorActionPreference = "Stop"

# IMPORTANT:
# Replace the URL below with the correct Language and Optional Features ISO
# for your Windows build/version.
$IsoUrl  = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1.240331-1435.ge_release_amd64fre_CLIENT_LOF_PACKAGES_OEM.iso"
$IsoPath = "$env:TEMP\Win11_LOF_24H2_25H2.iso"

try {
    Write-Host "Checking administrator privileges..." -ForegroundColor Cyan
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "This script must be run as Administrator."
    }

    Write-Host "Downloading ISO..." -ForegroundColor Cyan
    if (Test-Path $IsoPath) {
        Write-Host "ISO already exists: $IsoPath" -ForegroundColor Yellow
    } else {
        Invoke-WebRequest -Uri $IsoUrl -OutFile $IsoPath
    }

    Write-Host "Mounting ISO..." -ForegroundColor Cyan
    $mount = Mount-DiskImage -ImagePath $IsoPath -PassThru
    Start-Sleep -Seconds 2

    $volume = $mount | Get-Volume
    if (-not $volume.DriveLetter) {
        throw "Failed to detect mounted ISO drive letter."
    }

    $IsoDrive = $volume.DriveLetter
    $Candidates = @(
        "${IsoDrive}:\LanguagesAndOptionalFeatures",
        "${IsoDrive}:\"
    )

    $SourcePath = $Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $SourcePath) {
        throw "Package source was not found on the ISO. Expected LanguagesAndOptionalFeatures folder or ISO root."
    }

    Write-Host "Using source path: $SourcePath" -ForegroundColor Green

    $RsatList = Get-WindowsCapability -Online -Name RSAT* | Where-Object State -ne Installed

    if (-not $RsatList) {
        Write-Host "All RSAT components are already installed." -ForegroundColor Green
    } else {
        Write-Host "The following RSAT components will be installed:" -ForegroundColor Cyan
        $RsatList | Select-Object Name, State | Format-Table -AutoSize

        foreach ($item in $RsatList) {
            Write-Host "Installing $($item.Name) ..." -ForegroundColor Yellow
            Add-WindowsCapability -Online -Name $item.Name -Source $SourcePath -LimitAccess
        }

        Write-Host ""
        Write-Host "Final RSAT component state:" -ForegroundColor Cyan
        Get-WindowsCapability -Online -Name RSAT* | Select-Object Name, State | Format-Table -AutoSize
    }
}
catch {
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if (Test-Path $IsoPath) {
        try {
            $diskImage = Get-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue
            if ($diskImage -and $diskImage.Attached) {
                Write-Host "Dismounting ISO..." -ForegroundColor Cyan
                Dismount-DiskImage -ImagePath $IsoPath
            }
        }
        catch {
            Write-Host "Failed to dismount ISO automatically: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        try {
            if (Test-Path $IsoPath) {
                Write-Host "Deleting ISO..." -ForegroundColor Cyan
                Remove-Item -Path $IsoPath -Force
            }
        }
        catch {
            Write-Host "Failed to delete ISO: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "Done. Open Active Directory Users and Computers with: dsa.msc" -ForegroundColor Green
}
