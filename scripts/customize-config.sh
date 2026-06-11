#!/bin/bash
# customize-config.sh - Apply user-specified settings to OpenWrt .config
#
# Args:
#   $1: firmware_size (MB)  - rootfs partition size
#   $2: enable_wifi  (true/false)
#   $3: lan_ip       (e.g. 192.168.1.1)
#   $4: keep_debug   (true/false)

set -e

FIRMWARE_SIZE="$1"
ENABLE_WIFI="$2"
LAN_IP="$3"
KEEP_DEBUG="$4"

CONFIG_FILE=".config"

log() {
    echo ">>> $1"
}

# ---------------------------------------------------------------------------
# 1. Firmware partition size
# ---------------------------------------------------------------------------
log "设置固件分区大小为 ${FIRMWARE_SIZE} MB"
# Remove old rootfs size lines and set new ones
sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' "$CONFIG_FILE"
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=${FIRMWARE_SIZE}" >> "$CONFIG_FILE"

# If firmware is large, enable ext4 combo
if [ "$FIRMWARE_SIZE" -ge 2048 ]; then
    log "大固件：启用 EXT4 + SquashFS 组合"
    sed -i '/CONFIG_TARGET_ROOTFS_EXT4FS/d' "$CONFIG_FILE"
    sed -i '/CONFIG_TARGET_ROOTFS_SQUASHFS/d' "$CONFIG_FILE"
    echo "CONFIG_TARGET_ROOTFS_EXT4FS=y" >> "$CONFIG_FILE"
    echo "CONFIG_TARGET_ROOTFS_SQUASHFS=y" >> "$CONFIG_FILE"
fi

# ---------------------------------------------------------------------------
# 2. WiFi settings
# ---------------------------------------------------------------------------
if [ "$ENABLE_WIFI" = "true" ]; then
    log "开启 WiFi — 保留无线驱动和 wpad"
    # Ensure WiFi-related packages are enabled (they may already be)
    sed -i '/CONFIG_PACKAGE_kmod-brcmfmac/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_cypress-firmware-43455-sdio/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_wpad-basic-mbedtls/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_wireless-regdb/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_wireless-tools/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_wifi-scripts/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_hostapd-common/d' "$CONFIG_FILE"
    echo "CONFIG_PACKAGE_kmod-brcmfmac=y"     >> "$CONFIG_FILE"
    echo "CONFIG_PACKAGE_cypress-firmware-43455-sdio=y" >> "$CONFIG_FILE"
    echo "CONFIG_PACKAGE_wpad-basic-mbedtls=y" >> "$CONFIG_FILE"
    echo "CONFIG_PACKAGE_wireless-regdb=y"     >> "$CONFIG_FILE"
    echo "CONFIG_PACKAGE_wireless-tools=y"     >> "$CONFIG_FILE"
    echo "CONFIG_PACKAGE_wifi-scripts=y"       >> "$CONFIG_FILE"
    echo "CONFIG_PACKAGE_hostapd-common=y"     >> "$CONFIG_FILE"
    # Also keep iwinfo
    sed -i '/CONFIG_PACKAGE_iwinfo/d' "$CONFIG_FILE"
    echo "CONFIG_PACKAGE_iwinfo=y"             >> "$CONFIG_FILE"
else
    log "关闭 WiFi — 移除无线驱动和 wpad"
    # Remove WiFi-related packages
    sed -i '/CONFIG_PACKAGE_kmod-brcmfmac/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_cypress-firmware-43455-sdio/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_wpad-basic-mbedtls/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_wireless-regdb/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_wireless-tools/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_wifi-scripts/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_hostapd-common/d' "$CONFIG_FILE"
    sed -i '/CONFIG_PACKAGE_iwinfo/d' "$CONFIG_FILE"
    # Remove brcmfmac firmware USB fallback
    sed -i '/CONFIG_PACKAGE_brcmfmac-firmware-usb/d' "$CONFIG_FILE"
    sed -i '/CONFIG_BRCMFMAC/d' "$CONFIG_FILE"
    echo "# CONFIG_PACKAGE_kmod-brcmfmac is not set"          >> "$CONFIG_FILE"
    echo "# CONFIG_PACKAGE_cypress-firmware-43455-sdio is not set" >> "$CONFIG_FILE"
    echo "# CONFIG_PACKAGE_wpad-basic-mbedtls is not set"    >> "$CONFIG_FILE"
    echo "# CONFIG_PACKAGE_wireless-regdb is not set"        >> "$CONFIG_FILE"
    echo "# CONFIG_PACKAGE_wireless-tools is not set"        >> "$CONFIG_FILE"
    echo "# CONFIG_PACKAGE_wifi-scripts is not set"          >> "$CONFIG_FILE"
    echo "# CONFIG_PACKAGE_hostapd-common is not set"        >> "$CONFIG_FILE"
    echo "# CONFIG_PACKAGE_iwinfo is not set"                >> "$CONFIG_FILE"
    echo "# CONFIG_BRCMFMAC_PCIE is not set"                >> "$CONFIG_FILE"
    echo "# CONFIG_BRCMFMAC_SDIO is not set"                >> "$CONFIG_FILE"
    echo "# CONFIG_BRCMFMAC_USB is not set"                 >> "$CONFIG_FILE"
