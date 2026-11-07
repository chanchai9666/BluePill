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
	@echo "  make install    Install $(APP_BUNDLE) to $(INSTALL_DIR)"
	@echo "  make uninstall  Remove $(APP_BUNDLE) from $(INSTALL_DIR)"
	@echo "  make clean      Clean build artifacts and $(APP_BUNDLE)"

build:
	@./scripts/build-app.sh

test:
	@swift test

run: build
	@open $(APP_BUNDLE)

install: build
	@echo "==> Installing $(APP_BUNDLE) to $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_BUNDLE)"
	@cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/"
	@echo "==> Installed successfully to $(INSTALL_DIR)/$(APP_BUNDLE)"

uninstall:
	@echo "==> Removing $(APP_BUNDLE) from $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_BUNDLE)"
	@echo "==> Uninstalled successfully."

clean:
	@echo "==> Cleaning build artifacts..."
	@rm -rf .build $(APP_BUNDLE)
	@echo "==> Done."
