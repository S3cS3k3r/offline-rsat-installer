# Требуется запуск PowerShell от имени администратора

$ErrorActionPreference = "Stop"

$IsoUrl  = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1.240331-1435.ge_release_amd64fre_CLIENT_LOF_PACKAGES_OEM.iso"
$IsoPath = "$env:TEMP\Win11_LOF_24H2_25H2.iso"

try {
    Write-Host "Проверка прав администратора..." -ForegroundColor Cyan
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        throw "Скрипт нужно запускать от имени администратора."
    }

    Write-Host "Скачивание ISO..." -ForegroundColor Cyan
    if (Test-Path $IsoPath) {
        Write-Host "ISO уже скачан: $IsoPath" -ForegroundColor Yellow
    } else {
        Invoke-WebRequest -Uri $IsoUrl -OutFile $IsoPath
    }

    Write-Host "Монтирование ISO..." -ForegroundColor Cyan
    $mount = Mount-DiskImage -ImagePath $IsoPath -PassThru
    Start-Sleep -Seconds 2

    $volume = $mount | Get-Volume
    if (-not $volume.DriveLetter) {
        throw "Не удалось определить букву смонтированного ISO."
    }

    $IsoDrive = $volume.DriveLetter
    $Candidates = @(
        "${IsoDrive}:\LanguagesAndOptionalFeatures",
        "${IsoDrive}:\"
    )

    $SourcePath = $Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $SourcePath) {
        throw "Не найден источник пакетов на ISO. Ожидалась папка LanguagesAndOptionalFeatures или корень ISO."
    }

    Write-Host "Источник найден: $SourcePath" -ForegroundColor Green

    $RsatList = Get-WindowsCapability -Online -Name RSAT* | Where-Object State -ne Installed

    if (-not $RsatList) {
        Write-Host "Все RSAT уже установлены." -ForegroundColor Green
    } else {
        Write-Host "Будут установлены RSAT-компоненты:" -ForegroundColor Cyan
        $RsatList | Select-Object Name, State | Format-Table -AutoSize

        foreach ($item in $RsatList) {
            Write-Host "Установка $($item.Name) ..." -ForegroundColor Yellow
            Add-WindowsCapability -Online -Name $item.Name -Source $SourcePath -LimitAccess
        }

        Write-Host ""
        Write-Host "Итоговое состояние:" -ForegroundColor Cyan
        Get-WindowsCapability -Online -Name RSAT* | Select-Object Name, State | Format-Table -AutoSize
    }
}
catch {
    Write-Host ""
    Write-Host "Ошибка: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if (Test-Path $IsoPath) {
        try {
            $diskImage = Get-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue
            if ($diskImage -and $diskImage.Attached) {
                Write-Host "Размонтирование ISO..." -ForegroundColor Cyan
                Dismount-DiskImage -ImagePath $IsoPath
            }
        }
        catch {
            Write-Host "Не удалось автоматически размонтировать ISO: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        try {
            if (Test-Path $IsoPath) {
                Write-Host "Удаление ISO..." -ForegroundColor Cyan
                Remove-Item -Path $IsoPath -Force
            }
        }
        catch {
            Write-Host "Не удалось удалить ISO: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "Готово. Для AD Users and Computers: dsa.msc" -ForegroundColor Green
}
