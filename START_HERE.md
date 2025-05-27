# 🚀 RK-3568 QC 測試系統 - 開始使用

## 📋 一鍵使用流程

### 🖥️ 在 Windows 開發機上

1. **準備 USB**
   ```cmd
   # 雙擊執行
   prepare_usb.bat
   ```
   - 選擇 USB 磁碟機
   - 自動複製所有必要文件

### 🔌 在 RK-3568 設備上

2. **插入 USB 並執行**
   ```bash
   # 進入 USB 目錄
   cd /media/user1/usb/rk-3568-test

   # 一鍵執行 (三選一)
   sudo bash run_qc.sh    # 方法 1: 直接執行
   make                   # 方法 2: 使用 Makefile
   bash quick_start.sh    # 方法 3: 自動查找
   ```

## ✨ 就是這麼簡單！

所有複雜的設置都已自動化：
- ✅ 自動權限設置
- ✅ 自動依賴安裝
- ✅ 自動網路配置
- ✅ 自動掛載設置
- ✅ 自動工具查找
- ✅ 自動環境檢查

## 📁 文件說明

| 文件 | 用途 | 重要性 |
|------|------|--------|
| **run_qc.sh** | 🎯 **一鍵啟動腳本** | ⭐⭐⭐ |
| **prepare_usb.bat** | Windows USB 準備工具 | ⭐⭐⭐ |
| **START_HERE.md** | 快速開始指南 (本文件) | ⭐⭐⭐ |
| qc_test.sh | QC 測試核心腳本 | ⭐⭐ |
| check_environment.sh | 環境檢查腳本 | ⭐⭐ |
| README_SIMPLE.md | 簡化使用說明 | ⭐⭐ |
| Makefile | 自動化工具 | ⭐ |
| README_QC.md | 詳細技術文檔 | ⭐ |
| DEPLOYMENT.md | 部署指南 | ⭐ |

## 🎮 使用選項

### 完整流程 (推薦)
```bash
sudo bash run_qc.sh
```
自動設置環境 + 執行所有測試

### 分步執行
```bash
sudo bash run_qc.sh --setup-only    # 只設置環境
sudo bash run_qc.sh --check-only    # 只檢查環境
sudo bash run_qc.sh --test-only     # 只執行測試
```

### 使用 Makefile
```bash
make          # 一鍵執行 (等同於 make run)
make run      # 完整流程
make check    # 只檢查環境
make test     # 只執行測試
make clean    # 清理臨時文件
```

## 📊 測試項目概覽

| 🔍 測試項目 | ⚡ 自動化 | 🎯 說明 |
|------------|----------|---------|
| 🌐 網路測試 | ✅ 全自動 | 測試 eth0/eth1 連線到 192.168.8.1 |
| 🔌 GPIO 測試 | 🔄 半自動 | 控制 GPIO 輸出，需人工確認 LED |
| 🖥️ LCD 測試 | 🔄 半自動 | 測試 LCD 背光亮度控制，需人工確認變化 |
| 💾 eMMC 測試 | ✅ 全自動 | 測試內部存儲 10MB 讀寫性能 |
| 🔌 USB/SD 測試 | 🔄 半自動 | 自動檢測，未插入時等待用戶插入 10MB |
| 📡 UART 測試 | ✅ 全自動 | 測試 ttyS3/ttyS4 串口通訊 |
| 🔄 SPI 測試 | ✅ 全自動 | 測試 spidev0.0 介面 |
| 🔗 I2C 測試 | ✅ 全自動 | 掃描 I2C 設備 |
| ⏰ 時間測試 | ✅ 全自動 | 測試系統時間與硬體時鐘同步 |
| ⌨️ 按鍵測試 | 🔄 半自動 | 測試 4 個硬體按鍵，需人工按鍵 |

## 🎨 結果解讀

### 狀態指示
- 🟢 **綠色 ✓ PASS** = 測試通過
- 🔴 **紅色 ✗ FAIL** = 測試失敗
- 🟡 **黃色 ⚠ WARNING** = 警告或需要互動
- 🔵 **藍色 INFO** = 測試進行中的資訊

### 最終結果
```
================================
測試結果總結
================================
總測試項目: 10
通過: 9
失敗: 1

🎉 QC 測試完成！
```

## 📝 測試報告

每次測試都會生成詳細日誌：
```
/tmp/qc_test_20241201_143022.log
```

包含：
- 時間戳記
- 每個測試的詳細結果
- 錯誤訊息和診斷資訊

## ❓ 快速故障排除

### 常見問題

#### ❌ 權限不足
```bash
# 錯誤：Permission denied
# 解決：確保使用 sudo
sudo bash run_qc.sh
```

#### ❌ USB 未掛載
```bash
# 手動掛載
sudo mount /dev/sda1 /media/user1/usb
cd /media/user1/usb/rk-3568-test
```

#### ❌ 測試工具缺失
```bash
# 檢查環境
sudo bash run_qc.sh --check-only
```

#### ❌ 網路測試失敗
```bash
# 檢查網路配置
ip addr show eth0
ip addr show eth1
ping 192.168.8.1
```

## 🔧 進階功能

### 重複測試
```bash
# 可以多次執行，每次生成新日誌
sudo bash run_qc.sh --test-only
```

### 自定義配置
編輯 `run_qc.sh` 或 `qc_test.sh` 中的參數：
- GPIO ID 列表
- 網路測試目標
- 測試文件大小

### 桌面快捷方式
執行後會自動在桌面創建快捷方式：
```
/home/user1/Desktop/QC_Test.desktop
```

## 📞 技術支援

如遇問題，請提供：

1. **環境檢查結果**
   ```bash
   sudo bash run_qc.sh --check-only > environment_check.txt
   ```

2. **測試日誌**
   ```bash
   cp /tmp/qc_test_*.log ./
   ```

3. **系統資訊**
   ```bash
   uname -a > system_info.txt
   lsb_release -a >> system_info.txt
   ```

## 🎯 記住關鍵命令

```bash
# 🚀 一鍵執行所有操作
sudo bash run_qc.sh

# 或者使用 Makefile
make
```

---

**💡 提示：第一次使用建議先執行 `sudo bash run_qc.sh --check-only` 檢查環境！**
