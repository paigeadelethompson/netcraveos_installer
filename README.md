# Warning 
This image will erase anything already installed, use with caution. 

# How to create a bootable USB drive
- `dd if=installer.bin of=/dev/sdX` where `sdX` is the device node of your USB drive, see `cat /proc/partitions`
- The fourth partition in the image/on the USB drive is storage for SSH keys, it should mount on Linux or Windows and they will be installed to `/root/.ssh/authorized_keys`
# Testing
- Create a 32GB virtual disk `# qemu-img create -f qcow2 hdd.qcow2 32G` 
- Start QEMU with usermode networking and SD card emulation. This is a similar configuration to the zimaboard's hardware. You should only need `qemu-system-x86_64` and OVMF installed for this to work:
```
qemu-system-x86_64                                     \
-nographic                                             \
-nodefaults                                            \
-serial mon:stdio                                      \
-m 1024M                                               \
-drive file=installer.bin                              \
-drive id=mysdcard,if=none,format=qcow2,file=hdd.qcow2 \
-device sdhci-pci -device sd-card,drive=mysdcard       \
-bios /usr/share/OVMF/OVMF_CODE.fd                     \
-netdev user,id=user0                                  \
-net nic                                               \
-netdev hubport,hubid=0,id=port2,netdev=user0
