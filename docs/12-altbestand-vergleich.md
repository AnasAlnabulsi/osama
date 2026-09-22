# Vergleich mit `Server Dokumentation_ALT`

Stand: 22.09.2026

Der aktuelle Ist-Zustand unter `server-current-state` wurde mit dem hochgeladenen Altbestand verglichen.

## Grundregel

Der erfasste Serverzustand ist die Quelle der Wahrheit.

Alte Dateien werden nicht ungeprüft in die aktuelle Konfiguration übernommen.

## Einordnung des Altbestands

### 1. `Nextcloud Osama_ALT/`

**Status: vollständig historisch / Archiv**

Enthält frühere LXC-Systeme und Backups:

- LXC 100 Nextcloud
- LXC 101 Proxy
- LXC 106 Collabora
- alte Apache-Konfigurationen
- alte Nextcloud-Konfigurationen
- alte OnlyOffice-Konfigurationen
- Datenbank-Dumps
- Zertifikats-/Key-Material
- komplette Apache-Systembackups

Diese Systeme existieren im aktuellen Proxmox-Inventar nicht mehr als aktive LXC-Container.

Nichts daraus wird als aktuelle Konfiguration übernommen.

### 2. `nextcloud-stack_TEST/`

**Status: frühere Docker-Zwischenstufe / Archiv**

Der Ordner beschreibt eine ältere Architektur mit getrennten Compose-Dateien:

```text
nextcloud/docker-compose.yml
mariadb/docker-compose.yml
redis/docker-compose.yml
collabora/docker-compose.yml
apache-proxy/docker-compose.yml
```

Aktuell produktiv ist dagegen genau eine Datei:

```text
/docker/compose/docker-compose.yml
```

Alte Container-Namen:

```text
nextcloud-app
nextcloud-db
nextcloud-redis
collabora-app
apache-proxy
```

Aktuelle Container-Namen:

```text
nextcloud
mariadb
redis
collabora
proxy
```

Darum sind folgende Altdateien **nicht direkt ausführbar**:

- `scripts/install.sh`
- `scripts/update.sh`
- `scripts/check-passwords.sh`
- `scripts/logs-error-check.sh`
- `scripts/logs-error-repair.sh`
- `docker-befehle.md`
- `logs.md`
- `repair.md`
- `occ.md`

Die darin enthaltenen Ideen/Befehle können später einzeln auf die aktuelle Architektur portiert werden. Die Originaldateien bleiben Archiv.

Die alten `.env`-Dateien dürfen nicht in Git übernommen werden.

### 3. `NEU !!!!!!!!!!/doks/`

**Status: historische Migrationsdokumentation**

Die Dokumente beschreiben den Übergang von LXC auf Docker und enthalten teilweise damalige Zwischenstände.

Beispiele für inzwischen überholte Angaben:

- Nextcloud `31-apache` statt aktuell `35-apache`
- unklarer Netzwerkname `internal` / `compose_internal`
- frühere IP-Adressen der alten LXC-Systeme
- damalige Collabora-/WOPI-Fehlerzustände

Die Informationen sind als Migrationshistorie nützlich, aber nicht Quelle der aktuellen Konfiguration.

### 4. `NEU !!!!!!!!!!/proxmox_update/`

**Status: Archiv**

Die vorhandenen Maintenance-/Upgrade-Skripte stammen aus einem früheren Proxmox-Stand.

Der aktuell erfasste Host läuft auf:

```text
Proxmox VE 9.2.0
pve-manager 9.2.20
Kernel 7.0.14-19-pve
```

Die alten Upgrade-Skripte werden deshalb nicht als aktueller Betriebs-Code übernommen.

### 5. Dockge-Dokumentation

**Status: Archiv**

Im aktuellen VM-Inventar wurde kein produktiver Dockge-Stack als Bestandteil der dokumentierten Zielarchitektur festgestellt.

Die alte Dockge-Dokumentation bleibt daher historisch.

## Sensible Altdateien

Der Altbestand enthält Dateien, die niemals in ein Git-Repository gehören, unter anderem:

- echte `.env`
- `config.php` mit früheren Zugangsdaten/Secrets
- `nextcloud-db.sql`
- TLS Private Keys
- Let's-Encrypt-Migrationsarchive
- vollständige Apache-/Systembackups mit Zertifikatsmaterial

Der komplette Ordner `Server Dokumentation_ALT` sollte deshalb **außerhalb des Git-Repositories bleiben** oder als Ganzes ignoriert werden.

## Was aus ALT in den aktuellen Stand übernommen wurde

Keine alte produktive Konfigurationsdatei wurde ungeprüft übernommen.

Die aktuelle Konfiguration stammt ausschließlich aus der Inventarisierung des laufenden Systems.

Historisches Wissen aus ALT wurde nur zur Plausibilitätsprüfung verwendet.

## Aktuelle Quelle der Wahrheit

```text
server-current-state/
├── proxmox/etc/        # aktuelle Proxmox-Konfiguration als Code
├── proxmox/inventory/  # aktueller Host-/Hardware-/Runtime-Zustand
├── vm102/etc/          # aktuelle Ubuntu-Konfiguration
├── vm102/docker/       # aktueller produktiver Docker-Stack
├── vm102/inventory/    # aktueller VM-/Docker-Runtime-Zustand
└── docs/               # aktuelle Dokumentation
```

Änderungen am produktiven System sollten zukünftig von diesem Stand ausgehen.
