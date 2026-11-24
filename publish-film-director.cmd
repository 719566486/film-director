@echo off
setlocal
title Publish film-director to GitHub
set "publisher=%~dp0publish-film-director.ps1"
if not exist "%publisher%" set "publisher=%~dp0film-director\publish-film-director.ps1"
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%publisher%"
set "publishResult=%ERRORLEVEL%"
pause
exit /b %publishResult%
