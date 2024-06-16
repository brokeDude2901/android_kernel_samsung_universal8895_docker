# Docker for Exynos 8895
![image](https://github.com/brokeDude2901/android_kernel_samsung_universal8895_docker/assets/46110534/a4d9fce1-3650-4a70-b185-6030f1c3460e)
LinuxDeployPro             |  docker info
:-------------------------:|:-------------------------:
![](https://github.com/brokeDude2901/android_kernel_samsung_universal8895_docker/assets/46110534/c2398df6-e49c-488d-a43b-a044624b7fef)|![](https://github.com/brokeDude2901/android_kernel_samsung_universal8895_docker/assets/46110534/3dc96bbc-3376-49c6-af5c-16f85926982c)



## Tested working:
- Docker 26.1.4
- Storage Driver: vfs+overlay2 (do not use vfs please)
- Network Driver: bridged+host (working internet inside containers)
- hello-world, ubuntu, portainer, postgresql, npm, immich-app...

## What currently not working or not tested
- Docker on native Termux doesn't work, use LinuxDeploy or chroot Termux instead
- `docker stats` give zero stats
- No cpuset, no blkio features

## Installation
- Install TWRP with Heimdall (Linux) or Odin (Windows) (https://twrp.me/samsung/samsunggalaxynote8.html, https://twrp.me/samsung/samsunggalaxys8.html, https://twrp.me/samsung/samsunggalaxys8plus.html)
- Install the ROM from https://xdaforums.com/t/rom-10-hadesrom-q-v3-0-for-exynos-s8-s8-note8-04-02-2022.4208403/
- Root the rom with Magisk APK from https://github.com/topjohnwu/Magisk/releases/tag/v27.0
- Enable ADB Debugging and keep your phone connected via USB
- Clone this repo and run `build_kernel.sh` and wait for the compiled boot.img to flash automatically via ADB
- Install LinuxDeployPro APK from https://github.com/lateautumn233/Linuxdeploy-Pro, install your favorite chroot distro (ie: Ubuntu 22.04)
- Install latest Docker from https://get.docker.com: `curl -sSL https://get.docker.com/ | sh`
- Make a bash script to start Docker daemon (replace `192.168.1.1` with your actual gateway)
```
opts='rw,nosuid,nodev,noexec,relatime'
cgroups='blkio cpu cpuacct devices freezer memory pids'

# fix iptables so you can run with bridged network driver
ip route add default via 192.168.1.1 dev wlan0
ip rule add from all lookup main pref 30000

# unmount all cgroup
umount /sys/fs/cgroup/*
umount /sys/fs/cgroup

# try to mount cgroup root dir and exit in case of failure
if ! mountpoint -q /sys/fs/cgroup 2>/dev/null; then
  mkdir -p /sys/fs/cgroup
  mount -t tmpfs -o "${opts}" cgroup_root /sys/fs/cgroup || exit
fi

# try to mount differents cgroups
for cg in ${cgroups}; do
  if ! mountpoint -q "/sys/fs/cgroup/${cg}" 2>/dev/null; then
    mkdir -p "/sys/fs/cgroup/${cg}"
    mount -t cgroup -o "${opts},${cg}" "${cg}" "/sys/fs/cgroup/${cg}" \
    || rmdir "/sys/fs/cgroup/${cg}"
  fi
done
# start the docker daemon
dockerd
```
## Credits
- corsicanu for the ROM and kernel at https://github.com/corsicanu 
- FreddieOliveira for the guide at https://gist.github.com/FreddieOliveira/efe850df7ff3951cb62d74bd770dce27
