#!/system/bin/sh
# ==============================================================================
# Xiaomi Thermal Neutralizer — Early Boot Script (post-fs-data)
# ==============================================================================
MODDIR="${0%/*}"

# Prepare dummy binary if not present
DUMMY_BIN="/data/adb/xiaomi_thermal_neutralizer/dummy_bin"
mkdir -p /data/adb/xiaomi_thermal_neutralizer
if [ ! -f "$DUMMY_BIN" ]; then
    printf '#!/system/bin/sh\nexit 0\n' > "$DUMMY_BIN"
    chmod 0755 "$DUMMY_BIN" 2>/dev/null || true
    chcon u:object_r:vendor_file:s0 "$DUMMY_BIN" 2>/dev/null || true
fi

# Neutralize userspace binaries across all possible vendor partition paths
TARGETS="
/vendor/bin/thermal-engine
/system/vendor/bin/thermal-engine
/odm/bin/thermal-engine
/system/odm/bin/thermal-engine
/vendor/bin/mi_thermald
/system/vendor/bin/mi_thermald
/odm/bin/mi_thermald
/system/odm/bin/mi_thermald
"

for t_bin in $TARGETS; do
    if [ -f "$t_bin" ] && ! grep -q "$t_bin" /proc/mounts 2>/dev/null; then
        mount -o bind "$DUMMY_BIN" "$t_bin" 2>/dev/null || true
        chcon u:object_r:vendor_file:s0 "$t_bin" 2>/dev/null || true
    fi
done

# Stop services early before zygote initialization
stop mi_thermald 2>/dev/null || true
stop vendor.thermal-engine 2>/dev/null || true
stop thermal-engine 2>/dev/null || true

