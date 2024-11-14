#!/usr/bin/env bash

PROJECT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
MKOSI_OUT_DIR="${PROJECT_DIR}/mkosi.output"
MKOSI_CACHE_DIR="${PROJECT_DIR}/mkosi.cache"
IMAGE_VERSION="$( head -n1 "${PROJECT_DIR}"/VERSION )"
IMAGE_ID="asahi-debian-12-base"
MKOSI_ROOT_FS_DIR_NAME="${IMAGE_ID}_${IMAGE_VERSION}"
MOUNTPOINT_DIR="${PROJECT_DIR}/mnt"
ASAHI_INSTALL_IMAGES_DIR="${PROJECT_DIR}/asahi.install.images"

EFI_UUID=$(uuidgen | tr '[a-z]' '[A-Z]' | cut -c1-8 | fold -w4 | paste -sd '-')
ROOT_UUID=$(uuidgen)
BOOT_UUID=$(uuidgen)


function log() {
	# In this case we are not passing command line arguments to 'echo'
	# but instead an output string 
	# shellcheck disable=SC2145
	echo "[$(tput setaf 2)$(tput bold)info$(tput sgr0)] ${@}"
}

function unmount_images() {
    [[ -n "$(findmnt -n "${MOUNTPOINT_DIR}"/efi)" ]] && umount -Rf "${MOUNTPOINT_DIR}"/efi && log "Unmounted ${MOUNTPOINT_DIR}/efi"
    [[ -n "$(findmnt -n "${MOUNTPOINT_DIR}"/boot)" ]] && umount -Rf "${MOUNTPOINT_DIR}"/boot && log "Unmounted ${MOUNTPOINT_DIR}/boot"
    [[ -n "$(findmnt -n "${MOUNTPOINT_DIR}")" ]] && umount -Rf "${MOUNTPOINT_DIR}" && log "Unmounted ${MOUNTPOINT_DIR}"
}

function mount_images() {
    [[ -z "$(findmnt -n "${MOUNTPOINT_DIR}")" ]] && mount -o loop "${ASAHI_INSTALL_IMAGES_DIR}"/root.img "${MOUNTPOINT_DIR}" && log "Mounted ${ASAHI_INSTALL_IMAGES_DIR}/root.img to ${MOUNTPOINT_DIR}"
    [[ -z "$(findmnt -n "${MOUNTPOINT_DIR}"/boot)" ]] && mount -o loop "${ASAHI_INSTALL_IMAGES_DIR}"/boot.img "${MOUNTPOINT_DIR}"/boot && log "Mounted ${ASAHI_INSTALL_IMAGES_DIR}/boot.img to ${MOUNTPOINT_DIR}/boot"
    [[ -z "$(findmnt -n "${MOUNTPOINT_DIR}"/boot/efi)" ]] && mount --bind "${ASAHI_INSTALL_IMAGES_DIR}"/esp/ "${MOUNTPOINT_DIR}"/boot/efi/ && log "Bound ${ASAHI_INSTALL_IMAGES_DIR}/esp/ to ${MOUNTPOINT_DIR}/boot/efi/"
}

