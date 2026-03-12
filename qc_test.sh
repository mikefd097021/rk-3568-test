#!/bin/bash

# RK-3568 QC Interactive Test Script
# Author: Auto-generated QC Test Script
# Version: 3.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'    # 改為亮青色，更容易看清
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Get image version from kernel build date
BUILD_DATE=$(uname -v | sed -E 's/^#[0-9]+ SMP //')
IMAGE_VER=$(date -d "$BUILD_DATE" +"%y%m%d.%H%M" 2>/dev/null || echo "Unknown")

# Function to get mount point for a device pattern
get_mount_point() {
    local dev_pattern="$1"  # e.g., "mmcblk1p1" or "sd[a-z]1"
    # Search in /proc/mounts for the device and return the mount point
    # We use awk to handle potential spaces in mount paths (though they are escaped as \040)
    local mount_pt=$(grep -E "/dev/$dev_pattern" /proc/mounts | head -n 1 | awk '{print $2}' | sed 's/\\040/ /g')
    echo "$mount_pt"
}

# Test results tracking
declare -A test_results
declare -A test_id_map

# Initialize test name mapping (must match menu descriptions exactly)
test_id_map["ETH0_CONNECTIVITY"]="1. 網路 eth0 測試"
test_id_map["ETH1_CONNECTIVITY"]="2. 網路 eth1 測試"
test_id_map["GPIO_TEST"]="3. GPIO 測試"
test_id_map["LCD_TEST"]="4. LCD 背光測試"
test_id_map["EMMC_TEST"]="5. eMMC 存儲測試"
test_id_map["USB_TEST"]="6. USB 設備測試"
test_id_map["SDCARD_TEST"]="7. SD卡 測試"
test_id_map["UART_ttyS3"]="8. UART ttyS3 測試"
test_id_map["UART_ttyS4"]="9. UART ttyS4 測試"
test_id_map["SPI_TEST"]="10. SPI 測試"
test_id_map["I2C_TEST"]="11. I2C 測試"
test_id_map["TIME_TEST"]="12. 時間系統測試"
test_id_map["KEY_TEST"]="13. 按鍵測試"
test_id_map["SUSPEND_RESUME"]="14. 休眠喚醒測試"

test_count=0
pass_count=0
fail_count=0
skip_count=0

# Logging
LOG_FILE="/tmp/qc_test_$(date +%Y%m%d_%H%M%S).log"

# Helper functions
reset_results() {
    test_results=()
    test_count=0
    pass_count=0
    fail_count=0
    skip_count=0
}

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
    elif [ "$result" = "SKIP" ]; then
        echo -e "${YELLOW}⊘ $test_name: SKIP${NC}"
        [ -n "$details" ] && echo -e "  ${BLUE}Details: $details${NC}"
        skip_count=$((skip_count + 1))
        log_message "$test_name: SKIP - $details"
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
    echo -ne "${YELLOW}$question (y/n): ${NC}"
    while true; do
        read -n 1 -s response
        case "$response" in
            [Yy]) 
                echo -e "${GREEN}y${NC}"
                return 0 
                ;;
            [Nn]) 
                echo -e "${RED}n${NC}"
                return 1 
                ;;
        esac
    done
}

# Test functions
test_eth0() {
    print_header "網路 eth0 測試"
    echo -e "${BLUE}測試 eth0 連線...${NC}"
    if ping -I eth0 192.168.8.1 -c 3 -W 10 >/dev/null 2>&1; then
        print_result "ETH0_CONNECTIVITY" "PASS" "eth0 ping 192.168.8.1 成功"
    else
        print_result "ETH0_CONNECTIVITY" "FAIL" "eth0 ping 192.168.8.1 失敗"
    fi
}

