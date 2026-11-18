generate_udev_rule() {
  # Parse vendor and product hex IDs from fido2-token -L (requires read access to hidraw)
  fido2-token -L | while IFS=': ,' read -r dev _ vid _ pid desc; do
    vid="${vid#vendor=0x}"
    pid="${pid#product=0x}"
    
    # Optional: Look up clean strings from systemd hwdb if installed
    # hwdb_info=$(systemd-hwdb query "usb:v${vid^^}p${pid^^}*")

    cat <<EOF
# ${desc}
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="${vid}", ATTRS{idProduct}=="${pid}", TAG+="uaccess"
EOF
  done
}
