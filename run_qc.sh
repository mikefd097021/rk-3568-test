#!/bin/bash

# RK-3568 QC Test - One-Click Runner
# 一鍵運行 QC 測試系統，自動處理所有前置設置

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'    # 改為亮青色，更容易看清
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Get script directory (works even when run from USB)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
echo -e "\n"
echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║     RK-3568 QC 一鍵測試系統         ║${NC}"
echo -e "${PURPLE}║         自動化啟動程序               ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
echo

# Function to check and request root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}正在自動獲取 root 權限...${NC}"
        # 使用管道將密碼傳給 sudo -S 並重新執行腳本
        echo "fdtuser1" | sudo -S bash "$0" "$@"
        exit $?
    fi
    # 重新將 stdin 導向 TTY，否則後續的 read 命令會讀到管道剩餘的內容而跳出
    exec 0</dev/tty 2>/dev/null || true
    echo -e "${GREEN}✓ Root 權限確認${NC}"
}

# Function to auto-setup permissions
setup_permissions() {
    echo -e "${CYAN}自動設置執行權限與所有權...${NC}"

    # 如果是 root 執行，將目錄所有權交還給 user1，方便桌面操作
    if [ "$EUID" -eq 0 ]; then
        chown -R user1:user1 "$SCRIPT_DIR" 2>/dev/null
        echo -e "${GREEN}✓ 目錄所有權已更正為 user1${NC}"
    fi

    # Set execute permissions for all scripts
    chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null

    # Set GPIO permissions if available
    if [ -d "/sys/class/gpio" ]; then
        chmod 666 /sys/class/gpio/export 2>/dev/null
        chmod 666 /sys/class/gpio/unexport 2>/dev/null
        echo -e "${GREEN}✓ GPIO 權限設置完成${NC}"
    fi

    echo -e "${GREEN}✓ 權限設置完成${NC}"
}

# Function to install missing dependencies
install_dependencies() {
    echo -e "${CYAN}檢查並安裝必要依賴...${NC}"

    # Check if apt is available
    if which apt >/dev/null 2>&1; then
        # Update package list quietly
        apt update >/dev/null 2>&1

        # Install basic tools if missing
        local packages_to_install=""

        if ! which ping >/dev/null 2>&1; then
            packages_to_install="$packages_to_install iputils-ping"
        fi

        if ! which i2cdetect >/dev/null 2>&1; then
            packages_to_install="$packages_to_install i2c-tools"
        fi

        if [ -n "$packages_to_install" ]; then
            echo -e "${BLUE}安裝缺失的軟體包: $packages_to_install${NC}"
            apt install -y $packages_to_install >/dev/null 2>&1
        fi
    fi

    echo -e "${GREEN}✓ 依賴檢查完成${NC}"
}

# Function to setup network interfaces
setup_network() {
    echo -e "${CYAN}自動配置網路介面...${NC}"

    # Configure eth0 if exists
    if ip link show eth0 >/dev/null 2>&1; then
        ip link set eth0 up 2>/dev/null
        # Try to get IP via DHCP first, if fails use static
        if ! timeout 5 dhclient eth0 >/dev/null 2>&1; then
            ip addr add 192.168.8.100/24 dev eth0 2>/dev/null
        fi
        echo -e "${GREEN}✓ eth0 配置完成${NC}"
    fi

    # Configure eth1 if exists
    if ip link show eth1 >/dev/null 2>&1; then
        ip link set eth1 up 2>/dev/null
        # Try to get IP via DHCP first, if fails use static
        if ! timeout 5 dhclient eth1 >/dev/null 2>&1; then
            ip addr add 192.168.8.101/24 dev eth1 2>/dev/null
        fi
        echo -e "${GREEN}✓ eth1 配置完成${NC}"
    fi
}

# Function to setup mount points
setup_mount_points() {
    echo -e "${CYAN}設置存儲掛載點...${NC}"

    # Create mount directories
    mkdir -p /media/user1/usb 2>/dev/null
    mkdir -p /media/user1/sdcard 2>/dev/null

    # Auto-mount USB devices
    for device in /dev/sd[a-z]1; do
        if [ -b "$device" ]; then
            mount "$device" /media/user1/usb 2>/dev/null && \
            echo -e "${GREEN}✓ USB 設備已掛載: $device${NC}" && break
        fi
    done

    # Auto-mount SD card
    for device in /dev/mmcblk[0-9]p1; do
        if [ -b "$device" ] && [[ "$device" != *"mmcblk0"* ]]; then
            mount "$device" /media/user1/sdcard 2>/dev/null && \
            echo -e "${GREEN}✓ SD卡已掛載: $device${NC}" && break
        fi
    done

    echo -e "${GREEN}✓ 掛載點設置完成${NC}"
}

# Function to find and setup test tools
setup_test_tools() {
    echo -e "${CYAN}查找測試工具...${NC}"

    # Test tools to find
    local tools=("fltest_uarttest" "fltest_spidev_test" "fltest_keytest")

    for tool in "${tools[@]}"; do
        # 首先使用 which 命令檢查工具是否在 PATH 中
        if which "$tool" >/dev/null 2>&1; then
            local tool_path=$(which "$tool")
            echo -e "${GREEN}✓ 找到 $tool 於 $tool_path${NC}"
        else
            # 如果 which 找不到，再檢查特定路徑
            local found=false
            local tool_paths=(
                "/usr/bin"
                "/usr/local/bin"
                "/opt/forlinx/bin"
                "/home/user1"
                "$SCRIPT_DIR"
                "$SCRIPT_DIR/tools"
            )

            for path in "${tool_paths[@]}"; do
                if [ -x "$path/$tool" ]; then
                    # Add to PATH if not already there
                    if [[ ":$PATH:" != *":$path:"* ]]; then
                        export PATH="$path:$PATH"
                    fi
                    echo -e "${GREEN}✓ 找到 $tool 於 $path${NC}"
                    found=true
                    break
                fi
            done

            if [ "$found" = false ]; then
                echo -e "${YELLOW}⚠ 未找到 $tool，相關測試可能失敗${NC}"
            fi
        fi
    done
}

