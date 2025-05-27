# RK-3568 QC 測試系統部署指南

## 概述
此 QC 測試系統專為 RK-3568 開發板的 Ubuntu 系統設計。以下是完整的部署和使用指南。

## 文件結構
```
rk-3568-test/
├── qc_test.sh              # 主要 QC 測試腳本
├── check_environment.sh    # 環境檢查腳本
├── README_QC.md           # 使用說明文檔
├── DEPLOYMENT.md          # 部署指南 (本文件)
├── Makefile              # 自動化部署工具
└── plan.md               # 原始需求規劃
```

## 部署步驟

### 1. 將文件傳輸到 RK-3568 設備

#### 方法 A: 使用 SCP (推薦)
```bash
# 從開發機器傳輸到 RK-3568
scp -r rk-3568-test/ user1@<RK3568_IP>:/home/user1/
```

#### 方法 B: 使用 USB 或 SD 卡
```bash
# 在 RK-3568 上
cp -r /media/user1/usb/rk-3568-test/ /home/user1/
# 或
cp -r /media/user1/sdcard/rk-3568-test/ /home/user1/
```

#### 方法 C: 使用 Git (如果有網路)
```bash
# 在 RK-3568 上
cd /home/user1/
git clone <repository_url> rk-3568-test
```

### 2. 在 RK-3568 上設置權限
```bash
# 進入項目目錄
cd /home/user1/rk-3568-test/

# 設置執行權限
chmod +x qc_test.sh
chmod +x check_environment.sh

# 或使用 Makefile
make install
```

### 3. 檢查環境
```bash
# 檢查測試環境是否就緒
./check_environment.sh

# 或使用 Makefile
make check
```

### 4. 執行測試
```bash
# 執行完整 QC 測試
sudo ./qc_test.sh

# 或使用 Makefile
sudo make test
```

## 系統需求確認

### 必要軟體包
在 RK-3568 Ubuntu 系統上確認以下軟體包已安裝：

```bash
# 基本工具
sudo apt update
sudo apt install -y iputils-ping coreutils util-linux

# I2C 工具
sudo apt install -y i2c-tools

# 如果需要編譯測試工具
sudo apt install -y build-essential
```

### 測試工具安裝
確認以下測試工具可用：

```bash
# 檢查測試工具
which fltest_uarttest
which fltest_spidev_test
which fltest_keytest

# 如果不存在，請聯繫硬體供應商或檢查以下路徑：
ls /usr/local/bin/fltest_*
ls /opt/forlinx/bin/fltest_*
ls /home/user1/fltest_*
```

### 權限設置
```bash
# 確保用戶在必要的群組中
sudo usermod -a -G gpio,i2c,spi user1

# 設置 GPIO 權限 (如果需要)
sudo chmod 666 /sys/class/gpio/export
sudo chmod 666 /sys/class/gpio/unexport
```

## 測試前準備

### 1. 硬體連接檢查
- ✅ 網路線連接到 eth0 和 eth1
- ✅ GPIO 測試用 LED 或指示燈已連接
- ✅ LCD 顯示器已連接並支援背光控制
- ✅ UART 測試設備已連接 (如果需要)
- ✅ SPI 測試設備已連接 (如果需要)
- ✅ I2C 設備已連接 (如果需要)
- ✅ USB 設備或 SD 卡已插入 (可選)

### 2. 網路配置
```bash
# 配置網路介面
sudo ip addr add 192.168.8.100/24 dev eth0
sudo ip addr add 192.168.8.101/24 dev eth1
sudo ip link set eth0 up
sudo ip link set eth1 up

# 確認網路連通性
ping -c 1 192.168.8.1
```

### 3. 掛載點準備
```bash
# 創建 USB/SD 掛載點 (如果不存在)
sudo mkdir -p /media/user1/usb
sudo mkdir -p /media/user1/sdcard

# 掛載 USB 設備 (示例)
sudo mount /dev/sda1 /media/user1/usb

# 掛載 SD 卡 (示例)
sudo mount /dev/mmcblk1p1 /media/user1/sdcard
```

## 執行流程

### 完整測試流程
```bash
# 1. 環境檢查
./check_environment.sh

# 2. 執行測試
sudo ./qc_test.sh

# 3. 查看結果
cat /tmp/qc_test_*.log
```

### 單項測試 (如需要)
可以修改 `qc_test.sh` 腳本，註釋掉不需要的測試項目：

```bash
# 在 main() 函數中註釋不需要的測試
# test_network      # 註釋網路測試
test_gpio
test_emmc
# test_usb_sdcard   # 註釋 USB/SD 測試
# ...
```

## 故障排除

### 常見問題解決

#### 1. 權限問題
```bash
# 錯誤：Permission denied
# 解決：
sudo chmod +x qc_test.sh
sudo ./qc_test.sh
```

#### 2. 測試工具缺失
```bash
# 錯誤：fltest_uarttest: command not found
# 解決：
find / -name "fltest_*" 2>/dev/null
# 將找到的路徑添加到 PATH 或創建符號連結
```

#### 3. GPIO 權限問題
```bash
# 錯誤：cannot write to /sys/class/gpio/export
# 解決：
sudo chmod 666 /sys/class/gpio/export
sudo chmod 666 /sys/class/gpio/unexport
```

#### 4. 網路測試失敗
```bash
# 檢查網路配置
ip addr show
ip route show
ping -c 1 192.168.8.1
```

#### 5. LCD 背光測試失敗
```bash
# 錯誤：背光控制文件不存在
# 檢查背光系統
ls /sys/class/backlight/
cat /sys/class/backlight/*/brightness
cat /sys/class/backlight/*/max_brightness

# 如果路徑不同，修改腳本中的路徑
find /sys -name "*brightness*" 2>/dev/null
```

### 日誌分析
```bash
# 查看最新測試日誌
ls -la /tmp/qc_test_*.log | tail -1

# 分析失敗項目
grep "FAIL" /tmp/qc_test_*.log

# 查看詳細錯誤
tail -f /tmp/qc_test_*.log
```

## 自定義配置

### 修改測試參數
編輯 `qc_test.sh` 中的配置變數：

```bash
# GPIO 列表
gpio_ids=(5 6 8 13 16 17 90 91)

# 網路測試目標
ping -I eth0 192.168.8.1

# 測試文件大小
count=500  # eMMC 測試 500MB
count=50   # USB/SD 測試 50MB
```

### 添加新測試項目
1. 創建新的測試函數
2. 在 `main()` 函數中調用
3. 更新 `README_QC.md` 文檔

## 維護建議

### 定期檢查
- 每週執行一次完整測試
- 檢查日誌文件大小，定期清理舊日誌
- 更新測試工具版本

### 備份重要文件
```bash
# 備份配置和日誌
tar -czf qc_backup_$(date +%Y%m%d).tar.gz \
    qc_test.sh check_environment.sh /tmp/qc_test_*.log
```

## 技術支援

如遇到問題，請提供：
1. 系統資訊：`uname -a`
2. 錯誤日誌：`/tmp/qc_test_*.log`
3. 環境檢查結果：`./check_environment.sh`
4. 硬體連接狀態描述
