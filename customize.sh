#!/system/bin/sh
# ==============================================================================
# Xiaomi Thermal Neutralizer — Installation Script
# Target: Xiaomi / Redmi / POCO devices (SM6150 / Snapdragon)
# Environment: KernelSU, KernelSU-Next, APatch, Magisk
# ==============================================================================

ui_print "************************************************"
ui_print "*         XIAOMI THERMAL NEUTRALIZER           *"
ui_print "*           By Kiran (ProjectAether)           *"
ui_print "*         KernelSU & Magisk Systemless         *"
ui_print "************************************************"

ui_print "- Device: $(getprop ro.product.device 2>/dev/null || echo 'Xiaomi')"
ui_print "- SoC Platform: $(getprop ro.board.platform 2>/dev/null || echo 'sm6150')"

ui_print "- Setting up systemless overlay binaries..."
mkdir -p "$MODPATH/system/vendor/bin" 2>/dev/null

cat << 'EOF' > "$MODPATH/system/vendor/bin/thermal-engine"
#!/system/bin/sh
# Neutralized thermal-engine by Xiaomi Thermal Neutralizer
exit 0
EOF

cat << 'EOF' > "$MODPATH/system/vendor/bin/mi_thermald"
#!/system/bin/sh
# Neutralized mi_thermald by Xiaomi Thermal Neutralizer
exit 0
EOF

chmod 0755 "$MODPATH/system/vendor/bin/thermal-engine" 2>/dev/null || true
chmod 0755 "$MODPATH/system/vendor/bin/mi_thermald" 2>/dev/null || true
chcon u:object_r:vendor_file:s0 "$MODPATH/system/vendor/bin/thermal-engine" 2>/dev/null || true
chcon u:object_r:vendor_file:s0 "$MODPATH/system/vendor/bin/mi_thermald" 2>/dev/null || true

ui_print "- Setting file permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/system/vendor/bin/thermal-engine" 0 0 0755
set_perm "$MODPATH/system/vendor/bin/mi_thermald" 0 0 0755

ui_print " "
ui_print "- Immediate action: stopping running thermal daemons..."
stop mi_thermald 2>/dev/null || true
stop vendor.thermal-engine 2>/dev/null || true
stop thermal-engine 2>/dev/null || true
killall -9 thermal-engine mi_thermald 2>/dev/null || true

ui_print "- Clearing active cooling device throttle states..."
for cd in /sys/class/thermal/cooling_device*; do
    [ -f "$cd/cur_state" ] && echo 0 > "$cd/cur_state" 2>/dev/null || true
done

ui_print "- Setting thermal profile to Benchmark/Extreme (sconfig 10)..."
echo 10 > /sys/class/thermal/thermal_message/sconfig 2>/dev/null || true

ui_print " "
ui_print "================================================"
ui_print "  XIAOMI THERMAL THROTTLING NEUTRALIZED!        "
ui_print "  Reboot to engage complete systemless masks.   "
ui_print "================================================"

