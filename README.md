# AInstall
Checks multiple installation tools to more easily install whatever you want. 
Only works on PowerShell, I recommend using it with admin privileges.

This uses:
- Chocolatey
- Winget
- PowerShell Modules
- PowerShell PackageManagement

please message me if you have any ideas to add more installation tools at dion.gierman@gmail.com

# Easy installation
1. download release zip
2. extract zip
3. run Install.bat
4. done!

# Once installed
Once you have it installed, run 'AInstallPre' to install the prerequisites for the other commands.
When that's done you can now use:
- AInstall <name> (to install whatever you want (you can add multiple names for multiple installs))
- AUninstall <name> (to uninstall whatever you want (you can add multiple names for multiple installs))
- AUpgrade <name> (to upgrade whatever you want (you can add multiple names for multiple installs))
- check <exists/installed> <name> <(optional) manager> (to check if something exists and if it is installed)
- RestartTerminal <(optional) -no-admin> (this, well, restarts the terminal. automatically in admin.)
- KYS (this just shuts off your computer, no real reason)

# Easy update
To update this program, just run "AUpgrade self" in a powershell command line
