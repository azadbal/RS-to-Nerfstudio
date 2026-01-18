@echo on
setlocal ENABLEDELAYEDEXPANSION

REM ===== Project root (parent of script folder) =====
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "SCRIPT_DIR=%ROOT%"
for %%A in ("%SCRIPT_DIR%\..") do set "ROOT=%%~fA"
for %%A in ("%ROOT%") do set "ROOT_NAME=%%~nA"

set "SETTINGS_FILE=%SCRIPT_DIR%\User_Settings.txt"
if not exist "%SETTINGS_FILE%" (
  echo [ERROR] Missing User_Settings.txt
  exit /b 1
)
if exist "%SETTINGS_FILE%" (
  for /f "usebackq tokens=1* delims==" %%A in ("%SETTINGS_FILE%") do (
    if not "%%A"=="" if not "%%A:~0,1%"=="#" if not "%%A:~0,1%"==";" (
      call set "%%A=%%B"
    )
  )
)

REM  ===== Paths =====
set "IMG_DIR=%IMAGE_DIR%"
set "NS_DIR=%NS_DIR%"
set "OUT_DIR=%NS_OUTPUT_DIR%"
set "LOG_DIR=%ROOT%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "LOG=%LOG_DIR%\ns_convert.log"
echo. > "%LOG%"

REM ===== Source files to copy into nerfstudio =====
set "SRC_DIR=%NS_DIR%"
REM set "SRC_PLY1=%SRC_DIR%\pointcloud.ply"
set "SRC_CSV=%SRC_DIR%\reg.csv"

REM ===== Find conda =====
if not defined CONDA_BAT call :find_conda "%USERPROFILE%\anaconda3"
if not defined CONDA_BAT call :find_conda "%USERPROFILE%\miniconda3"
if not defined CONDA_BAT call :find_conda "C:\ProgramData\Anaconda3"
if not defined CONDA_BAT call :find_conda "C:\ProgramData\Miniconda3"
if not defined CONDA_BAT (
  echo [ERROR] conda.bat not found. Set CONDA_BAT manually. >> "%LOG%"
  echo [ERROR] conda.bat not found. Set CONDA_BAT manually.
  exit /b 1
)

REM ===== Checks =====
if not exist "%IMG_DIR%" (echo [ERROR] Missing images: "%IMG_DIR%" & exit /b 1)
if not exist "%SRC_CSV%" (echo [ERROR] Missing CSV: "%SRC_CSV%" & exit /b 1)
mkdir "%NS_DIR%"  2>nul
mkdir "%OUT_DIR%" 2>nul

echo [STEP] ns-process-data realitycapture ...
call "%CONDA_BAT%" run -n nerfstudio --no-capture-output ^
  ns-process-data realitycapture --data "%IMG_DIR%" --csv "%SRC_CSV%" --output-dir "%NS_DIR%" --max_dataset_size -1 ^
  1>>"%LOG%" 2>&1
if errorlevel 1 goto :err

REM ===== (Optional) sanity: ensure transforms.json exists & has frames =====
powershell -NoProfile -Command ^
  "if (!(Test-Path '%NS_DIR%\transforms.json')){Write-Host '[ERROR] transforms.json not found'; exit 2};" ^
  "$j=Get-Content -Raw '%NS_DIR%\transforms.json'|ConvertFrom-Json;" ^
  "$n=if($j.frames){$j.frames.Count}else{0};" ^
  "if($n -lt 1){Write-Host '[ERROR] 0 frames after processing. CSV/images mismatch.'; exit 2}else{Write-Host ('[OK] Frames: ' + $n)}"
if errorlevel 2 exit /b 1

REM ===== Edit transform.json to set camera model to OPENCV to use original distorted images (you dont need to undistort images to train) =====
powershell -NoProfile -Command ^
  "$p = '%NS_DIR%\transforms.json';" ^
  "$j = Get-Content -Raw $p | ConvertFrom-Json;" ^
  "$ordered = [ordered]@{};" ^
  "$ordered['ply_file_path'] = 'pointcloud.ply';" ^
  "$ordered['camera_model']  = 'OPENCV';" ^
  "foreach($name in $j.PSObject.Properties.Name){" ^
  "  if($name -eq 'orientation_override' -or $name -eq 'camera_model'){ continue }" ^
  "  $ordered[$name] = $j.$name" ^
  "}" ^
  "$utf8NoBom = New-Object System.Text.UTF8Encoding($false);" ^
  "[System.IO.File]::WriteAllText($p, (ConvertTo-Json $ordered -Depth 100), $utf8NoBom)"

:err
echo [FAIL] See log: "%LOG%"
exit /b 1

REM ===== Helper =====
:find_conda
set "CAND_ROOT=%~1"
if exist "%CAND_ROOT%\condabin\conda.bat" set "CONDA_BAT=%CAND_ROOT%\condabin\conda.bat"
exit /b 0