# Function to create desktop shortcut (optional)
create_shortcut() {
    local desktop_dir="/home/user1/Desktop"
    if [ -d "$desktop_dir" ]; then
        cat > "$desktop_dir/QC_Test.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=RK-3568 QC Test
Comment=一鍵 QC 測試
Exec=bash $SCRIPT_DIR/run_qc.sh
Icon=utilities-system-monitor
Terminal=true
Categories=System;
EOF
        chmod +x "$desktop_dir/QC_Test.desktop"
        echo -e "${GREEN}✓ 桌面快捷方式已創建${NC}"
    fi
}

# Function to run environment check
run_environment_check() {
    echo -e "${CYAN}執行環境檢查...${NC}"

    if [ -f "$SCRIPT_DIR/check_environment.sh" ]; then
        bash "$SCRIPT_DIR/check_environment.sh" | grep -E "(✓|✗|⚠)" | head -10
    else
        echo -e "${YELLOW}⚠ 環境檢查腳本不存在${NC}"
    fi
    echo
}

# Function to run QC test
run_qc_test() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${WHITE}開始執行 QC 測試${NC}"
    echo -e "${CYAN}================================${NC}"

    if [ -f "$SCRIPT_DIR/qc_test.sh" ]; then
        bash "$SCRIPT_DIR/qc_test.sh"
        echo
        echo -e "${GREEN}QC 測試執行完成${NC}"
    else
        echo -e "${RED}❌ QC 測試腳本不存在: $SCRIPT_DIR/qc_test.sh${NC}"
        read -p "按 Enter 鍵關閉程序..."
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo -e "${CYAN}使用方法：${NC}"
    echo -e "${WHITE}  $0 [選項]${NC}"
    echo
    echo -e "${CYAN}選項：${NC}"
    echo -e "${WHITE}  --check-only    只執行環境檢查${NC}"
    echo -e "${WHITE}  --setup-only    只執行環境設置${NC}"
    echo -e "${WHITE}  --test-only     只執行 QC 測試${NC}"
    echo -e "${WHITE}  --quick         執行快速測試 (減少測試時間)${NC}"
    echo -e "${WHITE}  --help          顯示此幫助${NC}"
    echo
    echo -e "${CYAN}預設行為：執行完整的設置和測試流程${NC}"
}

# Main execution
main() {
    local check_only=false
    local setup_only=false
    local test_only=false
    local quick_test=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check-only)
                check_only=true
                shift
                ;;
            --setup-only)
                setup_only=true
                shift
                ;;
            --test-only)
                test_only=true
                shift
                ;;
            --quick)
                quick_test=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}未知選項: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done

    # Check root privileges
    check_root "$@"

    echo -e "${BLUE}工作目錄: $SCRIPT_DIR${NC}"
    echo

    if [ "$quick_test" = true ]; then
        # Run quick test
        setup_permissions
        echo -e "${CYAN}執行快速測試模式...${NC}"
        echo
        if [ -f "$SCRIPT_DIR/qc_test_quick.sh" ]; then
            bash "$SCRIPT_DIR/qc_test_quick.sh"
            echo
            echo -e "${GREEN}快速測試執行完成${NC}"
        else
            echo -e "${RED}❌ 快速測試腳本不存在: $SCRIPT_DIR/qc_test_quick.sh${NC}"
            read -p "按 Enter 鍵關閉程序..."
            exit 1
        fi
    elif [ "$test_only" = true ]; then
        # Only run QC test
        run_qc_test
    elif [ "$check_only" = true ]; then
        # Only run environment check
        run_environment_check
        echo
        read -p "按 Enter 鍵關閉程序..."
    elif [ "$setup_only" = true ]; then
        # Only run setup
        setup_permissions
        install_dependencies
        setup_network
        setup_mount_points
        setup_test_tools
        create_shortcut
        echo -e "${GREEN}🎉 環境設置完成！${NC}"
        echo
        read -p "按 Enter 鍵關閉程序..."
    else
        # Full workflow
        echo -e "${CYAN}執行完整的一鍵設置和測試流程...${NC}"
        echo

        # Setup phase
        setup_permissions
        install_dependencies
        setup_network
        setup_mount_points
        setup_test_tools
        create_shortcut

        echo
        echo -e "${GREEN}✓ 環境設置完成${NC}"
        echo

        # Quick environment check
        run_environment_check

        # Ask user if they want to proceed
        echo -e "${YELLOW}是否立即開始 QC 測試？ (y/n): ${NC}"
        read -r response
        case "$response" in
            [Yy]|[Yy][Ee][Ss]|"")
                run_qc_test
                ;;
            *)
                echo -e "${BLUE}測試已取消。您可以稍後執行：${NC}"
                echo -e "${WHITE}  sudo bash $SCRIPT_DIR/run_qc.sh --test-only${NC}"
                ;;
        esac
    fi
}

# Trap to cleanup on exit
trap 'echo -e "\n${YELLOW}程序已中斷${NC}"' INT TERM

# Run main function with all arguments
main "$@"
