@echo off
setlocal EnableDelayedExpansion

REM ==================================================
REM Export latest valid splatfacto checkpoint as splat
REM Naming: <ProjectName>_<method_name>_<step-XXXXXXXX>.ext
REM ==================================================

REM -------- Project root and name --------
set "ROOT=%~dp0"

set "ROOT_NO_SLASH=%ROOT%"
if "%ROOT_NO_SLASH:~-1%"=="\" set "ROOT_NO_SLASH=%ROOT_NO_SLASH:~0,-1%"

for %%A in ("%ROOT_NO_SLASH%") do set "PROJECT_NAME=%%~nA"
set "ROOT_NAME=%PROJECT_NAME%"

set "SETTINGS_FILE=%ROOT%User_Settings.txt"
if exist "%SETTINGS_FILE%" (
  for /f "usebackq tokens=1* delims==" %%A in ("%SETTINGS_FILE%") do (
    if not "%%A"=="" if not "%%A:~0,1%"=="#" if not "%%A:~0,1%"==";" (
      call set "%%A=%%B"
    )
  )
)

if defined PROJECT_NAME set "PROJECT_NAME=%PROJECT_NAME%"
if not defined NS_DIR set "NS_DIR=%ROOT%nerfstudio"
if not defined NS_OUTPUT_DIR set "NS_OUTPUT_DIR=%NS_DIR%\output"
if not defined SPLAT_OUTPUT_DIR set "SPLAT_OUTPUT_DIR=%ROOT%splats"

REM -------- splatfacto base dir --------
set "SPLAT_DIR=%NS_OUTPUT_DIR%\nerfstudio\splatfacto"

if not exist "%SPLAT_DIR%" (
  echo [ERROR] Splatfacto directory not found:
  echo         "%SPLAT_DIR%"
  exit /b 1
)

REM -------- Find newest run that has at least one .ckpt --------
set "RUN_DIR="

for /f "delims=" %%D in ('dir "%SPLAT_DIR%" /b /ad /o-n') do (
  if not defined RUN_DIR (
    if exist "%SPLAT_DIR%\%%D\nerfstudio_models\*.ckpt" (
      set "RUN_DIR=%SPLAT_DIR%\%%D"
    )
  )
)

if not defined RUN_DIR (
  echo [ERROR] No runs with nerfstudio_models\*.ckpt found under:
  echo         "%SPLAT_DIR%"
  exit /b 1
)

REM -------- Pick latest .ckpt inside that run --------
set "CKPT="
for /f "delims=" %%F in ('dir "%RUN_DIR%\nerfstudio_models\*.ckpt" /b /a-d /o-n 2^>NUL') do (
  if not defined CKPT (
    set "CKPT=%RUN_DIR%\nerfstudio_models\%%F"
  )
)

if not defined CKPT (
  echo [ERROR] No .ckpt file found in:
  echo         "%RUN_DIR%\nerfstudio_models"
  exit /b 1
)

REM Extract step from ckpt filename, e.g. step-000008000.ckpt -> step-008000 (last 6 digits)
for %%F in ("%CKPT%") do set "CKPT_BASE=%%~nF"
set "STEP_TAG=%CKPT_BASE%"

REM Keep only last 6 digits if they exist
for /f "tokens=2 delims=-" %%S in ("%STEP_TAG%") do (
  set "NUM=%%S"
  set "NUM_LAST6=!NUM:~-6!"
  set "STEP_TAG=step-!NUM_LAST6!"
)


REM -------- Config for that run --------
set "CONFIG=%RUN_DIR%\config.yml"

if not exist "%CONFIG%" (
  echo [ERROR] config.yml not found in selected run:
  echo         "%CONFIG%"
  exit /b 1
)

REM -------- splats output dir --------
set "OUT=%SPLAT_OUTPUT_DIR%"
if not exist "%OUT%" mkdir "%OUT%"