test_eth1() {
    print_header "網路 eth1 測試"
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

    # 使用較小的測試大小以避免卡住，並添加超時控制
    local test_size=10  # 減少到 10MB
    local timeout_seconds=30  # 30秒超時

    echo -e "${BLUE}測試 eMMC 寫入性能 (${test_size}MB)...${NC}"
    local write_result
    local write_exit_code

    # 使用 timeout 命令防止卡住，並顯示進度
    if which pv >/dev/null 2>&1; then
        # 如果有 pv 命令，顯示進度條
        write_result=$(timeout $timeout_seconds dd if=/dev/zero bs=1M count=$test_size 2>/dev/null | pv -s ${test_size}M | dd of=./test_emmc conv=fsync 2>&1)
        write_exit_code=$?
    else
        # 沒有 pv 命令，使用普通 dd 但加上超時和簡單進度提示
        echo -e "${BLUE}  正在寫入 ${test_size}MB 數據，請稍候...${NC}"
        write_result=$(timeout $timeout_seconds dd if=/dev/zero of=./test_emmc bs=1M count=$test_size conv=fsync status=progress 2>&1)
        write_exit_code=$?
    fi

    if [ $write_exit_code -eq 124 ]; then
        echo -e "${YELLOW}寫入測試超時 (${timeout_seconds}秒)${NC}"
        rm -f ./test_emmc
        print_result "EMMC_TEST" "FAIL" "eMMC 寫入測試超時"
        return
    elif [ $write_exit_code -ne 0 ]; then
        echo -e "${RED}寫入測試失敗${NC}"
        rm -f ./test_emmc
        print_result "EMMC_TEST" "FAIL" "eMMC 寫入測試失敗"
        return
    fi

    echo -e "${BLUE}測試 eMMC 讀取性能...${NC}"
    local read_result
    local read_exit_code

    # 讀取測試也加上超時
    if [ -f "./test_emmc" ]; then
        if which pv >/dev/null 2>&1; then
            read_result=$(timeout $timeout_seconds dd if=./test_emmc bs=1M 2>/dev/null | pv -s ${test_size}M | dd of=/dev/null 2>&1)
            read_exit_code=$?
        else
            echo -e "${BLUE}  正在讀取 ${test_size}MB 數據，請稍候...${NC}"
            read_result=$(timeout $timeout_seconds dd if=./test_emmc of=/dev/null bs=1M status=progress 2>&1)
            read_exit_code=$?
        fi
        # Cleanup
        rm -f ./test_emmc
    else
        print_result "EMMC_TEST" "FAIL" "測試文件不存在，無法進行讀取測試"
        return
    fi

    if [ $read_exit_code -eq 124 ]; then
        print_result "EMMC_TEST" "FAIL" "eMMC 讀取測試超時"
    elif [ $read_exit_code -ne 0 ]; then
        print_result "EMMC_TEST" "FAIL" "eMMC 讀取測試失敗"
    else
        # 提取速度信息
        local write_speed=$(echo "$write_result" | grep -o '[0-9.]\+ [MG]B/s' | tail -1)
        local read_speed=$(echo "$read_result" | grep -o '[0-9.]\+ [MG]B/s' | tail -1)
        local details="寫入: ${write_speed:-N/A}, 讀取: ${read_speed:-N/A}"
        print_result "EMMC_TEST" "PASS" "eMMC 讀寫測試成功 - $details"
    fi
}

# Helper for USB/SD wait
wait_for_device() {
    local device_type="$1"
    local target="$2"  # 可以是路徑或設備模式 (如 mmcblk1p[0-9])
    local max_wait=10
    local wait_count=0

    echo -e "${YELLOW}未檢測到 $device_type，請插入 $device_type...${NC}"
    echo -e "${BLUE}等待 $device_type 插入 (最多等待 ${max_wait} 秒，按 Ctrl+C 跳過)${NC}"

    while [ $wait_count -lt $max_wait ]; do
        # 檢查是否為模式 (包含 [ 或 *) 還是直接的路徑
        if [[ "$target" == *"["* ]]; then
            local mount_path=$(get_mount_point "$target")
            if [ -n "$mount_path" ] && [ -d "$mount_path" ]; then
                echo -e "${GREEN}✓ 檢測到 $device_type 掛載於: $mount_path${NC}"
                return 0
            fi
        else
            if [ -d "$target" ] && [ "$(ls -A "$target" 2>/dev/null)" ]; then
                echo -e "${GREEN}✓ 檢測到 $device_type${NC}"
                return 0
            fi
        fi
        printf "\r${BLUE}等待中... %d/%d 秒${NC}" $wait_count $max_wait
        sleep 1
        wait_count=$((wait_count + 1))
    done
    echo
    echo -e "${YELLOW}⚠ 等待超時，跳過 $device_type 測試${NC}"
    return 1
}

test_usb() {
    print_header "USB 設備測試"
    local test_size=10
    local usb_path=$(get_mount_point "sd[a-z][0-9]")
    
    if [ -z "$usb_path" ] || [ ! -d "$usb_path" ]; then
        wait_for_device "USB 設備" "sd[a-z][0-9]"
        usb_path=$(get_mount_point "sd[a-z][0-9]")
    fi

    if [ -n "$usb_path" ] && [ -d "$usb_path" ]; then
        echo -e "${BLUE}偵測到 USB 掛載點: ${WHITE}$usb_path${NC}"
        echo -e "${BLUE}測試 USB 讀寫 (${test_size}MB)...${NC}"
        if timeout 30 dd if=/dev/zero of="$usb_path/test_usb" bs=1M count=$test_size conv=fsync >/dev/null 2>&1 && \
           timeout 30 dd if="$usb_path/test_usb" of=/dev/null bs=1M >/dev/null 2>&1; then
            print_result "USB_TEST" "PASS" "USB 讀寫測試成功 ($usb_path)"
            rm -f "$usb_path/test_usb"
        else
            print_result "USB_TEST" "FAIL" "USB 讀寫測試失敗 ($usb_path)"
            rm -f "$usb_path/test_usb" 2>/dev/null
        fi
    else
        print_result "USB_TEST" "SKIP" "未檢測到 USB 設備"
    fi
}

