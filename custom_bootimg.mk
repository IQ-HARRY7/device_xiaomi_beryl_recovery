# Copyright (C) 2025-2026 The OrangeFox Recovery Project
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Custom boot/vendor_boot rules for beryl.
# Keeps default boot image behavior (AVB enabled) and replaces vendor_boot with
# a stock-based image that only swaps the recovery ramdisk.

ifdef BUILDING_BOOT_IMAGE
ifeq (true,$(BOARD_AVB_ENABLE))
$(INSTALLED_BOOTIMAGE_TARGET): $(MKBOOTIMG) $(AVBTOOL) $(INTERNAL_BOOTIMAGE_FILES) $(BOARD_AVB_BOOT_KEY_PATH) $(BOARD_GKI_SIGNING_KEY_PATH)
	$(call pretty,"Target boot image: $@")
	$(call build_boot_board_avb_enabled,$@)

.PHONY: bootimage-nodeps
bootimage-nodeps: $(MKBOOTIMG) $(AVBTOOL) $(BOARD_AVB_BOOT_KEY_PATH) $(BOARD_GKI_SIGNING_KEY_PATH)
	@echo "make $@: ignoring dependencies"
	$(foreach b,$(INSTALLED_BOOTIMAGE_TARGET),$(call build_boot_board_avb_enabled,$(b)))
endif
endif

ifdef BUILDING_VENDOR_BOOT_IMAGE
VENDOR_BOOT_STOCK ?= $(DEVICE_PATH)/prebuilt/vendor_boot.img
VENDOR_BOOT_PATCH_DIR := $(PRODUCT_OUT)/vendor_boot_patch
FOX_MAGISKBOOT ?= $(PWD)/vendor/recovery/tools/magiskboot

$(INSTALLED_VENDOR_BOOTIMAGE_TARGET): $(recovery_uncompressed_ramdisk) $(VENDOR_BOOT_STOCK) $(FOX_MAGISKBOOT) $(AVBTOOL)
	$(call pretty,"Target vendor_boot image: $@ (patched stock)")
	@if [ ! -f "$(VENDOR_BOOT_STOCK)" ]; then \
		echo "error: missing stock vendor_boot at $(VENDOR_BOOT_STOCK)"; \
		exit 1; \
	fi
	@rm -rf "$(VENDOR_BOOT_PATCH_DIR)"
	@mkdir -p "$(VENDOR_BOOT_PATCH_DIR)"
	@cp -f "$(VENDOR_BOOT_STOCK)" "$(VENDOR_BOOT_PATCH_DIR)/stock.img"
	@cd "$(VENDOR_BOOT_PATCH_DIR)" && "$(FOX_MAGISKBOOT)" unpack -n stock.img
	@if [ -f "$(VENDOR_BOOT_PATCH_DIR)/vendor_ramdisk/recovery.cpio" ]; then \
		cp -f "$(recovery_uncompressed_ramdisk)" "$(VENDOR_BOOT_PATCH_DIR)/vendor_ramdisk/recovery.cpio"; \
	else \
		cp -f "$(recovery_uncompressed_ramdisk)" "$(VENDOR_BOOT_PATCH_DIR)/vendor_ramdisk_recovery.cpio"; \
	fi
	@cd "$(VENDOR_BOOT_PATCH_DIR)" && "$(FOX_MAGISKBOOT)" repack stock.img new_vendor_boot.img
	@cp -f "$(VENDOR_BOOT_PATCH_DIR)/new_vendor_boot.img" "$@"
	$(call assert-max-image-size,$@,$(BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE))
	$(AVBTOOL) erase_footer --image $@ >/dev/null 2>&1 || true
	$(AVBTOOL) add_hash_footer \
		--image $@ \
		$(call get-partition-size-argument,$(BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE)) \
		--partition_name vendor_boot $(INTERNAL_AVB_VENDOR_BOOT_SIGNING_ARGS) \
		$(BOARD_AVB_VENDOR_BOOT_ADD_HASH_FOOTER_ARGS)

# Darth9 - vendor_boot
ifneq ($(NOT_ORANGEFOX),1)
	$(BASH) $(FOX_VENDOR) FOX_VENDOR_CMD="Fox_After_Recovery_Image" \
  	FOX_MANIFEST_VER="14.1" \
  	BOARD_BOOT_HEADER_VERSION="$(BOARD_BOOT_HEADER_VERSION)" \
  	TARGET_ARCH="$(TARGET_ARCH)" \
	TARGET_RECOVERY_ROOT_OUT="$(TARGET_RECOVERY_ROOT_OUT)" \
	TARGET_VENDOR_RAMDISK_OUT="$(TARGET_VENDOR_RAMDISK_OUT)" \
	MKBOOTIMG="$(MKBOOTIMG)" \
	MKBOOTFS="$(MKBOOTFS)" \
	INTERNAL_RECOVERYIMAGE_ARGS='"$(INTERNAL_RECOVERYIMAGE_ARGS)"' \
	INTERNAL_MKBOOTIMG_VERSION_ARGS="$(INTERNAL_MKBOOTIMG_VERSION_ARGS)" \
	BOARD_MKBOOTIMG_ARGS='"$(BOARD_MKBOOTIMG_ARGS)"' \
	TARGET_OUT="$(TARGET_OUT)" \
  	COMPRESSION_COMMAND="$(COMPRESSION_COMMAND)" \
  	INSTALLED_RECOVERYIMAGE_TARGET="$(INSTALLED_RECOVERYIMAGE_TARGET)" \
  	INSTALLED_BOOTIMAGE_TARGET="$(INSTALLED_BOOTIMAGE_TARGET)" \
  	BOARD_BOOTIMAGE_PARTITION_SIZE=$(BOARD_BOOTIMAGE_PARTITION_SIZE) \
  	BOARD_RECOVERYIMAGE_PARTITION_SIZE=$(BOARD_RECOVERYIMAGE_PARTITION_SIZE) \
  	BOARD_USES_RECOVERY_AS_BOOT=$(BOARD_USES_RECOVERY_AS_BOOT) \
  	INTERNAL_KERNEL_CMDLINE="$(INTERNAL_KERNEL_CMDLINE)" \
  	vendor_ramdisk="$(INTERNAL_VENDOR_RAMDISK_TARGET)" \
  	INSTALLED_VENDOR_BOOTIMAGE_TARGET="$(INSTALLED_VENDOR_BOOTIMAGE_TARGET)" \
  	BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE=$(BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE) \
	INTERNAL_VENDOR_BOOTIMAGE_ARGS='"$(INTERNAL_VENDOR_BOOTIMAGE_ARGS)"' \
  	BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT=$(BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT) \
  	BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT=$(BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT) \
  	ORANGEFOX_CALLING_CARD="1.0" \
  	recovery_ramdisk="$(recovery_ramdisk)"
endif
# Darth9 - vendor_boot
endif
