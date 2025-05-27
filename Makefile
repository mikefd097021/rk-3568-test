# RK-3568 QC Test System Makefile

.PHONY: all install check test clean help run quick-start

# Default target - one-click run
all: run

# One-click run (recommended)
run:
	@echo "🚀 一鍵執行 QC 測試系統..."
	@if [ ! -x run_qc.sh ]; then \
		chmod +x run_qc.sh; \
	fi
	@if [ "$(shell id -u)" != "0" ]; then \
		echo "需要 root 權限，正在請求 sudo..."; \
		sudo bash run_qc.sh; \
	else \
		bash run_qc.sh; \
	fi

# Quick start alias
quick-start: run

# Set executable permissions (legacy)
install:
	@echo "設置執行權限..."
	chmod +x *.sh 2>/dev/null || true
	@echo "✓ 權限設置完成"

# Check environment only
check:
	@echo "檢查測試環境..."
	@if [ ! -x run_qc.sh ]; then \
		chmod +x run_qc.sh; \
	fi
	@if [ "$(shell id -u)" != "0" ]; then \
		sudo bash run_qc.sh --check-only; \
	else \
		bash run_qc.sh --check-only; \
	fi

# Run QC test only (legacy)
test:
	@echo "執行 QC 測試..."
	@if [ ! -x run_qc.sh ]; then \
		chmod +x run_qc.sh; \
	fi
	@if [ "$(shell id -u)" != "0" ]; then \
		sudo bash run_qc.sh --test-only; \
	else \
		bash run_qc.sh --test-only; \
	fi

# Clean temporary files
clean:
	@echo "清理臨時文件..."
	rm -f test_emmc
	rm -f /media/user1/usb/test_usb 2>/dev/null || true
	rm -f /media/user1/sdcard/test_sd 2>/dev/null || true
	rm -f /tmp/qc_test_*.log.old
	@echo "✓ 清理完成"

# Show help
help:
	@echo "🎯 RK-3568 QC 測試系統 - 一鍵使用"
	@echo ""
	@echo "🚀 推薦使用："
	@echo "  make          - 一鍵執行完整 QC 測試 (等同於 make run)"
	@echo "  make run      - 一鍵執行完整 QC 測試"
	@echo ""
	@echo "🔧 其他命令："
	@echo "  make check    - 只檢查測試環境"
	@echo "  make test     - 只執行 QC 測試"
	@echo "  make install  - 設置腳本執行權限"
	@echo "  make clean    - 清理臨時文件"
	@echo "  make help     - 顯示此幫助信息"
	@echo ""
	@echo "💡 使用流程："
	@echo "  1. 複製整個資料夾到 USB"
	@echo "  2. 在 RK-3568 上執行: make"
	@echo ""
	@echo "📋 或直接執行: sudo bash run_qc.sh"
