@echo off
setlocal

if not defined OHPM_BIN set "OHPM_BIN=C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin"
if not defined HVIGOR_BIN set "HVIGOR_BIN=C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin"
if not defined DEVECO_SDK_HOME set "DEVECO_SDK_HOME=%LOCALAPPDATA%\OpenHarmony\Sdk\12"

if not defined FLUTTER_OHOS_BIN (
  if exist "%USERPROFILE%\dev\flutter_ohos\bin\flutter.bat" (
    set "FLUTTER_OHOS_BIN=%USERPROFILE%\dev\flutter_ohos\bin"
  ) else if exist "D:\dev\flutter_ohos\bin\flutter.bat" (
    set "FLUTTER_OHOS_BIN=D:\dev\flutter_ohos\bin"
  ) else if exist "C:\dev\flutter_ohos\bin\flutter.bat" (
    set "FLUTTER_OHOS_BIN=C:\dev\flutter_ohos\bin"
  )
)

if exist "%OHPM_BIN%\ohpm.bat" (
  set "PATH=%OHPM_BIN%;%PATH%"
)

if exist "%HVIGOR_BIN%\hvigorw.bat" (
  set "PATH=%HVIGOR_BIN%;%PATH%"
)

set "EXIT_CODE="
set "DID_BUILD="

if exist "%FLUTTER_OHOS_BIN%\flutter.bat" (
  cmd /c ""%FLUTTER_OHOS_BIN%\flutter.bat" build hap %*"
  set "EXIT_CODE=%ERRORLEVEL%"
  set "DID_BUILD=1"
) else (
  flutter.bat >nul 2>nul
  if %ERRORLEVEL% equ 0 (
    cmd /c "flutter.bat build hap %*"
    set "EXIT_CODE=%ERRORLEVEL%"
    set "DID_BUILD=1"
  )
)

if not defined DID_BUILD (
  echo ERROR: flutter_ohos not found.
  echo Set FLUTTER_OHOS_BIN to your flutter_ohos\bin directory, or put flutter_ohos on PATH.
  exit /b 1
)

if not "%EXIT_CODE%"=="0" exit /b %EXIT_CODE%
call :post_build
exit /b 0

:post_build
set "HAP_FILE="
for /f "delims=" %%f in ('dir /b /s /o-d "%~dp0entry\build\*.hap" 2^>nul') do (
  set "HAP_FILE=%%f"
  goto found_hap
)

:found_hap
if defined HAP_FILE (
  if not exist "%~dp0dist" mkdir "%~dp0dist" >nul 2>nul
  copy /y "%HAP_FILE%" "%~dp0dist\todo_app.hap" >nul
  echo HAP: %HAP_FILE%
  echo Copied: %~dp0dist\todo_app.hap
) else (
  echo WARN: No .hap found under "%~dp0entry\build".
)
exit /b 0
