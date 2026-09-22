#!/usr/bin/env bash
set -u

VMID="${VMID:-102}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="/root/proxmox-full-inventory-${STAMP}"

mkdir -p "$OUT"/{host,pve,vm102,files}

run() {
  local file="$1"
  shift
  {
    echo "# COMMAND: $*"
    "$@" 2>&1 || true
  } > "$OUT/$file"
}

copy_if_exists() {
  local src="$1"
  local dst="$OUT/files${src}"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
  fi
}

echo "READ-ONLY Inventar: $OUT"

# Host / OS / Hardware
run host/hostnamectl.txt hostnamectl
run host/pveversion.txt pveversion -v
run host/uname.txt uname -a
run host/os-release.txt cat /etc/os-release
run host/cpu.txt lscpu
run host/memory.txt free -h
run host/dmi.txt bash -lc 'command -v dmidecode >/dev/null && { dmidecode -t system; dmidecode -t baseboard; dmidecode -t memory; }'
run host/pci.txt lspci -nnk
run host/usb.txt bash -lc 'command -v lsusb >/dev/null && lsusb'
run host/block.txt lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,FSVER,LABEL,UUID,PARTUUID,MOUNTPOINTS,MODEL,SERIAL,WWN
run host/blkid.txt blkid
run host/filesystems.txt df -hT
run host/mounts.txt findmnt
run host/swaps.txt swapon --show
run host/smart.txt bash -lc 'for d in /dev/sd? /dev/nvme?n1; do [ -b "$d" ] || continue; echo "===== $d ====="; smartctl -a "$d" 2>&1 || true; done'

# Boot / EFI / Kernel
run host/efi.txt bash -lc 'efibootmgr -v 2>/dev/null || true; echo; findmnt /boot /boot/efi 2>/dev/null || true'
run host/kernel-cmdline.txt cat /proc/cmdline
run host/modules.txt lsmod
run host/proxmox-boot-tool.txt bash -lc 'command -v proxmox-boot-tool >/dev/null && proxmox-boot-tool status'
run host/grub-default.txt bash -lc 'test -f /etc/default/grub && cat /etc/default/grub'

# Network
run host/ip-address.txt ip -details address
run host/ip-link.txt ip -details link
run host/ip-route.txt ip route show table all
run host/ip-rule.txt ip rule
run host/bridge.txt bash -lc 'bridge link; echo; bridge vlan show; echo; bridge fdb show'
run host/listening.txt ss -lntup
run host/resolv.txt cat /etc/resolv.conf
run host/hosts.txt cat /etc/hosts
run host/network-interfaces.txt bash -lc 'test -f /etc/network/interfaces && cat /etc/network/interfaces'
run host/network-interfaces-d.txt bash -lc 'find /etc/network/interfaces.d -maxdepth 2 -type f -print -exec sh -c '\''echo "--- $1"; cat "$1"'\'' _ {} \; 2>/dev/null'

# Storage
run host/pvesm-status.txt pvesm status
run host/storage-cfg.txt bash -lc 'cat /etc/pve/storage.cfg 2>/dev/null'
run host/zpool.txt bash -lc 'zpool list 2>/dev/null; echo; zpool status -v 2>/dev/null'
run host/zfs.txt bash -lc 'zfs list -t filesystem,volume,snapshot -o name,type,used,avail,refer,mountpoint,volsize 2>/dev/null'
run host/lvm.txt bash -lc 'pvs -a -o+devices 2>/dev/null; echo; vgs -a 2>/dev/null; echo; lvs -a -o+devices 2>/dev/null'
run host/fstab.txt cat /etc/fstab
run host/nfs-exports.txt bash -lc 'test -f /etc/exports && cat /etc/exports; find /etc/exports.d -type f -maxdepth 1 -print -exec cat {} \; 2>/dev/null'

# APT / Packages
run host/apt-sources.txt bash -lc 'for f in /etc/apt/sources.list /etc/apt/sources.list.d/*; do [ -f "$f" ] || continue; echo "===== $f ====="; cat "$f"; done'
run host/packages.txt dpkg-query -W -f='${binary:Package}\t${Version}\n'
run host/apt-policy.txt apt-cache policy
run host/held-packages.txt apt-mark showhold

