# Eigene Skripte und Automatisierung

## Proxmox Host

Aktuelles eigenes Skript:

- `/root/update.sh`
- Repository: `scripts/host/update.sh`

Das Skript ist ein interaktiver Proxmox Maintenance-/Upgrade-Assistent.
Es darf nicht automatisch oder ungeprüft ausgeführt werden.

Die beiden Inventarisierungsskripte liegen separat unter `scripts/` und sind
Dokumentationswerkzeuge, keine produktiven Serverdienste.

## VM 102

Aktuelles eigenes Wartungsskript:

- `/root/nextcloud-major-upgrade.sh`
- Repository: `scripts/vm102/nextcloud-major-upgrade.sh`

## Certbot Renewal Hooks

Produktive Hooks:

```text
/etc/letsencrypt/renewal-hooks/pre/10-stop-proxy.sh
/etc/letsencrypt/renewal-hooks/deploy/20-sync-certificates.sh
/etc/letsencrypt/renewal-hooks/post/30-start-proxy.sh
```

Repository:

```text
vm102/etc/letsencrypt/renewal-hooks/
```

Damit ist auch die automatische Zertifikatserneuerung einschließlich
Stop/Sync/Start-Ablauf als Code dokumentiert.
