.PHONY: all build test run install uninstall clean help

APP_NAME = BluePill
APP_BUNDLE = $(APP_NAME).app
INSTALL_DIR = /Applications

all: build

help:
	@echo "BluePill Build System"
	@echo "====================="
	@echo "  make build      Build release binary and package into $(APP_BUNDLE)"
	@echo "  make test       Run test suite (Unit & Integration tests)"
	@echo "  make run        Open $(APP_BUNDLE)"
	@echo "  make install    Stop running app, uninstall old version, build fresh, install to $(INSTALL_DIR), and clean build artifacts"
	@echo "  make uninstall  Stop running app and remove from $(INSTALL_DIR)"
	@echo "  make clean      Clean build artifacts and $(APP_BUNDLE)"

build:
	@./scripts/build-app.sh

test:
	@swift test

run: build
	@open $(APP_BUNDLE)

install:
	@echo "==> 1. Stopping running $(APP_NAME) instances..."
	@-killall $(APP_NAME) 2>/dev/null || true
	@sleep 1
	@echo "==> 2. Uninstalling previous version from $(INSTALL_DIR)/$(APP_BUNDLE)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_BUNDLE)"
	@echo "==> 3. Building fresh release of $(APP_NAME)..."
	@./scripts/build-app.sh
	@echo "==> 4. Installing to $(INSTALL_DIR)/$(APP_BUNDLE)..."
	@cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/"
	@echo "==> 5. Cleaning build artifacts..."
	@rm -rf .build $(APP_BUNDLE)
	@echo "==> Successfully installed to $(INSTALL_DIR)/$(APP_BUNDLE)"

uninstall:
	@echo "==> Stopping running $(APP_NAME) instances..."
	@-killall $(APP_NAME) 2>/dev/null || true
	@echo "==> Removing $(APP_BUNDLE) from $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_BUNDLE)"
	@echo "==> Uninstalled successfully."

clean:
	@echo "==> Cleaning build artifacts..."
	@rm -rf .build $(APP_BUNDLE)
	@echo "==> Done."
