@echo off
setlocal

set "OHPM_BIN=C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin"
set "HVIGOR_BIN=C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin"
set "FLUTTER_OHOS_BIN=D:\dev\flutter_ohos\bin"
set "DEVECO_SDK_HOME=C:\Users\kaiwang\AppData\Local\OpenHarmony\Sdk\12"

if exist "%OHPM_BIN%\ohpm.bat" (
  set "PATH=%OHPM_BIN%;%PATH%"
)

if exist "%HVIGOR_BIN%\hvigorw.bat" (
  set "PATH=%HVIGOR_BIN%;%PATH%"
)

if exist "%FLUTTER_OHOS_BIN%\flutter.bat" (
  call "%FLUTTER_OHOS_BIN%\flutter.bat" build hap %*
  exit /b %ERRORLEVEL%
)

echo ERROR: flutter_ohos not found at "%FLUTTER_OHOS_BIN%".
echo Edit this file to point at your flutter_ohos installation.
exit /b 1
