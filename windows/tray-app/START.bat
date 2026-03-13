@echo off
cd /d "%~dp0"
if not exist node_modules (
    echo Installing dependencies...
    npm install --silent
)
npx electron .
