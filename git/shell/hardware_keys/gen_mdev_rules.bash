generate_mdev_rule() {
  # Read directly from sysfs (works without root and without fido2-token)
  for uevent in /sys/class/hidraw/hidraw*/device/uevent; do
    [ -r "$uevent" ] || continue
    # Extract HID_ID=0003:0000VVVV:0000PPPP
    hid_id=$(awk -F'=' '/^HID_ID=/{print $2}' "$uevent")
    # Convert 8-char padded hex to 4-char VID/PID if needed, or match HID_ID directly
    printf 'HID_ID=%s;hidraw[0-9]* root:plugdev 660\n' "$hid_id"
  done
}
