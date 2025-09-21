# Self-elevate if not running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

try {
    $source = Join-Path -Path $PSScriptRoot -ChildPath 'Microsoft.PowerShell_profile.ps1'
    $targetDir = Join-Path -Path $HOME -ChildPath 'Documents\WindowsPowerShell'
    $target = Join-Path -Path $targetDir -ChildPath 'Microsoft.PowerShell_profile.ps1'

    if (-not (Test-Path $source)) {
        Write-Host "Source not found: $source" -ForegroundColor Red
        exit 1
    }

    if ((Get-Item $source).FullName -eq (Get-Item $target).FullName) {
        Write-Host "Source and target are the same file. Aborting to avoid self-append." -ForegroundColor Yellow
        exit 1
    }

    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory | Out-Null
    }

    Copy-Item -Path $source -Destination $target -Force
    Write-Host "Profile updated successfully." -ForegroundColor Green
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
Read-Host "Press Enter to exit"