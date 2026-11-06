@echo off
setlocal
set "GODOT=D:\Program Files\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
  echo [ERROR] Godot not found: %GODOT%
  echo Edit the GODOT path in run.bat.
  pause
  exit /b 1
)
cd /d "%~dp0"
start "" "%GODOT%" --path "."
