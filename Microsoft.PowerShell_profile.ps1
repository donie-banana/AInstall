function test()
{ 
    Write-Output 'test' 
}

function KYS() {
    shutdown /s /t 0
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

function AUninstall() {
    foreach ($pkg in $args) {
        $installedChoco = checkR installed $pkg choco
        if ($installedChoco) {
            choco unistall $pkg
            continue
        }

        $installedWinget = checkR installed $pkg winget
        if ($installedWinget) {
            winget install $pkg
            continue
        }

        $installedPSModule = checkR installed $pkg PSModule
        if ($installedPSModule) {
            Install-Module -Name $pkg
            continue
        }  

        $installedPSPKG = checkR installed $pkg PSPKG
        if ($installedPSPKG) {
            Install-Package $pkg
            continue
        }
    }

    Write-Host "Command finished..."
}

function AInstall() {
    foreach ($pkg in $args) {
        $existsChoco = checkR exists $pkg choco
        if ($existsChoco) {
            choco install $pkg
            continue
        }

        $existsWinget = checkR exists $pkg winget
        if ($existsWinget) {
            winget install $pkg
            continue
        }

        $existsPSModule = checkR exists $pkg PSModule
        if ($existsPSModule) {
            Install-Module -Name $pkg
            continue
        }  

        $existsPSPKG = checkR exists $pkg PSPKG
        if ($existsPSPKG) {
            Install-Package $pkg
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
