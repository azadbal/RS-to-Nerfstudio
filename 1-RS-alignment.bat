:: Import images, align, save project with folder-based ProjectName
:: Export image poses (Registeration) and sfm point cloud for Gaussian Splatting in NerfStudio

@echo off
setlocal enabledelayedexpansion

:: path to RealityCapture application
set "RealityCaptureExe=C:\Program Files\Epic Games\RealityScan_2.0\RealityScan.exe"

:: root folder of this script
set "RootFolder=%~dp0"

:: extract the root folder name (remove trailing backslash, get last folder name)
for %%i in ("%RootFolder:~0,-1%") do set "ProjectName=%%~nxi"

:: define RC output folder and create it if missing
set "RCFolder=%RootFolder%RC"
if not exist "%RCFolder%" mkdir "%RCFolder%"

:: define RC output folder and create it if missing
set "NSFolder=%RootFolder%nerfstudio"
if not exist "%NSFolder%" mkdir "%NSFolder%"

:: set paths
set "Images=%RootFolder%images"
set "SettingsFolder=X:\FILES\RC\RC_CLI\Settings"
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
	-exportRegistration "%NSFolder%\reg.csv" "%SettingsFolder%\RC-to-NerfStudio-camParams.xml" ^
	-exportSparsePointCloud "%NSFolder%\pointcloud.ply" "%SettingsFolder%\export-sfm-pointcloud.xml"
	
