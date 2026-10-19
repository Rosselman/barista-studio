# Barista Studio - Windows User Installer
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$InstallDir = "$env:LOCALAPPDATA\Programs\BaristaStudio"
$ExePath = "$InstallDir\barista_studio.exe"

Write-Host "Installing Barista Studio..." -ForegroundColor Cyan

if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Copy bundle contents to installation directory
Copy-Item -Path "$ScriptDir\*" -Destination $InstallDir -Recurse -Force

# Create Start Menu shortcut
$WshShell = New-Object -ComObject WScript.Shell
$StartMenuDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Barista Studio"
if (!(Test-Path $StartMenuDir)) {
    New-Item -ItemType Directory -Path $StartMenuDir -Force | Out-Null
}
$StartShortcut = $WshShell.CreateShortcut("$StartMenuDir\Barista Studio.lnk")
$StartShortcut.TargetPath = $ExePath
$StartShortcut.WorkingDirectory = $InstallDir
$StartShortcut.IconLocation = "$ExePath,0"
$StartShortcut.Save()

# Create Desktop shortcut
$DesktopDir = [System.Environment]::GetFolderPath("Desktop")
$DesktopShortcut = $WshShell.CreateShortcut("$DesktopDir\Barista Studio.lnk")
$DesktopShortcut.TargetPath = $ExePath
$DesktopShortcut.WorkingDirectory = $InstallDir
$DesktopShortcut.IconLocation = "$ExePath,0"
$DesktopShortcut.Save()

Write-Host "Barista Studio installed successfully!" -ForegroundColor Green
Write-Host "You can now launch it from your Desktop or Start Menu." -ForegroundColor Green
