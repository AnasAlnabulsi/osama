# Code vs. Inventar

## Als Code
Unter `proxmox/etc/`, `vm102/etc/` und `vm102/docker/` liegen reale,
anwendbare Konfigurationsdateien: Netzwerk, Storage, VM, fstab, systemd,
Cron, Docker Compose, Apache, MariaDB, Nextcloud und Certbot-Metadaten.

## Als Inventar
Unter `*/inventory/` liegen vollständige beobachtete Fakten, die nicht sinnvoll
als einzelne Config angewendet werden: Hardware, SMART, ZFS/LVM-Status,
Pakete, Kernelmodule, Sysctl-Laufzeitwerte, Ports, Services, Timer,
Docker-Runtime-Netze, Mounts, IPs und Snapshots.
