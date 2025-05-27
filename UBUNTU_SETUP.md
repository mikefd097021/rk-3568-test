# Ubuntu雙擊觸發Make設置說明

## 步驟1：設置腳本權限
在Ubuntu終端中執行：
```bash
chmod +x make-runner.sh
```

## 步驟2：創建.desktop文件（可選）
創建一個桌面應用程序條目：
```bash
sudo nano /usr/share/applications/make-runner.desktop
```

內容：
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Make Runner
Comment=Run make command in terminal
Exec=gnome-terminal -- bash -c "%f"
Icon=utilities-terminal
StartupNotify=true
NoDisplay=false
MimeType=text/x-makefile;
Categories=Development;
```

## 步驟3：設置文件關聯
### 方法A：通過文件管理器
1. 右鍵點擊 `Makefile`
2. 選擇 "屬性" (Properties)
3. 點擊 "打開方式" (Open With) 標籤
4. 點擊 "添加" (Add)
5. 瀏覽並選擇 `make-runner.sh`
6. 設為默認程序

### 方法B：通過命令行
```bash
# 將make-runner.sh設為Makefile的默認打開程序
xdg-mime default make-runner.desktop text/x-makefile

# 或者直接關聯到腳本
gio mime text/x-makefile make-runner.sh
```

## 步驟4：測試
雙擊項目中的 `Makefile` 文件，應該會：
1. 打開終端
2. 顯示可用的make目標
3. 執行make命令
4. 顯示結果
5. 等待用戶按Enter關閉

## 故障排除
如果雙擊沒有反應：
1. 確認腳本有執行權限：`ls -la make-runner.sh`
2. 手動測試腳本：`./make-runner.sh`
3. 檢查文件關聯：`xdg-mime query default text/x-makefile`

## 自定義選項
您可以編輯 `make-runner.sh` 來：
- 添加特定的make目標
- 修改終端顯示樣式
- 添加預處理或後處理步驟