# Systemd / Cron / Sysctl
run host/systemd-enabled.txt systemctl list-unit-files --state=enabled --no-pager
run host/systemd-running.txt systemctl list-units --type=service --state=running --no-pager
run host/systemd-failed.txt systemctl --failed --no-pager
run host/custom-units.txt bash -lc 'find /etc/systemd/system -type f -o -type l | sort'
run host/timers.txt systemctl list-timers --all --no-pager
run host/cron.txt bash -lc 'cat /etc/crontab 2>/dev/null; echo; find /etc/cron.d /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly -maxdepth 2 -type f -print 2>/dev/null'
run host/root-crontab.txt bash -lc 'crontab -l 2>/dev/null || true'
run host/sysctl.txt sysctl -a
run host/sysctl-files.txt bash -lc 'for f in /etc/sysctl.conf /etc/sysctl.d/*.conf; do [ -f "$f" ] || continue; echo "===== $f ====="; cat "$f"; done'

# Firewall
run host/nftables.txt bash -lc 'nft list ruleset 2>/dev/null || true'
run host/iptables.txt bash -lc 'iptables-save 2>/dev/null || true; echo; ip6tables-save 2>/dev/null || true'
run pve/firewall-files.txt bash -lc 'find /etc/pve/firewall -maxdepth 2 -type f -print -exec sh -c '\''echo "--- $1"; cat "$1"'\'' _ {} \; 2>/dev/null; test -f /etc/pve/firewall/cluster.fw && cat /etc/pve/firewall/cluster.fw'
run pve/datacenter-cfg.txt bash -lc 'cat /etc/pve/datacenter.cfg 2>/dev/null'
run pve/user-cfg.txt bash -lc 'cat /etc/pve/user.cfg 2>/dev/null'

# Proxmox Inventory
run pve/nodes.txt pvesh get /nodes
run pve/qm-list.txt qm list
run pve/pct-list.txt pct list
run pve/cluster.txt bash -lc 'pvecm status 2>/dev/null || true'
run pve/jobs.txt bash -lc 'cat /etc/pve/jobs.cfg 2>/dev/null || true'
run pve/replication.txt bash -lc 'cat /etc/pve/replication.cfg 2>/dev/null || true'
run pve/vzdump.txt bash -lc 'cat /etc/vzdump.conf 2>/dev/null || true'
run pve/ha.txt bash -lc 'ha-manager status 2>/dev/null || true'
run pve/pools.txt bash -lc 'pvesh get /pools 2>/dev/null || true'

# VM 102
run vm102/config.txt qm config "$VMID"
run vm102/status.txt qm status "$VMID"
run vm102/pending.txt bash -lc "qm pending $VMID 2>/dev/null || true"
run vm102/snapshots.txt bash -lc "qm listsnapshot $VMID 2>/dev/null || true"
run vm102/agent-ping.txt bash -lc "qm guest cmd $VMID ping 2>/dev/null || true"

# Important non-secret host config copies
for f in \
  /etc/hostname \
  /etc/hosts \
  /etc/fstab \
  /etc/network/interfaces \
  /etc/pve/storage.cfg \
  "/etc/pve/qemu-server/${VMID}.conf" \
  /etc/pve/datacenter.cfg \
  /etc/vzdump.conf \
  /etc/default/grub
do
  copy_if_exists "$f"
done

# Custom systemd unit contents
if [ -d /etc/systemd/system ]; then
  while IFS= read -r -d '' f; do
    case "$f" in
      *.service|*.timer|*.mount|*.path|*.socket)
        copy_if_exists "$f"
        ;;
    esac
  done < <(find /etc/systemd/system -type f -print0 2>/dev/null)
fi

# VM-side helper: deploy and run separately if needed.
cat > "$OUT/README.txt" <<EOF
Inventar wurde READ-ONLY erzeugt.

Wichtig:
- Dieses Archiv enthält Systemkonfigurationen, aber keine bewusst kopierten
  Passwort-/Key-Dateien.
- Prüfe das Archiv trotzdem vor Veröffentlichung.
- Für vollständiges Docker-/VM-Inventar das separate vm102-readonly-inventory.sh
  IN VM ${VMID} als root ausführen.
EOF

tar -czf "${OUT}.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")"

echo
echo "FERTIG:"
echo "${OUT}.tar.gz"
