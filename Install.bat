@echo off
setlocal

rem source (where the .bat is) and target (user's Documents\WindowsPowerShell)
set "sourcedir=%~dp0"
set "source=%sourcedir%blahblah.ps1"

set "targetdir=%USERPROFILE%\Documents\WindowsPowerShell\"
set "target=%targetdir%blahblah.ps1"

rem check source exists
if not exist "%source%" (
  echo Source not found: "%source%"
  exit /b 1
)

rem avoid appending the file to itself
if /I "%source%"=="%target%" (
  echo Source and target are the same file. Aborting to avoid self-append.
  exit /b 1
)

rem ensure target dir exists
if not exist "%targetdir%" mkdir "%targetdir%"

rem append (with a preceding newline) if target exists, otherwise copy
if exist "%target%" (
  (
    echo(
    type "%source%"
  ) >> "%target%"
) else (
  copy /Y "%source%" "%target%" >nul
)

endlocal
