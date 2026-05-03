@echo off
setlocal

rem ============================================================
rem  FrameVision Timeline Editor - simple local installer
rem ============================================================
rem  Boring BAT version. No EXE build. No PyInstaller.
rem  Creates the Python env and FFmpeg locally inside this repo.
rem
rem  Note:
rem  The normal Miniconda Windows installer refuses destination
rem  paths containing ')' . This installer uses micromamba instead:
rem  a tiny conda-compatible single exe that creates the same kind
rem  of local conda env without installing a full base conda into
rem  the repo path.
rem ============================================================

set "ROOT=%~dp0"
set "MAMBA_DIR=%ROOT%_micromamba"
set "MAMBA_ROOT=%ROOT%_micromamba_root"
set "MAMBA_EXE=%MAMBA_DIR%\micromamba.exe"
set "ENV_DIR=%ROOT%environments\timeline_editor"
set "TEMP_DIR=%ROOT%temp\installer"
set "BIN_DIR=%ROOT%presets\bin"
set "EDITOR_FILE=%ROOT%helpers\timeline_editor.py"
set "PYTHON_EXE=%ENV_DIR%\python.exe"
set "MAMBA_URL=https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-win-64"
set "FFMPEG_URL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
set "MAMBA_DOWNLOAD=%TEMP_DIR%\micromamba-win-64.exe"
set "FF_ZIP=%TEMP_DIR%\ffmpeg-master-latest-win64-gpl.zip"
set "FF_EXTRACT=%TEMP_DIR%\ffmpeg_extract"
set "MAMBA_ROOT_PREFIX=%MAMBA_ROOT%"

if /I "%~1"=="--self-test" goto SELF_TEST

echo.
echo ============================================================
echo  FrameVision Timeline Editor - simple local installer
echo ============================================================
echo.
echo Install folder:
echo   %ROOT%
echo.
echo This creates everything locally inside this folder:
echo   _micromamba\micromamba.exe
echo   _micromamba_root\
echo   environments\timeline_editor\
echo   presets\bin\ffmpeg.exe / ffprobe.exe / ffplay.exe
echo.

if not exist "%EDITOR_FILE%" goto ERR_NO_EDITOR
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
if errorlevel 1 goto ERR_MKDIR
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if errorlevel 1 goto ERR_MKDIR
if not exist "%ROOT%environments" mkdir "%ROOT%environments"
if errorlevel 1 goto ERR_MKDIR
if not exist "%MAMBA_DIR%" mkdir "%MAMBA_DIR%"
if errorlevel 1 goto ERR_MKDIR
if not exist "%MAMBA_ROOT%" mkdir "%MAMBA_ROOT%"
if errorlevel 1 goto ERR_MKDIR

where powershell >nul 2>nul
if errorlevel 1 goto ERR_NO_POWERSHELL

if exist "%MAMBA_EXE%" goto MAMBA_READY

echo [1/5] Downloading local micromamba conda helper...
set "DL_URL=%MAMBA_URL%"
set "DL_FILE=%MAMBA_DOWNLOAD%"
call :DOWNLOAD_FILE
if errorlevel 1 goto ERR_DOWNLOAD_MAMBA
copy /Y "%MAMBA_DOWNLOAD%" "%MAMBA_EXE%" >nul
if errorlevel 1 goto ERR_COPY_MAMBA

:MAMBA_READY
"%MAMBA_EXE%" --version >nul 2>nul
if errorlevel 1 goto ERR_MAMBA_BAD

echo [2/5] Creating/updating local Python 3.11 conda env...
if exist "%PYTHON_EXE%" goto ENV_READY
"%MAMBA_EXE%" create -y -p "%ENV_DIR%" -c conda-forge python=3.11 pip
if errorlevel 1 goto ERR_ENV_CREATE

:ENV_READY
echo [3/5] Installing Python packages: PySide6, numpy, pillow...
"%PYTHON_EXE%" -m pip install --upgrade pip
if errorlevel 1 goto ERR_PIP
"%PYTHON_EXE%" -m pip install PySide6 numpy pillow
if errorlevel 1 goto ERR_PIP

echo [4/5] Downloading and installing local FFmpeg bundle...
if exist "%BIN_DIR%\ffmpeg.exe" if exist "%BIN_DIR%\ffprobe.exe" if exist "%BIN_DIR%\ffplay.exe" goto FFMPEG_READY
set "DL_URL=%FFMPEG_URL%"
set "DL_FILE=%FF_ZIP%"
call :DOWNLOAD_FILE
if errorlevel 1 goto ERR_DOWNLOAD_FFMPEG
call :INSTALL_FFMPEG
if errorlevel 1 goto ERR_INSTALL_FFMPEG

:FFMPEG_READY
echo [5/5] Verifying install...
"%PYTHON_EXE%" -c "import PySide6, numpy, PIL; print('Python packages OK')"
if errorlevel 1 goto ERR_VERIFY_PY
"%BIN_DIR%\ffmpeg.exe" -version >nul 2>nul
if errorlevel 1 goto ERR_VERIFY_FFMPEG

