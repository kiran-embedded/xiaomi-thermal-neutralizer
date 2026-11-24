# Xiaomi Thermal Neutralizer

A lightweight, systemless Magisk / KernelSU / APatch module designed to safely neutralize aggressive userspace thermal throttling daemons (`mi_thermald` and `thermal-engine`) on Xiaomi, Redmi, and POCO devices powered by Qualcomm Snapdragon platforms.

---

## Overview

Modern Xiaomi devices running MIUI, HyperOS, or AOSP-derived custom ROMs employ aggressive userspace thermal management daemons. Specifically, `mi_thermald` and `thermal-engine` frequently impose hard frequency clamps on CPU and GPU cores at low thermal thresholds (often starting at 40°C–42°C battery/chassis temperature). This behavior leads to abrupt performance drops, micro-stuttering in demanding applications, and artificial frequency ceilings that bypass kernel governors.

**Xiaomi Thermal Neutralizer** provides a clean, surgical, and systemless solution:
1. Neutralizes userspace throttling daemons before initialization without deleting or breaking system binaries.
2. Engages Xiaomi's native in-kernel performance thermal profile (`sconfig 10`).
3. Dynamically restores unthrottled hardware frequency ceilings while preserving vital battery and hardware safety protections.

---

## Architecture & Implementation

### 1. Early-Boot Binary Masking (`post-fs-data.sh`)
During early boot (`post-fs-data`, prior to Zygote initialization), the module inspects common vendor partition paths:
- `/vendor/bin/thermal-engine`
- `/vendor/bin/mi_thermald`
- `/odm/bin/thermal-engine`
- `/odm/bin/mi_thermald`

Instead of deleting binaries or placing 0-byte dummy files (which can cause `init` aborts or `ENOEXEC` execution failures), the module mounts an executable POSIX stub:
```sh
#!/system/bin/sh
exit 0
```
labeled with the appropriate SELinux context (`u:object_r:vendor_file:s0`). When Android `init` attempts to launch these daemons, they exit cleanly with status code `0`, preventing respawn loops, service crashes, and log spam.

### 2. Driver Interface Engagement (`service.sh`)
Upon boot completion, the module interacts with Xiaomi's proprietary thermal sysfs interface:
- Sets `/sys/class/thermal/thermal_message/sconfig` to `10` (Xiaomi's official extreme performance profile).
- Sets `balance_mode` to `0`.
- Resets active states across all `/sys/class/thermal/cooling_device*/cur_state` nodes to `0`.

### 3. Dynamic Clock Ceiling Restoration
The module reads each CPU policy's hardware maximum directly from the Linux kernel (`cpuinfo_max_freq`) and restores `scaling_max_freq`:
- Automatically supports any Snapdragon architecture (e.g., SM6150, SM7150, SM7250, SM7325, SM8250, SM8350, SM8450, SM8550) without hardcoding arbitrary clocks.
- Restores Adreno GPU frequency limits from `/sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies`.

---

## Safety & Protection Model

Many generic "thermal disabler" modules employ hazardous methods—such as deleting `libthermalservice.so`, replacing `.rc` files with empty files, or echoing `0` into every kernel thermal zone. This can break `system_server`, disable Battery Management System (BMS) overtemperature cutoffs, and create thermal hazards during 33W–120W fast charging.

**Xiaomi Thermal Neutralizer takes a conservative, safety-first approach:**

| Protection Layer | Status | Description |
| :--- | :---: | :--- |
| **BMS Battery Temp Protection** | **Active** | Battery overtemperature and JEITA step-charging protections remain fully functional. |
| **In-Kernel Emergency Trips** | **Active** | Hardware-level critical thermal cutoffs (e.g., at 115°C junction) remain enforced by the kernel. |
| **System Library Integrity** | **Untouched** | No shared libraries (`.so`) or HAL `.rc` files are modified or emptied. |
| **SELinux Compliance** | **Enforced** | All mounted stubs maintain strict `vendor_file` labeling to avoid audit denials. |

---

## Compatibility

- **Platforms:** Qualcomm Snapdragon SoCs (Snapdragon 6xx, 7xx, 8xx, 8 Gen series).
- **OEM Firmware:** MIUI 12–14, Xiaomi HyperOS, and all AOSP/CAF-based custom ROMs (LineageOS, Paranoid Android, PixelOS, crDroid, etc.).
- **Root Solutions:**
  - Magisk v24.0+
  - KernelSU / KernelSU-Next
  - APatch

---

## Installation

1. Download the latest `Xiaomi-Thermal-Neutralizer-vX.X.X.zip` from the [Releases](https://github.com/kiran-embedded/xiaomi-thermal-neutralizer/releases) tab.
2. Open your root manager (KernelSU, Magisk, or APatch).
3. Navigate to **Modules** → **Install from storage**.
4. Select the downloaded ZIP file and confirm installation.
5. Reboot your device.

### Verification

After reboot, verify via an ADB shell or terminal emulator with root:
```sh
# 1. Verify daemons are not running (should return empty):
ps -ef | grep -iE "mi_thermald|thermal-engine" | grep -v grep

# 2. Check cooling device throttle states (should all return 0):
for cd in /sys/class/thermal/cooling_device*; do
    echo "$(basename $cd): $(cat $cd/cur_state 2>/dev/null)"
done

# 3. Check Xiaomi thermal profile (should return 10):
cat /sys/class/thermal/thermal_message/sconfig
```

---

## Uninstallation

1. Open your root manager and toggle or remove **Xiaomi Thermal Neutralizer**.
2. Reboot the device.
3. The module's `uninstall.sh` script automatically unbinds all mounts and restores default vendor services.

---

## License

This project is licensed under the [MIT License](LICENSE).
