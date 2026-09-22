#!/usr/bin/env bash
# ==============================================================================
# Proxmox VE – Safe Maintenance & Major Upgrade Assistant v2
# Sprache: Deutsch
#
# Unterstützte Upgrade-Pfade:
#   PVE 7 / Debian 11 bullseye -> PVE 8 / Debian 12 bookworm
#   PVE 8 / Debian 12 bookworm -> PVE 9 / Debian 13 trixie
#
# Ziel:
#   - aktuelle Patch-/Minor-Version innerhalb der aktiven PVE-Reihe installieren
#   - alle verfügbaren Debian-/Proxmox-Pakete und Abhängigkeiten aktualisieren
#   - Major-Upgrades erkennen und kontrolliert anbieten
#   - Bootloader, ZFS, Storage, VMs/CTs, APT/DPKG und Repositories prüfen
#   - vor JEDEM riskanten Schreibschritt Y/N fragen
#
# Sicherheitsprinzip:
#   Das Skript führt KEIN unbekanntes zukünftiges Major-Upgrade automatisch aus.
#   Für z.B. PVE 9 -> 10 muss diese Datei zuerst an die dann offizielle
#   Proxmox-Anleitung angepasst werden.
# ==============================================================================

set -u
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

LOG_DIR="/root/proxmox-maintenance-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/proxmox-maintenance-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

section(){ echo; echo -e "${BLUE}==============================================================================${NC}"; echo -e "${BOLD}${CYAN}$1${NC}"; echo -e "${BLUE}==============================================================================${NC}"; }
info(){ echo -e "${CYAN}[INFO]${NC} $*"; }
ok(){ echo -e "${GREEN}[OK]${NC} $*"; }
warn(){ echo -e "${YELLOW}[WARNUNG]${NC} $*"; }
error(){ echo -e "${RED}[FEHLER]${NC} $*"; }

ask_yes_no() {
    local prompt="$1" answer
    while true; do
        echo
        read -r -p "$prompt [y/N]: " answer
        case "${answer,,}" in
            y|yes|j|ja) return 0 ;;
            n|no|nein|"") return 1 ;;
            *) echo "Bitte y oder n eingeben." ;;
        esac
    done
}

pause(){ echo; read -r -p "Weiter mit ENTER ..."; }
command_exists(){ command -v "$1" >/dev/null 2>&1; }

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "Dieses Skript muss als root ausgeführt werden."
        exit 1
    fi
}

get_pve_major() {
    pveversion 2>/dev/null | sed -n 's/.*pve-manager\/\([0-9]\+\).*/\1/p' | head -n1
}

get_pve_full() {
    pveversion 2>/dev/null | head -n1
}

get_codename() {
    . /etc/os-release
    echo "${VERSION_CODENAME:-unknown}"
}

get_debian_major() {
    . /etc/os-release
    echo "${VERSION_ID:-unknown}" | cut -d. -f1
}

target_for_major() {
    case "$1" in
        7) echo "8|bullseye|bookworm|pve7to8" ;;
        8) echo "9|bookworm|trixie|pve8to9" ;;
        *) echo "" ;;
    esac
}

show_header() {
    clear
    section "PROXMOX VE – SICHERES UPDATE / MAJOR-UPGRADE v2"
    echo "Logdatei: $LOG_FILE"
    echo
    echo "Grundregel:"
    echo "  Patch-/Minor-Updates: neueste Version aus deinen aktiven Repositories."
    echo "  Major-Upgrade: nur bekannte und geprüfte Pfade 7->8 bzw. 8->9."
    echo "  Kritische Aktion: immer Y/N."
}

system_info() {
    section "1. SYSTEMINFORMATIONEN"
    echo "Hostname: $(hostname)"
    echo "Proxmox: $(get_pve_full)"
    echo "PVE-Hauptversion: $(get_pve_major)"
    echo "Debian: $(get_debian_major) / $(get_codename)"
    echo "Kernel: $(uname -r)"
    echo
    if [[ -d /sys/firmware/efi ]]; then
        ok "Bootmodus: UEFI"
    else
        info "Bootmodus: Legacy BIOS"
    fi
}

