# How to create a bootable USB drive
- `dd if=installer.bin of=/dev/sdX` where `sdX` is the device node of your USB drive, see `cat /proc/partitions`
# Testing
- `# qemu-img create -f qcow2 hdd.qcow2 32G` 
- `qemu-system-x86_64 -nodefaults -serial mon:stdio -m 1024M -drive file=installer.bin -drive id=mysdcard,if=none,format=qcow2,file=hdd.qcow2 -device sdhci-pci -device sd-card,drive=mysdcard -bios /usr/share/OVMF/OVMF_CODE.fd -netdev user,id=user0 -net nic -netdev hubport,hubid=0,id=port2,netdev=user0 -vga virtio`
