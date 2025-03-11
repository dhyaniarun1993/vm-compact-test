# Detect OS and architecture
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m)
BIN_DIR := bin
ANALYZER_BIN := $(BIN_DIR)/analyzer

# Normalize architecture naming
ifeq ($(ARCH),x86_64)
    ARCH := amd64
endif
ifeq ($(ARCH),aarch64)
    ARCH := arm64
endif

# Detect package manager
PKG_MANAGER :=
ifeq ($(OS),linux)
    ifeq ($(shell command -v apt-get),/usr/bin/apt-get)
        PKG_MANAGER := sudo apt-get install -y
    else ifeq ($(shell command -v yum),/usr/bin/yum)
        PKG_MANAGER := sudo yum install -y
    else ifeq ($(shell command -v pacman),/usr/bin/pacman)
        PKG_MANAGER := sudo pacman -Sy --noconfirm
    endif
else ifeq ($(OS),darwin)
    PKG_MANAGER := brew install
endif

# Define the binary based on OS and ARCH
ANALYZER_URL := https://github.com/ChainSafe/vm-compat/releases/latest/download/analyzer-$(OS)-$(ARCH)

# Install llvm-objdump if missing
install-llvm:
	@echo "Checking if llvm-objdump is installed..."
	@which llvm-objdump >/dev/null 2>&1 || (echo "Installing llvm-objdump..." && $(PKG_MANAGER) llvm)

fetch-analyzer:
	@if [ -f "$(ANALYZER_BIN)" ]; then \
		echo "Analyzer binary already exists, skipping download."; \
	else \
		echo "Fetching Analyzer Binary for $(OS)-$(ARCH)..."; \
		mkdir -p $(BIN_DIR); \
		curl -L -o $(ANALYZER_BIN) $(ANALYZER_URL); \
		chmod +x $(ANALYZER_BIN); \
	fi


analyze-program: fetch-analyzer install-llvm
	@echo "Analyzing op-program-client for cannon-singlethreaded-32..."
	$(ANALYZER_BIN) analyze  --with-trace=true --format=json  --vm-profile cannon-singlethreaded-32 ./main.go