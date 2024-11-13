#!/bin/bash 

BOOT_UUID="${1}"
ROOT_UUID="${2}"

apt update
apt install -y firmware-linux m1n1 linux-image-asahi
apt clean
rm -rf /var/lib/apt/lists/*

mkdir -p /efi/EFI/boot
cp /usr/lib/grub/arm64-efi/monolithic/grubaa64.efi /efi/EFI/boot/bootaa64.efi

cat > /efi/EFI/boot/grub.cfg <<EOF
search.fs_uuid "${BOOT_UUID}" root 
set prefix=(\$root)'/grub'
configfile \$prefix/grub.cfg
EOF

INITRD=$(ls -1 boot/initrd* | cut -d/ -f2 )
VMLINUZ=$(ls -1 boot/vmlinuz* | cut -d/ -f2)
cat > /boot/grub/grub.cfg <<EOF 
search.fs_uuid ${BOOT_UUID} root 
linux (\$root)/${VMLINUZ} root=UUID=${ROOT_UUID} rw net.ifnames=0 
initrd (\$root)/${INITRD}
EOF
