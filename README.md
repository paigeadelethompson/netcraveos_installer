# Warning 
This image will erase anything already installed, use with caution. 

# How to create a bootable USB drive
- `dd if=installer.bin of=/dev/sdX bs=1M` where `sdX` is the device node of your USB drive, see `cat /proc/partitions`
- The fourth partition in the image/on the USB drive is storage for SSH keys, it should mount on Linux or Windows. When the installer is run on the device, they will be installed to `/root/.ssh/authorized_keys`
# Network installer console 
The installer image will request `netcraveos.local` from the DHCP server and mDNS should resolve to it's DHCP leased address, in a perfect scenario: `ssh installer@netcraveos.local`. If you're using QEMU, use `ssh installer localhost -p 65534` to connect instead. The password is `netcraveos`
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

### MacOS
- `hdiutil attach -nomount -imagekey diskimage-class=CRawDiskImage installer_mac.bin`

should give you something like 
```
/dev/disk8          	GUID_partition_scheme
/dev/disk8s1        	Bios Boot Partition
/dev/disk8s2        	EFI
/dev/disk8s3        	Linux Filesystem
/dev/disk8s4        	Microsoft Basic Data
```
- MacFUSE is required 
```
if [ ! -f e2fsprogs-1.43.4.tar.gz ]; then
    curl -O -L https://www.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v1.43.4/e2fsprogs-1.43.4.tar.gz
fi
tar -zxvf e2fsprogs-1.43.4.tar.gz
cd e2fsprogs-1.43.4
./configure --prefix=/opt/gnu --disable-nls
make
sudo make install
sudo make install-libs
sudo cp /opt/gnu/lib/pkgconfig/* /usr/local/lib/pkgconfig
cd ../
export PATH=/opt/gnu/bin:$PATH
export PKG_CONFIG_PATH=/opt/gnu/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

cd fuse-ext2
./autogen.sh
CFLAGS="-idirafter/opt/gnu/include -idirafter/usr/local/include/osxfuse/" LDFLAGS="-L/opt/gnu/lib -L/usr/local/lib" ./configure
make
sudo make install
```
- `mkdir ~/mnt`
- `fuse-ext2 /dev/disk8s3 ~/mnt -o rw+`
- qemu on MacOS

```
qemu-system-x86_64                                     \
-nographic                                             \
-nodefaults                                            \
-serial stdio                                          \
-smp 4                                                 \
-m 3840M                                               \
-drive file=hdd.qcow2                                  \
-netdev user,id=user0,hostfwd=tcp::65534-:22           \
-net nic                                               \
-netdev hubport,hubid=0,id=port2,netdev=user0          \
-drive file=/dev/disk8                                 \
-drive if=pflash,format=raw,unit=0,file=/opt/homebrew/share/OVMF/OvmfX64/OVMF_CODE.fd,readonly=on   -drive if=pflash,format=raw,unit=1,file=/opt/homebrew/share/OVMF/OvmfX64/OVMF_VARS.fd
```

## Problems 
- There is no DXE for `sdhci-pci` on OVMF. Installing to it is possible but booting from it is not; have to use `-device file=hdd.qcow2` to boot it. 
- This will fail in a very unexpected way if there isn't enough memory provided (~1024M is a fair bet, it has to unpack the ISO in memory, the ISO and all of the installer components, enough to start up the partitioner, at which point the target filesystems become available.) 

