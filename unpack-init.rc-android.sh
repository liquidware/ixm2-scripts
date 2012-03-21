###################################################
#
# This script unpacks the ramdisk boot image for editing
# Typical usage is to quickyl edit init.rc file to adjust 
# startup behavoir.
#
# Files unpacked here:
# /tmp/initrd/fs/
#
# Files are repacked and sent to the device 
# after the editor (gedit in this case) is closed. 
#
# <chris.ladden@liquidware.com>
#
###################################################

#assumes file /media/boot/uInitrd exists
echo "Setting up directories"
rm -rf /tmp/initrd
mkdir /tmp/initrd
cd /tmp/initrd/
adb shell mkdir /sdcard/boot
adb shell mount -t msdos /dev/block/mmcblk0p1 /sdcard/boot
adb pull /sdcard/boot/uInitrd ./

echo "Unpacking fs"
dd bs=1 skip=64 if=./uInitrd of=initrd.gz
gunzip initrd.gz
mkdir fs
cd fs
cpio -id < ../initrd
ls -l /tmp/initrd/fs
echo "Unpacked fs to /tmp/initrd/fs"

#edit
echo "Opening: /tmp/initrd/fs/init.omap4pandaboard.rc"
gedit /tmp/initrd/fs/init.omap4pandaboard.rc

#pack image
echo "repacking fs"
pushd /tmp/initrd/fs
find ./ | cpio -H newc -o > ../newinitrd
cd ..
gzip newinitrd
mkimage -A arm -O linux -C gzip -T ramdisk -n "My Android Ramdisk Image" -d newinitrd.gz uInitrd-new

#store image
echo "sending image to android"
adb push uInitrd-new /sdcard/boot/uInitrd
adb shell sync 
popd