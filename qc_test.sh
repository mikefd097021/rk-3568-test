#!/bin/bash

# RK-3568 QC Interactive Test Script
# Author: Auto-generated QC Test Script
# Version: 1.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
LOG_FILE="/tmp/qc_test_$(date +%Y%m%d_%H%M%S).log"

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

# Test functions
test_network() {
    print_header "網路連線測試"
    
    # Test eth0
    echo -e "${BLUE}測試 eth0 連線...${NC}"
    if ping -I eth0 192.168.8.1 -c 3 -W 10 >/dev/null 2>&1; then
        print_result "ETH0_CONNECTIVITY" "PASS" "eth0 ping 192.168.8.1 成功"
    else
        print_result "ETH0_CONNECTIVITY" "FAIL" "eth0 ping 192.168.8.1 失敗"
    fi
    
    # Test eth1
    echo -e "${BLUE}測試 eth1 連線...${NC}"
    if ping -I eth1 192.168.8.1 -c 3 -W 10 >/dev/null 2>&1; then
        print_result "ETH1_CONNECTIVITY" "PASS" "eth1 ping 192.168.8.1 成功"
    else
        print_result "ETH1_CONNECTIVITY" "FAIL" "eth1 ping 192.168.8.1 失敗"
    fi
}

test_gpio() {
    print_header "GPIO 測試"
    
    local gpio_ids=(5 6 8 13 16 17 90 91)
    local gpio_test_result="PASS"
    local failed_gpios=()
    
    echo -e "${BLUE}準備測試 GPIO: ${gpio_ids[*]}${NC}"
    
    # Export and configure GPIOs
    for gpio in "${gpio_ids[@]}"; do
        echo "$gpio" > /sys/class/gpio/export 2>/dev/null
        echo "out" > "/sys/class/gpio/gpio$gpio/direction" 2>/dev/null
    done
    
    # Turn on all GPIOs
    echo -e "${BLUE}點亮所有 GPIO...${NC}"
    for gpio in "${gpio_ids[@]}"; do
        echo "1" > "/sys/class/gpio/gpio$gpio/value" 2>/dev/null
    done
    
    if ask_user "所有 GPIO 是否已點亮？"; then
        echo -e "${GREEN}GPIO 點亮測試通過${NC}"
    else
        gpio_test_result="FAIL"
        failed_gpios+=("點亮測試失敗")
    fi
    
    # Turn off all GPIOs
    echo -e "${BLUE}關閉所有 GPIO...${NC}"
    for gpio in "${gpio_ids[@]}"; do
        echo "0" > "/sys/class/gpio/gpio$gpio/value" 2>/dev/null
    done
    
    if ask_user "所有 GPIO 是否已關閉？"; then
        echo -e "${GREEN}GPIO 關閉測試通過${NC}"
    else
        gpio_test_result="FAIL"
        failed_gpios+=("關閉測試失敗")
    fi
    
    # Cleanup
    for gpio in "${gpio_ids[@]}"; do
        echo "$gpio" > /sys/class/gpio/unexport 2>/dev/null
    done
    
    if [ "$gpio_test_result" = "PASS" ]; then
        print_result "GPIO_TEST" "PASS" "所有 GPIO 測試通過"
    else
        print_result "GPIO_TEST" "FAIL" "${failed_gpios[*]}"
    fi
}

test_emmc() {
    print_header "eMMC 存儲測試"
    
    echo -e "${BLUE}測試 eMMC 寫入性能...${NC}"
    local write_result
    write_result=$(dd if=/dev/zero of=./test_emmc bs=1M count=500 conv=fsync 2>&1)
    local write_exit_code=$?
    
    echo -e "${BLUE}測試 eMMC 讀取性能...${NC}"
    local read_result
    read_result=$(dd if=./test_emmc of=/dev/null bs=1M 2>&1)
    local read_exit_code=$?
    
    # Cleanup
    rm -f ./test_emmc
    
    if [ $write_exit_code -eq 0 ] && [ $read_exit_code -eq 0 ]; then
        print_result "EMMC_TEST" "PASS" "eMMC 讀寫測試成功"
    else
        print_result "EMMC_TEST" "FAIL" "eMMC 讀寫測試失敗"
    fi
}