guest_check() {
    section "2. VMs UND CONTAINER"
    info "QEMU/KVM:"
    qm list 2>/dev/null || true
    echo
    info "LXC:"
    pct list 2>/dev/null || true

    local rv rc
    rv="$(qm list 2>/dev/null | awk 'NR>1 && $3=="running"{print $1}' | tr '\n' ' ' || true)"
    rc="$(pct list 2>/dev/null | awk 'NR>1 && $2=="running"{print $1}' | tr '\n' ' ' || true)"

    if [[ -n "$rv" || -n "$rc" ]]; then
        warn "Es laufen noch Gäste."
        [[ -n "$rv" ]] && echo "VMs: $rv"
        [[ -n "$rc" ]] && echo "CTs: $rc"
        warn "Für ein Major-Upgrade kontrolliert stoppen/migrieren."
    else
        ok "Keine laufenden Gäste."
    fi
}

storage_check() {
    section "3. STORAGE / ZFS / SPEICHERPLATZ"
    info "Proxmox Storage:"
    pvesm status || true
    echo
    info "Dateisysteme:"
    df -h
    echo

    if command_exists zpool; then
        info "ZFS:"
        zpool status || true
        if zpool status -x 2>/dev/null | grep -qi "all pools are healthy"; then
            ok "ZFS-Pools gesund."
        else
            warn "ZFS-Status manuell prüfen."
        fi
    fi

    local avail
    avail="$(df --output=avail / | tail -1 | tr -d ' ')"
    if [[ "$avail" =~ ^[0-9]+$ ]] && (( avail < 4194304 )); then
        error "Weniger als 4 GiB frei auf /. Major-Upgrade nicht empfohlen."
    else
        ok "Mindestens ca. 4 GiB frei auf /."
    fi
}

repo_check() {
    section "4. REPOSITORIES"
    grep -R --line-number -E '^[[:space:]]*deb |^Types:|^URIs:|^Suites:|^Components:|proxmox|pve|bullseye|bookworm|trixie|enterprise' \
      /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null || true
    echo
    warn "Gemischte aktive Debian-Suites (z.B. bookworm + trixie) während eines normalen Betriebs vermeiden."
}

bootloader_check() {
    section "5. BOOTLOADER / UEFI / GRUB"
    lsblk -f || true
    echo
    if findmnt /boot/efi >/dev/null 2>&1; then
        ok "/boot/efi ist gemountet."
        findmnt /boot/efi
    else
        warn "/boot/efi ist nicht gemountet."
    fi
    echo
    if command_exists proxmox-boot-tool; then
        info "proxmox-boot-tool:"
        proxmox-boot-tool status || true
    fi
    echo
    info "GRUB/systemd-boot Pakete:"
    dpkg -l | grep -E 'grub|systemd-boot' || true

    if [[ -d /sys/firmware/efi ]]; then
        if dpkg-query -W -f='${Status}' grub-efi-amd64 2>/dev/null | grep -q "install ok installed"; then
            ok "UEFI aktiv und grub-efi-amd64 installiert."
        else
            warn "UEFI aktiv, aber grub-efi-amd64 nicht als installiert erkannt."
            warn "NICHT automatisch repariert. Erst Bootpfad/ESP prüfen."
        fi
        if command_exists efibootmgr && ask_yes_no "UEFI Boot-Einträge anzeigen?"; then
            efibootmgr -v || true
        fi
    fi
}

package_health() {
    section "6. APT / DPKG GESUNDHEIT"
    info "dpkg --audit:"
    local audit
    audit="$(dpkg --audit 2>&1 || true)"
    if [[ -n "$audit" ]]; then
        warn "dpkg meldet:"
        echo "$audit"
    else
        ok "dpkg --audit leer."
    fi
    echo
    apt-get check || true
}

