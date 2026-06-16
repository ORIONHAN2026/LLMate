@echo off
chcp 65001 >nul
echo ============================================
echo   LLMWork Windows 打包脚本
echo ============================================
echo.

:: 检查 Inno Setup 是否安装
set "ISCC="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
)
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set "ISCC=C:\Program Files\Inno Setup 6\ISCC.exe"
)
if "%ISCC%"=="" (
    echo [警告] 未找到 Inno Setup 6，将只生成绿色版压缩包
    echo 如需生成安装包，请安装 Inno Setup: https://jrsoftware.org/isinfo.php
    echo.
    set "HAS_INNO=0"
) else (
    echo [检测] Inno Setup: %ISCC%
    set "HAS_INNO=1"
)

:: 清理旧构建
echo [1/4] 清理旧构建...
if exist "build\windows\x64\Release" (
    rmdir /s /q "build\windows\x64\Release"
)
if exist "LLMWork_windows" (
    rmdir /s /q "LLMWork_windows"
)
if exist "LLMWork_Setup.exe" (
    del /q "LLMWork_Setup.exe"
)

:: 编译 Release 版本
echo [2/4] 编译 Release 版本...
flutter build windows --release
if errorlevel 1 (
    echo 编译失败！
    pause
    exit /b 1
)

:: 复制到打包目录
echo [3/4] 复制打包文件...
mkdir "LLMWork_windows"
xcopy /e /i /y "build\windows\x64\Release" "LLMWork_windows"

:: 生成安装包
if "%HAS_INNO%"=="1" (
    echo [4/4] 生成安装包...

    :: 生成 Inno Setup 脚本
    set "ISS_FILE=installer_script.iss"
    (
        echo #define MyAppName "LLMWork"
        echo #define MyAppVersion "1.0.0"
        echo #define MyAppPublisher "LLMWork"
        echo #define MyAppURL "https://llmwork.app"
        echo #define MyAppExeName "LLMWork.exe"
        echo.
        echo [Setup]
        echo AppId={{B8F5A1D2-3E4C-5A6B-7C8D-9E0F1A2B3C4D}
        echo AppName={#MyAppName}
        echo AppVersion={#MyAppVersion}
        echo AppPublisher={#MyAppPublisher}
        echo AppPublisherURL={#MyAppURL}
        echo AppSupportURL={#MyAppURL}
        echo DefaultDirName={autopf}\{#MyAppName}
        echo DefaultGroupName={#MyAppName}
        echo AllowNoIcons=yes
        echo OutputDir=.
        echo OutputBaseFilename=LLMWork_Setup
        echo Compression=lzma
        echo SolidCompression=yes
        echo WizardStyle=modern
        echo PrivilegesRequired=lowest
        echo UninstallDisplayName={#MyAppName}
        echo UninstallDisplayIcon={app}\{#MyAppExeName}
        echo.
        echo [Languages]
        echo Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
        echo Name: "english"; MessagesFile: "compiler:Default.isl"
        echo.
        echo [Tasks]
        echo Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
        echo.
        echo [Files]
        echo Source: "LLMWork_windows\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
        echo.
        echo [Icons]
        echo Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
        echo Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
        echo Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
        echo.
        echo [Run]
        echo Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
    ) > "%ISS_FILE%"

    "%ISCC%" "%ISS_FILE%"
    if errorlevel 1 (
        echo 安装包生成失败！
        del "%ISS_FILE%"
        pause
        exit /b 1
    )
    del "%ISS_FILE%"
    echo.
    echo ============================================
    echo   打包完成！
    echo   安装包: LLMWork_Setup.exe
    echo   绿色版: LLMWork_windows\
    echo ============================================
) else (
    echo [4/4] 跳过安装包生成
    echo.
    echo ============================================
    echo   打包完成！
    echo   绿色版: LLMWork_windows\
    echo   可执行文件: LLMWork_windows\LLMWork.exe
    echo.
    echo   提示: 安装 Inno Setup 后可生成 .exe 安装包
    echo   https://jrsoftware.org/isinfo.php
    echo ============================================
)
pause