test_sdcard() {
    print_header "SD卡 測試"
    local test_size=10
    local sd_path=$(get_mount_point "mmcblk1p[0-9]")

    if [ -z "$sd_path" ] || [ ! -d "$sd_path" ]; then
        wait_for_device "SD卡" "mmcblk1p[0-9]"
        sd_path=$(get_mount_point "mmcblk1p[0-9]")
    fi

    if [ -n "$sd_path" ] && [ -d "$sd_path" ]; then
        echo -e "${BLUE}偵測到 SD卡 掛載點: ${WHITE}$sd_path${NC}"
        
        # 檢查是否可寫
        if [ ! -w "$sd_path" ]; then
            echo -e "${YELLOW}警告: 掛載點 $sd_path 似乎為唯讀，嘗試重新掛載為讀寫...${NC}"
            mount -o remount,rw "$sd_path" 2>/dev/null
        fi

        echo -e "${BLUE}測試 SD卡 讀寫 (${test_size}MB)...${NC}"
        if timeout 30 dd if=/dev/zero of="$sd_path/test_sd" bs=1M count=$test_size conv=fsync >/dev/null 2>&1 && \
           timeout 30 dd if="$sd_path/test_sd" of=/dev/null bs=1M >/dev/null 2>&1; then
            print_result "SDCARD_TEST" "PASS" "SD卡 讀寫測試成功 ($sd_path)"
            rm -f "$sd_path/test_sd"
        else
            print_result "SDCARD_TEST" "FAIL" "SD卡 讀寫測試失敗，請檢查權限或磁碟狀態 ($sd_path)"
            rm -f "$sd_path/test_sd" 2>/dev/null
        fi
    else
        print_result "SDCARD_TEST" "SKIP" "未檢測到 SD卡 設備掛載點"
    fi
}

test_uart_ttyS3() {
    print_header "UART ttyS3 測試"
    local device="/dev/ttyS3"
    echo -e "${BLUE}測試 $device...${NC}"
    if which fltest_uarttest >/dev/null 2>&1; then
        local uart_output
        uart_output=$(timeout 10 fltest_uarttest -d "$device" 2>&1)
        if echo "$uart_output" | grep -q "forlinx_uart_test.1234567890"; then
            print_result "UART_ttyS3" "PASS" "$device 測試成功"
        else
            print_result "UART_ttyS3" "FAIL" "$device 測試失敗"
        fi
    else
        print_result "UART_ttyS3" "FAIL" "fltest_uarttest 命令不存在"
    fi
}

test_uart_ttyS4() {
    print_header "UART ttyS4 測試"
    local device="/dev/ttyS4"
    echo -e "${BLUE}測試 $device...${NC}"
    if which fltest_uarttest >/dev/null 2>&1; then
        local uart_output
        uart_output=$(timeout 10 fltest_uarttest -d "$device" 2>&1)
        if echo "$uart_output" | grep -q "forlinx_uart_test.1234567890"; then
            print_result "UART_ttyS4" "PASS" "$device 測試成功"
        else
            print_result "UART_ttyS4" "FAIL" "$device 測試失敗"
        fi
    else
        print_result "UART_ttyS4" "FAIL" "fltest_uarttest 命令不存在"
    fi
}

