#!/bin/bash
set -o errexit

# Vars
CONTAINER=$(buildah from scratch)
MOUNTPOINT=$(buildah mount $CONTAINER)

URL='https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz'
STEAM=/home/steam/steamcmd
OS=$(egrep '^NAME' /etc/os-release | cut -d '=' -f2)
VER=$(egrep '^VERSION_ID' /etc/os-release | cut -d '=' -f2)

# Install dependencies
if [[ $OS =~ 'Fedora' ]]; then
  dnf install -y --installroot $MOUNTPOINT --releasever $VER coreutils\
    glibc.i686 libstdc++.i686 --nodocs --setopt install_weak_deps=False
  dnf clean all -y --installroot $MOUNTPOINT --releasever $VER
else
  echo "Unsupported OS. Exiting"; exit
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
buildah run $CONTAINER -- sh\
 -c "$STEAM/steamcmd.sh +login anonymous validate +exit"
buildah unmount $CONTAINER

buildah commit --squash $CONTAINER docker.io/emsoucy/steamcmd 
