# Warning 
This image will erase anything already installed, use with caution. 

# How to create a bootable USB drive
- `dd if=installer.bin of=/dev/sdX bs=1M` where `sdX` is the device node of your USB drive, see `cat /proc/partitions`
- The fourth partition in the image/on the USB drive is storage for SSH keys, it should mount on Linux or Windows. When the installer is run on the device, they will be installed to `/root/.ssh/authorized_keys`
# Testing
- Create a 32GB virtual disk `qemu-img create -f qcow2 hdd.qcow2 32G` 
- Add an SSH key to the image:
```
sudo losetup -P -f installer.bin
sudo mount mount -t vfat /dev/loop0p4 /mnt
ssh-keygen -t ed25519 -f ~/.ssh/id_netcrave_installer 
sudo cp ~/.ssh/id_netcrave_installer.pub /mnt/keys 
sudo umount /mnt
sudo losetup -d /dev/loop0
```
- Start QEMU with usermode networking and SD card emulation. This is a similar configuration to the zimaboard's hardware. You should only need `qemu-system-x86_64` and OVMF installed for this to work. OVMF is typically installed along-side `qemu-system-x86_64` so you only need to locate it. It's typically located in `/usr/share/ovmf` or `/usr/share/OVMF`. This does not require X11 and uses the serial port as a TTY and works in terminals: 
```
qemu-system-x86_64                                     \
-nographic                                             \
-nodefaults                                            \
-serial stdio                                          \
-curses                                                \
-smp 4                                                 \
-m 3840M                                               \
-drive file=installer.bin                              \
-drive id=mysdcard,if=none,format=qcow2,file=hdd.qcow2 \
-device sdhci-pci -device sd-card,drive=mysdcard       \
-bios /usr/share/OVMF/OVMF_CODE.fd                     \
-netdev user,id=user0,hostfwd=tcp::65534-:22           \
-net nic                                               \
-netdev hubport,hubid=0,id=port2,netdev=user0
```
## Network console 
The installer image will request `netcraveos.local` from the DHCP server and mDNS should resolve to it's DHCP leased address, in a perfect scenario: `ssh -i ~/.ssh/id_netcrave_installer root@netcraveos.local`. If you're using QEMU, use `ssh -i ~/.ssh/id_netcrave_installer localhost -p 65534` to connect instead.
