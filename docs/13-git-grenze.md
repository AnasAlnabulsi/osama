# Git-Grenze

Empfohlene lokale Struktur:

```text
Server/
├── Server Dokumentation_ALT/   # nur lokales Archiv, NICHT Git
└── server-current-state/       # späteres Git-Repository
```

`Server Dokumentation_ALT` enthält historische Secrets, Datenbank-Dumps und Schlüsselmaterial.
Diesen Ordner nicht in das Repository verschieben.

Das Git-Repository sollte direkt in `server-current-state/` initialisiert werden, nicht im gemeinsamen Elternordner.
