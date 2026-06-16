@echo off
chcp 65001 >nul
echo ============================================
echo   LLMWork Windows 打包脚本
echo ============================================
echo.

:: 清理旧构建
echo [1/3] 清理旧构建...
if exist "build\windows\x64\Release" (
    rmdir /s /q "build\windows\x64\Release"
)
if exist "LLMWork_windows" (
    rmdir /s /q "LLMWork_windows"
)

:: 编译 Release 版本
echo [2/3] 编译 Release 版本...
flutter build windows --release
if errorlevel 1 (
    echo 编译失败！
    pause
    exit /b 1
)

:: 复制到打包目录
echo [3/3] 复制打包文件...
mkdir "LLMWork_windows"
xcopy /e /i /y "build\windows\x64\Release" "LLMWork_windows"

echo.
echo ============================================
echo   打包完成！
echo   输出目录: LLMWork_windows\
echo   可执行文件: LLMWork_windows\LLMWork.exe
echo ============================================
pause