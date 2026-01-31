@echo off
setlocal

set "OHPM_BAT=C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin\ohpm.bat"
if exist "%OHPM_BAT%" (
  call "%OHPM_BAT%" %*
  exit /b %ERRORLEVEL%
)

set "OHPM_NOEXT=C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin\ohpm"
if exist "%OHPM_NOEXT%" (
  "%OHPM_NOEXT%" %*
  exit /b %ERRORLEVEL%
)

echo ERROR: ohpm not found.
echo - Install DevEco Studio, or
echo - Add ohpm to PATH, or
echo - Edit this file to point at your ohpm installation.
exit /b 1
