@echo off
cd /d %~dp0../
call lua bin/busted_bootstrap.lua %*
