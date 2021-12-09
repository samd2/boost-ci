@ECHO OFF
setlocal enabledelayedexpansion

IF NOT DEFINED B2_CI_VERSION (
    echo You need to set B2_CI_VERSION in your CI script
    exit /B 1
)

PATH=%ADDPATH%%PATH%

@ECHO OFF
if "%B2_TOOLSET%" == "gcc" (
    set cxx_exe="g++.exe"
)else if "%B2_TOOLSET%" == "clang-win" (
    set cxx_exe="clang-cl.exe"
)else (
    set cxx_exe=""
)
if NOT "%cxx_exe%" == "" (
    call :GetPath %cxx_exe%,cxx_path
    call :GetVersion %cxx_exe%,cxx_version
    echo Compiler location: !cxx_path!
    echo Compiler version: !cxx_version!
)
@ECHO ON

SET B2_TOOLCXX=toolset=%B2_TOOLSET%

IF DEFINED B2_CXXSTD (SET B2_CXXSTD=cxxstd=%B2_CXXSTD%)
IF DEFINED B2_CXXFLAGS (SET B2_CXXFLAGS=cxxflags=%B2_CXXFLAGS%)
IF DEFINED B2_DEFINES (SET B2_DEFINES=define=%B2_DEFINES%)
IF DEFINED B2_ADDRESS_MODEL (SET B2_ADDRESS_MODEL=address-model=%B2_ADDRESS_MODEL%)
IF DEFINED B2_LINK (SET B2_LINK=link=%B2_LINK%)
IF DEFINED B2_VARIANT (SET B2_VARIANT=variant=%B2_VARIANT%)

set SELF_S=%SELF:\=/%
IF NOT DEFINED B2_TARGETS (SET B2_TARGETS=libs/!SELF_S!/test)

cd %BOOST_ROOT%

IF DEFINED SCRIPT (
    call libs\%SELF%\%SCRIPT%
) ELSE (
    REM Echo the complete build command to the build log
    ECHO b2 --abbreviate-paths %B2_TARGETS% %B2_TOOLCXX% %B2_CXXSTD% %B2_CXXFLAGS% %B2_DEFINES% %B2_THREADING% %B2_ADDRESS_MODEL% %B2_LINK% %B2_VARIANT% -j3
    REM Now go build...
    b2 --abbreviate-paths %B2_TARGETS% %B2_TOOLCXX% %B2_CXXSTD% %B2_CXXFLAGS% %B2_DEFINES% %B2_THREADING% %B2_ADDRESS_MODEL% %B2_LINK% %B2_VARIANT% -j3
)

EXIT /B %ERRORLEVEL%

:GetPath
for %%i in (%~1) do set %~2=%%~$PATH:i
EXIT /B 0

:GetVersion
for /F "delims=" %%i in ('%~1 --version ^2^>^&^1') do set %~2=%%i & goto :done
:done
EXIT /B 0


