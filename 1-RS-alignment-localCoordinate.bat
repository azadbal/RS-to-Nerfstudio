:: Import images, align, save project with folder-based ProjectName
:: Export image poses (Registeration) and sfm point cloud for Gaussian Splatting in NerfStudio

@echo on
setlocal enabledelayedexpansion

set "QUIT_FLAG="
if /I "%~1"=="autoquit" set "QUIT_FLAG=-quit"


:: path to RealityCapture application
set "RealityCaptureExe=C:\Program Files\Epic Games\RealityScan_2.0\RealityScan.exe"

:: root folder of this script
set "RootFolder=%~dp0"

:: extract the root folder name (remove trailing backslash, get last folder name)
for %%i in ("%RootFolder:~0,-1%") do set "ProjectName=%%~nxi"
set "ROOT=%RootFolder:~0,-1%"
set "ROOT_NAME=%ProjectName%"

set "SETTINGS_FILE=%RootFolder%User_Settings.txt"
if exist "%SETTINGS_FILE%" (
  for /f "usebackq tokens=1* delims==" %%A in ("%SETTINGS_FILE%") do (
    if not "%%A"=="" if not "%%A:~0,1%"=="#" if not "%%A:~0,1%"==";" (
      call set "%%A=%%B"
    )
  )
)

if defined PROJECT_NAME set "ProjectName=%PROJECT_NAME%"
if defined IMAGE_DIR set "Images=%IMAGE_DIR%"
if defined NS_DIR set "NSFolder=%NS_DIR%"
if defined REALITYSCAN_EXE set "RealityCaptureExe=%REALITYSCAN_EXE%"

:: define RC output folder and create it if missing
set "RCFolder=%RootFolder%RC"
if not exist "%RCFolder%" mkdir "%RCFolder%"

:: define RC output folder and create it if missing
if not defined NSFolder set "NSFolder=%RootFolder%nerfstudio"
if not exist "%NSFolder%" mkdir "%NSFolder%"

:: set paths
if not defined Images set "Images=%RootFolder%images"
set "SettingsFolder=%RootFolder%\misc\Settings"
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
	
