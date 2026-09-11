@echo off
echo Dang khac phuc loi Git index...
if exist .git\index del /f /q .git\index
git reset
git status
echo.
echo Da khac phuc loi Git index thanh cong!
pause
