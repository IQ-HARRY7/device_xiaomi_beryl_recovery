# Copyright (C) 2025-2026 OrangeFox Recovery Project
# SPDX-License-Identifier: GPL-3.0-only

FDEVICE="beryl"

fox_get_target_device() {
    local chkdev=""

    if [ -n "$ZSH_VERSION" ]; then
        local current_source="${(%):-%x}"
        chkdev=$(echo "$current_source" | grep -w "$FDEVICE")
    elif [ -n "$BASH_VERSION" ]; then
    	chkdev=$(echo "$BASH_SOURCE" | grep -w "$FDEVICE")
    fi

    if [ -n "$chkdev" ]; then
    	FOX_BUILD_DEVICE="$FDEVICE"
    else
        if [ -n "$BASH_VERSION" ]; then
 		chkdev=$(set | grep BASH_ARGV | grep -w "$FDEVICE")
        elif [ -n "$ZSH_VERSION" ]; then
		chkdev=$(echo "$*" | grep -w "$FDEVICE")
	fi
	[ -n "$chkdev" ] && FOX_BUILD_DEVICE="$FDEVICE"
    fi
}

if [ -z "$1" -a -z "$FOX_BUILD_DEVICE" ]; then
	fox_get_target_device
fi

if [ "$1" = "$FDEVICE" -o "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then

    export LC_ALL="C"
    export ALLOW_MISSING_DEPENDENCIES=true
    export BUILD_USERNAME=OrangeFox
    export BUILD_HOSTNAME=github

    export FOX_VENDOR_BOOT_RECOVERY=1
    export FOX_VANILLA_BUILD=1
    export TARGET_DEVICE_ALT="citrine"
    export FOX_TARGET_DEVICES="beryl,citrine"

    export FOX_VIRTUAL_AB_DEVICE=1
    export FOX_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
    export FOX_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"

    export FOX_USE_DATA_RECOVERY_FOR_SETTINGS=1
    export FOX_USE_UPDATED_MAGISKBOOT=1
    export FOX_COMPRESS_EXECUTABLES=1

    # Binaries & Tools
    export FOX_USE_BASH_SHELL=1
    export FOX_USE_BUSYBOX_BINARY=1
    export FOX_USE_TAR_BINARY=1
    export FOX_USE_SED_BINARY=1
    export FOX_USE_XZ_UTILS=1
    export FOX_USE_ZSTD_BINARY=1
    export FOX_USE_LZ4_BINARY=1
    export FOX_USE_DATE_BINARY=1
    export FOX_REPLACE_TOOLBOX_GETPROP=1

    # OrangeFox Addons
    export FOX_ENABLE_APP_MANAGER=1
    export FOX_DELETE_AROMAFM=1
    export FOX_DELETE_INITD_ADDON=1

    # prevent automated reboot when flashing Orangefox.zip
    export FOX_INSTALLER_DISABLE_AUTOREBOOT=1

    # to reduce Orangefox size
    export FOX_DRASTIC_SIZE_REDUCTION=1

    # KernelSU-Next / SukiSu support
    export FOX_ENABLE_KERNELSU_NEXT_SUPPORT=0
    # export FOX_ENABLE_SUKISU_SUPPORT=1
    #Temporary disabled.

    # to fix CANNOT LINK EXECUTIVES & Keystore2 related issues in "Android 16" (ONLY!)
    export FOX_ADD_API_V36_PREBUILTS=2

else
    if [ -z "$FOX_BUILD_DEVICE" ] && [ -z "$BASH_SOURCE" ] && [ -z "$ZSH_VERSION" ]; then
	echo "I: This script requires bash or zsh. Not processing $FDEVICE"
    fi
fi
#