call :CLEANUP_INSTALLER_TEMP

echo.
echo ============================================================
echo  Install finished.
echo ============================================================
echo.
echo Start the editor with:
echo   run.bat
echo.
pause
exit /b 0

:DOWNLOAD_FILE
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri $env:DL_URL -OutFile $env:DL_FILE"
exit /b %ERRORLEVEL%

:INSTALL_FFMPEG
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $zip=$env:FF_ZIP; $extract=$env:FF_EXTRACT; $bin=$env:BIN_DIR; if(Test-Path -LiteralPath $extract){Remove-Item -LiteralPath $extract -Recurse -Force}; [void](New-Item -ItemType Directory -Force -Path $extract); [void](New-Item -ItemType Directory -Force -Path $bin); Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force; foreach($n in @('ffmpeg.exe','ffprobe.exe','ffplay.exe')){$files=@(Get-ChildItem -LiteralPath $extract -Recurse -Filter $n); if($files.Count -lt 1){throw ('Missing ' + $n)}; Copy-Item -LiteralPath $files[0].FullName -Destination (Join-Path $bin $n) -Force}; Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue; Remove-Item -LiteralPath $extract -Recurse -Force -ErrorAction SilentlyContinue"
exit /b %ERRORLEVEL%

:CLEANUP_INSTALLER_TEMP
if exist "%MAMBA_DOWNLOAD%" del /F /Q "%MAMBA_DOWNLOAD%" >nul 2>nul
if exist "%FF_ZIP%" del /F /Q "%FF_ZIP%" >nul 2>nul
if exist "%FF_EXTRACT%" rmdir /S /Q "%FF_EXTRACT%" >nul 2>nul
exit /b 0

:SELF_TEST
echo.
echo ============================================================
echo  FrameVision Timeline Editor installer self-test
echo ============================================================
echo.
echo Root path:
echo   %ROOT%
echo.
if not exist "%EDITOR_FILE%" goto ERR_NO_EDITOR
where powershell >nul 2>nul
if errorlevel 1 goto ERR_NO_POWERSHELL
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
if errorlevel 1 goto ERR_SELFTEST_WRITE
echo test> "%TEMP_DIR%\self test path (1).txt"
if errorlevel 1 goto ERR_SELFTEST_WRITE
if not exist "%TEMP_DIR%\self test path (1).txt" goto ERR_SELFTEST_WRITE
del /F /Q "%TEMP_DIR%\self test path (1).txt" >nul 2>nul
echo OK: script can write inside this repo path.
echo OK: PowerShell is available for download/extract helpers.
echo OK: editor file exists.
echo OK: installer avoids Miniconda's invalid ')' destination-folder bug.
echo.
echo Self-test finished. This does not install anything.
echo.
pause
exit /b 0

:ERR_NO_EDITOR
echo.
echo ERROR: Could not find:
echo   %EDITOR_FILE%
echo Make sure install.bat is in the repo root folder.
echo.
pause
exit /b 1

:ERR_MKDIR
echo.
echo ERROR: Could not create needed local folders.
echo.
pause
exit /b 1

:ERR_NO_POWERSHELL
echo.
echo ERROR: PowerShell was not found. Windows PowerShell is needed only for download and unzip.
echo.
pause
exit /b 1

:ERR_DOWNLOAD_MAMBA
echo.
echo ERROR: Could not download micromamba.
echo URL:
echo   %MAMBA_URL%
echo.
pause
exit /b 1

:ERR_COPY_MAMBA
echo.
echo ERROR: Could not copy micromamba into:
echo   %MAMBA_EXE%
echo.
pause
exit /b 1

:ERR_MAMBA_BAD
echo.
echo ERROR: micromamba was downloaded but could not run:
echo   %MAMBA_EXE%
echo.
pause
exit /b 1

:ERR_ENV_CREATE
echo.
echo ERROR: Could not create the local Python 3.11 conda env.
echo.
pause
exit /b 1

:ERR_PIP
echo.
echo ERROR: pip package install failed.
echo Needed packages: PySide6 numpy pillow
echo.
pause
exit /b 1

:ERR_DOWNLOAD_FFMPEG
echo.
echo ERROR: Could not download FFmpeg bundle.
echo URL:
echo   %FFMPEG_URL%
echo.
pause
exit /b 1

:ERR_INSTALL_FFMPEG
echo.
echo ERROR: Could not extract/copy FFmpeg bundle.
echo Expected output:
echo   %BIN_DIR%\ffmpeg.exe
echo   %BIN_DIR%\ffprobe.exe
echo   %BIN_DIR%\ffplay.exe
echo.
pause
exit /b 1

:ERR_VERIFY_PY
echo.
echo ERROR: Python package verification failed.
echo.
pause
exit /b 1

:ERR_VERIFY_FFMPEG
echo.
echo ERROR: FFmpeg verification failed.
echo.
pause
exit /b 1

:ERR_SELFTEST_WRITE
echo.
echo ERROR: Self-test could not write a file in temp\installer.
echo This usually means a permissions or path problem.
echo.
pause
exit /b 1
