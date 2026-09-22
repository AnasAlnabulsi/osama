# Proxmox-Host

Die exakten Dateien liegen unter `proxmox/etc/`.

## Netzwerk
`eno1` ist Port der Bridge `vmbr0`. `vmbr0` hat `192.168.178.20/24`, Gateway `192.168.178.1`,
STP ist aus, Forward Delay ist `0`.

`eno1-offload-fix.service` deaktiviert TSO, GSO und GRO auf `eno1`.

## Boot
EFI wird verwendet. GRUB timeout: 5 Sekunden. Default-Kernelparameter: `quiet`.

## Vollständige Runtime-Dokumentation
Hardware, Pakete, Module, Sysctl, laufende/aktivierte Services, Timer, Ports und SMART liegen unter
`proxmox/inventory/host/`.
