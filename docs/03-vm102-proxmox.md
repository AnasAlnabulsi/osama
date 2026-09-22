# VM 102 `DockerStack` auf Proxmox

- VMID `102`
- 4 Cores, 1 Socket
- 16384 MiB RAM
- QEMU Guest Agent an
- VirtIO-Netzwerk an `vmbr0`
- Proxmox-Firewallflag am NIC an
- `scsi0`: `SSD1`, 60 GiB
- `scsi1`: `SSD-2T`, 500 GiB
- Controller `virtio-scsi-pci`
- Autostart an
- Startup: order 1, up 30
- Snapshot `vor_prox_update` dokumentiert

Exakt: `proxmox/etc/pve/qemu-server/102.conf`.
