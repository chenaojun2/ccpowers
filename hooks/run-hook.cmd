: << 'CMDBLOCK'
@echo off
REM 跨平台多语言封装器，用于运行钩子脚本。
REM Windows 上：cmd.exe 运行批处理部分，找到并调用 bash。
REM Unix 上：shell 将此解释为脚本（: 在 bash 中是空操作）。
REM
REM 用法：run-hook.cmd <脚本名> [参数...]

if "%~1"=="" (
    echo run-hook.cmd: 缺少脚本名 >&2
    exit /b 1
)

set "HOOK_DIR=%~dp0"

REM 尝试 Git for Windows 标准路径下的 bash
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

REM 尝试 PATH 中的 bash
where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    bash "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

REM 未找到 bash - 静默退出
exit /b 0
CMDBLOCK

# Unix：直接运行指定脚本
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
