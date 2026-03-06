#!/bin/bash

NEW_TIME="2026-03-01 1:30:00"

echo "Disable NTP auto synchronization..."
sudo timedatectl set-ntp false

echo "Setting system time to: $NEW_TIME"
sudo timedatectl set-time "$NEW_TIME"

echo "Writing system time to RTC..."
sudo hwclock --systohc

#echo "Re-enabling NTP auto synchronization..."
#sudo timedatectl set-ntp true

echo
echo "===== Current System Time ====="
date

echo
echo "===== RTC Time ====="
sudo hwclock -r

echo
echo "===== Time Sync Status ====="
timedatectl status
