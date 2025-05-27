
利用以下各項測試訊息,撰寫一個ubuntu可用的互動式script,給測試人員使用.
需要明確顯示各項成功與失敗,與最後的成功與失敗總結,顏色需要標示清楚.

# 網路

## 測試方式
   自動測試連線是否正常,自動判定成功或失敗,eth0/1都要測試

## 相關控制與參數
ping -I eth0 192.168.8.1 -w 30

ping -I eth1 192.168.8.1 -w 30


# gpio

## 測試方式
    點亮所有以下包含的gpioID,詢問測試人員是否點亮,關閉所有gpio,詢問測試人員是否已關閉,gpio運行結果顯示

## 相關控制與參數
gpioID : 5,6,8,13,16,17,90,91

echo gpioID > /sys/class/gpio/export

echo <in/out> > /sys/class/gpio/gpio<gpioID>/direction

echo 1 > /sys/class/gpio/gpio<gpioID>value

echo 0 > /sys/class/gpio/gpio<gpioID>value

cat /sys/class/gpio/gpio<gpioID>value

echo gpioID > /sys/class/gpio/unexport


# emmc

## 測試方式
    自動測試讀寫是否正常,自動判定成功或失敗

## 相關控制與參數
dd if=/dev/zero of=./test bs=1M count=500 conv=fsync
dd if=./test of=/dev/null bs=1M

# usb/sdcard

## 測試方式
    自動找尋usb/sdcard,自動測試讀寫是否正常,自動判定成功或失敗

## 相關控制與參數
ls /media/user1/{usb,sdcard}
dd if=/dev/zero of=/media/user1/{usb,sdcard}/test bs=1M count=50 conv=fsync

dd if=/media/user1/{usb,sdcard}/test of=/dev/zero bs=1M


# uart
## 測試方式
    自動測試uart是否正常,自動判定成功或失敗

## 相關控制與參數
root@mpc:/home/user1# fltest_uarttest -d /dev/ttyS4
Welcome to uart test
Send test data:
forlinx_uart_test.1234567890...
Read Test Data finished,Read:
forlinx_uart_test.1234567890...

root@mpc:/home/user1# fltest_uarttest -d /dev/ttyS3
Welcome to uart test
Send test data:
forlinx_uart_test.1234567890...
Read Test Data finished,Read:
forlinx_uart_test.1234567890...


# spi
## 測試方式
    自動測試spi是否正常,自動判定成功或失敗

## 相關控制與參數

root@mpc:/home/user1# fltest_spidev_test -D /dev/spidev0.0
spi mode: 0
bits per word: 8
max speed: 500000 Hz (500 KHz)

FF FF FF FF FF FF
40 00 00 00 00 95
FF FF FF FF FF FF
FF FF FF FF FF FF
FF FF FF FF FF FF
DE AD BE EF BA AD
F0 0D

# i2c
## 測試方式
    自動測試i2c是否正常,自動判定成功或失敗

## 相關控制與參數
root@mpc:/home/user1# i2cdetect -y 1
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f
10: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f
20: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f
30: 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f
40: 40 41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f
50: 50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f
60: 60 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f
70: 70 71 72 73 74 75 76 77

# time
## 測試方式
    自動測試時間是否正常,自動判定成功或失敗

## 相關控制與參數
date
hwclock -wu 
hwclock --show

# key
## 測試方式
    啟動後請測試人員由recovery按鈕開始依序按下4個按鈕,收到如下回應表示正常,自動判定成功或失敗

## 相關控制與參數
root@mpc:/home/user1# fltest_keytest
Available devices:
/dev/input/event2:    adc-keys
key115 Presse
key115 Released
key114 Presse
key114 Released
key139 Presse
key139 Released


