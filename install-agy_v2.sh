#!/usr/bin/env bash
# Antigravity CLI - Xiaomi/Legacy ARM Fix Installer (V3 - Improved Compatibility)
set -e

BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

AGY_HOME="$HOME/.antigravity-termux"
BIN_DEST="$PREFIX/bin/agy"
URL="https://github.com/wallentx/antigravity-cli-termux/releases/latest/download/antigravity-termux-standalone.tar.gz"

echo -e "${CYAN}${BOLD}Antigravity CLI - Xiaomi/Termux Installer${RESET}"
echo -e "------------------------------------------"

# 1. Check for Play Store version (common cause of 'Package not found')
if [[ "$PREFIX" == *"/com.termux/files/usr"* ]] && [[ "$(uname -a)" == *"2020"* ]]; then
    echo -e "${RED}${BOLD}[CRITICAL] You are using the deprecated Play Store version of Termux.${RESET}"
    echo -e "${YELLOW}Please uninstall this version and install Termux from F-Droid or GitHub.${RESET}"
    echo -e "The Play Store version is no longer updated and cannot install glibc.${RESET}"
    exit 1
fi

# 2. Install Dependencies
echo -e "${CYAN}[1/5]${RESET} Enabling specialized repositories..."
# We install glibc-repo first to "unlock" the glibc package
pkg update -y
pkg install -y glibc-repo || {
    echo -e "${YELLOW}Retrying repo activation...${RESET}"
    apt install -y glibc-repo
}

echo -e "${CYAN}[2/5]${RESET} Installing system dependencies..."
pkg update -y # Update again to see the new glibc packages
pkg install -y glibc qemu-user-aarch64 proot curl tar

# 3. Setup Directories
echo -e "${CYAN}[3/5]${RESET} Preparing directories..."
mkdir -p "$AGY_HOME/bin"
mkdir -p "$AGY_HOME/lib"

# 4. Download and Extract
echo -e "${CYAN}[4/5]${RESET} Downloading and patching engine..."
TMP_TAR=$(mktemp)
curl -fL "$URL" -o "$TMP_TAR"
tar -xzf "$TMP_TAR" -C "$AGY_HOME" bin/agy.va39
mv "$AGY_HOME/bin/agy.va39" "$AGY_HOME/bin/agy.engine"
rm "$TMP_TAR"

# 5. Setup Glibc Shim
echo -e "${CYAN}[5/5]${RESET} Configuring environment fixes..."
ln -sf "$PREFIX/glibc/lib/"* "$AGY_HOME/lib/"
rm -f "$AGY_HOME/lib/libc.so"
ln -sf "$PREFIX/glibc/lib/libc.so.6" "$AGY_HOME/lib/libc.so"

# 6. Create Wrapper
cat << 'EOF' > "$AGY_HOME/agy.sh"
#!/usr/bin/env bash
AGY_HOME="$HOME/.antigravity-termux"
export LD_PRELOAD=""
unset LD_LIBRARY_PATH
export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"
export GODEBUG=cpu.all=off,netdns=go

exec proot -b "$PREFIX/etc/resolv.conf:/etc/resolv.conf" \
           -b "$PREFIX/etc/tls/cert.pem:/etc/ssl/certs/ca-certificates.crt" \
           qemu-aarch64 "$AGY_HOME/lib/ld-linux-aarch64.so.1" --library-path "$AGY_HOME/lib" "$AGY_HOME/bin/agy.engine" "$@"
EOF

chmod +x "$AGY_HOME/agy.sh"
ln -sf "$AGY_HOME/agy.sh" "$BIN_DEST"

echo -e "------------------------------------------"
echo -e "${GREEN}${BOLD}Installation Successful!${RESET}"
echo -e "To update, simply run: ${BOLD}bash install-agy.sh${RESET}"
echo ""
agy --version