backup_host_config() {
    section "7. HOST-KONFIGURATION SICHERN"
    local dir="/root/pve-pre-upgrade-backup-$(date +%Y%m%d-%H%M%S)"
    warn "Dieses Backup ersetzt KEIN VM-/CT-Datenbackup."
    if ! ask_yes_no "Host-Konfiguration jetzt lokal sichern?"; then
        warn "Übersprungen."
        return
    fi

    mkdir -p "$dir"
    for f in /etc/network/interfaces /etc/hosts /etc/resolv.conf /etc/fstab /etc/default/grub /etc/lvm/lvm.conf /etc/apt/sources.list; do
        [[ -e "$f" ]] && cp -a "$f" "$dir/" || true
    done
    [[ -d /etc/pve ]] && cp -a /etc/pve "$dir/" || true
    [[ -d /etc/apt/sources.list.d ]] && cp -a /etc/apt/sources.list.d "$dir/" || true

    pveversion -v > "$dir/pveversion.txt" 2>&1 || true
    qm list > "$dir/qm-list.txt" 2>&1 || true
    pct list > "$dir/pct-list.txt" 2>&1 || true
    pvesm status > "$dir/pvesm-status.txt" 2>&1 || true
    lsblk -f > "$dir/lsblk.txt" 2>&1 || true
    zpool status > "$dir/zpool-status.txt" 2>&1 || true

    tar -czf "$dir.tar.gz" -C "$(dirname "$dir")" "$(basename "$dir")"
    ok "Gesichert: $dir.tar.gz"
}

update_current_release() {
    section "8. ALLE PAKETE DER AKTUELLEN RELEASE AKTUALISIEREN"
    info "apt update lädt aktuelle Paketlisten."
    if ! ask_yes_no "'apt update' ausführen?"; then return; fi
    apt update || { error "apt update fehlgeschlagen."; return 1; }

    echo
    info "Aktualisierbare Pakete/Bibliotheken:"
    apt list --upgradable 2>/dev/null || true

    echo
    info "Simulation des vollständigen Updates:"
    apt-get -s full-upgrade || true

    echo
    warn "'apt full-upgrade' aktualisiert auch Bibliotheken/Abhängigkeiten,"
    warn "entfernt/ersetzt Pakete aber ggf. zur Abhängigkeitsauflösung."
    warn "Wenn proxmox-ve ersatzlos entfernt werden soll: NICHT bestätigen."

    if ask_yes_no "Alle verfügbaren Pakete der aktuellen Release mit 'apt full-upgrade' aktualisieren?"; then
        apt full-upgrade
        local rc=$?
        if (( rc != 0 )); then
            error "full-upgrade Fehlercode $rc. NICHT rebooten."
            return "$rc"
        fi
        ok "Paketupgrade beendet."
    fi
}

show_upgrade_target() {
    section "9. MAJOR-UPGRADE-ZIEL ERKENNEN"
    local major mapping target from to checker
    major="$(get_pve_major)"
    mapping="$(target_for_major "$major")"

    echo "Installiert: $(get_pve_full)"
    echo "Debian: $(get_codename)"

    if [[ -z "$mapping" ]]; then
        if [[ "$major" == "9" ]]; then
            ok "PVE 9 erkannt. Dieses Skript kennt derzeit keinen freigegebenen Nachfolger-Pfad."
            info "Normale Updates installieren weiterhin die neuesten PVE-9.x Pakete aus deinem Repository."
        else
            warn "Für PVE $major ist in diesem Skript kein Major-Upgrade-Pfad hinterlegt."
        fi
        return
    fi

    IFS='|' read -r target from to checker <<< "$mapping"
    info "Bekannter sicherer Pfad:"
    echo "PVE $major / $from -> PVE $target / $to"
    echo "Offizieller Prüfer: $checker --full"
}

