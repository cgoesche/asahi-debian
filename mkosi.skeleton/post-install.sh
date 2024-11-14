#!/bin/bash 

BOOT_UUID=${1}
ROOT_UUID=${2}

function log() {
	# In this case we are not passing command line arguments to 'echo'
	# but instead an output string 
	# shellcheck disable=SC2145
	echo "[$(tput setaf 2)$(tput bold)info$(tput sgr0)] ${@}"
}

log "Installing Firmware, UEFI Bootloader and Linux Asahi kernel"
apt update
apt install -y firmware-linux m1n1 linux-image-asahi
apt clean
rm -rf /var/lib/apt/lists/*

log "Creating /efi/EFI/BOOT/"
mkdir -p /efi/EFI/BOOT
cp /usr/lib/grub/arm64-efi/monolithic/grubaa64.efi /efi/EFI/BOOT/bootaa64.efi

#cat > /efi/EFI/boot/grub.cfg <<EOF
#search.fs_uuid "${BOOT_UUID}" root 
#set prefix=(\$root)'/grub'
#configfile \$prefix/grub.cfg
#EOF
log "Creating /efi/EFI/BOOT/grub.cfg"
cat > /efi/EFI/BOOT/grub.cfg <<EOF
search --no-floppy --fs-uuid --set=dev ${BOOT_UUID}
set prefix=(\$dev)/grub
export \$prefix
configfile \$prefix/grub.cfg
EOF

log "Creating /efi/EFI/debian/grub.cfg"
cat > /efi/EFI/debian/grub.cfg <<EOF
search --no-floppy --fs-uuid --set=dev ${BOOT_UUID}
set prefix=(\$dev)/grub
export \$prefix
configfile \$prefix/grub.cfg
EOF

INITRD="$(ls -1 /boot/initrd* | cut -d/ -f3 | sort | head -1)"
VMLINUZ="$(ls -1 /boot/vmlinuz* | cut -d/ -f3 | sort | head -1)"
log "Creating /boot/grub/grub.cfg"
cat > /boot/grub/grub.cfg <<EOF 
load_video
insmod gzio
insmod part_gpt
insmod ext2
search --no-floppy --fs-uuid --set=root ${BOOT_UUID}
echo "Loading Linux ${VMLINUZ} ..."
linux /${VMLINUZ} root=UUID=${ROOT_UUID} rw net.ifnames=0 
echo "Loading Linux ${INITRD} ..."
initrd /${INITRD}
boot
EOF

log "Setting hostname"
echo "asahi-debian" > /etc/hostname

log "Creating 'asahi-user' user and setting new password"
useradd -m -s /bin/bash asahi-user 
passwd asahi-user