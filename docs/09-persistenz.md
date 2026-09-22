# Persistenz

| Host | Container |
|---|---|
| `/docker/mariadb/data` | `/var/lib/mysql` |
| `/docker/mariadb/backup` | `/backup` |
| `/docker/mariadb/conf.d` | `/etc/mysql/conf.d` |
| `/docker/redis` | `/data` |
| `/docker/nextcloud/app` | `/var/www/html` |
| `/docker/nextcloud/config` | `/var/www/html/config` |
| `/docker/nextcloud/data` | `/var/www/html/data` |
| `/docker/proxy/apache2/sites` | `/usr/local/apache2/conf/extra/sites` |
| `/docker/proxy/letsencrypt` | `/etc/letsencrypt` |
| `/docker/proxy/httpd.conf` | `/usr/local/apache2/conf/httpd.conf` |

Daten selbst gehören ins Backup, nicht ins Git.