fi

# ---------------------------------------------------------------------------
# 3. LAN IP address
# ---------------------------------------------------------------------------
log "设置 LAN IP 为 ${LAN_IP}"

# Compute netmask-based broadcast from IP. We assume /24 (255.255.255.0)
# so broadcast is first_3_octets.255
OCTETS=(${LAN_IP//./ })
BROADCAST="${OCTETS[0]}.${OCTETS[1]}.${OCTETS[2]}.255"

sed -i '/CONFIG_TARGET_PREINIT_IP/d' "$CONFIG_FILE"
sed -i '/CONFIG_TARGET_PREINIT_BROADCAST/d' "$CONFIG_FILE"
echo "CONFIG_TARGET_PREINIT_IP=\"${LAN_IP}\""           >> "$CONFIG_FILE"
echo "CONFIG_TARGET_PREINIT_BROADCAST=\"${BROADCAST}\"" >> "$CONFIG_FILE"

# Also update config_generate default LAN IP for first-boot
DEFAULT_NETWORK_FILE="package/base-files/files/bin/config_generate"
if [ -f "$DEFAULT_NETWORK_FILE" ]; then
    log "修改默认 LAN IP 在 config_generate 中"
    # The line says: lan) ipad=${ipaddr:-"192.168.1.1"} ;;
    sed -i "s/ipad=\${ipaddr:-\"192\.168\.[0-9]*\.[0-9]*\"}/ipad=\${ipaddr:-\"${LAN_IP}\"}/g" "$DEFAULT_NETWORK_FILE"
fi

# ---------------------------------------------------------------------------
# 4. Debug symbols
# ---------------------------------------------------------------------------
if [ "$KEEP_DEBUG" = "true" ]; then
    log "保留调试符号"
    sed -i '/CONFIG_DEBUG/d' "$CONFIG_FILE"
    echo "CONFIG_DEBUG=y" >> "$CONFIG_FILE"
else
    log "剥离调试符号以减小固件体积"
    sed -i '/CONFIG_DEBUG/d' "$CONFIG_FILE"
    echo "# CONFIG_DEBUG is not set" >> "$CONFIG_FILE"
    # Enable strip to reduce size
    sed -i '/CONFIG_USE_STRIP/d' "$CONFIG_FILE"
    echo "CONFIG_USE_STRIP=y" >> "$CONFIG_FILE"
fi

# ---------------------------------------------------------------------------
# 5. Clean up duplicates and finalize
# ---------------------------------------------------------------------------
log "整理 .config 文件"
# Remove trailing empty lines, deduplicate (keep last occurrence)
awk 'NF' "$CONFIG_FILE" | tac | awk '!seen[$1]++' | tac > "${CONFIG_FILE}.tmp"
mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

# Run defconfig to normalize
make defconfig

echo ""
echo "====== 最终配置摘要 ======"
echo "固件分区大小: $(grep CONFIG_TARGET_ROOTFS_PARTSIZE $CONFIG_FILE)"
echo "LAN IP:        $(grep CONFIG_TARGET_PREINIT_IP $CONFIG_FILE)"
if [ "$ENABLE_WIFI" = "true" ]; then
    echo "WiFi:          已开启"
else
    echo "WiFi:          已关闭"
fi
echo "=========================="
