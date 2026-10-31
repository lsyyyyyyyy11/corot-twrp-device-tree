#!/system/bin/sh
# Reset the build-date.utc props to 1970-01-01 so TWRP's timestamp-based
# "is this zip older?" OTA checks never false-positive on a freshly built
# recovery image.
#
# Previous form passed the literal string "0000000000". That is not a valid
# Unix timestamp (it parses as 0 only by accident, and some property readers
# / callers of strftime rejected or mis-rendered it), and every resetprop
# failure was silently swallowed because the script unconditionally exited 0.
EPOCH=0

# Pick a prop-overriding tool that actually exists in this ramdisk. 'resetprop'
# ships with Magisk; if the recovery was built without it we fall back to
# busybox's 'setprop' applet, and only fail loudly if neither is available --
# otherwise the whole override would be a silent no-op.
if command -v resetprop >/dev/null 2>&1; then
    SETPROP() { resetprop -n "$1" "$2"; }
elif [ -x /system/bin/busybox ] && /system/bin/busybox setprop --help >/dev/null 2>&1; then
    SETPROP() { /system/bin/busybox setprop "$1" "$2"; }
else
    echo "overrideprops: no resetprop/busybox available, skipping" >&2
    exit 1
fi

rc=0
for p in \
    ro.build.date.utc \
    ro.system.build.date.utc \
    ro.system_ext.build.date.utc \
    ro.vendor.build.date.utc \
    ro.odm.build.date.utc \
    ro.product.build.date.utc; do
    if ! SETPROP "$p" "$EPOCH"; then
        echo "overrideprops: failed to set $p=$EPOCH" >&2
        rc=1
    fi
done
exit $rc
