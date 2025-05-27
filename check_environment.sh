#!/bin/bash

# RK-3568 QC Test Environment Check Script
# This script verifies that all required tools and permissions are available

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'    # 改為亮青色，更容易看清
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║     RK-3568 QC 環境檢查工具         ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
echo

# Check if running as root
echo -e "${CYAN}檢查執行權限...${NC}"
if [ "$EUID" -eq 0 ]; then
    echo -e "${GREEN}✓ Root 權限確認${NC}"
else
    echo -e "${RED}✗ 需要 Root 權限${NC}"
    echo -e "${YELLOW}  請使用: sudo $0${NC}"
fi
echo

# Check system information
echo -e "${CYAN}系統資訊檢查...${NC}"
echo -e "${BLUE}系統版本: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")${NC}"
echo -e "${BLUE}核心版本: $(uname -r)${NC}"
echo -e "${BLUE}架構: $(uname -m)${NC}"
echo

# Check required commands
echo -e "${CYAN}檢查必要命令...${NC}"

commands=(
    "ping:網路測試"
    "dd:存儲測試"
    "date:時間測試"
    "hwclock:硬體時鐘"
    "timeout:超時控制"
)

for cmd_info in "${commands[@]}"; do
    cmd="${cmd_info%%:*}"
    desc="${cmd_info##*:}"
    if which "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $cmd ($desc)${NC}"
    else
        echo -e "${RED}✗ $cmd ($desc) - 未找到${NC}"
    fi
done
echo

# Check optional test tools
echo -e "${CYAN}檢查測試工具...${NC}"

test_tools=(
    "fltest_uarttest:UART測試工具"
    "fltest_spidev_test:SPI測試工具"
    "fltest_keytest:按鍵測試工具"
    "i2cdetect:I2C檢測工具"
)

for tool_info in "${test_tools[@]}"; do
    tool="${tool_info%%:*}"
    desc="${tool_info##*:}"
    if which "$tool" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $tool ($desc)${NC}"
        echo -e "${BLUE}  路徑: $(which "$tool")${NC}"
    else
        echo -e "${YELLOW}⚠ $tool ($desc) - 未找到${NC}"
        echo -e "${BLUE}  建議檢查路徑: /usr/local/bin/, /opt/forlinx/bin/, /home/user1/${NC}"
    fi
done
echo

# Check GPIO system
echo -e "${CYAN}檢查 GPIO 系統...${NC}"
if [ -d "/sys/class/gpio" ]; then
    echo -e "${GREEN}✓ GPIO 系統可用${NC}"
    echo -e "${BLUE}  路徑: /sys/class/gpio${NC}"

    # Test GPIO export capability
    if [ -w "/sys/class/gpio/export" ]; then
        echo -e "${GREEN}✓ GPIO export 可寫${NC}"
    else
        echo -e "${RED}✗ GPIO export 不可寫${NC}"
    fi
else
    echo -e "${RED}✗ GPIO 系統不可用${NC}"
fi
echo

# Check LCD backlight system
echo -e "${CYAN}檢查 LCD 背光系統...${NC}"
backlight_path="/sys/class/backlight/lvds-backlight/brightness"
max_brightness_path="/sys/class/backlight/lvds-backlight/max_brightness"

if [ -f "$backlight_path" ]; then
    echo -e "${GREEN}✓ LCD 背光控制可用${NC}"
    echo -e "${BLUE}  亮度控制: $backlight_path${NC}"

    # Check if writable
    if [ -w "$backlight_path" ]; then
        echo -e "${GREEN}✓ 背光控制可寫${NC}"
    else
        echo -e "${RED}✗ 背光控制不可寫${NC}"
    fi

    # Show current and max brightness
    if [ -f "$max_brightness_path" ]; then
        current_brightness=$(cat "$backlight_path" 2>/dev/null)
        max_brightness=$(cat "$max_brightness_path" 2>/dev/null)
        echo -e "${BLUE}  當前亮度: $current_brightness / $max_brightness${NC}"
    fi
else
    echo -e "${YELLOW}⚠ LCD 背光控制不可用${NC}"
    echo -e "${BLUE}  檢查路徑: /sys/class/backlight/*/brightness${NC}"
    # Try to find alternative backlight paths
    backlight_dirs=$(find /sys/class/backlight -name "brightness" 2>/dev/null | head -3)
    if [ -n "$backlight_dirs" ]; then
        echo -e "${BLUE}  找到的背光控制:${NC}"
        echo "$backlight_dirs" | while read -r path; do
            echo -e "${BLUE}    $path${NC}"
        done
    fi
fi
echo

# Check network interfaces
echo -e "${CYAN}檢查網路介面...${NC}"
interfaces=(eth0 eth1)
for iface in "${interfaces[@]}"; do
    if ip link show "$iface" >/dev/null 2>&1; then
        status=$(ip link show "$iface" | grep -o "state [A-Z]*" | cut -d' ' -f2)
        echo -e "${GREEN}✓ $iface 存在 (狀態: $status)${NC}"
    else
        echo -e "${RED}✗ $iface 不存在${NC}"
    fi
