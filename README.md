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
1. download release
2. run Install.bat
3. done!

# Once installed
Once you have it installed, run 'AInstallPre' to install the prerequisites for the other commands.
When that's done you can now use:
- AInstall <name> to install whatever you want (you can add multiple names for multiple installs)
- AUninstall <name> to uninstall whatever you want (you can add multiple names for multiple installs)
- check <exists/installed> <name> <(optional) manager> to check if something exists and if it is installed
