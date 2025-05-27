@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ╔══════════════════════════════════════╗
echo ║     RK-3568 QC 測試系統             ║
echo ║        USB 準備工具                  ║
echo ╚══════════════════════════════════════╝
echo.

:: 檢查是否在正確的目錄
if not exist "run_qc.sh" (
    echo ❌ 錯誤：請在包含 QC 測試文件的目錄中執行此批次檔
    echo.
    echo 確保以下文件存在：
    echo   - run_qc.sh
    echo   - qc_test.sh
    echo   - check_environment.sh
    echo.
    pause
    exit /b 1
)

echo ✓ 檢測到 QC 測試文件
echo.

:: 顯示可用的磁碟機
echo 可用的磁碟機：
for /f "skip=1 tokens=1,2" %%a in ('wmic logicaldisk get size^,caption') do (
    if not "%%a"=="" (
        set /a size_gb=%%b/1024/1024/1024 2>nul
        if !size_gb! gtr 0 (
            echo   %%a - 大小: !size_gb! GB
        )
    )
)
echo.

:: 讓用戶選擇目標磁碟機
set /p target_drive="請輸入目標 USB 磁碟機代號 (例如: E): "

:: 驗證磁碟機
if not exist "%target_drive%\" (
    echo ❌ 錯誤：磁碟機 %target_drive% 不存在
    pause
    exit /b 1
)

:: 確認操作
echo.
echo ⚠️  警告：將會複製 QC 測試系統到 %target_drive%\rk-3568-test\
echo.
set /p confirm="確定要繼續嗎？ (Y/N): "
if /i not "%confirm%"=="Y" (
    echo 操作已取消
    pause
    exit /b 0
)

:: 創建目標目錄
set target_dir=%target_drive%\rk-3568-test
echo.
echo 📁 創建目標目錄: %target_dir%
if exist "%target_dir%" (
    echo ⚠️  目標目錄已存在，將會覆蓋
    rmdir /s /q "%target_dir%" 2>nul
)
mkdir "%target_dir%" 2>nul

:: 複製文件
echo.
echo 📋 複製 QC 測試文件...

set files_to_copy=run_qc.sh qc_test.sh check_environment.sh README_SIMPLE.md README_QC.md DEPLOYMENT.md Makefile plan.md

for %%f in (%files_to_copy%) do (
    if exist "%%f" (
        echo   複製 %%f...
        copy "%%f" "%target_dir%\" >nul 2>&1
        if !errorlevel! equ 0 (
            echo     ✓ 成功
        ) else (
            echo     ❌ 失敗
        )
    ) else (
        echo   ⚠️  文件不存在: %%f
    )
)

:: 創建使用說明文件
echo.
echo 📝 創建快速使用說明...
(
echo RK-3568 QC 測試系統 - 快速使用指南
echo =====================================
echo.
echo 1. 將此 USB 插入 RK-3568 開發板
echo.
echo 2. 在 RK-3568 上執行以下命令：
echo    cd /media/user1/usb/rk-3568-test
echo    sudo bash run_qc.sh
echo.
echo 3. 按照螢幕提示完成測試
echo.
echo 詳細說明請參考 README_SIMPLE.md
echo.
echo 生成時間: %date% %time%
) > "%target_dir%\使用說明.txt"

:: 創建 Linux 快速啟動腳本
echo.
echo 🚀 創建 Linux 快速啟動腳本...
(
echo #!/bin/bash
echo # RK-3568 QC 測試快速啟動腳本
echo # 自動檢測 USB 掛載點並執行測試
echo.
echo echo "正在查找 QC 測試系統..."
echo.
echo # 常見的 USB 掛載點
echo USB_PATHS=(
echo     "/media/user1/usb/rk-3568-test"
echo     "/media/usb/rk-3568-test"
echo     "/mnt/usb/rk-3568-test"
echo     "/media/*/rk-3568-test"
echo ^)
echo.
echo for path in "${USB_PATHS[@]}"; do
echo     if [ -f "$path/run_qc.sh" ]; then
echo         echo "找到 QC 測試系統: $path"
echo         cd "$path"
echo         sudo bash run_qc.sh
echo         exit 0
echo     fi
echo done
echo.
echo echo "❌ 未找到 QC 測試系統"
echo echo "請確認 USB 已正確掛載"
) > "%target_dir%\quick_start.sh"

:: 檢查複製結果
echo.
echo 🔍 驗證複製結果...
set success_count=0
set total_count=0

for %%f in (%files_to_copy%) do (
    set /a total_count+=1
    if exist "%target_dir%\%%f" (
        set /a success_count+=1
        echo   ✓ %%f
    ) else (
        echo   ❌ %%f
    )
)

echo.
echo 📊 複製統計：
echo   成功: !success_count! / !total_count! 個文件
echo   目標位置: %target_dir%

if !success_count! equ !total_count! (
    echo.
    echo ✅ USB 準備完成！
    echo.
    echo 📋 使用步驟：
    echo   1. 將 USB 插入 RK-3568 開發板
    echo   2. 在 RK-3568 終端執行：
    echo      cd /media/user1/usb/rk-3568-test
    echo      sudo bash run_qc.sh
    echo.
    echo 💡 提示：也可以執行 quick_start.sh 自動查找測試系統
    echo.
    
    :: 詢問是否開啟目標目錄
    set /p open_folder="是否要開啟目標目錄？ (Y/N): "
    if /i "!open_folder!"=="Y" (
        explorer "%target_dir%"
    )
) else (
    echo.
    echo ❌ 複製過程中出現錯誤，請檢查：
    echo   - USB 磁碟機是否有足夠空間
    echo   - USB 磁碟機是否可寫
    echo   - 文件是否被其他程序佔用
)

echo.
pause
