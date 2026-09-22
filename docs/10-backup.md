# Backup

Proxmox-Backupstorages:
- `Backup` → `/mnt/backup`
- `Backup_Extern_SSD` → `/mnt/pve/Backup_Extern_SSD`

`/etc/vzdump.conf` enthält keine abweichenden globalen VZDump-Werte.
`/etc/pve/jobs.cfg` war bei der Inventarisierung leer.

Der dokumentierte Zustand belegt damit keine über `jobs.cfg` geplanten Proxmox-Backupjobs.
