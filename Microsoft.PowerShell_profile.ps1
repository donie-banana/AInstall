function KYS() {
    shutdown /s /t 0
}

function RestartTerminal {
    param(
        [switch]$noadmin
    )
    $psExe = "$($env:SystemRoot)\System32\WindowsPowerShell\v1.0\powershell.exe"
    if ($noadmin) {
        Start-Process -FilePath $psExe
        Write-Host "A new non-admin PowerShell window has been opened. This window will now close."
    } else {
        Start-Process -FilePath $psExe -Verb RunAs
        Write-Host "A new admin PowerShell window has been opened. This window will now close."
    }
    Start-Sleep -Seconds 2
    exit
}

function AInstallChoco() {
    Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.ServicePointManager]::SecurityProtocol = `
    [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

function AInstallWinget() {
    Invoke-WebRequest -Uri "https://aka.ms/Microsoft.DesktopAppInstaller" -OutFile "$env:TEMP\AppInstaller.appxbundle"
    Add-AppxPackage "$env:TEMP\AppInstaller.appxbundle"
}

function AInstallPSPKG() {
    Install-Module -Name PowerShellGet -Force -AllowClobber
}

function AinstallPre() {
    if ($args.Count -eq 0) {
        AInstallWinget
        AInstallPSPKG
        AInstallChoco
    }
    else {
        foreach ($mngr in $args) {
            if ($mngr -eq 'choco') {
                AInstallChoco
            }
            elseif ($mngr -eq 'PSPKG') {
                AInstallPSPKG
            }
            elseif ($mngr -eq 'winget') {
                AInstallWinget
            }
        }
    }
}

function checkR() {
    $type = $args[0]
    $pkg = $args[1]
    $check = $args[2]

    if ($type -eq 'exists') {
        if ($check -eq 'choco') {
            return choco search $pkg | Select-String "^$pkg"
        }
        elseif ($check -eq 'winget') {
            return winget search $pkg
        }
        elseif ($check -eq 'PSModule') {
            return Get-Module -ListAvailable -Name $pkg
        }
        elseif ($check -eq 'PSPKG') {
            Import-Module PackageManagement
            return Find-Package -Name $pkg -ErrorAction SilentlyContinue
        }        
        else {
            Import-Module PackageManagement
            $result = @()
            $result += [PSCustomObject]@{ Source = 'choco'; Result = (choco search $pkg | Select-String "^$pkg") }
            $result += [PSCustomObject]@{ Source = 'winget'; Result = (winget search $pkg) }
            $result += [PSCustomObject]@{ Source = 'PSModule'; Result = (Get-Module -ListAvailable -Name $pkg) }
            $result += [PSCustomObject]@{ Source = 'PSPKG'; Result = (Find-Package -Name $pkg -ErrorAction SilentlyContinue) }
            return $result
        }
    }
    elseif ($type -eq 'installed') {
        if ($check -eq 'choco') {
            return choco list -l $pkg | Select-String "^$pkg"
        }
        elseif ($check -eq 'winget') {
            return winget list --name $pkg | Select-String "^$pkg"a
        }
        elseif ($check -eq 'PSModule') {
            return Get-InstalledModule -Name $pkg -ErrorAction SilentlyContinue
        }
        elseif ($check -eq 'PSPKG') {
            Import-Module PackageManagement
            return Get-Package -Name $pkg -ErrorAction SilentlyContinue
        }        
        else {
            Import-Module PackageManagement
            $result = @()
            $result += [PSCustomObject]@{ Source = 'choco'; Result = (choco list -l $pkg | Select-String "^$pkg") }
            $result += [PSCustomObject]@{ Source = 'winget'; Result = (winget list --name $pkg | Select-String "^$pkg") }
            $result += [PSCustomObject]@{ Source = 'PSModule'; Result = (Get-InstalledModule -Name $pkg -ErrorAction SilentlyContinue) }
            $result += [PSCustomObject]@{ Source = 'PSPKG'; Result = (Get-Package -Name $pkg -ErrorAction SilentlyContinue) }
            return $result
        }
    }
}


function check() {
    $check = checkR @args
    if ($args.Count -gt 2 -and $null -ne $args[2]) {
        $check = checkR @args
        ($check | Out-String).Trim()
    }
    else { #FIX THIS
        $check = checkR @args
        foreach ($x in $check) {
            Write-Host "Source: $($x.Source)" -ForegroundColor Cyan
            if ($null -ne $x.Result) {
                Write-Host ($x.Result | Out-String).Trim()
            } else {
                Write-Host "No result found." -ForegroundColor DarkGray
            }
            Write-Host "-----------------------------"
        }
    }
}

function AInstall() {
    foreach ($pkg in $args) {
        $existsChoco = checkR exists $pkg choco
        if ($existsChoco) {
            choco install $pkg -y
            continue
        }

        $existsWinget = checkR exists $pkg winget
        if ($existsWinget) {
            winget install $pkg --silent
            continue
        }

        $existsPSModule = checkR exists $pkg PSModule
        if ($existsPSModule) {
            Install-Module -Name $pkg -Force
            continue
        }  

        $existsPSPKG = checkR exists $pkg PSPKG
        if ($existsPSPKG) {
            Install-Package $pkg -Force
            continue
        }

        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " Package '$pkg' not found in:" -ForegroundColor Red
        Write-Host "   - Chocolatey:" -ForegroundColor DarkGray
        Write-Host ($existsChoco | Out-String).Trim() -ForegroundColor Gray
        Write-Host "   - Winget:" -ForegroundColor DarkGray
        Write-Host ($existsWinget | Out-String).Trim() -ForegroundColor Gray
        Write-Host "   - PowerShell Modules:" -ForegroundColor DarkGray
        Write-Host ($existsPSModule | Out-String).Trim() -ForegroundColor Gray
        Write-Host "   - PowerShell PackageManagement:" -ForegroundColor DarkGray
        Write-Host ($existsPSPKG | Out-String).Trim() -ForegroundColor Gray
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host ""
    }
    Write-Host "Command finished..."
}

function AUninstall() {
    foreach ($pkg in $args) {
        $installedChoco = checkR installed $pkg choco
        if ($installedChoco) {
            choco uninstall $pkg -y
            continue
        }

        $installedWinget = checkR installed $pkg winget
        if ($installedWinget) {
            winget uninstall --id $pkg --silent
            continue
        }

        $installedPSModule = checkR installed $pkg PSModule
        if ($installedPSModule) {
            Uninstall-Module -Name $pkg -Force
            continue
        }  

        $installedPSPKG = checkR installed $pkg PSPKG
        if ($installedPSPKG) {
            Uninstall-Package -Name $pkg -Force
            continue
        }

        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " Package '$pkg' not installed or not found in:" -ForegroundColor Red
        Write-Host "   - Chocolatey:" -ForegroundColor DarkGray
        Write-Host ($installedChoco | Out-String).Trim() -ForegroundColor Gray
        Write-Host "   - Winget:" -ForegroundColor DarkGray
        Write-Host ($installedWinget | Out-String).Trim() -ForegroundColor Gray
        Write-Host "   - PowerShell Modules:" -ForegroundColor DarkGray
        Write-Host ($installedPSModule | Out-String).Trim() -ForegroundColor Gray
        Write-Host "   - PowerShell PackageManagement:" -ForegroundColor DarkGray
        Write-Host ($installedPSPKG | Out-String).Trim() -ForegroundColor Gray
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host ""
    }
    Write-Host "Command finished..."
}

function AUpdate() {
    $restart = false
    foreach ($pkg in $args) {
        if ($pkg -eq "self") {
            $repo = "donie-banana/AInstall"
            $apiUrl = "https://api.github.com/repos/$repo/releases/latest"
            $release = Invoke-RestMethod -Uri $apiUrl
            $latestVersion = $release.tag_name
            $CurrentVersion = "v1.1" # versie

            if ($CurrentVersion -eq $latestVersion) {
                Write-Host "You are already on the latest version ($CurrentVersion)." -ForegroundColor Green
                return
            }
            $zipUrl = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1 -ExpandProperty browser_download_url
            $zipPath = "$env:TEMP\AInstall-latest.zip"
            $extractPath = "$env:TEMP\AInstall-latest"

            Write-Host "Downloading latest release from $zipUrl..."
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

            Write-Host "Extracting..."
            Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

            Write-Host "Running Install.bat..."
            Start-Process -FilePath "$extractPath\Install.bat" -Verb RunAs

            Write-Host "Update initiated. Please follow any prompts in the installer."
            continue
        }

        $installedChoco = checkR installed $pkg choco
        if ($installedChoco) {
            choco upgrade $pkg -y
            continue
        }

        $installedWinget = checkR installed $pkg winget
        if ($installedWinget) {
            winget upgrade --id $pkg --silent
            continue
        }

        $installedPSModule = checkR installed $pkg PSModule
        if ($installedPSModule) {
            Update-Module -Name $pkg -Force
            continue
        }

        $installedPSPKG = checkR installed $pkg PSPKG
        if ($installedPSPKG) {
            Update-Package -Name $pkg -Force
            continue
        }

        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " Package '$pkg' not installed or not found in:" -ForegroundColor Red
        Write-Host "   - Chocolatey:" -ForegroundColor DarkGray
        Write-Host ($installedChoco | Out-String).Trim() -ForegroundColor Gray
        Write-Host "   - Winget:" -ForegroundColor DarkGray
        Write-Host ($installedWinget | Out-String).Trim() -ForegroundColor Gray
        Write-Host "   - PowerShell Modules:" -ForegroundColor DarkGray
        Write-Host ($installedPSModule | Out-String).Trim() -ForegroundColor Gray
        Write-Host "   - PowerShell PackageManagement:" -ForegroundColor DarkGray
        Write-Host ($installedPSPKG | Out-String).Trim() -ForegroundColor Gray
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host ""
    }

    if ($restart) {
        RestartTerminal
    }

    Write-Host "Command finished..."
}