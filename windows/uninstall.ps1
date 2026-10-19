# Barista Studio - Windows User Uninstaller
$ErrorActionPreference = "SilentlyContinue"

$InstallDir = "$env:LOCALAPPDATA\Programs\BaristaStudio"
$StartMenuDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Barista Studio"
$DesktopDir = [System.Environment]::GetFolderPath("Desktop")

Write-Host "Uninstalling Barista Studio..." -ForegroundColor Yellow

Remove-Item -Path "$DesktopDir\Barista Studio.lnk" -Force
Remove-Item -Path $StartMenuDir -Recurse -Force
Remove-Item -Path $InstallDir -Recurse -Force

Write-Host "Barista Studio has been uninstalled." -ForegroundColor Green
