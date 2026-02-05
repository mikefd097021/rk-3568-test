sudo apt update

sudo apt install python3-pip -y

sudo python3 -m pip install --upgrade pip setuptools

sudo apt install python3-tk -y


sudo python3 setup.py install

# 安裝後
/usr/local/lib/python3.x/dist-packages/fdttest

# 如何手動新增桌面捷徑？

假設你的程式安裝後可以用 myapp 執行，可以手動建立一個 .desktop 檔：

建立檔案

nano ~/.local/share/applications/myapp.desktop


寫入內容（依你的程式修改）：

[Desktop Entry]
Version=2.0
Name=MyApp
Comment=My Python Application
Exec=/usr/bin/python3 /usr/local/bin/myapp   # 或直接填可執行檔路徑
Icon=/usr/share/icons/hicolor/48x48/apps/myapp.png
Terminal=false
Type=Application
Categories=Utility;


儲存後賦予執行權限：

chmod +x ~/.local/share/applications/myapp.desktop


重新整理桌面/應用程式選單，你就能找到捷徑了。

🔹 如果你要「桌面上有圖示」

可以複製 .desktop 檔到桌面：

cp ~/.local/share/applications/myapp.desktop ~/Desktop/
chmod +x ~/Desktop/myapp.desktop


# kernel6
pip uninstall fdttest

pip install build

python3 -m build

pip install dist/fdttest-1.0-py3-none-any.whl
