#!/bin/bash

# RK-3568 QC Quick Test Script - 快速測試版本
# 減少測試時間，適合快速驗證

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'    # 亮青色，更容易看清
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Test results tracking
declare -A test_results
test_count=0
pass_count=0
fail_count=0

# Logging
LOG_FILE="/tmp/qc_quick_test_$(date +%Y%m%d_%H%M%S).log"

# Helper functions
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}================================${NC}"
    log_message "Starting test: $1"
}

print_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"

    test_count=$((test_count + 1))
    test_results["$test_name"]="$result"

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ $test_name: PASS${NC}"
        [ -n "$details" ] && echo -e "  ${BLUE}Details: $details${NC}"
        pass_count=$((pass_count + 1))
        log_message "$test_name: PASS - $details"
    else
        echo -e "${RED}✗ $test_name: FAIL${NC}"
        [ -n "$details" ] && echo -e "  ${YELLOW}Details: $details${NC}"
        fail_count=$((fail_count + 1))
        log_message "$test_name: FAIL - $details"
    fi
    echo
}

ask_user() {
    local question="$1"
    local response
    echo -e "${YELLOW}$question (y/n): ${NC}"
    read -r response
    case "$response" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# Quick test functions
test_network_quick() {
    print_header "網路連線測試 (快速)"

    # Test eth0 with fewer pings
    echo -e "${BLUE}測試 eth0 連線...${NC}"
    if timeout 10 ping -I eth0 192.168.8.1 -c 1 -W 5 >/dev/null 2>&1; then
        print_result "ETH0_CONNECTIVITY" "PASS" "eth0 ping 成功"
    else
        print_result "ETH0_CONNECTIVITY" "FAIL" "eth0 ping 失敗"
    fi

    # Test eth1 with fewer pings
    echo -e "${BLUE}測試 eth1 連線...${NC}"
    if timeout 10 ping -I eth1 192.168.8.1 -c 1 -W 5 >/dev/null 2>&1; then
        print_result "ETH1_CONNECTIVITY" "PASS" "eth1 ping 成功"
    else
        print_result "ETH1_CONNECTIVITY" "FAIL" "eth1 ping 失敗"
    fi
}

test_gpio_quick() {
    print_header "GPIO 測試 (快速)"

    local gpio_ids=(5 6 8 13)  # 只測試部分 GPIO
    local gpio_test_result="PASS"

    echo -e "${BLUE}快速測試 GPIO: ${gpio_ids[*]}${NC}"

    # Export and configure GPIOs
    for gpio in "${gpio_ids[@]}"; do
        echo "$gpio" > /sys/class/gpio/export 2>/dev/null
        echo "out" > "/sys/class/gpio/gpio$gpio/direction" 2>/dev/null
        echo "1" > "/sys/class/gpio/gpio$gpio/value" 2>/dev/null
    done

    if ask_user "GPIO 是否已點亮？"; then
        echo -e "${GREEN}GPIO 測試通過${NC}"
    else
        gpio_test_result="FAIL"
    fi

    # Cleanup
    for gpio in "${gpio_ids[@]}"; do
        echo "0" > "/sys/class/gpio/gpio$gpio/value" 2>/dev/null
        echo "$gpio" > /sys/class/gpio/unexport 2>/dev/null
    done

    print_result "GPIO_QUICK_TEST" "$gpio_test_result" "快速 GPIO 測試"
}

test_emmc_quick() {
    print_header "eMMC 存儲測試 (快速)"

    # 使用很小的測試大小
    local test_size=10  # 只測試 10MB
    local timeout_seconds=30  # 30秒超時

    echo -e "${BLUE}快速測試 eMMC 寫入 (${test_size}MB)...${NC}"
    echo -e "${BLUE}  正在寫入 ${test_size}MB 數據...${NC}"

    local write_result
    write_result=$(timeout $timeout_seconds dd if=/dev/zero of=./test_emmc_quick bs=1M count=$test_size conv=fsync 2>&1)
    local write_exit_code=$?

    if [ $write_exit_code -eq 124 ]; then
        rm -f ./test_emmc_quick
        print_result "EMMC_QUICK_TEST" "FAIL" "寫入測試超時"
        return
    elif [ $write_exit_code -ne 0 ]; then
        rm -f ./test_emmc_quick
        print_result "EMMC_QUICK_TEST" "FAIL" "寫入測試失敗"
        return
    fi

    echo -e "${BLUE}快速測試 eMMC 讀取...${NC}"
    local read_result
    read_result=$(timeout $timeout_seconds dd if=./test_emmc_quick of=/dev/null bs=1M 2>&1)
    local read_exit_code=$?

    # Cleanup
    rm -f ./test_emmc_quick

    if [ $read_exit_code -eq 124 ]; then
        print_result "EMMC_QUICK_TEST" "FAIL" "讀取測試超時"
    elif [ $read_exit_code -ne 0 ]; then
        print_result "EMMC_QUICK_TEST" "FAIL" "讀取測試失敗"
    else
        print_result "EMMC_QUICK_TEST" "PASS" "eMMC 快速讀寫測試成功"
    fi
}

test_basic_commands() {
    print_header "基本命令測試"

    local commands=("date" "hwclock --show" "ls /sys/class/gpio")
    local all_pass=true

    for cmd in "${commands[@]}"; do
        echo -e "${BLUE}測試命令: $cmd${NC}"
        if timeout 5 $cmd >/dev/null 2>&1; then
            echo -e "${GREEN}  ✓ 成功${NC}"
        else
            echo -e "${RED}  ✗ 失敗${NC}"
            all_pass=false
        fi
    done

    if [ "$all_pass" = true ]; then
        print_result "BASIC_COMMANDS" "PASS" "基本命令測試通過"
    else
        print_result "BASIC_COMMANDS" "FAIL" "部分基本命令失敗"
    fi
}

test_lcd_quick() {
    print_header "LCD 背光測試 (快速)"

    local backlight_path="/sys/class/backlight/lvds-backlight/brightness"
    local max_brightness_path="/sys/class/backlight/lvds-backlight/max_brightness"

    # 檢查背光控制文件是否存在
    if [ ! -f "$backlight_path" ]; then
        print_result "LCD_QUICK_TEST" "FAIL" "背光控制文件不存在"
        return
    fi

    echo -e "${BLUE}快速測試 LCD 背光控制...${NC}"

    # 獲取當前亮度和最大亮度
    local original_brightness
    original_brightness=$(cat "$backlight_path" 2>/dev/null)

    local max_brightness
    if [ -f "$max_brightness_path" ]; then
        max_brightness=$(cat "$max_brightness_path" 2>/dev/null)
    else
        max_brightness=255
    fi

    # 快速測試：只測試亮度變化
    local half_brightness=$((max_brightness / 2))

    echo -e "${BLUE}調整亮度到一半 ($half_brightness)...${NC}"
    if echo "$half_brightness" > "$backlight_path" 2>/dev/null; then
        sleep 1
        if ask_user "LCD 螢幕是否變暗了？"; then
            # 恢復原始亮度
            echo "$original_brightness" > "$backlight_path" 2>/dev/null
            print_result "LCD_QUICK_TEST" "PASS" "LCD 背光控制正常"
        else
            # 恢復原始亮度
            echo "$original_brightness" > "$backlight_path" 2>/dev/null
            print_result "LCD_QUICK_TEST" "FAIL" "LCD 背光變化未被確認"
        fi
    else
        print_result "LCD_QUICK_TEST" "FAIL" "無法控制 LCD 背光"
    fi
}

test_device_files() {
    print_header "設備文件檢查"

    local devices=("/dev/ttyS3" "/dev/ttyS4" "/sys/class/gpio" "/sys/class/backlight/lvds-backlight/brightness")
    local found_count=0

    for device in "${devices[@]}"; do
        if [ -e "$device" ]; then
            echo -e "${GREEN}✓ $device 存在${NC}"
            found_count=$((found_count + 1))
        else
            echo -e "${YELLOW}⚠ $device 不存在${NC}"
        fi
    done

    if [ $found_count -eq ${#devices[@]} ]; then
        print_result "DEVICE_FILES" "PASS" "所有設備文件存在"
    else
        print_result "DEVICE_FILES" "FAIL" "部分設備文件缺失 ($found_count/${#devices[@]})"
    fi
}

# Main execution
main() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║      RK-3568 QC 快速測試系統        ║${NC}"
    echo -e "${PURPLE}║            版本 1.0                  ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}快速測試模式 - 減少測試時間${NC}"
    echo -e "${CYAN}測試日誌: $LOG_FILE${NC}"
    echo

    log_message "QC Quick Test Started"

    # Run quick tests
    test_network_quick
    test_gpio_quick
    test_lcd_quick
    test_emmc_quick
    test_basic_commands
    test_device_files

    # Final summary
    echo -e "${CYAN}================================${NC}"
    echo -e "${WHITE}快速測試結果總結${NC}"
    echo -e "${CYAN}================================${NC}"
    echo -e "${BLUE}總測試項目: $test_count${NC}"
    echo -e "${GREEN}通過: $pass_count${NC}"
    echo -e "${RED}失敗: $fail_count${NC}"
    echo

    if [ $fail_count -eq 0 ]; then
        echo -e "${GREEN}🎉 快速測試全部通過！${NC}"
        echo -e "${BLUE}💡 建議執行完整測試以獲得詳細結果${NC}"
        log_message "All quick tests passed"
    else
        echo -e "${RED}❌ 有 $fail_count 項測試失敗${NC}"
        echo -e "${YELLOW}失敗的測試項目：${NC}"
        for test_name in "${!test_results[@]}"; do
            if [ "${test_results[$test_name]}" = "FAIL" ]; then
                echo -e "${RED}  - $test_name${NC}"
            fi
        done
        log_message "Quick test FAILED - $fail_count tests failed"
    fi

    echo
    echo -e "${CYAN}詳細日誌: $LOG_FILE${NC}"
    echo -e "${BLUE}執行完整測試: sudo bash qc_test.sh${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}請以 root 權限執行此腳本${NC}"
    echo "使用方法: sudo $0"
    exit 1
fi

# Run main function
main "$@"
