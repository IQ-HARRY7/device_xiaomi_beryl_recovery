# PitchBlack Recovery Project (PBRP) Port Documentation for beryl

**Device**: Xiaomi Redmi Note 14 5G / POCO M7 Pro 5G (`beryl` / `citrine`)  
**Base**: OrangeFox 14.1 / TWRP Minimal Manifest  
**Target Recovery**: PitchBlack Recovery Project (PBRP)  
**Maintainer**: 🔥IQ_HARRY_07🔥  
**Date**: 2026-10-10  

---

## 1. Overview of Changes

We ported the `beryl` recovery device tree from OrangeFox Recovery Project (OFRP) to PitchBlack Recovery Project (PBRP) while preserving hardware functionality (MediaTek Dimensity 7025-Ultra, FBE v2 crypto, dynamic partitions, and `vendor_boot` Header v4 repacking).

---

## 2. File Changes Summary

### New Files Created:
- **`pb_beryl.mk`**:
  - Inherits `core_64_bit.mk`, `base.mk`, `updatable_apex.mk`, `gsi_keys.mk`, and `device/xiaomi/beryl/device.mk`.
  - Inherits PBRP common configuration: `$(call inherit-product-if-exists, vendor/pb/config/common.mk)`.
  - Defines `PRODUCT_DEVICE := beryl`, `PRODUCT_NAME := pb_beryl`, `PRODUCT_MODEL := Redmi Note 14 5G`.
  - Sets properties `ro.pbrp.device=beryl`, `ro.twrp.vendor_boot=true`, `persist.sys.fuse.passthrough.enable=true`.

### Files Modified:
- **`AndroidProducts.mk`**:
  - Registered `pb_beryl.mk` alongside `twrp_beryl.mk`.
  - Added modern lunch choices via `COMMON_LUNCH_CHOICES`:
    `pb_beryl-user`, `pb_beryl-userdebug`, `pb_beryl-eng`, `twrp_beryl-user`, `twrp_beryl-userdebug`, `twrp_beryl-eng`.
  - (No legacy `add_lunch_combo` in `vendorsetup.sh`—using `COMMON_LUNCH_CHOICES` standard).

- **`twrp_beryl.mk`**:
  - Replaced inclusion of `fox_beryl.mk` with `$(call inherit-product-if-exists, vendor/pb/config/common.mk)`.

- **`BoardConfig.mk`**:
  - Removed OrangeFox Soong plugin: `-include bootable/recovery/orangefox_soong.mk`.
  - Removed OrangeFox flashlight flags: `OF_FLASHLIGHT_ENABLE := 1` and `OF_FL_PATH1 := /tmp/flashlight`.
  - Added PBRP build variables:
    ```makefile
    # Flashlight / Torch
    PB_TORCH_PATH := "/sys/class/leds/flashlight"
    PB_TORCH_MAX_BRIGHTNESS := 1

    # PitchBlack Recovery Project (PBRP) Configuration
    PB_DEVICE_MODEL := "Redmi Note 14 5G"
    PB_DEVICE := beryl
    PB_TARGET_ARCH := arm64
    PB_SOC_PLATFORM := mt6855
    PB_VIRTUAL_AB_DEVICE := true
    PB_VENDOR_BOOT_RECOVERY := true
    PB_MAINTAINER := 🔥IQ_HARRY_07🔥
    PB_DISABLE_DEFAULT_DM_VERITY := true
    PB_DISABLE_DEFAULT_TREBLE_COMP := true
    PB_ENABLE_LPTOOLS := false
    TW_DEVICE_VERSION := "PBRP-beryl"
    ```

- **`vendorsetup.sh`**:
  - Removed deprecated `add_lunch_combo` calls.
  - Implemented smart device targeting (`pb_get_target_device`) with complete PBRP build flags:
    ```bash
    # Device & Maintainer metadata
    export PB_DEVICE="beryl"
    export TARGET_DEVICE_ALT="citrine"
    export PB_TARGET_DEVICES="beryl,citrine"
    export PB_MAINTAINER="🔥IQ_HARRY_07🔥"

    # Architecture & Chipset platform
    export PB_ARCH="arm64"
    export PB_TARGET_ARCH="arm64"
    export PB_SOC_PLATFORM="mt6855"
    export PB_CHIPSET="MediaTek Dimensity 7025-Ultra"

    # Virtual A/B & Vendor Boot Partition Configuration
    export PB_VIRTUAL_AB_DEVICE=1
    export PB_VIRTUAL_AB=1
    export PB_AB_DEVICE=1
    export PB_VENDOR_BOOT_RECOVERY=1
    export PB_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
    export PB_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"

    # Settings & Storage
    export PB_USE_DATA_RECOVERY_FOR_SETTINGS=1
    export PB_USE_UPDATED_MAGISKBOOT=1
    export PB_COMPRESS_EXECUTABLES=1

    # Binaries, Shell & Utilities
    export PB_USE_BASH_SHELL=1
    export PB_USE_BUSYBOX_BINARY=1
    export PB_USE_TAR_BINARY=1
    export PB_USE_SED_BINARY=1
    export PB_USE_XZ_UTILS=1
    export PB_USE_ZSTD_BINARY=1
    export PB_USE_LZ4_BINARY=1
    export PB_USE_DATE_BINARY=1
    export PB_REPLACE_TOOLBOX_GETPROP=1

    # Root Solutions Support (KernelSU-Next / SukiSu / Magisk)
    export PB_ENABLE_KERNELSU_NEXT_SUPPORT=1
    export PB_ENABLE_SUKISU_SUPPORT=1

    # Android 16 / API 36 prebuilts support
    export PB_ADD_API_V36_PREBUILTS=2
    ```

- **`custom_bootimg.mk`**:
  - Replaced hardcoded `FOX_MAGISKBOOT` with flexible multi-path `MAGISKBOOT` detection (`external/magisk-prebuilt`, `vendor/recovery/tools/magiskboot`, and system `$PATH`).
  - Removed OrangeFox post-processing hook `Fox_After_Recovery_Image` (lines 51-81) while preserving stock `vendor_boot` Header v4 repacking and AVB footer signing.

- **`README.md`**:
  - Updated title to PitchBlack Recovery Project (PBRP).

- **Reference / Backup files preserved**:
  - `fox_beryl.mk.bak`: Preserved OrangeFox configuration.
  - `vendorsetup.sh.ref`: User reference file.

---

## 3. How to Build PBRP for beryl

```bash
# In the root of your PBRP Android build directory:
source build/envsetup.sh
lunch pb_beryl-userdebug
# or lunch pb_beryl-eng

# Compile PBRP flashable zip and recovery image:
mka pbrp -j$(nproc --all)
# or
mka vendorbootimage -j$(nproc --all)
```
