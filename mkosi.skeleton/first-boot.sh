#!/bin/bash

# Logging the output to log file
exec > >(tee /tmp/first-boot.log ) 2>&1

ROOT_PART="$(/usr/sbin/blkid --label debian-root)"
ESP="$(/usr/sbin/blkid -L "EFI - ASAHI")"
ESP_MNT_DIR="$(findmnt -nm "${ESP}" | cut -d' ' -f1)"
FIRMWARE_TARBALL="${ESP_MNT_DIR}/vendorfw/firmware.tar"


function log() {    
    case ${1} in
        1) echo "[$(tput setaf 1)$(tput bold)alert$(tput sgr0)] ${2}"
        ;;
        6) echo "[$(tput setaf 2)$(tput bold)info$(tput sgr0)] ${2}"
        ;;
        *) echo "${1}"
        ;;
    esac
}

function welcome_message() {
cat <<EOF
                                                                                                     
        %%%%%%%%                                                    %%                               
     %%%%@      %%%%               @@@@             @@@@          #%%%%#                             
   %%%%           %%%%             @@@#              @@@            %@                               
  %%               *%              @@@               @@@                                             
 %%#      #%        %%       @@@@@@@@@     @@@@@@@   @@@  @@@@@    @@@@   @@@@@@@@@    @@@@ *@@@@@*  
 %@      #          %%     @@@@    @@@   @@@    @@@  @@@%@@@@@@@%  @@@@   @@%   @@@@    @@@@@  @@@@* 
 %#      %      *   %     #@@@     @@@  @@@*    %@@% @@@@    @@@@  %@@@          @@@@   @@@%    @@@@ 
 %#      *%   %    % *    @@@*     @@@  @@@     #@@@ @@@      @@@  #@@@      *@%@@@@@   @@@     @@@@ 
 #%       ##%   %%        @@@      @@@  @@@@@@@@@@@@ @@@      @@@  #@@@   @@@@@%%@@@@   @@@     @@@@ 
  %%                      @@@@     @@@  @@@          @@@      @@@  #@@@  @@@     @@@@   @@@     @@@@ 
   %%                     %@@@     @@@  @@@@         @@@     *@@@  %@@@  @@@     @@@@   @@@     @@@@ 
    %%                     @@@@   @@@@%  @@@@        @@@     @@@   @@@@  @@@%   @@@@@   @@@     @@@@ 
      %%                    @@@@@@@@@@@   @@@@@@@@@  @@@@@@@@@     @@@@   @@@@@@ @@@@   @@@     @@@@ 
        #%                                                                                           
                                                                                                     
Welcome to your new Asahi Debian OS brought to you by many many community members of various projects.

I am glad that you have decided to install Debian on your Apple Silicon using my installer images. 
If you want you can give me feedback on your overall experience and/or advice on how to improve things.

I will regularly work on this poject until Debian officially releases an upstream version for Apple Silicon hardware.

Now, to finalize your installation please follow the steps below and let the script handle the rest.

Have fun with your new system and good luck :D 

Copyright (c) 2024 Christian Goeschel Ndjomouo, Debian, Asahi Linux


EOF
}

function expanding_root_fs() {
    log "6" "Identifying root partition ..."
    if [[ -n "${ROOT_PART}" ]]; then 
        log "6" "Root partition found: ${ROOT_PART}"
    else 
        log "1" "Root partition could not be detected ... this is fatal!"
        exit 1
    fi
    
    log "6" "Expanding root partition filesystem to full disk size"
    /usr/sbin/resize2fs "${ROOT_PART}"

    return 0
}

function extract_firmware() {
    log "6" "Identifying EFI system partition ..."
    if [[ -n "${ESP}" ]]; then 
        log "6" "EFI system partition found: ${ESP}"
    else 
        log "1" "EFI system partition could not be detected ... this is fatal!"
        exit 1
    fi

    log "6" "Extracting firmware"
    if ! tar -C /lib/firmware -xf "${FIRMWARE_TARBALL}"; then
        log "1" "Failed to load Broadcom Wireless driver"
        return 1
    fi

    return 0
}

function setup_wifi() {
    log "6" "Loading Broadcom Wireless driver"
    rm -f /etc/modprobe.d/blacklist.conf
    
    if ! modprobe brcmfmac &>/dev/null; then
        log "1" "Failed to load Broadcom Wireless driver"
        return 1
    fi

    systemctl restart NetworkManager.service

    return 0
}

function main() {
    welcome_message
    printf "This script will finalize the system setup and fix current issues found in most Asahi Linux installations\n"
    read -r -p "Do you want to proceed (y/N) ?: " reply
    if [[ ! "${reply}" =~ ^[yY] ]]; then
        log "6" "Operation cancelled ..."
        exit 1
    fi

    log "6" "Starting system setup ..."
    expanding_root_fs

    if extract_firmware; then
        setup_wifi
    fi
    
    log "6" "Updating GRUB"
    update-grub
}

if ! main; then
    log "1" "System setup failed ... please review log messages in /tmp/first-boot.log"
fi
log "6" "System setup completed successfully, please reboot now."