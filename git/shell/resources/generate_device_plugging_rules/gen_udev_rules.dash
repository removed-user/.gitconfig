#!/bin/dash
generate_udev_rule() {
    for dev in /sys/class/hidraw/hidraw*; do
        [ -r "$dev/device/uevent" ] || continue

        # Check report descriptor for FIDO usage page (0x06 0xd0 0xf1)
        if [ -r "$dev/device/report_descriptor" ]; then
            od -An -tx1 "$dev/device/report_descriptor" | tr -d ' \n' | grep -q "06d0f1" || continue
        else
            continue
        fi

        # Extract HID_ID (e.g., 0003:00001050:00000407) and HID_NAME
        hid_id=$(awk -F'=' '/^HID_ID=/{print $2}' "$dev/device/uevent")
        hid_name=$(awk -F'=' '/^HID_NAME=/{print $2}' "$dev/device/uevent")
        [ -n "$hid_id" ] || continue

        cat <<EOF
# ${hid_name:-FIDO2 Security Key}
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ENV{HID_ID}=="${hid_id}", TAG+="uaccess"
EOF
    done | awk '!seen[$0]++'
}
generate_udev_rule
