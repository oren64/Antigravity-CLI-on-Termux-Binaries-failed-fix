# Antigravity (AGY) Termux Installer

A custom installation script designed to patch and fix compatibility crashes when running **[wallentx/antigravity-cli-termux](https://github.com/wallentx/antigravity-cli-termux)** on Xiaomi and other ARMv8.0 Android devices. 

---

## 🔍 The Problem & The Fix

### What Was Wrong
When using the original installer, users on Xiaomi and various other Android architectures often hit an immediate crash: 
`[ERR] Binaries failed to execute locally`. 

This is caused by two critical hardware and kernel conflicts:
* **Missing CPU Instructions:** The official application utilizes **LSE (Large System Extensions)** instructions for speed. If your phone's processor relies on the **ARMv8.0** architecture, it cannot interpret these instructions, resulting in an `Illegal instruction` crash.
* **Memory Layout Mismatch:** The native application expects a standard Linux **48-bit memory space**, whereas many Android kernels enforce a **39-bit memory space**.

### The Fix
This installer deploys a custom environment that gracefully bypasses these hardware and kernel limitations:

> * **Emulation:** Utilizes `qemu-user-aarch64` to seamlessly "teach" your CPU how to execute the missing hardware instructions.
> * **Memory Patch:** Pulls a community-patched version of the engine (`va39`) explicitly rebuilt to match the Android 39-bit memory layout.
> * **Environment Shim:** Implements a library shim interface to route the application directly to the Termux `glibc` libraries without causing structural crashes.

---

## 🛠️ What the Script Does

The `install-agy.sh` script automates the entire setup environment by performing the following steps:

1. **Installs Requirements:** Ensures essential system packages like `glibc` and `qemu-user-aarch64` are present.
2. **Fetches the Engine:** Automatically downloads the latest 39-bit memory-compatible version of the engine.
3. **Bypasses CPU Limits:** Configures QEMU to emulate the missing instructions that cause crashes on Xiaomi devices.
4. **Fixes Library Paths:** Sets up a dedicated environment "shim" so the application can cleanly locate its dependencies within Termux.

---

## 🔄 How to Update

Updating is entirely automated. Because the script natively handles removing the old deployment and reinstalling the fresh build, you only need to run the command again:

```bash
bash install-agy.sh