test_spi() {
    print_header "SPI 測試"

    echo -e "${BLUE}測試 SPI 設備 /dev/spidev0.0...${NC}"
    if which fltest_spidev_test >/dev/null 2>&1; then
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
    if which i2cdetect >/dev/null 2>&1; then
        local i2c_output=""
        local max_wait=10  # 最多等待 10 秒
        local wait_count=0
        local scan_result=1
        
        # 使用倒數計時顯示
        while [ $wait_count -lt $max_wait ]; do
            # 顯示等待進度
            printf "\r${BLUE}掃描中... %d/%d 秒${NC}" $wait_count $max_wait
            
            # 非阻塞方式執行 i2cdetect 命令 (背景執行)
            timeout 1 i2cdetect -y 1 > /tmp/i2c_result.tmp 2>&1 &
            sleep 1
            wait_count=$((wait_count + 1))
            
            # 檢查結果
            if grep -q "0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f" /tmp/i2c_result.tmp 2>/dev/null; then
                i2c_output=$(cat /tmp/i2c_result.tmp)
                scan_result=0
                break
            fi
        done
        
        echo  # 換行，結束倒計時顯示
        
        if [ $scan_result -eq 0 ]; then
            print_result "I2C_TEST" "PASS" "I2C 掃描成功"
        else
            print_result "I2C_TEST" "FAIL" "I2C 掃描超時（${max_wait}秒）或失敗"
        fi
        
        # 清理臨時文件
        rm -f /tmp/i2c_result.tmp
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

test_lcd() {
    print_header "LCD 背光測試"

    local backlight_path="/sys/class/backlight/lvds-backlight/brightness"
    local max_brightness_path="/sys/class/backlight/lvds-backlight/max_brightness"

    # 檢查背光控制文件是否存在
    if [ ! -f "$backlight_path" ]; then
        print_result "LCD_TEST" "FAIL" "背光控制文件不存在: $backlight_path"
        return
    fi

    echo -e "${BLUE}開始 LCD 背光測試...${NC}"

    # 獲取最大亮度值
    local max_brightness
    if [ -f "$max_brightness_path" ]; then
        max_brightness=$(cat "$max_brightness_path" 2>/dev/null)
        echo -e "${BLUE}最大亮度值: $max_brightness${NC}"
    else
        max_brightness=255  # 預設值
        echo -e "${YELLOW}使用預設最大亮度值: $max_brightness${NC}"
    fi

    # 保存當前亮度
    local original_brightness
    original_brightness=$(cat "$backlight_path" 2>/dev/null)
    echo -e "${BLUE}當前亮度: $original_brightness${NC}"

    # 步驟1: 設置最大亮度
    echo -e "${BLUE}設置亮度到最大值 ($max_brightness)...${NC}"
    if echo "$max_brightness" > "$backlight_path" 2>/dev/null; then
        echo -e "${GREEN}✓ 亮度已設置到最大${NC}"
        sleep 2  # 等待亮度變化
    else
        print_result "LCD_TEST" "FAIL" "無法設置最大亮度"
        return
    fi

    # 步驟2: 減半亮度
    local half_brightness=$((max_brightness / 2))
    echo -e "${BLUE}設置亮度到一半 ($half_brightness)...${NC}"
    if echo "$half_brightness" > "$backlight_path" 2>/dev/null; then
        echo -e "${GREEN}✓ 亮度已減半${NC}"
        sleep 2  # 等待亮度變化

        # 詢問用戶是否看到變暗
        if ask_user "LCD 螢幕是否變暗了？"; then
            echo -e "${GREEN}✓ LCD 變暗測試通過${NC}"
        else
            # 恢復原始亮度
            echo "$original_brightness" > "$backlight_path" 2>/dev/null
            print_result "LCD_TEST" "FAIL" "用戶確認 LCD 未變暗"
            return
        fi
    else
        # 恢復原始亮度
        echo "$original_brightness" > "$backlight_path" 2>/dev/null
        print_result "LCD_TEST" "FAIL" "無法設置一半亮度"
        return
    fi

    # 步驟3: 再次調亮
    echo -e "${BLUE}重新設置亮度到最大值...${NC}"
    if echo "$max_brightness" > "$backlight_path" 2>/dev/null; then
        echo -e "${GREEN}✓ 亮度已調回最大${NC}"
        sleep 2  # 等待亮度變化

        # 詢問用戶是否看到變亮
        if ask_user "LCD 螢幕是否重新變亮了？"; then
            echo -e "${GREEN}✓ LCD 變亮測試通過${NC}"
            # 恢復原始亮度
            echo "$original_brightness" > "$backlight_path" 2>/dev/null
            print_result "LCD_TEST" "PASS" "LCD 背光控制正常，亮度變化測試通過"
        else
            # 恢復原始亮度
            echo "$original_brightness" > "$backlight_path" 2>/dev/null
            print_result "LCD_TEST" "FAIL" "用戶確認 LCD 未重新變亮"
        fi
    else
        # 恢復原始亮度
        echo "$original_brightness" > "$backlight_path" 2>/dev/null
        print_result "LCD_TEST" "FAIL" "無法重新設置最大亮度"
    fi
}

test_keys() {
    print_header "按鍵測試"

    local found_114=false # 音量減
    local found_115=false # 音量加
    local found_139=false # 選單
    local found_158=false # 返回/Recovery
    local found_count=0
    local duration=30
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))

    echo -e "${YELLOW}請在倒計時結束前按下以下 4 個按鍵：${NC}"
    echo -e "${BLUE}- btn1 (音量加), btn2 (音量減), btn3 (選單), btn4 (返回/Recovery)${NC}"
    echo

    if ! which fltest_keytest >/dev/null 2>&1; then
        print_result "KEY_TEST" "FAIL" "fltest_keytest 命令不存在"
        return
    fi

    # 啟動測試工具並取得其輸出流 (使用文件描述符 3)
    exec 3< <(fltest_keytest 2>&1)
    local tool_pid=$!

    while true; do
        local now=$(date +%s)
        local remaining=$((end_time - now))

        if [ $remaining -lt 0 ]; then
            printf "\r${RED}倒數計時:  0 秒 | 進度: %d/4 [ %s %s %s %s ]${NC}\n" \
                $found_count \
                "$([ "$found_115" = true ] && echo "btn1" || echo "---")" \                
                "$([ "$found_114" = true ] && echo "btn2" || echo "---")" \
                "$([ "$found_139" = true ] && echo "btn3" || echo "---")" \
                "$([ "$found_158" = true ] && echo "btn4" || echo "---")"
            echo -e "${RED}時間到！測試未完成。${NC}"
            break
        fi

        # 顯示倒數計時與狀態面板
        printf "\r${YELLOW}倒數計時: %2d 秒 | 進度: %d/4 [ %s %s %s %s ]${NC}" \
            $remaining $found_count \
            "$([ "$found_115" = true ] && echo "btn1" || echo "---")" \
            "$([ "$found_114" = true ] && echo "btn2" || echo "---")" \
            "$([ "$found_139" = true ] && echo "btn3" || echo "---")" \
            "$([ "$found_158" = true ] && echo "btn4" || echo "---")"

        # 非阻塞讀取工具輸出 (0.1秒超時)
        while read -t 0.1 -u 3 line; do
            if [[ "$line" =~ "114" ]] && [ "$found_114" = false ]; then
                found_114=true
                found_count=$((found_count + 1))
            fi
            if [[ "$line" =~ "115" ]] && [ "$found_115" = false ]; then
                found_115=true
                found_count=$((found_count + 1))
            fi
            if [[ "$line" =~ "139" ]] && [ "$found_139" = false ]; then
                found_139=true
                found_count=$((found_count + 1))
            fi
            if [[ "$line" =~ "158" ]] && [ "$found_158" = false ]; then
                found_158=true
                found_count=$((found_count + 1))
            fi

            # 如果集齊 4 個鍵，立即更新 UI 並跳出
            if [ "$found_count" -eq 4 ]; then
                printf "\r${GREEN}倒數計時: %2d 秒 | 進度: 4/4 [ 114 115 139 158 ]${NC}\n" $remaining
                echo -e "${GREEN}🎉 已成功檢測到所有目標按鍵！${NC}"
                break 2
            fi
        done
    done

    # 清理資源
    pkill -P $tool_pid 2>/dev/null
    kill $tool_pid 2>/dev/null
    exec 3<&-

    # 最終結果輸出
    if [ "$found_count" -eq 4 ]; then
        print_result "KEY_TEST" "PASS" "成功檢測到所有鍵碼: 114, 115, 139, 158"
    else
        local missing=""
        [ "$found_114" = false ] && missing+="114 "
        [ "$found_115" = false ] && missing+="115 "
        [ "$found_139" = false ] && missing+="139 "
        [ "$found_158" = false ] && missing+="158 "
        print_result "KEY_TEST" "FAIL" "未完成測試。缺失鍵碼: $missing"
    fi
}

