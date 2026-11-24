#!/system/bin/sh
# ==============================================================================
# Xiaomi Thermal Neutralizer — Late Boot Background Service (service.sh)
# Target: Xiaomi / Redmi / POCO devices (Qualcomm Snapdragon)
# ==============================================================================

# Wait until boot completes
until [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ]; do
    sleep 2
done

neutralize_thermal() {
    # 1. Stop thermal daemons
    stop mi_thermald 2>/dev/null || true
    stop vendor.thermal-engine 2>/dev/null || true
    stop thermal-engine 2>/dev/null || true
    killall -9 thermal-engine mi_thermald 2>/dev/null || true

    # 2. Reset cooling devices to unthrottled state (cur_state 0)
    for cd in /sys/class/thermal/cooling_device*; do
        if [ -f "$cd/cur_state" ]; then
            echo 0 > "$cd/cur_state" 2>/dev/null || true
        fi
    done

    # 3. Configure Xiaomi thermal driver profile to benchmark/extreme (sconfig 10)
    if [ -f /sys/class/thermal/thermal_message/sconfig ]; then
        echo 10 > /sys/class/thermal/thermal_message/sconfig 2>/dev/null || true
    fi
    if [ -f /sys/class/thermal/thermal_message/balance_mode ]; then
        echo 0 > /sys/class/thermal/thermal_message/balance_mode 2>/dev/null || true
    fi

    # 4. Restore CPU frequency ceilings dynamically from hardware specs
    for pol in /sys/devices/system/cpu/cpufreq/policy*; do
        if [ -f "$pol/cpuinfo_max_freq" ]; then
            hardmax=$(cat "$pol/cpuinfo_max_freq" 2>/dev/null)
            if [ -n "$hardmax" ]; then
                echo "$hardmax" > "$pol/scaling_max_freq" 2>/dev/null || true
            fi
        fi
    done

    # 5. Restore Adreno GPU clock ceiling dynamically
    if [ -d /sys/class/kgsl/kgsl-3d0 ]; then
        if [ -f /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies ]; then
            max_gpu=$(tr ' ' '\n' < /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies 2>/dev/null | sort -n | tail -1)
            [ -n "$max_gpu" ] && echo "$max_gpu" > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 2>/dev/null || true
        elif [ -f /sys/class/kgsl/kgsl-3d0/max_gpuclk ]; then
            max_clk=$(cat /sys/class/kgsl/kgsl-3d0/max_gpuclk 2>/dev/null)
            [ -n "$max_clk" ] && echo "$max_clk" > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 2>/dev/null || true
        fi
        [ -f /sys/class/kgsl/kgsl-3d0/max_pwrlevel ] && echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel 2>/dev/null || true
    fi
}

# Run immediately upon boot completion
neutralize_thermal

# Lightweight watchdog: ensures thermal daemons remain neutralized
# Runs every 60 seconds with zero measurable CPU/battery impact
(
    while true; do
        sleep 60
        # If any cooling device is clamped by thermal HAL, reset it
        for cd in /sys/class/thermal/cooling_device[0-9]*; do
            if [ -f "$cd/cur_state" ]; then
                state=$(cat "$cd/cur_state" 2>/dev/null)
                if [ "$state" != "0" ] && [ -n "$state" ]; then
                    echo 0 > "$cd/cur_state" 2>/dev/null || true
                fi
            fi
        done
        # Ensure sconfig stays at 10
        if [ -f /sys/class/thermal/thermal_message/sconfig ]; then
            cur_sconfig=$(cat /sys/class/thermal/thermal_message/sconfig 2>/dev/null)
            if [ "$cur_sconfig" != "10" ]; then
                echo 10 > /sys/class/thermal/thermal_message/sconfig 2>/dev/null || true
            fi
        fi
    done
) &
