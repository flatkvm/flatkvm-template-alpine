#!/bin/sh

if [ $(id -u) != 0 ]; then
	echo "This script must be run as root"
	exit -1
fi

B=$(which buildah)
if [ -z "${B}" ]; then
	echo "This script requires \"buildah\""
	exit -1
fi

which qemu-img > /dev/null
if [ $? != 0 ]; then
	echo "This script requires \"qemu-img\""
	exit -1
fi

which qemu-nbd > /dev/null
if [ $? != 0 ]; then
	echo "This script requires \"qemu-nbd\""
	exit -1
fi

CTR=$($B from alpine:edge)
$B copy $CTR files/repositories /etc/apk/repositories

$B run $CTR apk add busybox-initscripts busybox xorg-server xf86-input-keyboard xf86-input-mouse xf86-input-libinput ttf-ubuntu-font-family i3wm dbus dbus-x11 xterm lightdm lightdm-gtk-greeter pulseaudio pulseaudio-alsa openrc libgudev udev-init-scripts eudev udev-init-scripts-openrc xrandr flatpak alsa-utils consolekit2 sudo setxkbmap

$B copy $CTR files/flatkvm-boot /etc/init.d/flatkvm-boot
$B run $CTR rc-update add flatkvm-boot boot
$B run $CTR rc-update add acpid default
$B run $CTR rc-update add alsa default
$B run $CTR rc-update add bootmisc boot
$B run $CTR rc-update add dbus default
$B run $CTR rc-update add devfs sysinit
$B run $CTR rc-update add dmesg sysinit
$B run $CTR rc-update add hostname boot
$B run $CTR rc-update add killprocs shutdown
$B run $CTR rc-update add lightdm default
$B run $CTR rc-update add mount-ro shutdown
$B run $CTR rc-update add networking boot
$B run $CTR rc-update add udev sysinit
$B run $CTR rc-update add udev-postmount default
$B run $CTR rc-update add udev-trigger sysinit
$B run $CTR rc-update add urandom boot

$B copy $CTR files/shadow /etc/shadow
$B copy $CTR files/sudoers /etc/sudoers
$B copy $CTR files/group /etc/group
$B copy $CTR files/lightdm.conf /etc/lightdm/lightdm.conf
$B run $CTR mkdir -p /home/flatkvm/.config/i3
$B copy $CTR files/i3.config /home/flatkvm/.config/i3/config
$B run $CTR rm /etc/network/if-up.d/dad
$B copy $CTR files/interfaces /etc/network/interfaces
$B copy $CTR files/resolv.conf /etc/resolv.conf
$B copy $CTR files/asound.state /var/lib/alsa/asound.state
$B copy $CTR files/Xmodmap /home/flatkvm/.Xmodmap
$B copy $CTR files/flatkvm-agent /usr/bin/flatkvm-agent
$B run $CTR mkdir -p /var/lib/flatpak

$B copy $CTR files/roboto.tgz /tmp/roboto.tgz
$B run $CTR tar xpf /tmp/roboto.tgz -C /

qemu-img create -f qcow2 template-alpine-tmp.qcow2 1G
modprobe nbd
qemu-nbd -c /dev/nbd0 template-alpine-tmp.qcow2
mkfs.ext4 /dev/nbd0
mount /dev/nbd0 /mnt

MDIR=$($B mount $CTR)
cp -a $MDIR/. /mnt

umount /mnt
qemu-nbd -d /dev/nbd0
$B rm $CTR

qemu-img convert -c -f qcow2 -O qcow2 template-alpine-tmp.qcow2 template-alpine.qcow2
rm template-alpine-tmp.qcow2