function create_asahi_install_images() {
	unmount_images
    # Get the absolute path to the mkosi generated root filesystem
    mkosi_rootfs_absolute_path="$( realpath -- "$(find "${MKOSI_OUT_DIR}" -type d -iname "${MKOSI_ROOT_FS_DIR_NAME}" | sort | head -1 )")"
    
    mkdir "${MOUNTPOINT_DIR}"
    mkdir -p "${MOUNTPOINT_DIR}"/efi


    log "Creating Asahi installation images ..."
    rm -rf "${ASAHI_INSTALL_IMAGES_DIR:?}"/*
    rm -rf "${mkosi_rootfs_absolute_path}"/var/lib/apt/lists/*

    log "Creating ${ASAHI_INSTALL_IMAGES_DIR}/efi.img ..."
    fallocate -l "512MB" "${ASAHI_INSTALL_IMAGES_DIR}"/efi.img

    log "Creating ${ASAHI_INSTALL_IMAGES_DIR}/boot.img ..."
    fallocate -l "2G" "${ASAHI_INSTALL_IMAGES_DIR}"/boot.img

    log "Creating ${ASAHI_INSTALL_IMAGES_DIR}/root.img ..."
    fallocate -l "8G" "${ASAHI_INSTALL_IMAGES_DIR}"/root.img

    log "Creating fat filesystem on efi.img"
    mkfs.msdos "${ASAHI_INSTALL_IMAGES_DIR}"/efi.img

    log "Creating ext2 filesystem on boot.img"
    mkfs.ext2 -U "${BOOT_UUID}" -L debian-boot -b 4096 "${ASAHI_INSTALL_IMAGES_DIR}"/boot.img

    log "Creating ext4 filesystem on root.img"
    mkfs.ext4 -U "${ROOT_UUID}" -L debian-root -b 4096 "${ASAHI_INSTALL_IMAGES_DIR}"/root.img

    mount -o loop "${ASAHI_INSTALL_IMAGES_DIR}"/root.img "${MOUNTPOINT_DIR}"
    log "Mounted ${ASAHI_INSTALL_IMAGES_DIR}/root.img to ${MOUNTPOINT_DIR}"

    mkdir -p "${MOUNTPOINT_DIR}"/boot
    mount -o loop "${ASAHI_INSTALL_IMAGES_DIR}"/boot.img "${MOUNTPOINT_DIR}"/boot
    log "Mounted ${ASAHI_INSTALL_IMAGES_DIR}/boot.img to ${MOUNTPOINT_DIR}/boot"

    mkdir -p "${MOUNTPOINT_DIR}"/efi
    mount -o loop "${ASAHI_INSTALL_IMAGES_DIR}"/efi.img "${MOUNTPOINT_DIR}"/efi
    log "Mounted ${ASAHI_INSTALL_IMAGES_DIR}/efi.img to ${MOUNTPOINT_DIR}/efi"

    log 'Copying files to root.img'
    rsync -aHAX --exclude '/tmp/*' --exclude '/boot/*' --exclude '/home/*' --exclude '/efi' "${mkosi_rootfs_absolute_path}/" "${MOUNTPOINT_DIR}"
    log "Copying files to boot.img"
    rsync -aHAX "${mkosi_rootfs_absolute_path}"/boot/ "${MOUNTPOINT_DIR}"/boot
    
    log "Setting pre-defined uuid (${EFI_UUID}) for efi vfat partition in /etc/fstab"
    sed -i "s/EFI_UUID/${EFI_UUID}/" "${MOUNTPOINT_DIR}"/etc/fstab

    log "Setting uuid (${BOOT_UUID}) for ext2 boot partition in /etc/fstab"
    sed -i "s/BOOT_UUID/${BOOT_UUID}/" "${MOUNTPOINT_DIR}"/etc/fstab
    
    log "Setting uuid (${ROOT_UUID}) for ext4 partition in /etc/fstab"
    sed -i "s/ROOT_UUID/${ROOT_UUID}/" "${MOUNTPOINT_DIR}"/etc/fstab

    arch-chroot "${MOUNTPOINT_DIR}" grub-editenv create
    
    sed -i "s/ROOT_UUID/${ROOT_UUID}/" "${MOUNTPOINT_DIR}"/etc/kernel/cmdline
    arch-chroot "${MOUNTPOINT_DIR}" grub-install --target=arm64-efi --efi-directory=/efi
    arch-chroot "${MOUNTPOINT_DIR}" ./post-install.sh "${BOOT_UUID}" "${ROOT_UUID}"
}

mkosi clean
mkosi
create_asahi_install_images

log "Copying files ..."
rsync -aHAX "${MOUNTPOINT_DIR}"/efi/ "${ASAHI_INSTALL_IMAGES_DIR}"/esp/
rsync -aHAX "${MOUNTPOINT_DIR}"/boot/efi/ "${ASAHI_INSTALL_IMAGES_DIR}"/esp/

cd "${ASAHI_INSTALL_IMAGES_DIR}" || exit 1

echo "${EFI_UUID}" > "${PROJECT_DIR}"/efi.uuid

#log "Compressing boot.img root.img and esp/ ..."
#zip -r9 "${PROJECT_DIR}"/debian-12-base.zip .

#log "Unmounting umages ..."
#unmount_images

