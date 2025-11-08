@echo off
setlocal ENABLEDELAYEDEXPANSION

REM ===== Project root (this .bat's folder) =====
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

REM ===== Paths =====
set "NS_DIR=%ROOT%\nerfstudio"
set "OUT_DIR=%NS_DIR%\output"
set "LOG=%ROOT%\ns_train.log"
echo. > "%LOG%"

REM ===== Find conda =====
call :find_conda "%USERPROFILE%\anaconda3"
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
    --viewer.websocket_host 127.0.0.1 ^
    --viewer.websocket_port 7007 ^
    --max-num-iterations 15000 ^
    --pipeline.model.use-bilateral-grid True ^
    --data "%NS_DIR%" ^
	--output-dir "%NS_DIR%\output" ^
  1>>"%LOG%" 2>&1
if errorlevel 1 goto :err

start "" http://127.0.0.1:7007/
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
