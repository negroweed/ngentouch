#!/system/bin/sh
#
# Free to use.
# You can steal/modify/copy any codes in this script without any credits.
#

# Automatically sets by the installer
BB=

# usage: write <VALUE> <PATH>
write() {
    if [ -f "$2" ]; then
        if [ ! -w "$2" ]; then
            chmod +w "$2"
        fi
        echo "$1" >"$2"
    fi
}

settings put global block_untrusted_touches 0
settings put system pointer_speed 7

i="/proc/touchpanel"
write "1" "$i/game_switch_enable"
write "1" "$i/oppo_tp_direction"
write "0" "$i/oppo_tp_limit_enable"
write "0" "$i/oplus_tp_limit_enable"
write "1" "$i/oplus_tp_direction"

# bump sampling rate
find /sys -type f -name 'bump_sample_rate' | while read -r boost_sr; do
    write "1" "$boost_sr"
done

# Enable Touch boost
write "1" /sys/module/msm_performance/parameters/touchboost
write "1" /sys/power/pnpmgr/touch_boost
write "enable 1" /proc/perfmgr/tchbst/user/usrtch
write "1" /proc/perfmgr/tchbst/kernel/tb_enable
write "1" /sys/devices/virtual/touch/touch_boost
write "1" /sys/module/msm_perfmon/parameters/touch_boost_enable

# InputDispatcher, and InputReader tweaks
tids=$(ps -Tp $(pidof -s system_server) -o tid,cmd | grep -E 'InputDispatcher|InputReader' | awk '{print $1}')

for tid in $tids; do
    $BB renice -n -20 -p $tid
    $BB chrt -f -p 99 $tid
done