test_usb_sdcard() {
    print_header "USB/SD卡 測試"
    
    local devices_found=0
    
    # Check for USB devices
    if [ -d "/media/user1/usb" ] && [ "$(ls -A /media/user1/usb 2>/dev/null)" ]; then
        echo -e "${BLUE}發現 USB 設備，測試讀寫...${NC}"
        if dd if=/dev/zero of=/media/user1/usb/test_usb bs=1M count=50 conv=fsync >/dev/null 2>&1 && \
           dd if=/media/user1/usb/test_usb of=/dev/null bs=1M >/dev/null 2>&1; then
            print_result "USB_TEST" "PASS" "USB 讀寫測試成功"
            rm -f /media/user1/usb/test_usb
        else
            print_result "USB_TEST" "FAIL" "USB 讀寫測試失敗"
        fi
        devices_found=1
    fi
    
    # Check for SD card
    if [ -d "/media/user1/sdcard" ] && [ "$(ls -A /media/user1/sdcard 2>/dev/null)" ]; then
        echo -e "${BLUE}發現 SD卡，測試讀寫...${NC}"
        if dd if=/dev/zero of=/media/user1/sdcard/test_sd bs=1M count=50 conv=fsync >/dev/null 2>&1 && \
           dd if=/media/user1/sdcard/test_sd of=/dev/null bs=1M >/dev/null 2>&1; then
            print_result "SDCARD_TEST" "PASS" "SD卡 讀寫測試成功"
            rm -f /media/user1/sdcard/test_sd
        else
            print_result "SDCARD_TEST" "FAIL" "SD卡 讀寫測試失敗"
        fi
        devices_found=1
    fi
    
    if [ $devices_found -eq 0 ]; then
        print_result "USB_SDCARD_TEST" "FAIL" "未發現 USB 或 SD卡 設備"
    fi
}

test_uart() {
    print_header "UART 測試"
    
    local uart_devices=("/dev/ttyS3" "/dev/ttyS4")
    local uart_test_result="PASS"
    local failed_uarts=()
    
    for device in "${uart_devices[@]}"; do
        echo -e "${BLUE}測試 $device...${NC}"
        if command -v fltest_uarttest >/dev/null 2>&1; then
            local uart_output
            uart_output=$(timeout 10 fltest_uarttest -d "$device" 2>&1)
            if echo "$uart_output" | grep -q "forlinx_uart_test.1234567890"; then
                print_result "UART_${device##*/}" "PASS" "$device 測試成功"
            else
                print_result "UART_${device##*/}" "FAIL" "$device 測試失敗"
                uart_test_result="FAIL"
                failed_uarts+=("$device")
            fi
        else
            print_result "UART_${device##*/}" "FAIL" "fltest_uarttest 命令不存在"
            uart_test_result="FAIL"
            failed_uarts+=("$device")
        fi
    done
}

test_spi() {
    print_header "SPI 測試"
    
    echo -e "${BLUE}測試 SPI 設備 /dev/spidev0.0...${NC}"
    if command -v fltest_spidev_test >/dev/null 2>&1; then
        local spi_output
        spi_output=$(timeout 10 fltest_spidev_test -D /dev/spidev0.0 2>&1)
        if echo "$spi_output" | grep -q "spi mode:" && echo "$spi_output" | grep -q "bits per word:"; then
            print_result "SPI_TEST" "PASS" "SPI 測試成功"
        else
            print_result "SPI_TEST" "FAIL" "SPI 測試失敗"
        fi
    else
        print_result "SPI_TEST" "FAIL" "fltest_spidev_test 命令不存在"
    fi
}

