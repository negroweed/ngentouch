#!/system/bin/sh
MODDIR=$(dirname "$0")
until [ -n "$(getprop sys.boot_completed)" ]; do
	sleep 1
done

# exec main script
$MODDIR/script/ntm.sh