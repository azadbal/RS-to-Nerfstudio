@echo on
setlocal ENABLEDELAYEDEXPANSION

set "ROOT=%~dp0"

echo [MASTER] Running step 1
call "%ROOT%1-RS-alignment-georeferenced.bat" autoquit

echo [MASTER] Running step 2
call "%ROOT%2-RS-to-NS-converter.bat"

echo [MASTER] Running step 3
call "%ROOT%3-Nerfstudio-train-georef-autoscaleOff.bat"

echo [MASTER] Running step 4
call "%ROOT%4-Export-latest-splat.bat"

echo [MASTER] Done running all steps (no error checks).
endlocal
exit /b 0