test_i2c() {
    print_header "I2C 測試"
    
    echo -e "${BLUE}測試 I2C 設備掃描...${NC}"
    if command -v i2cdetect >/dev/null 2>&1; then
        local i2c_output
        i2c_output=$(i2cdetect -y 1 2>&1)
        if echo "$i2c_output" | grep -q "0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f"; then
            print_result "I2C_TEST" "PASS" "I2C 掃描成功"
        else
            print_result "I2C_TEST" "FAIL" "I2C 掃描失敗"
        fi
    else
        print_result "I2C_TEST" "FAIL" "i2cdetect 命令不存在"
    fi
}

test_time() {
    print_header "時間系統測試"
    
    echo -e "${BLUE}測試系統時間...${NC}"
    local current_date
    current_date=$(date)
    echo -e "${BLUE}當前系統時間: $current_date${NC}"
    
    echo -e "${BLUE}同步硬體時鐘...${NC}"
    if hwclock -wu >/dev/null 2>&1; then
        local hw_time
        hw_time=$(hwclock --show 2>&1)
        if [ $? -eq 0 ]; then
            print_result "TIME_TEST" "PASS" "時間系統正常，硬體時鐘: $hw_time"
        else
            print_result "TIME_TEST" "FAIL" "硬體時鐘讀取失敗"
        fi
    else
        print_result "TIME_TEST" "FAIL" "硬體時鐘同步失敗"
    fi
}

test_keys() {
    print_header "按鍵測試"
    
    echo -e "${YELLOW}請按照以下順序測試按鍵：${NC}"
    echo -e "${BLUE}1. Recovery 按鈕${NC}"
    echo -e "${BLUE}2. 其他四個按鈕依序按下${NC}"
    echo -e "${YELLOW}測試將在 30 秒後開始，按 Ctrl+C 可提前結束${NC}"
    
    if command -v fltest_keytest >/dev/null 2>&1; then
        echo -e "${BLUE}啟動按鍵測試程序...${NC}"
        local key_output
        key_output=$(timeout 30 fltest_keytest 2>&1)
        
        local key_count
        key_count=$(echo "$key_output" | grep -c "Presse")
        
        if [ "$key_count" -ge 5 ]; then
            print_result "KEY_TEST" "PASS" "檢測到 $key_count 個按鍵事件"
        else
            print_result "KEY_TEST" "FAIL" "只檢測到 $key_count 個按鍵事件，預期至少 5 個"
        fi
    else
        print_result "KEY_TEST" "FAIL" "fltest_keytest 命令不存在"
    fi
}

# Main execution
main() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║        RK-3568 QC 測試系統          ║${NC}"
    echo -e "${PURPLE}║            版本 1.0                  ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}測試日誌將保存到: $LOG_FILE${NC}"
    echo
    
    log_message "QC Test Started"
    
    # Run all tests
    test_network
    test_gpio
    test_emmc
    test_usb_sdcard
    test_uart
    test_spi
    test_i2c
    test_time
    test_keys
    
    # Final summary
    echo -e "${CYAN}================================${NC}"
    echo -e "${WHITE}測試結果總結${NC}"
    echo -e "${CYAN}================================${NC}"
    echo -e "${BLUE}總測試項目: $test_count${NC}"
    echo -e "${GREEN}通過: $pass_count${NC}"
    echo -e "${RED}失敗: $fail_count${NC}"
    echo
    
    if [ $fail_count -eq 0 ]; then
        echo -e "${GREEN}🎉 所有測試通過！設備 QC 測試成功！${NC}"
        log_message "All tests passed - QC SUCCESS"
    else
        echo -e "${RED}❌ 有 $fail_count 項測試失敗，請檢查設備！${NC}"
        echo -e "${YELLOW}失敗的測試項目：${NC}"
        for test_name in "${!test_results[@]}"; do
            if [ "${test_results[$test_name]}" = "FAIL" ]; then
                echo -e "${RED}  - $test_name${NC}"
            fi
        done
        log_message "QC FAILED - $fail_count tests failed"
    fi
    
    echo
    echo -e "${CYAN}詳細日誌請查看: $LOG_FILE${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}請以 root 權限執行此腳本${NC}"
    echo "使用方法: sudo $0"
    exit 1
fi

# Run main function
main "$@"
