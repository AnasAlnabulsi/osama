#!/usr/bin/env bash
set -Eeuo pipefail

COMPOSE_DIR="/docker/compose"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.yml"
BACKUP_BASE="/docker/mariadb/backup/nextcloud-major-upgrade"

NC_CONTAINER="nextcloud"
DB_CONTAINER="mariadb"

log() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

fail() {
    echo
    echo "❌ FEHLER: $1"
    echo "Upgrade wurde gestoppt."
    exit 1
}

nc_status() {
    docker exec -u www-data "$NC_CONTAINER" php occ status
}

current_version() {
    docker exec -u www-data "$NC_CONTAINER" php occ status \
        | awk '/versionstring:/ {print $3}'
}

backup_db() {
    VERSION="$(current_version)"
    DATE="$(date +%Y%m%d-%H%M%S)"
    DIR="${BACKUP_BASE}/${VERSION}-${DATE}"

    mkdir -p "$DIR"

    log "DB-Backup vor Upgrade von Nextcloud ${VERSION}"

    docker exec "$DB_CONTAINER" sh -c \
      'exec mariadb-dump -u root -p"$MYSQL_ROOT_PASSWORD" \
       --single-transaction \
       --routines \
       --triggers \
       --events \
       --all-databases' \
       > "${DIR}/all-databases.sql"

    test -s "${DIR}/all-databases.sql" \
        || fail "Datenbank-Backup ist leer."

    tail -n 10 "${DIR}/all-databases.sql" \
        | grep -q "Dump completed" \
        || fail "MariaDB-Dump scheint unvollständig zu sein."

    echo "✅ Backup: ${DIR}/all-databases.sql"
}

healthcheck() {
    TARGET="$1"

    log "Healthcheck Nextcloud ${TARGET}"

    sleep 10

    nc_status

    VERSION="$(current_version)"

    [[ "$VERSION" == "${TARGET}."* ]] \
        || fail "Erwartet Nextcloud ${TARGET}.x, gefunden ${VERSION}"

    MAINTENANCE="$(
        docker exec -u www-data "$NC_CONTAINER" php occ status |
        awk '/maintenance:/ {print $3}'
    )"

    DBUPGRADE="$(
        docker exec -u www-data "$NC_CONTAINER" php occ status |
        awk '/needsDbUpgrade:/ {print $3}'
    )"

    [[ "$MAINTENANCE" == "false" ]] \
        || fail "Nextcloud befindet sich im Maintenance Mode."

    [[ "$DBUPGRADE" == "false" ]] \
        || fail "Ein Datenbank-Upgrade ist noch erforderlich."

    docker exec "$DB_CONTAINER" sh -c \
      'mariadb-admin -u root -p"$MYSQL_ROOT_PASSWORD" ping' \
      | grep -q "alive" \
      || fail "MariaDB antwortet nicht."

    docker exec redis redis-cli ping \
      | grep -q "PONG" \
      || fail "Redis antwortet nicht."

    HTTP_NC="$(curl -k -sS -o /dev/null -w '%{http_code}' \
        https://nextcloud.barye.cloudns.asia/)"

    [[ "$HTTP_NC" =~ ^(200|301|302|303)$ ]] \
        || fail "Nextcloud HTTP-Test fehlgeschlagen: ${HTTP_NC}"

    HTTP_COLLABORA="$(curl -sS -o /dev/null -w '%{http_code}' \
        http://127.0.0.1:9980/hosting/discovery)"

    [[ "$HTTP_COLLABORA" == "200" ]] \
        || fail "Collabora-Test fehlgeschlagen: ${HTTP_COLLABORA}"

    echo
    echo "✅ Nextcloud ${VERSION}"
    echo "✅ Maintenance Mode AUS"
    echo "✅ DB-Upgrade nicht erforderlich"
    echo "✅ MariaDB OK"
    echo "✅ Redis OK"
    echo "✅ Nextcloud HTTP ${HTTP_NC}"
    echo "✅ Collabora HTTP ${HTTP_COLLABORA}"
}

upgrade_major() {
    TARGET="$1"

    log "Upgrade auf Nextcloud ${TARGET}"

    backup_db

    echo
    echo "Ändere Image auf nextcloud:${TARGET}-apache"

    sed -i -E \
      "s|image:[[:space:]]*nextcloud:[^[:space:]]+|image: nextcloud:${TARGET}-apache|" \
      "$COMPOSE_FILE"

    grep -E 'image:.*nextcloud:' "$COMPOSE_FILE"

    cd "$COMPOSE_DIR"

    docker compose pull nextcloud

    docker compose up -d nextcloud

    echo "Warte auf Nextcloud..."
    sleep 30

    # Falls der Entrypoint das Upgrade nicht vollständig erledigt hat
    if docker exec -u www-data "$NC_CONTAINER" php occ status \
        | grep -q 'needsDbUpgrade: true'; then

        log "Nextcloud DB-Upgrade"

        docker exec -u www-data "$NC_CONTAINER" php occ upgrade
    fi

    # Falls Maintenance nach erfolgreichem Upgrade noch aktiv ist
    if docker exec -u www-data "$NC_CONTAINER" php occ status \
        | grep -q 'maintenance: true'; then

        docker exec -u www-data "$NC_CONTAINER" \
            php occ maintenance:mode --off
    fi

    docker exec -u www-data "$NC_CONTAINER" \
        php occ db:add-missing-indices || true

    healthcheck "$TARGET"
}


# ============================================================
# START
# ============================================================

cd "$COMPOSE_DIR"

log "Ausgangszustand"

nc_status

START_VERSION="$(current_version)"

[[ "$START_VERSION" == 33.* ]] \
    || fail "Dieses Skript erwartet Nextcloud 33.x. Gefunden: ${START_VERSION}"

echo
read -r -p "Upgrade 33 → 34 → 35 wirklich starten? [y/N]: " ANSWER

[[ "$ANSWER" =~ ^[Yy]$ ]] || {
    echo "Abgebrochen."
    exit 0
}

upgrade_major "34"

log "NEXTCLOUD 34 ERFOLGREICH"

echo
echo "⚠️ Jetzt sollte Nextcloud 34 kurz manuell getestet werden."
echo
read -r -p "Nextcloud 34 funktioniert? Weiter auf 35? [y/N]: " ANSWER

[[ "$ANSWER" =~ ^[Yy]$ ]] || {
    echo
    echo "Gestoppt auf Nextcloud 34."
    exit 0
}

upgrade_major "35"

log "UPGRADE FERTIG"

nc_status

echo
echo "🎉 Nextcloud Major-Upgrade erfolgreich:"
echo "   33 → 34 → 35"
echo
echo "Aktuelles Compose-Image:"
grep -E 'image:.*nextcloud:' "$COMPOSE_FILE"
