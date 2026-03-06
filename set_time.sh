#!/bin/bash

# 設定要修改的時間

NEW_TIME="2026-03-01 1:30:00"

echo "Setting system time to: $NEW_TIME"

# 設定系統時間

sudo timedatectl set-time "$NEW_TIME"

# 寫入硬體時鐘 (RTC)

sudo hwclock --systohc

echo "Time update completed."

echo
echo "Current system time:"
date

echo
echo "RTC time:"
sudo hwclock -r
