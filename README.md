# Testing (MBR)

- `qemu-system-x86_64 -nodefaults -nographic -hda installer.bin -serial mon:stdio -m 1024M`

# Testing (EFI)

- `qemu-system-x86_64 -nodefaults -nographic -hda installer.bin -serial mon:stdio -m 1024M -bios /usr/share/ovmf/OVMF.fd`