test_suspend_resume() {
    print_header "休眠喚醒測試"

    echo -e "${YELLOW}系統準備進入休眠模式 (freeze)...${NC}"
    echo -e "${BLUE}請注意觀察主機板藍色燈號：${NC}"
    echo -e "${BLUE}  1. 燈號應停止閃爍${NC}"
    echo -e "${BLUE}  2. 螢幕將變黑${NC}"
    echo -e "${BLUE}確認休眠後，請使用【觸控螢幕】喚醒系統。${NC}"
    echo

    if ! ask_user "準備好開始休眠測試了嗎？"; then
        print_result "SUSPEND_RESUME" "SKIP" "使用者取消休眠測試"
        return
    fi

    # 倒數計時
    for i in 3 2 1; do
        echo -e "${RED}系統將在 $i 秒後休眠...${NC}"
        sleep 1
    done

    log_message "System entering suspend (manual freeze mode)..."
    
    # 保存當前亮度與背光路徑
    local backlight_path="/sys/class/backlight/lvds-backlight/brightness"
    local current_brightness=255
    if [ -f "$backlight_path" ]; then
        current_brightness=$(cat "$backlight_path")
    fi

    local start_time=$(date +%s)
    
    # 執行休眠 (依照要求只用 freeze)
    local suspend_success=false
    if echo freeze > /sys/power/state 2>/dev/null; then
        suspend_success=true
    fi

    if [ "$suspend_success" = true ]; then
        # === 喚醒後強制點亮螢幕 ===
        # 1. 解除 Framebuffer 空白狀態
        echo 0 > /sys/class/graphics/fb0/blank 2>/dev/null
        # 2. 恢復/強制設置背光亮度
        if [ -f "$backlight_path" ]; then
             echo "$current_brightness" > "$backlight_path" 2>/dev/null
        fi
        # 3. 嘗試喚醒 VT
        chvt 1 2>/dev/null && chvt 7 2>/dev/null
        # ============================

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo
        echo -e "${GREEN}系統已喚醒！ (休眠耗時: ${duration} 秒)${NC}"
        log_message "System resumed. Duration: ${duration}s"

        # 自動判定為成功 (因為能執行到這裡代表已經喚醒)
        print_result "SUSPEND_RESUME" "PASS" "休眠與喚醒測試成功 (耗時 ${duration}s)"
    else
        print_result "SUSPEND_RESUME" "FAIL" "無法進入 freeze 休眠模式"
    fi
}

