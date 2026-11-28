#!/bin/bash
# N1 package-set check (Muse 2026-11-28).
#   n1_check.sh config <path/.config>     -> run after `make defconfig`
#   n1_check.sh rootfs <rootfs.tar.gz>    -> run on the built rootfs before packaging
# Exit 1 on any violation so a wrong image is never packaged or uploaded (the previous release stays).
# Writes a one-line summary to $GITHUB_ENV as N1CHECK when available.
mode="$1"; f="$2"
REQ_PKGS="msd_lite luci-app-msd_lite podman luci-app-homeproxy cloudflared luci-app-amlogic"
BAN_PKGS="udpxy luci-app-udpxy iw iw-full wpad wpad-basic-mbedtls wpad-mbedtls wpad-openssl hostapd hostapd-common wifi-scripts kmod-cfg80211 kmod-mac80211 attendedsysupgrade-common luci-app-attendedsysupgrade miniupnpd miniupnpd-nftables luci-app-upnp"
BAN_RE='^CONFIG_PACKAGE_kmod-(ath[0-9a-z-]*|carl9170|rsi91x[a-z-]*|rt2[0-9a-z-]*|rt61pci|rt73usb|rtl8[0-9]{3}[a-z]*|rtl8xxxu|rtw8[0-9a-z-]*|mt76[0-9a-z-]*|mt7601u|brcmfmac|brcmsmac|b43[a-z]*|iwlwifi|mwifiex[a-z-]*|mwl8k|p54[a-z-]*|zd1211rw|libertas[a-z-]*|ath9k[a-z-]*|ath10k[a-z-]*|ath11k[a-z-]*|wil6210|mac80211-hwsim)=[ym]'
bad=(); miss=()
case "$mode" in
config)
  [ -f "$f" ] || { echo "no config: $f"; exit 1; }
  for p in $REQ_PKGS; do grep -q "^CONFIG_PACKAGE_${p}=y" "$f" || miss+=("$p"); done
  for p in $BAN_PKGS; do grep -qE "^CONFIG_PACKAGE_${p}=[ym]" "$f" && bad+=("$p"); done
  while read -r l; do [ -n "$l" ] && bad+=("${l#CONFIG_PACKAGE_}"); done < <(grep -E "$BAN_RE" "$f" | sed 's/=.*//')
  ;;
rootfs)
  [ -f "$f" ] || { echo "no rootfs: $f"; exit 1; }
  L=$(tar -tzf "$f")
  echo "$L" | grep -qE '^\./usr/(s?bin)/msd_lite$' || miss+=("msd_lite binary")
  echo "$L" | grep -qE '^\./usr/(s?bin)/udpxy$' && bad+=("udpxy binary")
  echo "$L" | grep -qE '^\./usr/sbin/iw$' && bad+=("iw binary")
  echo "$L" | grep -qE '^\./sbin/wifi$' && bad+=("/sbin/wifi")
  echo "$L" | grep -qE '/(cfg80211|mac80211)\.ko$' && bad+=("cfg80211/mac80211 module")
  echo "$L" | grep -qE '^\./usr/bin/podman$' || miss+=("podman binary")
  ;;
*) echo "usage: $0 config|rootfs FILE"; exit 2 ;;
esac
if [ ${#bad[@]} -eq 0 ] && [ ${#miss[@]} -eq 0 ]; then
  s="check-$mode ok"
else
  s="check-$mode FAIL"; [ ${#miss[@]} -gt 0 ] && s="$s missing: ${miss[*]};"; [ ${#bad[@]} -gt 0 ] && s="$s unwanted: ${bad[*]}"
fi
echo "$s"
[ -n "$GITHUB_ENV" ] && echo "N1CHECK=${N1CHECK:+$N1CHECK | }$s" >> "$GITHUB_ENV"
[[ "$s" == *" ok" ]]
