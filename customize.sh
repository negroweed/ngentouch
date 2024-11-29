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

test_util_linux() {
    local bbox="$1"
    local s=/data/local/tmp/test.sh
    
    echo "while true; do sleep 60; done" >$s
    chmod +x $s
    
    # exec dummy script
    sh $s & local pid=$!
    
    # testing
    if $bbox renice -n -5 -p $pid >/dev/null 2>&1; then
        local renice=1
    fi
    
    if $bbox chrt -f -p 5 $pid >/dev/null 2>&1; then
        local chrt=1
    fi
    
    # kill and remove the script
    kill -TERM $pid
    rm $s
    
    # print the result
    if [ -n "$renice" ] && [ -n "$chrt" ]; then
        return 0
    else
        return 1
    fi
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

print_info "Finding Prebuilt BusyBox Binary..."
sleep 2

if [ -f "/data/adb/ksu/bin/busybox" ]; then
    BB_BIN=/data/adb/ksu/bin/busybox
elif [ -f "/data/adb/ap/bin/busybox" ]; then
    BB_BIN=/data/adb/ap/bin/busybox
elif [ -f "/data/adb/magisk/busybox" ]; then
    BB_BIN=/data/adb/magisk/busybox
else
    print_error "Couldn't find Prebuilt BusyBox binary!"
fi

busybox_module=$(find /data/adb/modules -name 'busybox')

print_info "Found Prebuilt BusyBox binary"
ui_print
print_info "Testing util-linux commands..."

if ! test_util_linux "$BB_BIN"; then
    if [ -n "$busybox_module" ]; then
        print_warn "They didn't worked properly."
        sleep 1
        print_info "Testing busybox module's util-linux commands..."
        if test_util_linux "$busybox_module"; then
            print_info "They worked properly:)"
            BB_BIN=$busybox_module
        else
            print_error "They didn't worked properly, change your busybox module."
        fi
    else
        print_info "They didn't worked properly, update your root manager or install busybox module"
    fi
else
    print_info "They worked properly:)"
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

print_info "Installation Completed, enjoy my module 🙂"

mv -f $TMPDIR/module.prop $MODPATH
set_perm_recursive "$MODPATH" 0 0 0777 0777