run_major_checker() {
    section "10. OFFIZIELLEN MAJOR-UPGRADE-CHECKER AUSFÜHREN"
    local major mapping target from to checker
    major="$(get_pve_major)"
    mapping="$(target_for_major "$major")"

    if [[ -z "$mapping" ]]; then
        warn "Kein bekannter Major-Upgrade-Checker für PVE $major hinterlegt."
        return
    fi
    IFS='|' read -r target from to checker <<< "$mapping"

    if ! command_exists "$checker"; then
        error "$checker ist nicht vorhanden."
        error "Zuerst aktuelle PVE-$major-Pakete installieren."
        return 1
    fi

    info "Der Checker ändert nichts am System."
    "$checker" --full || true
    echo
    warn "FAILURES müssen vor dem Upgrade behoben werden."
    warn "WARNINGS müssen verstanden und bewertet werden."
}

switch_major_repos() {
    section "11. REPOSITORIES FÜR NÄCHSTE PVE-HAUPTVERSION"
    local major current mapping target expected target_suite checker
    major="$(get_pve_major)"
    current="$(get_codename)"
    mapping="$(target_for_major "$major")"

    if [[ -z "$mapping" ]]; then
        error "Kein automatisierter Repository-Pfad für PVE $major."
        return 1
    fi

    IFS='|' read -r target expected target_suite checker <<< "$mapping"

    if [[ "$current" != "$expected" ]]; then
        error "Erwartete Debian-Suite '$expected', erkannt '$current'."
        error "Repository-Umschaltung wird verweigert."
        return 1
    fi

    warn "Geplant: PVE $major/$expected -> PVE $target/$target_suite"
    warn "Nur fortfahren, wenn:"
    echo "  - aktuelle PVE-$major-Version installiert ist"
    echo "  - $checker --full geprüft wurde"
    echo "  - Backups vorhanden sind"
    echo "  - Gäste gestoppt/migriert sind"
    echo "  - Storage/ZFS gesund sind"

    if ! ask_yes_no "Repositories wirklich von '$expected' auf '$target_suite' umstellen?"; then
        return
    fi

    local stamp="/root/apt-repos-before-pve${major}-to-${target}-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$stamp"
    cp -a /etc/apt/sources.list "$stamp/" 2>/dev/null || true
    cp -a /etc/apt/sources.list.d "$stamp/" 2>/dev/null || true
    ok "APT-Konfiguration gesichert unter $stamp"

    # Klassische .list-Dateien und /etc/apt/sources.list.
    [[ -f /etc/apt/sources.list ]] && sed -i "s/${expected}/${target_suite}/g" /etc/apt/sources.list
    find /etc/apt/sources.list.d -maxdepth 1 -type f -name '*.list' -print0 2>/dev/null |
      while IFS= read -r -d '' f; do
          # Enterprise-Datei wird nicht aktiviert; nur vorhandene Suite wird ersetzt.
          sed -i "s/${expected}/${target_suite}/g" "$f"
      done

    # deb822 .sources Dateien – Suites:-Zeilen anpassen.
    find /etc/apt/sources.list.d -maxdepth 1 -type f -name '*.sources' -print0 2>/dev/null |
      while IFS= read -r -d '' f; do
          sed -i "s/\b${expected}\b/${target_suite}/g" "$f"
      done

    echo
    info "Neue APT-Konfiguration:"
    grep -R --line-number -E "^[[:space:]]*deb |^Types:|^URIs:|^Suites:|^Components:|${expected}|${target_suite}|proxmox|pve" \
      /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null || true

    echo
    warn "Prüfe, ob aktive alte '$expected'-Einträge übrig sind."
    if ! ask_yes_no "Repository-Ausgabe sieht korrekt aus und 'apt update' darf laufen?"; then
        warn "apt update nicht ausgeführt."
        return
    fi

    apt update || {
        error "apt update fehlgeschlagen. NICHT upgraden."
        return 1
    }

    echo
    apt policy proxmox-ve pve-manager || true
    local candidate
    candidate="$(apt-cache policy proxmox-ve | awk '/Candidate:/ {print $2}')"
    if [[ "$candidate" == "$target".* ]]; then
        ok "APT-Kandidat für proxmox-ve ist $candidate -> erwartete PVE-$target-Reihe."
    else
        error "Unerwarteter proxmox-ve Kandidat: $candidate"
        error "Major-Upgrade wird NICHT empfohlen."
    fi
}

