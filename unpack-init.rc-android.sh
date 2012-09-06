#!/bin/sh
###################################################
#
# This script unpacks the ramdisk boot image for 
# editing.
#  
# Typical usage is to execute:
# 
# 1. Attach adb to the device
# 2. execute:
# 
# $ ./unpack-init.rc-android.sh
#
# Which then opens init.rc file into an editor
# and allows for tweaking of the startup behavoir.
#
# Files unpacked are located here for reference:
# /tmp/initrd/fs/
#
# The files are repacked and sent to the device 
# after the editor (gedit in this case) is closed. 
#
# <chris.ladden@liquidware.com>
#
###################################################

#assumes file /media/boot/uInitrd exists

function pull() {
    echo "Setting up directories"
    rm -rf /tmp/initrd
    mkdir -p /tmp/initrd/fs
    cd /tmp/initrd/
    adb remount
    adb shell mkdir /sdcard/boot
    adb shell mount -t msdos /dev/block/mmcblk0p1 /sdcard/boot
    adb pull /sdcard/boot/uInitrd ./
}

function unpack() {
  echo "Unpacking fs"
	dd bs=1 skip=64 if=./uInitrd of=initrd.gz
	gunzip initrd.gz
	cd /tmp/initrd/fs
	cpio -id < ../initrd
	ls -l /tmp/initrd/fs
	echo "Unpacked fs to /tmp/initrd/fs"
}

function edit() {
	#edit
	echo "Opening: /tmp/initrd/fs/init.omap4pandaboard.rc"
	nano /tmp/initrd/fs/init.omap4pandaboard.rc
}

function pack() {
	#pack image
	echo "repacking fs"
	pushd /tmp/initrd/fs
	find ./ | cpio -H newc -o > ../newinitrd
	cd ..
	gzip newinitrd
	mkimage -A arm -O linux -C gzip -T ramdisk -n "My Android Ramdisk Image" -d newinitrd.gz uInitrd-new
}

function push() {
	#store image
	echo "sending image to android"
	adb push uInitrd-new /sdcard/boot/uInitrd
	adb shell sync 
	popd
}

#Parse arguments
while getopts ":i:k:" opt; do
HAVE_ARGS="1"
  case $opt in
    i)
        #Use init.rc file specified on the command line
        echo "-i init.rc was triggered, Parameter: $OPTARG" >&2
        thefile="$OPTARG"
        if [ -f $thefile ]; then
            pull
            unpack
            cp $thefile /tmp/initrd/fs/init.omap4pandaboard.rc
            pack
            push
        else
            echo "ERROR: File not found"
            exit 1
        fi
      ;;
    k)
        #Use a kernel file specified on the command line
        echo "-k kernel was triggered, Parameter: $OPTARG" >&2
        thefile="$OPTARG"
        if [ -f $thefile ]; then
            pull
            adb push $thefile /boot/uImage
            adb shell sync
        else
            echo "ERROR: File not found"
            exit 1
        fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ "$HAVE_ARGS" = "" ]; then
    #Main
    pull
    unpack
    edit
    pack
    push
fi
