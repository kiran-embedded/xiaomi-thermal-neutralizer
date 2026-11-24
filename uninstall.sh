#!/system/bin/sh
# Unbind any mounts
for t_bin in /vendor/bin/thermal-engine /system/vendor/bin/thermal-engine /odm/bin/thermal-engine /vendor/bin/mi_thermald /system/vendor/bin/mi_thermald /odm/bin/mi_thermald; do
    umount -l "$t_bin" 2>/dev/null || true
done
rm -rf /data/adb/xiaomi_thermal_neutralizer 2>/dev/null || true
start mi_thermald 2>/dev/null || true
start vendor.thermal-engine 2>/dev/null || true

