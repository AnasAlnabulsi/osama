# Vollständige Storage- und Partitionsdokumentation

## Proxmox Host

Die exakten Partitionstabellen liegen unter `proxmox/inventory/storage/`.

### `/dev/sda` – Systemdisk

Dokumentiert mit:

- `sfdisk-sda.txt`
- `parted-sda.txt`
- `gdisk-sda.txt`

Aufteilung:

- kleine BIOS/Boot-Partition
- EFI-Systempartition (`/boot/efi`)
- LVM Physical Volume
- VG `pve`
- LV `root`
- LV `swap`
- Thin Pool `data`
- VM-102-Systemdisk als LVM-Thin-Volume

### `/dev/sdb` – Samsung SSD 870 QVO 2 TB

Dokumentiert mit:

- `sfdisk-sdb.txt`
- `parted-sdb.txt`
- `gdisk-sdb.txt`

Aufteilung:

- `sdb1`: 500 GiB ext4 → `/mnt/backup`
- `sdb2`: ZFS-Member → Pool `SSD-2T`

Zusätzlich vollständig dokumentiert:

- `zpool-get-all.txt`
- `zfs-get-all.txt`
- `zpool-history.txt`

### `/dev/sdc` – externe SanDisk SSD

Dokumentiert mit:

- `sfdisk-sdc.txt`
- `parted-sdc.txt`
- `gdisk-sdc.txt`

Eine ext4-Partition, gemountet als Proxmox-Storage `Backup_Extern_SSD`.

## VM 102

Exakte Tabellen unter `vm102/inventory/storage/`.

### `/dev/sda` – 60 GiB Systemdisk

- GPT
- 1 MiB Hilfspartition
- 2 GiB `/boot`
- Rest als LVM PV
- VG `ubuntu-vg`
- LV `ubuntu-lv` → `/`

### `/dev/sdb` – 500 GiB Docker-Datendisk

Direkt als ext4-Dateisystem verwendet, ohne zusätzliche Partition.
Mountpoint: `/docker`.
