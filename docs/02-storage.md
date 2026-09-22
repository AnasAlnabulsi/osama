# Storage und Festplatten

## `/dev/sda` – KINGSTON SA400S37480G
- ca. 447 GiB
- EFI auf `sda2`
- LVM auf `sda3`
- VG `pve`
- Root ext4, Swap und LVM-Thin `data`
- Proxmox Storage-ID `SSD1`
- VM 102 Systemdisk: 60 GiB

## `/dev/sdb` – Samsung SSD 870 QVO 2TB
- `sdb1`: ext4 → `/mnt/backup`
- `sdb2`: ZFS-Pool `SSD-2T`
- ZFS bei Erfassung: `ONLINE`, keine bekannten Datenfehler
- VM 102 Datendisk: 500 GiB

## `/dev/sdc` – SanDisk Extreme Portable SSD
- ext4
- Mount: `/mnt/pve/Backup_Extern_SSD`
- systemd Mount-Unit dokumentiert

## Proxmox Storages
`local`, `SSD1`, `SSD-2T`, `Backup`, `Backup_Extern_SSD`.

Exakte Definition: `proxmox/etc/pve/storage.cfg`.
