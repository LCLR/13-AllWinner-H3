# Recompile with: mkimage -C none -A arm -T script -d boot.cmd boot.scr
# CPU=H3
# OS=ubuntu-tft

echo "running ubuntu-tft boot.scr"
setenv fsck.repair yes
setenv ramdisk rootfs.cpio.gz
setenv kernel zImage

setenv env_addr 0x45000000
setenv kernel_addr 0x46000000
setenv ramdisk_addr 0x47000000
setenv dtb_addr 0x48000000

fatload mmc 0 ${kernel_addr} ${kernel}
fatload mmc 0 ${ramdisk_addr} ${ramdisk}
setenv ramdisk_size ${filesize}

fatload mmc 0 ${dtb_addr} sun8i-${cpu}-${board}.dtb
fdt addr ${dtb_addr}

# setup XR819 MAC address
if test $board = nanopi-duo; then fdt set xr819 local-mac-address ${wifi_mac_node}; fi

# setup boot_device
fdt set mmc${boot_mmc} boot_device <1>

setenv fbcon map:1
setenv overlayfs data=/dev/mmcblk0p3
#setenv hdmi_res drm_kms_helper.edid_firmware=HDMI-A-1:edid/1280x720.bin video=HDMI-A-1:1280x720@60
setenv pmdown snd-soc-core.pmdown_time=3600000

setenv bootargs "console=ttyS0,115200 earlyprintk
root=/dev/mmcblk0p2 rootfstype=ext4 rw rootwait fsck.repair=${fsck.repair}
panic=10 fbcon=${fbcon} ${hdmi_res} ${overlayfs} ${pmdown}"

bootz ${kernel_addr} ${ramdisk_addr}:${ramdisk_size} ${dtb_addr}
