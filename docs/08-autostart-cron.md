# Autostart, Cron und Timer

## Proxmox
Eigene relevante Units:
- `eno1-offload-fix.service`
- `mnt-pve-Backup_Extern_SSD.mount`

## VM 102
`docker-compose-nextcloud.service` startet `/docker/compose` per
`docker compose up -d` und stoppt mit `docker compose down`.

Nextcloud Cron läuft alle 5 Minuten:
`docker exec --user www-data nextcloud php -f /var/www/html/cron.php`.

Alle beobachteten Timer stehen zusätzlich im jeweiligen Inventory.
