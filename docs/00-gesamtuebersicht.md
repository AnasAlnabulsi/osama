# Gesamtübersicht

## Proxmox
- Host: `pve`
- Proxmox VE `9.2.0`
- pve-manager `9.2.20`
- Kernel `7.0.14-19-pve`
- Host-IP `192.168.178.20/24`
- Gateway `192.168.178.1`
- Bridge `vmbr0`
- aktive VM: `102 DockerStack`
- keine LXC-Container im erfassten Ist-Zustand

## VM 102
- 4 vCPU, 16 GiB RAM
- Systemdisk 60 GiB auf `SSD1`
- Datendisk 500 GiB auf `SSD-2T`
- Ubuntu 24.04.5 LTS
- `/docker` auf eigener ext4-Disk
- Netzwerk über DHCP, beobachtet: `192.168.178.171/24`

## Docker
Aktiv: MariaDB 11.4, Redis 7 Alpine, Nextcloud 35 Apache, Collabora CODE latest, Apache httpd 2.4.
