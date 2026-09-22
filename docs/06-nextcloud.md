# Nextcloud

Aktive geschwärzte Konfiguration: `vm102/docker/nextcloud/config/config.php`.

- Datadir `/var/www/html/data`
- DB `mysql`, Host `mariadb`, Port `3306`, DB `nextcloud`
- UTF8MB4 an
- APCu als lokaler Cache
- Redis für Locking, Host `redis`, Port `6379`
- HTTPS overwrite aktiv
- CLI URL `https://nextcloud.barye.cloudns.asia`
- Phone Region `DE`
- Maintenance Window `02:00`
- Log-Level `3`

Trusted Domains und Trusted Proxies stehen vollständig in der Config.
Secrets sind `REDACTED`.
