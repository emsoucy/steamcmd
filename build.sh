#!/bin/bash
set -o errexit

# Vars
CONTAINER=$(buildah from --ulimit nofile=2048 scratch)
MOUNTPOINT=$(buildah mount $CONTAINER)

URL='https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz'
STEAM=/home/steam/steamcmd
VER=$(egrep '^VERSION_ID' /etc/os-release | cut -d '=' -f2)

# Install dependencies
if [ $(command -v 'dnf') ]; then
  dnf install -y --installroot $MOUNTPOINT --releasever $VER \
    SDL2.i686 SDL2.x86_64 coreutils glibc-langpack-en glibc.i686 \
    libstdc++.i686 --nodocs --refresh --setopt install_weak_deps=False
  rm -rf $MOUNTPOINT/var/cache/dnf
else
  echo "Build script requires dnf package manager. Exiting."
  exit 1;
fi

# Create steam user
mkdir $MOUNTPOINT/home/steam
echo 'steam:x:1000:1000::/home/steam:/bin/bash' >> $MOUNTPOINT/etc/passwd
echo 'steam:x:1000:' >> $MOUNTPOINT/etc/group
echo "PATH=\$PATH:$STEAM" >> $MOUNTPOINT/home/steam/.bashrc
buildah config --user steam:steam $CONTAINER
buildah config --workingdir '/home/steam' $CONTAINER

# Get steamcmd, unpack, and update
mkdir $MOUNTPOINT$STEAM
wget -qO- $URL | tar xvzf - -C $MOUNTPOINT$STEAM
chmod -R 700 $MOUNTPOINT/home/steam
chown -R 1000:1000 $MOUNTPOINT/home/steam
buildah run $CONTAINER -- sh \
  -c "$STEAM/steamcmd.sh +login anonymous validate +exit"

buildah unmount $CONTAINER
buildah commit --squash $CONTAINER steamcmd 
