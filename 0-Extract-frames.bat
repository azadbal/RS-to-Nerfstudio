@echo off
REM ============================================================
REM  FFmpeg 4fps Frame Extractor (NVIDIA accelerated)
REM  Usage: Drag and drop a video file onto this .bat
REM ============================================================

REM Get input video path from drag & drop
set "input=%~1"

REM Exit if no file provided
if "%input%"=="" (
    echo Drag a video file onto this .bat to run it.
    pause
    exit /b
)

REM Get directory and base filename
set "dir=%~dp1"
set "name=%~n1"

REM Create output folder called "frames" inside same directory
set "frames=%dir%images"
if not exist "%frames%" mkdir "%frames%"

REM Run ffmpeg using NVIDIA CUDA for decoding
echo Extracting frames at 4fps from "%~nx1" ...
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -c:v hevc_cuvid ^
 -i "%input%" ^
 -vf "fps=4,scale_cuda=-1:-1,hwdownload,format=nv12" ^
 -q:v 5 -threads 0 ^
 "%frames%\frame_%%04d.jpg"

echo.
echo Done! Frames saved in:
echo "%frames%"
pause
