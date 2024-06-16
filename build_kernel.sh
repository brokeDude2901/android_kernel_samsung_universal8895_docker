#!/bin/bash
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
commit=$(git rev-parse --short HEAD)
adb devices
kernel=$(adb shell uname -a)
device=$(adb shell su -c "cat /proc/cmdline" | sed 's/ /\n/g' | grep androidboot.bootloader)
tmpfolder=/sdcard/tmp
if echo $device | grep 'G950[FN]'; then
	codename=dreamlte
elif echo $device | grep 'G955[FN]'; then
	codename=dream2lte
elif echo $device | grep 'N950[FN]'; then
	codename=greatlte    	
else	
	echo "Unknown device $device is not supported, make sure you only have 1 connected ADB device !"
    	exit
fi
bootdev=$(adb shell su -c find /dev/block/platform -iname boot) &&
bootimg=build_exynos8895-$codename-boot.img
defconfig=exynos8895-"$codename"_defconfig
echo ""
echo "**************************************************************************"
echo "Kernel	: $kernel"
echo "Device	: $codename ($device)"
echo "Boot	: $bootdev"
echo "Kconfig	: docker-$defconfig"
echo "Commit	: $commit"
echo "**************************************************************************"
adb shell su -c "mkdir -p $tmpfolder" &&
adb shell su -c "dd if=$bootdev of=$tmpfolder/$bootimg bs=4096" &&
adb pull $tmpfolder/$bootimg ./android/pulled-$bootimg &&
echo ""
echo "Compiling kernel with docker-$defconfig ..."
echo "=========================================================================="
cp ./arch/arm64/configs/$defconfig ./arch/arm64/configs/docker-$defconfig &&
cat << EOF >> ./arch/arm64/configs/docker-$defconfig
# Fix freeze/reset
CONFIG_NETFILTER_XT_MATCH_QTAGUID=n
# Fix no network inside container
CONFIG_ANDROID_PARANOID_NETWORK=n
# Fix postgres shmem problem
CONFIG_SYSVIPC=y
# Overlay2 with Native Diff support
CONFIG_OVERLAY_FS=y
# Others required by Docker
CONFIG_BRIDGE=y
CONFIG_BRIDGE_NETFILTER=y
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y
CONFIG_NETFILTER_XT_MATCH_IPVS=y
CONFIG_IP_VS=y
CONFIG_IP_VS_NFCT=y
CONFIG_IP_VS_PROTO_TCP=y
CONFIG_IP_VS_PROTO_UDP=y
CONFIG_IP_VS_RR=y
CONFIG_LOCALVERSION_AUTO=n
CONFIG_LOCALVERSION="-$commit-docker"
# Testing
CONFIG_BLK_CGROUP=y
CONFIG_CMDLINE="loop.max_part=7 cgroup_enable=blkio,cpu,cpuacct,devices,freezer,memory,pids,schedtune buildvariant=eng"
EOF
make mrproper &&
make docker-"$defconfig" &&
make -s -j $(nproc) || exit
echo ""
echo "Repacking kernel to compiled-$bootimg ..."
echo "=========================================================================="
mkdir -p ./android/magiskboot/tmp/ && 
cd ./android/magiskboot/tmp/ &&
chmod +x ../* &&
../magiskboot_x86 unpack -h ../../pulled-$bootimg &&
cp ../../../arch/arm64/boot/dtb.img ./extra &&
cp ../../../arch/arm64/boot/Image ./kernel &&
#sed -i '2s/.*/cmdline=androidboot.selinux=permissive/' header &&
../magiskboot_x86 repack ../../pulled-$bootimg ../../compiled-$bootimg &&
../magiskboot_x86 cleanup &&
cd ../../../ &&
echo ""
echo "Flashing new-$bootimg to $bootdev ..."
echo "=========================================================================="
adb push ./android/compiled-$bootimg $tmpfolder/compiled-$bootimg &&
adb shell su -c "dd if=$tmpfolder/compiled-$bootimg of=$bootdev bs=4096" &&
adb shell su -c "sync" &&
adb reboot
echo ""
echo "Done. Phone is rebooting!"
echo "=========================================================================="