# NTP Time Sync function
sync_ntp_time() {
    print_header "內部網路時間自動校正"
    
    if ! ask_user "是否要從內部伺服器同步系統時間？"; then
        echo -e "${YELLOW}已跳過時間同步.${NC}"
        echo
        return 1
    fi

    local NTP_SERVER="192.168.2.115"
    local CONF_FILE="/etc/systemd/timesyncd.conf"
    local CONF_BACKUP=""

    # Backup original config content
    if [ -f "$CONF_FILE" ]; then
        CONF_BACKUP=$(cat "$CONF_FILE")
        echo -e "${BLUE}Configuring temporary NTP server: ${WHITE}$NTP_SERVER${NC}"

        # Apply temporary modifications
        if grep -q "^NTP=" "$CONF_FILE"; then
            sed -i "s/^NTP=.*/NTP=$NTP_SERVER/" "$CONF_FILE"
        else
            sed -i "/^\[Time\]/a NTP=$NTP_SERVER" "$CONF_FILE"
        fi
        # Uncomment FallbackNTP
        sed -i 's/^#FallbackNTP=/FallbackNTP=/' "$CONF_FILE"
    else
        echo -e "${RED}Error: Configuration file $CONF_FILE not found${NC}"
    fi

    echo -e "${BLUE}Restarting systemd-timesyncd to apply temporary settings...${NC}"
    systemctl restart systemd-timesyncd 2>/dev/null || echo -e "${YELLOW}Failed to restart systemd-timesyncd${NC}"

    echo -e "${BLUE}Enabling NTP synchronization...${NC}"
    timedatectl set-ntp true 2>/dev/null

    echo -e "${BLUE}Waiting for synchronization to complete (max 30s)...${NC}"

    local SYNC_OK=0
    for i in {1..15}; do
        # Get system sync status
        local STATUS_RAW=$(timedatectl status 2>/dev/null)
        local TIMESYNC_RAW=$(timedatectl timesync-status 2>/dev/null)
        
        # Check if synced
        local IS_SYNCED=$(echo "$STATUS_RAW" | grep -i "System clock synchronized: yes" || true)
        
        # Get current connected server
        local CURRENT_SERVER=$(echo "$TIMESYNC_RAW" | grep -E "Server:|ServerName:" | awk '{print $2}' || echo "None")

        if [ -n "$IS_SYNCED" ]; then
            printf "\r${GREEN}Check %d/15: [Synced] Server: %s${NC}" $i "$CURRENT_SERVER"
            SYNC_OK=1
            echo "" 
            break
        else
            printf "\r${CYAN}Check %d/15: [Syncing...] Current Server: %s${NC}" $i "$CURRENT_SERVER"
        fi

        sleep 2
    done

    # Restore config immediately after check (without restarting service)
    if [ -n "$CONF_BACKUP" ]; then
        echo -e "${BLUE}Restoring original NTP configuration file...${NC}"
        echo "$CONF_BACKUP" > "$CONF_FILE"
        echo -e "${GREEN}✓ Configuration file restored (takes effect after next reboot)${NC}"
    fi

    if [ "$SYNC_OK" -eq 1 ]; then
        echo -e "${GREEN}✓ System time successfully synchronized with NTP server${NC}"
        echo -e "${BLUE}Writing system time to hardware clock (RTC)...${NC}"
        hwclock --systohc 2>/dev/null
        echo -e "${GREEN}✓ RTC updated${NC}"
    else
        echo ""
        echo -e "${RED}⚠ WARNING: Unable to confirm synchronization status after 30s timeout${NC}"
    fi

    echo
    echo -e "${WHITE}Current detailed time status:${NC}"
    timedatectl status 2>/dev/null | grep -E "Local time|System clock synchronized|NTP service" || timedatectl status
    if timedatectl timesync-status >/dev/null 2>&1; then
        echo -e "${WHITE}NTP connection details:${NC}"
        timedatectl timesync-status | grep -E "Server|Packet count|Offset" || true
    fi
    echo
    echo -e "${YELLOW}Press Enter to continue to the test menu...${NC}"
    read -r
}

