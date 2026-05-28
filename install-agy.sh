#!/usr/bin/env bash
# Antigravity CLI - Xiaomi/Legacy ARM Fix Installer
# This script enables agy on devices that lack LSE instructions or 48-bit VA support.

set -e

BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

AGY_HOME="$HOME/.antigravity-termux"
BIN_DEST="$PREFIX/bin/agy"
URL="https://github.com/wallentx/antigravity-cli-termux/releases/latest/download/antigravity-termux-standalone.tar.gz"

echo -e "${CYAN}${BOLD}Antigravity CLI - Xiaomi/Termux Installer${RESET}"
echo -e "------------------------------------------"

# 1. Environment Check
if [[ "$(uname -m)" != "aarch64" ]]; then
    echo -e "${RED}[ERR] This script only supports aarch64 (ARM64).${RESET}"
    exit 1
fi

# 2. Install Dependencies
echo -e "${CYAN}[1/5]${RESET} Installing system dependencies..."
pkg update -y
pkg install -y glibc-repo glibc qemu-user-aarch64 curl tar

# 3. Setup Directories
echo -e "${CYAN}[2/5]${RESET} Preparing directories..."
mkdir -p "$AGY_HOME/bin"
mkdir -p "$AGY_HOME/lib"

# 4. Download and Extract
echo -e "${CYAN}[3/5]${RESET} Downloading and patching engine..."
TMP_TAR=$(mktemp)
curl -fL "$URL" -o "$TMP_TAR"
tar -xzf "$TMP_TAR" -C "$AGY_HOME" bin/agy.va39
mv "$AGY_HOME/bin/agy.va39" "$AGY_HOME/bin/agy.engine"
rm "$TMP_TAR"

# 5. Setup Glibc Shim
echo -e "${CYAN}[4/5]${RESET} Configuring glibc shim..."
ln -sf "$PREFIX/glibc/lib/"* "$AGY_HOME/lib/"
# Remove the linker script and replace with a direct symlink to the ELF
rm -f "$AGY_HOME/lib/libc.so"
ln -sf "$PREFIX/glibc/lib/libc.so.6" "$AGY_HOME/lib/libc.so"

# 6. Create Wrapper
echo -e "${CYAN}[5/5]${RESET} Creating launcher..."
cat << 'EOF' > "$AGY_HOME/agy.sh"
#!/usr/bin/env bash
AGY_HOME="$HOME/.antigravity-termux"
export LD_PRELOAD=""
unset LD_LIBRARY_PATH
export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"
export GODEBUG=cpu.all=off,netdns=go
qemu-aarch64 "$AGY_HOME/lib/ld-linux-aarch64.so.1" --library-path "$AGY_HOME/lib" "$AGY_HOME/bin/agy.engine" "$@"
EOF

chmod +x "$AGY_HOME/agy.sh"
ln -sf "$AGY_HOME/agy.sh" "$BIN_DEST"

echo -e "------------------------------------------"
echo -e "${GREEN}${BOLD}Installation Successful!${RESET}"
echo -e "You can now run ${BOLD}agy${RESET} from anywhere."
echo -e "To update, simply run this script again."
echo ""
agy --version
