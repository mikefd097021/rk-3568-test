# RK-3568 QC 測試系統

## 概述
這是一個專為 RK-3568 開發板設計的 QC (Quality Control) 互動式測試腳本，用於自動化測試硬體功能並生成詳細的測試報告。

## 功能特色

### 🔧 測試項目
1. **網路連線測試** - 自動測試 eth0/eth1 網路介面
2. **GPIO 測試** - 互動式測試 GPIO 輸出功能
3. **LCD 背光測試** - 互動式測試 LCD 背光亮度控制
4. **eMMC 存儲測試** - 自動測試內部存儲讀寫性能
5. **USB/SD卡測試** - 自動檢測並測試外部存儲設備
6. **UART 測試** - 測試串口通訊功能
7. **SPI 測試** - 測試 SPI 介面
8. **I2C 測試** - 測試 I2C 設備掃描
9. **時間系統測試** - 測試系統時間與硬體時鐘同步
10. **按鍵測試** - 互動式測試硬體按鍵

### 🎨 視覺特色
- **彩色輸出** - 清楚區分成功/失敗狀態
- **即時反饋** - 每個測試項目即時顯示結果
- **詳細日誌** - 自動生成時間戳記的測試日誌
- **總結報告** - 測試完成後提供完整統計

## 系統需求

### 硬體要求
- RK-3568 開發板
- 網路連線 (eth0/eth1)
- GPIO 測試用 LED 或指示燈
- LCD 顯示器 (支援背光控制)
- USB 設備或 SD 卡 (可選)

### 軟體要求
- Ubuntu 系統
- Root 權限
- 必要的測試工具：
  - `fltest_uarttest` (UART 測試)
  - `fltest_spidev_test` (SPI 測試)
  - `fltest_keytest` (按鍵測試)
  - `i2cdetect` (I2C 測試)

## 安裝與使用

### 1. 準備工作
```bash
# 確保腳本有執行權限
chmod +x qc_test.sh

# 檢查必要工具是否存在
which fltest_uarttest
which fltest_spidev_test
which fltest_keytest
which i2cdetect
```

### 2. 執行測試
```bash
# 以 root 權限執行
sudo ./qc_test.sh
```

### 3. 測試流程
1. **自動測試項目** - 網路、eMMC、USB/SD卡、UART、SPI、I2C、時間
2. **互動測試項目** - GPIO、LCD 背光、按鍵測試需要人工確認
3. **結果確認** - 每個測試完成後立即顯示結果
4. **最終報告** - 所有測試完成後顯示統計摘要

## 測試結果說明

### 狀態指示
- ✅ **綠色 PASS** - 測試通過
- ❌ **紅色 FAIL** - 測試失敗
- 🔵 **藍色** - 測試進行中的資訊
- 🟡 **黃色** - 需要用戶互動的提示

### 日誌文件
- 位置：`/tmp/qc_test_YYYYMMDD_HHMMSS.log`
- 內容：包含所有測試的詳細時間戳記和結果
- 格式：`YYYY-MM-DD HH:MM:SS - 測試項目: 結果 - 詳細資訊`

## 故障排除

### 常見問題

#### 1. 權限不足
```bash
# 錯誤：請以 root 權限執行此腳本
# 解決：使用 sudo 執行
sudo ./qc_test.sh
```

#### 2. 測試工具缺失
```bash
# 錯誤：fltest_uarttest 命令不存在
# 解決：安裝或確認測試工具路徑
which fltest_uarttest
```

#### 3. GPIO 權限問題
```bash
# 錯誤：無法寫入 GPIO 控制文件
# 解決：確認 GPIO 系統已啟用
ls /sys/class/gpio/
```

#### 4. 網路測試失敗
```bash
# 錯誤：ping 192.168.8.1 失敗
# 解決：檢查網路配置和連線
ip addr show eth0
ip addr show eth1
```

#### 5. LCD 背光測試失敗
```bash
# 錯誤：背光控制文件不存在
# 解決：檢查背光系統是否啟用
ls /sys/class/backlight/
cat /sys/class/backlight/*/brightness
```

### 測試工具安裝

如果測試工具缺失，請聯繫硬體供應商或參考以下路徑：
```bash
# 通常測試工具位於
/usr/local/bin/
/opt/forlinx/bin/
/home/user1/
```

## 自定義配置

### 修改測試參數
可以編輯腳本中的以下變數：

```bash
# GPIO ID 列表
gpio_ids=(5 6 8 13 16 17 90 91)

# 網路測試目標
ping -I eth0 192.168.8.1

# eMMC 測試大小
dd ... count=500  # 500MB

# USB/SD 測試大小
dd ... count=50   # 50MB
```

### 添加新測試項目
在 `main()` 函數中添加新的測試函數調用：

```bash
test_network
test_gpio
test_your_new_test  # 添加新測試
test_emmc
# ...
```

## 技術支援

如有問題請檢查：
1. 系統日誌：`/tmp/qc_test_*.log`
2. 硬體連接是否正確
3. 必要的測試工具是否已安裝
4. 系統權限是否足夠

## 版本資訊
- 版本：1.0
- 支援平台：RK-3568 + Ubuntu
- 最後更新：2024
