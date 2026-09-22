# Vollständigkeitsstatus

Stand der Inventarisierung: 22.09.2026

Erfasst sind:

- Proxmox-Version, Kernel und Pakete
- Hardware, CPU, RAM, PCI/USB
- alle erkannten physischen Datenträger
- exakte Partitionstabellen
- UUIDs/PARTUUIDs
- LVM einschließlich IDs, Extents und Thin Pool
- ZFS einschließlich Pool-/Dataset-Properties und History
- Mounts und Dateisysteme
- Proxmox Storage-Konfiguration
- Netzwerk, Bridge, Routing und Interfaces
- EFI/GRUB/Boot
- Firewall-Laufzeitstatus
- systemd, Timer und Cron
- eigene Host-Skripte
- Proxmox VM 102 vollständig
- VM-102-System- und Docker-Disk
- Ubuntu-Netzwerk und Filesysteme
- Docker Compose und Container-Runtime
- Docker-Netze, Mounts und Persistenz
- Nextcloud
- MariaDB
- Redis
- Collabora
- Apache Reverse Proxy
- Certbot Renewal-Konfiguration
- Certbot Renewal Hooks
- eigenes Nextcloud-Upgrade-Skript

Nicht im Repository enthalten sind bewusst:

- echte Secrets
- echte `.env`-Werte
- TLS Private Keys
- Datenbankdateien/-Dumps
- Nextcloud-Nutzdaten
- Redis-Daten
- vollständige Container-/Anwendungsdaten

Diese gehören in das Backup, nicht in Git.
