@echo off
setlocal

rem ============================================================
rem  FrameVision Timeline Editor - simple launcher
rem ============================================================

set "ROOT=%~dp0"
set "ENV_DIR=%ROOT%environments\timeline_editor"
set "PYTHON_EXE=%ENV_DIR%\python.exe"
set "BIN_DIR=%ROOT%presets\bin"
set "EDITOR_FILE=%ROOT%helpers\timeline_editor.py"

if /I "%~1"=="--self-test" goto SELF_TEST

echo.
echo Starting FrameVision Timeline Editor...
echo.

if not exist "%PYTHON_EXE%" goto ERR_NO_ENV
if not exist "%EDITOR_FILE%" goto ERR_NO_EDITOR
if not exist "%BIN_DIR%\ffmpeg.exe" goto WARN_NO_FFMPEG
if not exist "%BIN_DIR%\ffprobe.exe" goto WARN_NO_FFMPEG_AFTER

:RUN_EDITOR
set "PATH=%BIN_DIR%;%ENV_DIR%;%ENV_DIR%\Scripts;%PATH%"
cd /d "%ROOT%"
"%PYTHON_EXE%" "%EDITOR_FILE%"
if errorlevel 1 goto ERR_EDITOR_EXIT
exit /b 0

:WARN_NO_FFMPEG
echo WARNING: ffmpeg.exe was not found in presets\bin.
echo Export/media features may fail. Run install.bat again to repair it.
echo.
goto RUN_EDITOR

:WARN_NO_FFMPEG_AFTER
echo WARNING: ffprobe.exe was not found in presets\bin.
echo Media probing may fail. Run install.bat again to repair it.
echo.
goto RUN_EDITOR

:SELF_TEST
echo.
echo ============================================================
echo  FrameVision Timeline Editor run self-test
echo ============================================================
echo.
echo Root path:
echo   %ROOT%
echo.
if not exist "%EDITOR_FILE%" goto ERR_NO_EDITOR
if not exist "%PYTHON_EXE%" goto ERR_NO_ENV
"%PYTHON_EXE%" -c "import PySide6, numpy, PIL; print('Python packages OK')"
if errorlevel 1 goto ERR_PY_TEST
if not exist "%BIN_DIR%\ffmpeg.exe" goto ERR_NO_FFMPEG
if not exist "%BIN_DIR%\ffprobe.exe" goto ERR_NO_FFMPEG
"%BIN_DIR%\ffmpeg.exe" -version >nul 2>nul
if errorlevel 1 goto ERR_NO_FFMPEG
echo OK: env, packages, editor file, and FFmpeg were found.
echo.
pause
exit /b 0

:ERR_NO_ENV
echo.
echo ERROR: Local Python env was not found:
echo   %PYTHON_EXE%
echo.
echo Run install.bat first.
echo.
pause
exit /b 1

:ERR_NO_EDITOR
echo.
echo ERROR: Could not find:
echo   %EDITOR_FILE%
echo Make sure run.bat is in the repo root folder.
echo.
pause
exit /b 1

:ERR_NO_FFMPEG
echo.
echo ERROR: FFmpeg was not found or could not run in:
echo   %BIN_DIR%
echo Run install.bat again.
echo.
pause
exit /b 1

:ERR_PY_TEST
echo.
echo ERROR: Python package test failed.
echo Needed packages: PySide6 numpy pillow
echo Run install.bat again.
echo.
pause
exit /b 1

:ERR_EDITOR_EXIT
echo.
echo ERROR: Timeline editor closed with an error.
echo.
pause
exit /b 1