# Main execution
main() {
    local ntp_performed=false
    while true; do
        reset_results
        clear

        if [ "$ntp_performed" = false ]; then
            sync_ntp_time
            ntp_performed=true
            clear
        fi

        echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║       RK-3568 QC Test System         ║${NC}"
        echo -e "${PURPLE}║            Version 4.1               ║${NC}"
        echo -e "${PURPLE}║      Image Version: $IMAGE_VER      ║${NC}"
        echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
        echo
        echo -e "${CYAN}測試項目選單：${NC}"
        echo -e "  ${WHITE}0. 執行基礎測試 (1-13項, 不含休眠)${NC}"
        echo -e "  ${WHITE}1. 網路 eth0 測試${NC}"
        echo -e "  ${WHITE}2. 網路 eth1 測試${NC}"
        echo -e "  ${WHITE}3. GPIO 測試${NC}"
        echo -e "  ${WHITE}4. LCD 背光測試${NC}"
        echo -e "  ${WHITE}5. eMMC 存儲測試${NC}"
        echo -e "  ${WHITE}6. USB 設備測試${NC}"
        echo -e "  ${WHITE}7. SD卡 測試${NC}"
        echo -e "  ${WHITE}8. UART ttyS3 測試${NC}"
        echo -e "  ${WHITE}9. UART ttyS4 測試${NC}"
        echo -e "  ${WHITE}10. SPI 測試${NC}"
        echo -e "  ${WHITE}11. I2C 測試${NC}"
        echo -e "  ${WHITE}12. 時間系統測試${NC}"
        echo -e "  ${WHITE}13. 按鍵測試${NC}"
        echo -e "  ${WHITE}14. 休眠喚醒測試${NC}"
        echo -e "  ${WHITE}98. 執行完整測試 (1-14項, 含休眠)${NC}"
        echo -e "  ${WHITE}99. 跳過測試並進入退出選單${NC}"
        echo
        read -p "請選擇測試項目 (0-99): " choice

        log_message "QC Test Started - Choice: $choice"

        case "$choice" in
            0)
                # 執行前 13 項測試
                test_eth0
                test_eth1
                test_gpio
                test_lcd
                test_emmc
                test_usb
                test_sdcard
                test_uart_ttyS3
                test_uart_ttyS4
                test_spi
                test_i2c
                test_time
                test_keys
                ;;
            98)
                # 執行前 13 項測試
                test_eth0
                test_eth1
                test_gpio
                test_lcd
                test_emmc
                test_usb
                test_sdcard
                test_uart_ttyS3
                test_uart_ttyS4
                test_spi
                test_i2c
                test_time
                test_keys

                # 中途總結報告 (前 13 項)
                echo
                echo -e "${CYAN}================================${NC}"
                echo -e "${WHITE}第一階段測試總結 (1-13項)${NC}"
                echo -e "${CYAN}================================${NC}"
                echo -e "${BLUE}已測試項目: $test_count${NC}"
                echo -e "${GREEN}通過: $pass_count${NC}"
                echo -e "${RED}失敗: $fail_count${NC}"
                if [ $skip_count -gt 0 ]; then
                    echo -e "${YELLOW}跳過: $skip_count${NC}"
                fi
                echo
                echo -e "${YELLOW}接下來將進行最後一項：休眠喚醒測試${NC}"
                echo -e "${YELLOW}請按 Enter 鍵繼續...${NC}"
                read -r

                # 執行第 14 項休眠測試
                test_suspend_resume
                ;;
            1) test_eth0 ;;
            2) test_eth1 ;;
            3) test_gpio ;;
            4) test_lcd ;;
            5) test_emmc ;;
            6) test_usb ;;
            7) test_sdcard ;;
            8) test_uart_ttyS3 ;;
            9) test_uart_ttyS4 ;;
            10) test_spi ;;
            11) test_i2c ;;
            12) test_time ;;
            13) test_keys ;;
            14) test_suspend_resume ;;
            99) # 直接跳到總結與退出
                echo -e "${YELLOW}已跳過所有測試項目。${NC}"
                ;;
            *) echo -e "${RED}無效的選擇${NC}"; continue ;;
        esac

        # Final summary (全項目)
        echo -e "${CYAN}================================${NC}"
        echo -e "${WHITE}最終測試結果總結${NC}"
        echo -e "${CYAN}================================${NC}"
        echo -e "${BLUE}總測試項目: $test_count${NC}"
        echo -e "${GREEN}通過: $pass_count${NC}"
        echo -e "${RED}失敗: $fail_count${NC}"
        if [ $skip_count -gt 0 ]; then
            echo -e "${YELLOW}跳過: $skip_count${NC}"
        fi
        echo

        if [ $fail_count -eq 0 ]; then
            if [ $skip_count -eq 0 ]; then
                echo -e "${GREEN}🎉 測試通過！${NC}"
                log_message "QC SUCCESS"
            else
                echo -e "${GREEN}✅ 執行的測試通過！${NC}"
                log_message "QC PARTIAL SUCCESS"
            fi
        else
            echo -e "${RED}❌ 有測試項目失敗！${NC}"
            echo -e "${RED}失敗項目列表：${NC}"
            # 按 ID 順序遍歷所有可能的測試項目
            for key in "ETH0_CONNECTIVITY" "ETH1_CONNECTIVITY" "GPIO_TEST" "LCD_TEST" \
                       "EMMC_TEST" "USB_TEST" "SDCARD_TEST" "UART_ttyS3" \
                       "UART_ttyS4" "SPI_TEST" "I2C_TEST" "TIME_TEST" \
                       "KEY_TEST" "SUSPEND_RESUME"; do
                if [ "${test_results[$key]}" = "FAIL" ]; then
                    echo -e "  ${RED}- ${test_id_map[$key]}${NC}"
                fi
            done
            log_message "QC FAILED"
        fi

        # 輸出跳過項目清單
        if [ $skip_count -gt 0 ]; then
            echo -e "${YELLOW}跳過項目列表：${NC}"
            for key in "ETH0_CONNECTIVITY" "ETH1_CONNECTIVITY" "GPIO_TEST" "LCD_TEST" \
                       "EMMC_TEST" "USB_TEST" "SDCARD_TEST" "UART_ttyS3" \
                       "UART_ttyS4" "SPI_TEST" "I2C_TEST" "TIME_TEST" \
                       "KEY_TEST" "SUSPEND_RESUME"; do
                if [ "${test_results[$key]}" = "SKIP" ]; then
                    echo -e "  ${YELLOW}- ${test_id_map[$key]}${NC}"
                fi
            done
        fi

        echo
        echo -e "${CYAN}詳細日誌請查看: $LOG_FILE${NC}"
        echo
        echo -e "${YELLOW}輸入 'r' 回到測試選單，輸入 'd' 清除測試資料並退出${NC}"
        echo -e "${YELLOW}按其他任意鍵關閉測試程序...${NC}"
        read -n 1 -r restart_choice
        echo
        if [[ "$restart_choice" =~ ^[Rr]$ ]]; then
            continue
        elif [[ "$restart_choice" =~ ^[Dd]$ ]]; then
            echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
            echo -e "${RED}║                ⚠️  DANGER WARNING  ⚠️                ║${NC}"
            echo -e "${RED}╠══════════════════════════════════════════════════════╣${NC}"
            echo -e "${RED}║                                                      ║${NC}"
            echo -e "${RED}║  This operation will:                                ║${NC}"
            echo -e "${RED}║  1. PERMANENTLY delete the folder (rk-3568-test)     ║${NC}"
            echo -e "${RED}║  2. Delete the QC Test desktop shortcut              ║${NC}"
            echo -e "${RED}║                                                      ║${NC}"
            echo -e "${RED}║  ⚠️  CAUTION: This action CANNOT be undone!          ║${NC}"
            echo -e "${RED}║  All test logs will be permanently removed.          ║${NC}"
            echo -e "${RED}║                                                      ║${NC}"
            echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}"
            echo
            if ask_user "Are you sure you want to clean all data and exit?"; then
                echo -e "${CYAN}正在清除資料...${NC}"
                # 刪除桌面快捷方式 (可能存在的路徑)
                rm -f /home/user1/Desktop/QC_Test.desktop 2>/dev/null
                rm -rf /home/user1/Desktop/rk-3568-test 2>/dev/null
                # 獲取當前腳本所在的目錄 (假設它是 rk-3568-test)
                local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                # 執行刪除 (在背景執行以確保腳本能正常退出)
                (sleep 1 && rm -rf "$current_dir") &
                echo -e "${GREEN}資料清除指令已發送。系統即將退出。${NC}"
                exit 0
            else
                echo -e "${BLUE}操作已取消。${NC}"
                continue
            fi
        else
            break
        fi
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}正在自動獲取 root 權限...${NC}"
    echo "fdtuser1" | sudo -S bash "$0" "$@"
    exit $?
fi
# 恢復終端互動輸入
exec 0</dev/tty 2>/dev/null || true

# Run main function
main "$@"
