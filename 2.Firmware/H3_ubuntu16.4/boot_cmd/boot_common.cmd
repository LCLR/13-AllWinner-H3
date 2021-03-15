# Recompile with: mkimage -C none -A arm -T script -d boot.cmd boot.scr
# CPU=H3
# OS=friendlycore/ubuntu-oled/ubuntu-wifiap/openwrt/debian/debian-nas...

echo "running boot.scr"
setenv load_addr 0x44000000
setenv fix_addr 0x44500000
fatload mmc 0 ${load_addr} uEnv.txt
env import -t ${load_addr} ${filesize}

fatload mmc 0 ${kernel_addr} ${kernel}
fatload mmc 0 ${ramdisk_addr} ${ramdisk}
setenv ramdisk_size ${filesize}

fatload mmc 0 ${dtb_addr} sun8i-${cpu}-${board}.dtb
fdt addr ${dtb_addr}

# merge overlay
fdt resize 65536
overlay search
for i in ${overlays}; do
    if fatload mmc 0 ${load_addr} overlays/sun8i-h3-${i}.dtbo; then
        echo "applying overlay ${i}..."
        fdt apply ${load_addr}
    fi
done
fatload mmc 0 ${fix_addr} overlays/sun8i-h3-fixup.scr
source ${fix_addr}

# setup XR819 MAC address
if test $board = nanopi-duo; then fdt set xr819 local-mac-address ${wifi_mac_node}; fi

# setup boot_device
fdt set mmc${boot_mmc} boot_device <1>

setenv overlayfs data=/dev/mmcblk0p3
#setenv hdmi_res drm_kms_helper.edid_firmware=HDMI-A-1:edid/1280x720.bin video=HDMI-A-1:1280x720@60
setenv pmdown snd-soc-core.pmdown_time=3600000

setenv bootargs "console=${debug_port} earlyprintk
root=/dev/mmcblk0p2 rootfstype=ext4 rw rootwait fsck.repair=${fsck.repair}
panic=10 fbcon=${fbcon} ${hdmi_res} ${overlayfs} ${pmdown}"

bootz ${kernel_addr} ${ramdisk_addr}:${ramdisk_size} ${dtb_addr}
