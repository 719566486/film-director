@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Publish film-director to GitHub
set "GH_PROMPT_DISABLED="
set "GH_HOST=github.com"
set "GH_PAGER=cat"
set "repoDir=%~dp0."
if not exist "%repoDir%\.git" set "repoDir=%~dp0film-director"
if not exist "%repoDir%\.git" set "repoDir=%USERPROFILE%\Documents\Codex\2026-11-24\new-chat\film-director"
if not exist "%repoDir%\.git" goto noRepo
pushd "%repoDir%" || goto noRepo
if not exist ".agents\skills\film-director\SKILL.md" goto noRepo
set "ghTool="
for /f "delims=" %%G in ('where gh.exe 2^>nul') do if not defined ghTool set "ghTool=%%G"
if not defined ghTool if exist "%ProgramFiles%\GitHub CLI\gh.exe" set "ghTool=%ProgramFiles%\GitHub CLI\gh.exe"
if defined ghTool goto auth
echo GitHub CLI is required. Windows will offer to install the official GitHub.cli package.
winget install --id GitHub.cli --exact --source winget
if errorlevel 1 goto failed
if exist "%ProgramFiles%\GitHub CLI\gh.exe" set "ghTool=%ProgramFiles%\GitHub CLI\gh.exe"
if not defined ghTool for /f "delims=" %%G in ('where gh.exe 2^>nul') do if not defined ghTool set "ghTool=%%G"
if not defined ghTool goto reopen
:auth
"%ghTool%" auth status --hostname github.com >nul 2>&1
if errorlevel 1 (
  "%ghTool%" auth login --hostname github.com --git-protocol https --web
  if errorlevel 1 goto failed
)
set "owner="
for /f "delims=" %%A in ('""%ghTool%" api user --jq .login"') do set "owner=%%A"
if not defined owner goto failed
set "dest=%owner%/film-director"
echo Publishing the local main branch to https://github.com/%dest%
set "localHead="
for /f "delims=" %%H in ('git rev-parse refs/heads/main') do set "localHead=%%H"
if not defined localHead goto failed
set "visibility="
for /f "delims=" %%V in ('""%ghTool%" repo view "%dest%" --json visibility --jq .visibility 2^>nul"') do set "visibility=%%V"
if not defined visibility goto create
if /i not "%visibility%"=="PUBLIC" goto collision
set "remoteHead="
for /f "delims=" %%H in ('""%ghTool%" api repos/%dest%/commits/main --jq .sha 2^>nul"') do set "remoteHead=%%H"
if "%remoteHead%"=="%localHead%" goto success
if defined remoteHead goto collision
if not exist ".git\film-director-created-for-%owner%" goto collision
goto push
:create
"%ghTool%" repo create "%dest%" --public --description "AI film directing skill: cinematography, animation, sound, editing and Kling storyboards."
if errorlevel 1 goto failed
echo %dest%>".git\film-director-created-for-%owner%"
:push
set "helperPath=%ghTool:\=/%"
git -c credential.helper= -c "credential.helper=! '%helperPath%' auth git-credential" push "https://github.com/%dest%.git" refs/heads/main:refs/heads/main
if errorlevel 1 goto failed
set "remoteHead="
for /f "delims=" %%H in ('""%ghTool%" api repos/%dest%/commits/main --jq .sha"') do set "remoteHead=%%H"
if not "%localHead%"=="%remoteHead%" goto failed
"%ghTool%" repo view "%dest%" --json visibility --jq .visibility | findstr /x PUBLIC >nul
if errorlevel 1 goto failed
:success
echo VERIFIED PUBLIC REPOSITORY: https://github.com/%dest%
echo Commit: %localHead%
pause
exit /b 0
:collision
echo A different repository already exists at this name. Its settings and history were preserved.
goto failed
:noRepo
echo The local film-director repository could not be located.
goto failed
:reopen
echo GitHub CLI was installed. Close this window and run this file again to refresh PATH.
goto failed
:failed
echo Publication was not verified. The message above identifies the step to retry.
pause
exit /b 1
