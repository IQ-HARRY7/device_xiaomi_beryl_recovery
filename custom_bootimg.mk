# Copyright (C) 2026 PitchBlack Recovery Project
# SPDX-License-Identifier: Apache-2.0
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
MAGISKBOOT ?= $(PWD)/external/magisk-prebuilt/prebuilt/magiskboot_arm
ifeq ($(wildcard $(MAGISKBOOT)),)
    MAGISKBOOT := $(PWD)/vendor/recovery/tools/magiskboot
    ifeq ($(wildcard $(MAGISKBOOT)),)
        MAGISKBOOT := magiskboot
    endif
endif

$(INSTALLED_VENDOR_BOOTIMAGE_TARGET): $(recovery_uncompressed_ramdisk) $(VENDOR_BOOT_STOCK) $(AVBTOOL)
	$(call pretty,"Target vendor_boot image: $@ (patched stock)")
	@if [ ! -f "$(VENDOR_BOOT_STOCK)" ]; then \
		echo "error: missing stock vendor_boot at $(VENDOR_BOOT_STOCK)"; \
		exit 1; \
	fi
	@rm -rf "$(VENDOR_BOOT_PATCH_DIR)"
	@mkdir -p "$(VENDOR_BOOT_PATCH_DIR)"
	@cp -f "$(VENDOR_BOOT_STOCK)" "$(VENDOR_BOOT_PATCH_DIR)/stock.img"
	@cd "$(VENDOR_BOOT_PATCH_DIR)" && "$(MAGISKBOOT)" unpack -n stock.img
	@if [ -f "$(VENDOR_BOOT_PATCH_DIR)/vendor_ramdisk/recovery.cpio" ]; then \
		cp -f "$(recovery_uncompressed_ramdisk)" "$(VENDOR_BOOT_PATCH_DIR)/vendor_ramdisk/recovery.cpio"; \
	else \
		cp -f "$(recovery_uncompressed_ramdisk)" "$(VENDOR_BOOT_PATCH_DIR)/vendor_ramdisk_recovery.cpio"; \
	fi
	@cd "$(VENDOR_BOOT_PATCH_DIR)" && "$(MAGISKBOOT)" repack stock.img new_vendor_boot.img
	@cp -f "$(VENDOR_BOOT_PATCH_DIR)/new_vendor_boot.img" "$@"
	$(call assert-max-image-size,$@,$(BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE))
	$(AVBTOOL) erase_footer --image $@ >/dev/null 2>&1 || true
	$(AVBTOOL) add_hash_footer \
		--image $@ \
		$(call get-partition-size-argument,$(BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE)) \
		--partition_name vendor_boot $(INTERNAL_AVB_VENDOR_BOOT_SIGNING_ARGS) \
		$(BOARD_AVB_VENDOR_BOOT_ADD_HASH_FOOTER_ARGS)

endif