done
echo

# Check storage paths
echo -e "${CYAN}檢查存儲路徑...${NC}"

# Check current directory write permission
if [ -w "." ]; then
    echo -e "${GREEN}✓ 當前目錄可寫 (eMMC 測試)${NC}"
else
    echo -e "${RED}✗ 當前目錄不可寫${NC}"
fi

# Check USB/SD mount points
usb_path="/media/user1/usb"
sd_path="/media/user1/sdcard"

if [ -d "$usb_path" ]; then
    if [ "$(ls -A "$usb_path" 2>/dev/null)" ]; then
        echo -e "${GREEN}✓ USB 設備已掛載: $usb_path${NC}"
    else
        echo -e "${YELLOW}⚠ USB 路徑存在但為空: $usb_path${NC}"
    fi
else
    echo -e "${YELLOW}⚠ USB 路徑不存在: $usb_path${NC}"
fi

if [ -d "$sd_path" ]; then
    if [ "$(ls -A "$sd_path" 2>/dev/null)" ]; then
        echo -e "${GREEN}✓ SD卡已掛載: $sd_path${NC}"
    else
        echo -e "${YELLOW}⚠ SD卡路徑存在但為空: $sd_path${NC}"
    fi
else
    echo -e "${YELLOW}⚠ SD卡路徑不存在: $sd_path${NC}"
fi
echo

# Check device files
echo -e "${CYAN}檢查設備文件...${NC}"

devices=(
    "/dev/ttyS3:UART3設備"
    "/dev/ttyS4:UART4設備"
    "/dev/spidev0.0:SPI設備"
)

for dev_info in "${devices[@]}"; do
    dev="${dev_info%%:*}"
    desc="${dev_info##*:}"
    if [ -e "$dev" ]; then
        echo -e "${GREEN}✓ $dev ($desc)${NC}"
    else
        echo -e "${YELLOW}⚠ $dev ($desc) - 不存在${NC}"
    fi
done
echo

# Check input devices for key testing
echo -e "${CYAN}檢查輸入設備...${NC}"
if [ -d "/dev/input" ]; then
    input_devices=$(ls /dev/input/event* 2>/dev/null | wc -l)
    if [ "$input_devices" -gt 0 ]; then
        echo -e "${GREEN}✓ 找到 $input_devices 個輸入設備${NC}"
        ls /dev/input/event* 2>/dev/null | head -3 | while read -r device; do
            echo -e "${BLUE}  $device${NC}"
        done
    else
        echo -e "${YELLOW}⚠ 未找到輸入設備${NC}"
    fi
else
    echo -e "${RED}✗ /dev/input 目錄不存在${NC}"
fi
echo

# Summary
echo -e "${CYAN}================================${NC}"
echo -e "${WHITE}環境檢查總結${NC}"
echo -e "${CYAN}================================${NC}"

# Count issues
critical_issues=0
warnings=0

# Check critical requirements
if [ "$EUID" -ne 0 ]; then
    critical_issues=$((critical_issues + 1))
fi

if ! which ping >/dev/null 2>&1; then
    critical_issues=$((critical_issues + 1))
fi

if ! which dd >/dev/null 2>&1; then
    critical_issues=$((critical_issues + 1))
fi

if [ ! -d "/sys/class/gpio" ]; then
    critical_issues=$((critical_issues + 1))
fi

# Check warnings
if ! which fltest_uarttest >/dev/null 2>&1; then
    warnings=$((warnings + 1))
fi

if ! which fltest_spidev_test >/dev/null 2>&1; then
    warnings=$((warnings + 1))
fi

if ! which fltest_keytest >/dev/null 2>&1; then
    warnings=$((warnings + 1))
fi

if ! which i2cdetect >/dev/null 2>&1; then
    warnings=$((warnings + 1))
fi

echo -e "${BLUE}關鍵問題: $critical_issues${NC}"
echo -e "${YELLOW}警告: $warnings${NC}"
echo

if [ $critical_issues -eq 0 ]; then
    if [ $warnings -eq 0 ]; then
        echo -e "${GREEN}🎉 環境檢查完全通過！可以執行 QC 測試。${NC}"
    else
        echo -e "${YELLOW}⚠️  環境基本滿足要求，但有 $warnings 個警告。${NC}"
        echo -e "${YELLOW}   某些測試項目可能會失敗，但不影響基本功能。${NC}"
    fi
    echo
    echo -e "${CYAN}執行 QC 測試：${NC}"
    echo -e "${WHITE}sudo ./qc_test.sh${NC}"
else
    echo -e "${RED}❌ 發現 $critical_issues 個關鍵問題，請先解決後再執行 QC 測試。${NC}"
fi

echo
