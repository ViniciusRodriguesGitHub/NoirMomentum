@echo off
where godot >nul 2>nul
if errorlevel 1 (
  echo O comando godot nao foi encontrado.
  echo Feche e abra novamente o PowerShell ou abra o projeto pela Godot.
  pause
  exit /b 1
)

start "" godot --editor --path "%~dp0"

