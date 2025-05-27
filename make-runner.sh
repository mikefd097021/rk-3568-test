#!/bin/bash

# Make Runner Script
# 此腳本允許通過雙擊文件來觸發make命令
# 使用方法：將此腳本設置為Makefile的默認打開程序

# 獲取腳本所在目錄或傳入文件的目錄
if [ "$#" -eq 0 ]; then
    # 如果沒有參數，使用腳本所在目錄
    WORK_DIR="$(dirname "$(readlink -f "$0")")"
else
    # 如果有參數（文件路徑），使用該文件所在目錄
    WORK_DIR="$(dirname "$(readlink -f "$1")")"
fi

echo "=== Make Runner ==="
echo "工作目錄: $WORK_DIR"
echo "==================="

# 切換到工作目錄
cd "$WORK_DIR" || {
    echo "錯誤：無法切換到目錄 $WORK_DIR"
    read -p "按Enter鍵關閉..."
    exit 1
}

# 檢查是否存在Makefile
if [ ! -f "Makefile" ] && [ ! -f "makefile" ]; then
    echo "錯誤：在目錄 $WORK_DIR 中找不到Makefile"
    read -p "按Enter鍵關閉..."
    exit 1
fi

# 顯示可用的make目標
echo "可用的make目標："
make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}' | sort -u | head -10

echo ""
echo "開始執行make..."
echo "=================="

# 執行make命令
if make; then
    echo ""
    echo "=================="
    echo "✅ Make執行成功！"
else
    echo ""
    echo "=================="
    echo "❌ Make執行失敗！"
fi

echo ""
read -p "按Enter鍵關閉終端..."
