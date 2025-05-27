# RK-3568 QC 測試系統 - 一鍵使用指南

## 🚀 快速開始

### 1. 複製到 USB
將整個 `rk-3568-test` 資料夾複製到 USB 隨身碟

### 2. 插入 RK-3568 設備
將 USB 插入 RK-3568 開發板

### 3. 一鍵運行
```bash
# 進入 USB 目錄 (通常自動掛載在 /media/user1/usb)
cd /media/user1/usb/rk-3568-test

# 一鍵執行 QC 測試
sudo bash run_qc.sh
```

## ✨ 就是這麼簡單！

`run_qc.sh` 會自動處理：
- ✅ 權限設置
- ✅ 依賴安裝
- ✅ 網路配置
- ✅ 掛載點設置
- ✅ 測試工具查找
- ✅ 環境檢查
- ✅ QC 測試執行

## 📁 文件結構
```
rk-3568-test/
├── run_qc.sh              # 🎯 一鍵啟動腳本 (主要使用這個)
├── qc_test.sh              # QC 測試核心腳本
├── check_environment.sh    # 環境檢查腳本
├── README_SIMPLE.md        # 簡化使用說明 (本文件)
├── README_QC.md           # 詳細技術文檔
├── DEPLOYMENT.md          # 部署指南
├── Makefile              # 自動化工具
└── plan.md               # 原始需求
```

## 🎮 使用選項

### 完整流程 (推薦)
```bash
sudo bash run_qc.sh
```

### 只檢查環境
```bash
sudo bash run_qc.sh --check-only
```

### 只設置環境
```bash
sudo bash run_qc.sh --setup-only
```

### 只執行測試
```bash
sudo bash run_qc.sh --test-only
```

## 📊 測試項目

| 項目 | 說明 | 互動需求 |
|------|------|----------|
| 🌐 網路 | 測試 eth0/eth1 連線 | 無 |
| 🔌 GPIO | 測試 GPIO 輸出 | 需確認 LED 亮滅 |
| 💾 eMMC | 測試內部存儲 | 無 |
| 🔌 USB/SD | 測試外部存儲 | 無 |
| 📡 UART | 測試串口通訊 | 無 |
| 🔄 SPI | 測試 SPI 介面 | 無 |
| 🔗 I2C | 測試 I2C 介面 | 無 |
| ⏰ 時間 | 測試系統時鐘 | 無 |
| ⌨️ 按鍵 | 測試硬體按鍵 | 需按指定按鍵 |

## 🎨 結果顯示

- 🟢 **綠色 ✓** = 測試通過
- 🔴 **紅色 ✗** = 測試失敗  
- 🟡 **黃色 ⚠** = 警告或需要互動
- 🔵 **藍色** = 測試進行中

## 📝 測試報告

測試完成後會生成詳細日誌：
```
/tmp/qc_test_YYYYMMDD_HHMMSS.log
```

## ❓ 常見問題

### Q: 提示權限不足？
A: 確保使用 `sudo` 執行：
```bash
sudo bash run_qc.sh
```

### Q: USB 沒有自動掛載？
A: 手動掛載後執行：
```bash
sudo mount /dev/sda1 /media/user1/usb
cd /media/user1/usb/rk-3568-test
sudo bash run_qc.sh
```

### Q: 某些測試失敗？
A: 檢查硬體連接和測試工具是否存在：
```bash
sudo bash run_qc.sh --check-only
```

### Q: 想要重複測試？
A: 可以多次執行，每次都會生成新的日誌：
```bash
sudo bash run_qc.sh --test-only
```

## 🛠️ 進階使用

如需詳細的技術文檔和自定義配置，請參考：
- `README_QC.md` - 完整技術文檔
- `DEPLOYMENT.md` - 部署和故障排除指南

## 📞 技術支援

如遇問題，請提供：
1. 執行 `sudo bash run_qc.sh --check-only` 的輸出
2. 測試日誌文件 `/tmp/qc_test_*.log`
3. 硬體連接狀態描述

---

**🎯 記住：只需要一個命令 `sudo bash run_qc.sh` 就能完成所有 QC 測試！**
