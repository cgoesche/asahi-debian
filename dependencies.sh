#!/usr/bin/env bash

declare -a PACKAGES=( build-essential \
bash \
git \
mount \
zip \
uuid-runtime \
locales \
gcc-aarch64-linux-gnu \ 
libc6-dev \
device-tree-compiler \ 
imagemagick \
ccache \
eatmydata \ 
debootstrap \ 
pigz \
libncurses-dev \ 
qemu-user-static \ 
binfmt-support \
rsync \
git \
bc \
kmod \
cpio \
libncurses5-dev \
libelf-dev:native \ 
libssl-dev \
dwarves \
zstd \
lsb-release \
clang-15 \
lld-15 \
debhelper \ 
clang-15 \
flex \
bison \
libclang-dev \
arch-install-scripts \
curl \
bubblewrap \
mkosi \ )

# shellcheck disable=SC2048
for pkg in ${PACKAGES[*]}; do 
    sudo apt install -y "${pkg}"
done

