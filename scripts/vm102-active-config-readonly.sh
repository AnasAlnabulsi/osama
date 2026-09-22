#!/usr/bin/env bash
set -u

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="/root/vm102-active-config-${STAMP}"

mkdir -p "$OUT"/{docker,system,network,configs}

copy_text() {
  local src="$1"
  local dst="$2"
  [ -f "$src" ] || return 0
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
}

redact_nextcloud() {
  local src="$1"
  local dst="$2"
  [ -f "$src" ] || return 0
  mkdir -p "$(dirname "$dst")"

  python3 - "$src" "$dst" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
secret_keys = {
    "passwordsalt", "secret", "dbpassword",
    "mail_smtppassword", "objectstore", "redis.password"
}
out = []
for line in open(src, encoding="utf-8", errors="replace"):
    m = re.match(r"^(\s*)'([^']+)'\s*=>", line)
    if m and m.group(2).lower() in secret_keys:
        out.append(f"{m.group(1)}'{m.group(2)}' => 'REDACTED',\n")
    else:
        out.append(line)
open(dst, "w", encoding="utf-8").writelines(out)
PY
}

redact_compose() {
  local src="$1"
  local dst="$2"
  [ -f "$src" ] || return 0
  mkdir -p "$(dirname "$dst")"

  python3 - "$src" "$dst" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
out = []
for line in open(src, encoding="utf-8", errors="replace"):
    # Preserve variable references such as ${MYSQL_PASSWORD}.
    if "${" in line:
        out.append(line)
        continue
    if re.search(r'(?i)\b(password|passwd|secret|token|api[_-]?key)\b\s*[:=]', line):
        indent = re.match(r'^\s*', line).group(0)
        if line.lstrip().startswith("- "):
            key = re.split(r'[:=]', line.strip()[2:], 1)[0]
            out.append(f"{indent}- {key}=REDACTED\n")
        else:
            key = re.split(r'[:=]', line.strip(), 1)[0]
            out.append(f"{indent}{key}: REDACTED\n")
    else:
        out.append(line)
open(dst, "w", encoding="utf-8").writelines(out)
PY
}

echo "Erfasse nur den aktuell aktiven VM-/Docker-Zustand..."

# Compose
redact_compose /docker/compose/docker-compose.yml \
  "$OUT/configs/docker/compose/docker-compose.yml"

# .env: nur Variablennamen
if [ -f /docker/compose/.env ]; then
  awk '
    /^[[:space:]]*#/ { print; next }
    /^[[:space:]]*$/ { print; next }
    /^[A-Za-z_][A-Za-z0-9_]*=/ {
      split($0,a,"=");
      print a[1] "="
    }
  ' /docker/compose/.env > "$OUT/configs/docker/compose/.env.example"
fi

# Aktive Proxy-Konfiguration
copy_text /docker/proxy/httpd.conf \
  "$OUT/configs/docker/proxy/httpd.conf"

if [ -d /docker/proxy/apache2/sites ]; then
  while IFS= read -r -d '' f; do
    rel="${f#/docker/proxy/}"
    copy_text "$f" "$OUT/configs/docker/proxy/$rel"
  done < <(find /docker/proxy/apache2/sites -maxdepth 1 -type f -name '*.conf' -print0)
fi

# MariaDB aktive Zusatzkonfiguration
if [ -d /docker/mariadb/conf.d ]; then
  while IFS= read -r -d '' f; do
    rel="${f#/docker/mariadb/}"
    copy_text "$f" "$OUT/configs/docker/mariadb/$rel"
  done < <(find /docker/mariadb/conf.d -maxdepth 1 -type f -print0)
fi

# Nextcloud aktive Konfiguration, Secrets sicher entfernen
if [ -d /docker/nextcloud/config ]; then
  while IFS= read -r -d '' f; do
    rel="${f#/docker/nextcloud/}"
    case "$f" in
      *.php) redact_nextcloud "$f" "$OUT/configs/docker/nextcloud/$rel" ;;
      *)     copy_text "$f" "$OUT/configs/docker/nextcloud/$rel" ;;
    esac
  done < <(find /docker/nextcloud/config -maxdepth 1 -type f -print0)
fi

# Certbot: nur Konfiguration/Metadaten, keine Zertifikate/Private Keys
if [ -d /docker/proxy/letsencrypt/renewal ]; then
  mkdir -p "$OUT/configs/docker/proxy/letsencrypt/renewal"
  find /docker/proxy/letsencrypt/renewal -maxdepth 1 -type f -name '*.conf' \
    -exec cp -a {} "$OUT/configs/docker/proxy/letsencrypt/renewal/" \;
