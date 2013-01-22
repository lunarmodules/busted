@ECHO OFF
setlocal ENABLEDELAYEDEXPANSION 
for /f "delims=" %%i in ('cd') do set cwd=%%i
for %%X in (luajit.exe) do (set FOUND=%%~$PATH:X)
if defined FOUND (
  set cmd=luajit
) else (
  for %%X in (lua.exe) do (set FOUND=%%~$PATH:X)
  if defined FOUND (
    set cmd=lua
  )
)
if "%cmd%"=="" (
  echo "Busted requires that a valid execution environment be specified(or that you have lua or luajit accessible in your PATH). Aborting."
) else (
  if "%*"=="--help" set TRUE=1
  if "%*"=="--version" set TRUE=1
  if defined TRUE  (
    ("%cmd%" "%~dp0busted_bootstrap" %*)
  ) else (
    ("%cmd%" "%~dp0busted_bootstrap" --cwd="%cwd%\\" %*)
    exit /B !ERRORLEVEL!
  )
)
