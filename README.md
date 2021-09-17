## Another steamcmd base image?
Yes. I wanted to build a smaller base image from scratch without relying on a 3rd party OS base image built for general use. This is designed to lay the foundation for Steam dedicated server containers.

## Building
Currently designed to use ```dnf``` package manager to install the few required packages into the mounted from-scratch image.
```
buildah unshare bash build.sh
```

## Usage
The image uses default user ```steam``` whose path contains ```steamcmd.sh```

To install a game inside the container:
```
$HOME/steamcmd/steamcmd.sh +login anonymous +app_update $appId validate +exit
```
```$appId``` is the unique Steam application ID.
Steam application IDs can be found at [SteamDB](https://steamdb.info/apps/).