fi

# Docker-Laufzeit
docker ps -a --no-trunc > "$OUT/docker/docker-ps.txt" 2>&1 || true
docker compose -f /docker/compose/docker-compose.yml config --services \
  > "$OUT/docker/compose-services.txt" 2>&1 || true
docker network ls > "$OUT/docker/networks.txt" 2>&1 || true
docker volume ls > "$OUT/docker/volumes.txt" 2>&1 || true

for id in $(docker network ls -q 2>/dev/null); do
  docker network inspect "$id" 2>/dev/null
done > "$OUT/docker/network-inspect.json"

docker inspect $(docker ps -aq) \
  --format '{{.Name}}|{{range .Mounts}}{{.Type}}:{{.Source}}->{{.Destination}} rw={{.RW}};{{end}}' \
  > "$OUT/docker/mounts.txt" 2>/dev/null || true

docker inspect $(docker ps -aq) \
  --format '{{.Name}}|restart={{.HostConfig.RestartPolicy.Name}}|image={{.Config.Image}}' \
  > "$OUT/docker/runtime.txt" 2>/dev/null || true

# Persistenzstruktur – keine Nutzdaten
find /docker -xdev -maxdepth 3 -type d -printf '%M %u:%g %p\n' \
  | sort > "$OUT/docker/persistent-directories.txt"

du -xhd1 /docker 2>/dev/null | sort -h > "$OUT/docker/disk-usage.txt"

# VM-Systemkonfiguration
hostnamectl > "$OUT/system/hostnamectl.txt"
uname -a > "$OUT/system/uname.txt"
cat /etc/os-release > "$OUT/system/os-release.txt"

lsblk -e7 -o NAME,PATH,SIZE,TYPE,FSTYPE,FSVER,LABEL,UUID,PARTUUID,MOUNTPOINTS,MODEL,SERIAL \
  > "$OUT/system/block-devices.txt"

findmnt > "$OUT/system/mounts.txt"
cat /etc/fstab > "$OUT/system/fstab.txt"

# Netzwerk
ip -br address > "$OUT/network/ip-address.txt"
ip route > "$OUT/network/routes.txt"

if [ -d /etc/netplan ]; then
  mkdir -p "$OUT/configs/etc/netplan"
  find /etc/netplan -maxdepth 1 -type f -exec cp -a {} "$OUT/configs/etc/netplan/" \;
fi

# Docker daemon config
if [ -f /etc/docker/daemon.json ]; then
  copy_text /etc/docker/daemon.json "$OUT/configs/etc/docker/daemon.json"
fi

# Relevante Cronjobs
mkdir -p "$OUT/configs/etc/cron.d"
for f in /etc/cron.d/*; do
  [ -f "$f" ] || continue
  copy_text "$f" "$OUT/configs$f"
done

crontab -l > "$OUT/system/root-crontab.txt" 2>&1 || true
systemctl list-timers --all --no-pager > "$OUT/system/timers.txt"

# Aktive/custom systemd Units
systemctl list-unit-files --state=enabled --no-pager \
  > "$OUT/system/enabled-units.txt"

if [ -d /etc/systemd/system ]; then
  while IFS= read -r -d '' f; do
    rel="${f#/}"
    copy_text "$f" "$OUT/configs/$rel"
  done < <(
    find /etc/systemd/system -maxdepth 2 -type f \
      \( -name '*.service' -o -name '*.timer' -o -name '*.mount' \) \
      -print0
  )
fi

# Checksums
find "$OUT/configs" -type f -exec sha256sum {} \; | sort \
  > "$OUT/config-checksums.txt"

cat > "$OUT/README.txt" <<'EOF'
Aktiver Zustand von VM 102 / DockerStack.

Bewusst NICHT enthalten:
- /docker/backups
- Nextcloud-Nutzdaten
- Nextcloud-App-Quellcode
- MariaDB-Datenbankdateien
- Redis-Daten
- Zertifikate und private Schlüssel
- echte .env-Werte
- bekannte Secret-Werte aus Nextcloud config.php

Dieses Archiv ist für den Abgleich des aktuellen produktiven Zustands gedacht.
EOF

tar -czf "${OUT}.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")"

echo
echo "FERTIG:"
echo "${OUT}.tar.gz"