perform_major_upgrade() {
    section "12. MAJOR-UPGRADE AUSFÜHREN"
    local major mapping target from to checker candidate
    major="$(get_pve_major)"
    mapping="$(target_for_major "$major")"

    if [[ -z "$mapping" ]]; then
        error "Kein bekannter Upgrade-Pfad."
        return 1
    fi
    IFS='|' read -r target from to checker <<< "$mapping"

    candidate="$(apt-cache policy proxmox-ve | awk '/Candidate:/ {print $2}')"
    echo "Installiert: $(apt-cache policy proxmox-ve | awk '/Installed:/ {print $2}')"
    echo "Kandidat:    $candidate"

    if [[ "$candidate" != "$target".* ]]; then
        error "Kandidat ist nicht PVE $target.x. Abbruch."
        return 1
    fi

    info "Simulation:"
    apt-get -s full-upgrade || true
    echo
    warn "Bei Fragen zu /etc/network/interfaces, GRUB, SSH, LVM oder Storage:"
    warn "NICHT blind Y wählen. Im Zweifel N und Unterschiede mit D ansehen."
    warn "Das Skript beantwortet dpkg-Konfigurationsfragen absichtlich NICHT automatisch."

    if ask_yes_no "Major-Upgrade PVE $major -> PVE $target jetzt mit 'apt full-upgrade' starten?"; then
        apt full-upgrade
        local rc=$?
        if (( rc != 0 )); then
            error "Major-Upgrade mit Fehlercode $rc beendet."
            error "NICHT REBOOTEN. Erst Reparatur/Prüfung ausführen."
            return "$rc"
        fi
        ok "Major-Upgrade-Befehl beendet."
    fi
}

repair_packages() {
    section "13. UNTERBROCHENES APT/DPKG REPARIEREN"
    warn "Nur bei unterbrochenem oder fehlerhaftem Upgrade verwenden."

    if ask_yes_no "'dpkg --configure -a' ausführen?"; then
        dpkg --configure -a || true
    fi
    if ask_yes_no "'apt --fix-broken install' ausführen?"; then
        apt --fix-broken install || true
    fi
    if ask_yes_no "Verbleibendes 'apt full-upgrade' ausführen?"; then
        apt full-upgrade || true
    fi
}

optional_cleanup() {
    section "14. AUFRÄUMEN / VERALTETE ABHÄNGIGKEITEN"
    info "Automatisch nicht mehr benötigte Pakete:"
    apt-get -s autoremove || true
    warn "Kernel oder wichtige Pakete können in Sonderfällen als automatisch markiert sein."
    if ask_yes_no "'apt autoremove' wirklich ausführen?"; then
        apt autoremove
    else
        info "Autoremove übersprungen."
    fi
}

modernize_sources_if_trixie() {
    section "15. APT-QUELLEN MODERNISIEREN (DEBIAN 13)"
    if [[ "$(get_codename)" != "trixie" ]]; then
        info "Nicht auf Trixie – dieser Schritt ist aktuell nicht relevant."
        return
    fi
    if command_exists apt && apt help 2>/dev/null | grep -q "modernize-sources"; then
        warn "Debian 13 empfiehlt das moderne deb822-Format für Paketquellen."
        info "Vorher wird nur eine Simulation/Information angeboten."
        if ask_yes_no "'apt modernize-sources' interaktiv starten?"; then
            apt modernize-sources
        fi
    else
        info "apt modernize-sources ist auf diesem System nicht verfügbar."
    fi
}

post_check() {
    section "16. ABSCHLUSSPRÜFUNG"
    system_info
    package_health
    echo
    info "Offene Updates:"
    apt list --upgradable 2>/dev/null || true
    echo
    info "Installierte PVE-Kernel:"
    dpkg -l | grep -E 'proxmox-kernel|pve-kernel' || true
    echo
    info "Fehlerhafte systemd-Units:"
    systemctl --failed || true
    echo
    pvesm status || true
    echo
    if command_exists zpool; then zpool status || true; fi
    echo
    qm list || true
    pct list || true
}

