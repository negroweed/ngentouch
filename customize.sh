#!/bin/sh

SKIPUNZIP=1

print_info() {
    local msg="$1"
    ui_print "[INFO] $msg"
}

print_error() {
    local msg="$1"
    abort "[ERROR] $msg"
}

print_warn() {
    local msg="$1"
    ui_print "[WARN] $msg"
}

ui_print ""
ui_print "░█▀█░█▀▀░█▀▀░█▀█░▀█▀░█▀█░█░█░█▀▀░█░█
░█░█░█░█░█▀▀░█░█░░█░░█░█░█░█░█░░░█▀█
░▀░▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀"
ui_print "_____________________________________________"
ui_print "   Feel The Responsiveness and Smoothness!  "
ui_print ""
sleep 1

rm -rf /data/ngentouch

sleep 1

print_info "Finding BusyBox Binary..."
sleep 2

if [ -f "/data/adb/ksu/bin/busybox" ]; then
    BB_BIN=/data/adb/ksu/bin/busybox
elif [ -f "/data/adb/ap/bin/busybox" ]; then
    BB_BIN=/data/adb/ap/bin/busybox
elif [ -f "/data/adb/magisk/busybox" ]; then
    BB_BIN=/data/adb/magisk/busybox
else
    print_error "Couldn't find BusyBox binary!"
fi

if [ -n "$BB_BIN" ]; then
    print_info "Found BusyBox binary"
    ui_print
    print_info "Testing BusyBox util-linux commands..."
    
    # create dummy script
    s=/data/local/tmp/test.sh
    echo "while true; do sleep 60; done" >$s
    chmod +x $s
    
    # exec dummy script
    sh $s & pid=$!
    
    # testing
    if $BB_BIN renice -n -5 -p $pid >/dev/null 2>&1; then
        print_info "renice command worked properly"
        renice=1
    else
        print_warn "renice command didn't work properly"
    fi
    
    if $BB_BIN chrt -f -p 5 $pid >/dev/null 2>&1; then
        print_info "chrt command worked properly"
        chrt=1
    else
        print_warn "chrt command didn't work properly"
    fi
    
    # kill and remove the script
    kill -TERM $pid
    rm $s
    
    # print the result
    if [ -n "$renice" ] && [ -n "$chrt" ]; then
        print_info "BusyBox util-linux commands worked properly"
    else
        print_error "BusyBox util-linux commands didn't work properly!"
    fi
fi

ui_print
print_info "Testing settings commands..."

if settings put global test 1 2>/dev/null; then
    print_info "Test 1: PASSED"
    test1=1
else
    print_warn "Test 1: FAILED"
fi

a="$(settings get global test 2>/dev/null)"
if [ -n "$a" ] && [ "$a" != "null" ] && [ "$a" = "1" ]; then
    print_info "Test 2: PASSED"
    test2=1
else
    print_warn "Test 2: FAILED"
fi

if settings delete global test &>/dev/null; then
    print_info "Test 3: PASSED"
    test3=1
else
    print_warn "Test 3: FAILED"
fi

ui_print ""
if [ -n "$test1" ] && [ -n "$test2" ] && [ -n "$test3" ]; then
    print_info "Your ROM supports this module..."
else
    print_error "Your ROM doesn't support this module"
fi

unzip -o "$ZIPFILE" 'script/*' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'system.prop' -d "$MODPATH" >&2

# set the BB variable
sed -i "s|BB=|BB=$BB_BIN|g" $MODPATH/script/ntm.sh

mv -f $TMPDIR/module.prop $MODPATH

if cat /proc/cpuinfo | grep -q 'Qualcomm'; then
(
    echo 'persist.vendor.qti.inputopts.movetouchslop=0.1'
    echo 'persist.vendor.qti.inputopts.enable=true'
) >>$MODPATH/system.prop
fi

set_perm_recursive "$MODPATH" 0 0 0777 0777

print_info "Installation Completed, enjoy my module 🙂"