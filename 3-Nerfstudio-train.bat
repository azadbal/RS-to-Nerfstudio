@echo on
setlocal ENABLEDELAYEDEXPANSION

set "imagedownscale=2"
set "maxsteps=15000"
set "viewerhost=127.0.0.1"
set "viewerport=7007"

REM ===== Project root (this .bat's folder) =====
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
for %%A in ("%ROOT%") do set "ROOT_NAME=%%~nA"

set "SETTINGS_FILE=%ROOT%\User_Settings.txt"
if exist "%SETTINGS_FILE%" (
  for /f "usebackq tokens=1* delims==" %%A in ("%SETTINGS_FILE%") do (
    if not "%%A"=="" if not "%%A:~0,1%"=="#" if not "%%A:~0,1%"==";" (
      call set "%%A=%%B"
    )
  )
)
if defined IMAGE_DOWNSCALE set "imagedownscale=%IMAGE_DOWNSCALE%"
if defined MAX_STEPS set "maxsteps=%MAX_STEPS%"
if defined VIEWER_HOST set "viewerhost=%VIEWER_HOST%"
if defined VIEWER_PORT set "viewerport=%VIEWER_PORT%"

REM ===== Paths =====
if not defined NS_DIR set "NS_DIR=%ROOT%\nerfstudio"
set "OUT_DIR=%NS_DIR%\output"
if defined NS_OUTPUT_DIR set "OUT_DIR=%NS_OUTPUT_DIR%"
set "LOG=%ROOT%\ns_train.log"
echo. > "%LOG%"

REM ===== Find conda =====
if not defined CONDA_BAT call :find_conda "%USERPROFILE%\anaconda3"
if not defined CONDA_BAT call :find_conda "%USERPROFILE%\miniconda3"
if not defined CONDA_BAT call :find_conda "C:\ProgramData\Anaconda3"
if not defined CONDA_BAT call :find_conda "C:\ProgramData\Miniconda3"
if not defined CONDA_BAT (
  echo [ERROR] conda.bat not found. Set CONDA_BAT manually.
  exit /b 1
)

REM ===== Sanity checks =====
if not exist "%NS_DIR%\transforms.json" (
  echo [ERROR] Missing transforms.json in "%NS_DIR%"
  exit /b 1
)

REM ===== Train only (viewer enabled @ http://127.0.0.1:7007) =====
call "%CONDA_BAT%" run -n nerfstudio --no-capture-output ^
  ns-train splatfacto ^
    --vis viewer+tensorboard ^
    --viewer.websocket_host %viewerhost% ^
    --viewer.websocket_port %viewerport% ^
    --max-num-iterations %maxsteps% ^
    --pipeline.model.use-bilateral-grid True ^
    --data "%NS_DIR%" ^
	--output-dir "%OUT_DIR%" ^
	nerfstudio-data ^
    --downscale-factor %imagedownscale%
  1>>"%LOG%" 2>&1
if errorlevel 1 goto :err

start "" http://%viewerhost%:%viewerport%/
echo [OK] Training started. Logs: "%LOG%"
exit /b 0

:err
echo [FAIL] See log: "%LOG%"
exit /b 1

REM ===== Helper =====
:find_conda
set "CAND_ROOT=%~1"
if exist "%CAND_ROOT%\condabin\conda.bat" set "CONDA_BAT=%CAND_ROOT%\condabin\conda.bat"
exit /b 0