reboot_prompt() {
    section "17. KONTROLLIERTER REBOOT"
    warn "Vorher sicherstellen: APT/DPKG sauber, neuer Kernel installiert, Storage gesund, Gäste kontrolliert."
    if ask_yes_no "Server jetzt wirklich rebooten?"; then
        reboot
    fi
}

start_guest() {
    section "18. GÄSTE STARTEN"
    qm list || true
    pct list || true
    echo
    read -r -p "VM-ID starten (leer = keine): " id
    if [[ -n "${id:-}" ]] && ask_yes_no "VM $id starten?"; then
        qm start "$id"
        qm status "$id" || true
    fi
    echo
    read -r -p "CT-ID starten (leer = keine): " id
    if [[ -n "${id:-}" ]] && ask_yes_no "CT $id starten?"; then
        pct start "$id"
        pct status "$id" || true
    fi
}

readonly_full_check() {
    system_info
    guest_check
    storage_check
    repo_check
    bootloader_check
    package_health
    show_upgrade_target
}

guided_flow() {
    section "GEFÜHRTER GESAMTABLAUF"
    readonly_full_check
    pause

    backup_host_config
    pause

    update_current_release
    pause

    # Version kann sich durch normales Update nicht über Major ändern.
    show_upgrade_target
    pause

    local mapping
    mapping="$(target_for_major "$(get_pve_major)")"
    if [[ -n "$mapping" ]]; then
        run_major_checker
        pause
        warn "Jetzt die Checker-Ausgabe sorgfältig bewerten."
        if ask_yes_no "Sind alle FAILURES behoben und alle WARNINGS geklärt?"; then
            guest_check
            storage_check
            bootloader_check
            pause
            switch_major_repos
            pause
            perform_major_upgrade
            pause
            post_check
        else
            warn "Major-Upgrade sicher beendet."
        fi
    else
        info "Kein bekannter Major-Sprung erforderlich/verfügbar. Nur aktuelle Release wurde aktualisiert."
        post_check
    fi
}

menu() {
    while true; do
        show_header
        echo "1)  Komplette Nur-Lese-Prüfung"
        echo "2)  Alle Pakete/Bibliotheken der aktuellen PVE-Release aktualisieren"
        echo "3)  Nächstes Major-Upgrade-Ziel anzeigen"
        echo "4)  Offiziellen Major-Upgrade-Checker ausführen"
        echo "5)  Host-Konfiguration sichern"
        echo "6)  Repositories für nächste PVE-Hauptversion umstellen"
        echo "7)  Major-Upgrade starten"
        echo "8)  Unterbrochenes APT/DPKG reparieren"
        echo "9)  Autoremove prüfen/optional ausführen"
        echo "10) Debian-13 APT-Quellen optional modernisieren"
        echo "11) Abschlussprüfung"
        echo "12) Kontrollierter Reboot"
        echo "13) VM/Container starten"
        echo "14) KOMPLETTER geführter Ablauf"
        echo "0)  Beenden"
        echo
        read -r -p "Auswahl: " choice

        case "$choice" in
            1) readonly_full_check; pause ;;
            2) update_current_release; pause ;;
            3) show_upgrade_target; pause ;;
            4) run_major_checker; pause ;;
            5) backup_host_config; pause ;;
            6) switch_major_repos; pause ;;
            7) perform_major_upgrade; pause ;;
            8) repair_packages; pause ;;
            9) optional_cleanup; pause ;;
            10) modernize_sources_if_trixie; pause ;;
            11) post_check; pause ;;
            12) reboot_prompt ;;
            13) start_guest; pause ;;
            14) guided_flow; pause ;;
            0)
                section "ENDE"
                echo "Log: $LOG_FILE"
                exit 0
                ;;
            *) warn "Ungültige Auswahl."; sleep 1 ;;
        esac
    done
}

require_root
menu
