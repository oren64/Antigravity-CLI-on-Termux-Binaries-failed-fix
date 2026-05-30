#!/usr/bin/env bash
# Antigravity CLI - Universal Xiaomi/Termux Fix (V8 - Pro Performance)
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

# 1. Dependency Setup
echo -e "${CYAN}[1/4]${RESET} Updating packages..."
pkg update -y
pkg install -y glibc-repo 
pkg update -y
pkg install -y glibc qemu-user-aarch64 curl tar util-linux

# 2. Download Engine
echo -e "${CYAN}[2/4]${RESET} Downloading patched engine..."
mkdir -p "$AGY_HOME/bin" "$AGY_HOME/lib"
curl -fL "$URL" | tar -xzf - -C "$AGY_HOME" bin/agy.va39
mv -f "$AGY_HOME/bin/agy.va39" "$AGY_HOME/bin/agy.engine"

# 3. Library Shim
echo -e "${CYAN}[3/4]${RESET} Setting up library shims..."
ln -sf "$PREFIX/glibc/lib/"* "$AGY_HOME/lib/"
rm -f "$AGY_HOME/lib/libc.so"
ln -sf "$PREFIX/glibc/lib/libc.so.6" "$AGY_HOME/lib/libc.so"

# 4. The Launcher (Pro Performance V8)
echo -e "${CYAN}[4/4]${RESET} Creating high-performance launcher..."
cat << 'EOF' > "$AGY_HOME/agy.sh"
#!/usr/bin/env bash
export AGY_HOME="$HOME/.antigravity-termux"
export LD_PRELOAD=""
unset LD_LIBRARY_PATH
export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"

# Performance Hacks
export QEMU_CPU=max
export QEMU_GUEST_BASE=0   # Faster memory mapping
export GOMAXPROCS=1        # Reduce context switching lag
export GOGC=off            # Reduce garbage collection lag (heavy but fast)
export GODEBUG=cpu.all=off,netdns=go

# taskset -c 4-7 binds to high-performance "Big" cores on Xiaomi devices
# This significantly reduces input lag.
exec taskset -c 4-7 qemu-aarch64 "$AGY_HOME/lib/ld-linux-aarch64.so.1" \
     --library-path "$AGY_HOME/lib" \
     "$AGY_HOME/bin/agy.engine" "$@"
EOF

chmod +x "$AGY_HOME/agy.sh"
ln -sf "$AGY_HOME/agy.sh" "$BIN_DEST"

echo -e "------------------------------------------"
echo -e "${GREEN}${BOLD}Success! Ultimate Performance Fix Applied.${RESET}"
"$AGY_HOME/agy.sh" --version
