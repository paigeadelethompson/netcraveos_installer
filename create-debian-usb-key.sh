#!/usr/bin/env bash

DIRNAME="$(dirname $0)"

DISK="$1"
: "${DEBIAN_RELEASE:=stretch}"
: "${DEBIAN_VERSION:=9.2.1}"
: "${DEBIAN_MIRROR:=http://ftp.debian.org}"
: "${ARCH:=amd64}"
: "${REMOTE_ISO:=https://cdimage.debian.org/debian-cd/current/${ARCH}/iso-cd/debian-${DEBIAN_VERSION}-${ARCH}-netinst.iso}"
ISO_NAME="${REMOTE_ISO##*/}"

usage() {
  cat << EOF
Usage: $0 <disk> <iso>

disk     Disk to use (e.g. /dev/sdb) - will be wiped out

Overriding options via environment variables
DEBIAN_RELEASE  Release of Debian (default: buster)
DEBIAN_VERSION  VERSION of Debian (default: 9.2.1)
DEBIAN_MIRROR   Debian mirror (default: http://ftp.debian.org)
ARCH            Architecture (default: amd64)
EOF
}

[ $# -ne 1 ]     && echo "Please provide required args" && usage && exit 1
[ -z "${DISK}" ] && echo "Please provide a disk"        && usage && exit 1

EFI="${DISK}p2"
ROOT="${DISK}p3"
KEYS="${DISK}p4"

echo "Getting ISO"
wget --continue -O "${DIRNAME}/${ISO_NAME}" "${REMOTE_ISO}"
ISO="${DIRNAME}/${ISO_NAME}"

parted ${DISK} mklabel gpt 
parted ${DISK} mkpart primary fat32 1 2
parted ${DISK} set 1 bios_grub on
parted ${DISK} mkpart primary fat32 2 100
parted ${DISK} mkpart primary ext2 100 4000
parted ${DISK} mkpart primary fat32 4000 4700
parted ${DISK} set 2 boot on

echo "Creating a filesystem on ${EFI}"
mkfs.vfat -F32 "${EFI}"

echo "Creating a filesystem on ${ROOT}"
mkfs.ext2 "${ROOT}"

echo "Creating a filesystem on ${KEYS}"
mkfs.exfat "${KEYS}"

parted ${DISK} print

mkdir -p /mnt/
mount "${ROOT}" /mnt/
mkdir -p /mnt/boot/efi
mount "${EFI}" /mnt/boot/efi

grub-install --target=x86_64-efi "${DISK}" --efi-directory=/mnt/boot/efi --boot-directory=/mnt/boot

grub-install "${DISK}" --boot-directory=/mnt/boot

echo "Download the initrd image"
mkdir "/mnt/hdmedia-${DEBIAN_RELEASE}"
wget -O "/mnt/hdmedia-${DEBIAN_RELEASE}/vmlinuz" "${DEBIAN_MIRROR}/debian/dists/${DEBIAN_RELEASE}/main/installer-${ARCH}/current/images/hd-media/vmlinuz"
wget -O "/mnt/hdmedia-${DEBIAN_RELEASE}/initrd.gz" "${DEBIAN_MIRROR}/debian/dists/${DEBIAN_RELEASE}/main/installer-${ARCH}/current/images/hd-media/initrd.gz"
mkdir -p /mnt/isos
rsync -aP "${ISO}" /mnt/isos

echo "Create grub config file"
cat << EOF > /mnt/boot/grub/grub.cfg
set timeout_style=menu
set timeout=32
set hdmedia="/hdmedia-${DEBIAN_RELEASE}"
set preseed="/hd-media/preseed"
set iso="/isos/${ISO_NAME}"

menuentry "Debian ${DEBIAN_RELEASE} ${ARCH} auto install" {
  linux  \$hdmedia/vmlinuz iso-scan/filename=\$iso priority=critical auto=true preseed/file=\$preseed/preseed.cfg console=tty0 console=ttyS0,115200n8 DEBIAN_FRONTEND=text DEBCONF_DEBUG=5
  initrd \$hdmedia/initrd.gz
}
EOF

mkdir /mnt/preseed

sync

umount /mnt/boot/efi
umount /mnt/

