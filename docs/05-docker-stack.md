# Docker Stack

Hauptdatei: `vm102/docker/compose/docker-compose.yml`.

| Service | Image | Persistenz |
|---|---|---|
| mariadb | `mariadb:11.4` | `/docker/mariadb/{data,backup,conf.d}` |
| redis | `redis:7-alpine` | `/docker/redis` |
| nextcloud | `nextcloud:35-apache` | `/docker/nextcloud/{app,config,data}` |
| collabora | `collabora/code:latest` | keine Host-Persistenz |
| proxy | `httpd:2.4` | `/docker/proxy/...` |

Alle Container: `restart: unless-stopped`.

Aktives Compose-Netz: `compose_internal`, beobachtetes Subnetz `172.23.0.0/16`.
Ältere unbenutzte Docker-Netze bleiben im Runtime-Inventar dokumentiert.