REM -------- Locate conda.bat --------
if not defined CONDA_BAT call :find_conda "%USERPROFILE%\anaconda3"
if not defined CONDA_BAT call :find_conda "%USERPROFILE%\miniconda3"
if not defined CONDA_BAT call :find_conda "C:\ProgramData\Anaconda3"
if not defined CONDA_BAT call :find_conda "C:\ProgramData\Miniconda3"

if not defined CONDA_BAT (
  echo [ERROR] conda.bat not found. Set CONDA_BAT manually.
  exit /b 1
)

REM -------- Parse method_name and num_downscales from config.yml --------
for /f "usebackq delims=" %%M in (`
  powershell -NoProfile -Command ^
    "(Get-Content '%CONFIG%') -match '^\s*method_name\s*:' | Select-Object -First 1 | ForEach-Object { ($_ -split ':',2)[1].Trim() }"
`) do set "METHOD_NAME=%%M"

for /f "usebackq delims=" %%D in (`
  powershell -NoProfile -Command ^
    "(Get-Content '%CONFIG%') -match '^\s*num_downscales\s*:' | Select-Object -First 1 | ForEach-Object { ($_ -split ':',2)[1].Trim() }"
`) do set "DOWNSCALE=%%D"

if not defined METHOD_NAME set "METHOD_NAME=unknown"
if not defined DOWNSCALE set "DOWNSCALE=unknown"

REM sanitize for filenames
set "METHOD_NAME=%METHOD_NAME: =_%"
set "METHOD_NAME=%METHOD_NAME::=_%"
set "STEP_TAG=%STEP_TAG::=_%"
set "DOWNSCALE=%DOWNSCALE: =_%"
set "DOWNSCALE=%DOWNSCALE::=_%"

set "DOWNSCALE_TAG=downscale%DOWNSCALE%"
set "SPLAT_NAME=%PROJECT_NAME%_%METHOD_NAME%_%STEP_TAG%_%DOWNSCALE_TAG%"

echo [INFO] Project root:  %ROOT_NO_SLASH%
echo [INFO] Project name:  %PROJECT_NAME%
echo [INFO] Selected run:  %RUN_DIR%
echo [INFO] Checkpoint:    %CKPT%
echo [INFO] Step tag:      %STEP_TAG%
echo [INFO] Downscale:     %DOWNSCALE%
echo [INFO] Config:        %CONFIG%
echo [INFO] Output dir:    %OUT%
echo [INFO] Splat name:    %SPLAT_NAME%
echo.


REM -------- Run ns-export via conda --------
call "%CONDA_BAT%" run -n nerfstudio --no-capture-output ^
  ns-export gaussian-splat ^
    --load-config "%CONFIG%" ^
    --output-dir "%OUT%"

if errorlevel 1 (
  echo [ERROR] ns-export failed.
  exit /b 1
)

REM -------- Rename latest exported file --------
set "EXPORTED_FILE="

for /f "delims=" %%F in ('dir "%OUT%\*.ply" "%OUT%\*.splat" /b /a-d /o-d 2^>NUL') do (
  set "EXPORTED_FILE=%%F"
  goto :rename_file
)

:rename_file
if not defined EXPORTED_FILE (
  echo [ERROR] No exported splat file found in "%OUT%" to rename.
  exit /b 1
)

for %%X in ("%OUT%\%EXPORTED_FILE%") do set "EXPORTED_EXT=%%~xX"

ren "%OUT%\%EXPORTED_FILE%" "%SPLAT_NAME%%EXPORTED_EXT%"

echo [OK] Exported and renamed to "%SPLAT_NAME%%EXPORTED_EXT%"
exit /b 0

REM ================== FUNCTIONS ==================

:find_conda
set "CAND_ROOT=%~1"
if exist "%CAND_ROOT%\condabin\conda.bat" (
  set "CONDA_BAT=%CAND_ROOT%\condabin\conda.bat"
)
exit /b 0
