:: Import images, align, save project with folder-based ProjectName
:: Export image poses (Registeration) and sfm point cloud for Gaussian Splatting in NerfStudio

@echo on
setlocal enabledelayedexpansion

set "QUIT_FLAG="
if /I "%~1"=="autoquit" set "QUIT_FLAG=-quit"


:: root folder of this script
set "RootFolder=%~dp0"
set "SCRIPT_DIR=%RootFolder:~0,-1%"
for %%A in ("%SCRIPT_DIR%\..") do set "ROOT=%%~fA"

:: extract the root folder name (remove trailing backslash, get last folder name)
for %%i in ("%ROOT%") do set "ProjectName=%%~nxi"
set "ROOT_NAME=%ProjectName%"

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

set "ProjectName=%PROJECT_NAME%"
set "Images=%IMAGE_DIR%"
set "NSFolder=%NS_DIR%"
set "RealityCaptureExe=%REALITYSCAN_EXE%"

:: define RC output folder and create it if missing
set "RCFolder=%ROOT%\RC"
if not exist "%RCFolder%" mkdir "%RCFolder%"

:: define RC output folder and create it if missing
if not exist "%NSFolder%" mkdir "%NSFolder%"

:: set paths
set "SettingsFolder=%SCRIPT_DIR%\misc\Settings"
set "Project=%RCFolder%\%ProjectName%.rsproj"

:: run RealityCapture
"%RealityCaptureExe%" -newScene ^
    -set "appIncSubdirs=true" ^
    -addFolder "%Images%" ^
	-selectAllImages ^
	-setConstantCalibrationGroups ^
    -align ^
	-save "%Project%" ^
    -selectMaximalComponent ^
	-selectAllImages ^
	-exportRegistration "%NSFolder%\reg.csv" "%SettingsFolder%\export-RCPoses-localCoordinate.xml" ^
	-exportSparsePointCloud "%NSFolder%\pointcloud.ply" "%SettingsFolder%\export-sfm-pointcloud-localCoordinate.xml" ^
	%QUIT_FLAG%
	
