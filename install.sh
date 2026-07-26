#!/data/data/com.termux/files/usr/bin/bash
#
# Antigravity CLI - Termux
# Script de instalacion para Termux
# v1.0.0
#
# Script creado por Sebastian Laguna
# https://github.com/tuusuario/antigravity-termux
#
# Descripcion:
#   Instala Antigravity CLI (agy) de forma nativa en Termux
#   utilizando el fork comunitario wallentx/antigravity-cli-termux.
#   Sin proot, sin VMs, sin Cloud Shell.
#
# Uso:
#   bash install.sh              Instalacion completa
#   bash install.sh --help       Muestra esta ayuda
#   bash install.sh --version    Muestra la version
#   bash install.sh --uninstall  Desinstala agy
#

set -eEuo pipefail

# ── Configuracion ────────────────────────────────────────────────────────────

SCRIPT_VERSION="1.0.0"
SCRIPT_AUTHOR="Sebastian Laguna"
SCRIPT_REPO="https://github.com/sebastianl1/antigravity_termux"

AGY_REPO="wallentx/antigravity-cli-termux"
AGY_URL="https://github.com/${AGY_REPO}/releases/latest/download/antigravity-termux-standalone.tar.gz"
AGY_BIN_DIR="$PREFIX/bin"
BACKUP_DIR="$HOME/backups"
OPCODE_CONFIG_DIR="$HOME/.config/opencode"
OPCODE_CONFIG_FILE="$OPCODE_CONFIG_DIR/opencode.json"
TMP_DIR="$PREFIX/tmp/agy-install"
EXTRACT_DIR="$TMP_DIR/extract"
TARBALL="$TMP_DIR/antigravity-termux-standalone.tar.gz"
LOG_FILE="$TMP_DIR/install.log"
INSTALL_FAILED=false

# ── Colores (profesionales, sin llamativos) ─────────────────────────────────

BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
WHITE="\033[97m"
RESET="\033[0m"

# ── Dimensiones ─────────────────────────────────────────────────────────────

COLS=66

# ── Funciones de dibujo ─────────────────────────────────────────────────────

make_line() {
    local char="${1:-─}"
    local line=""
    printf -v line "%*s" "$COLS" ""
    echo "${line// /${char}}"
}

box_line() {
    echo -e "  ${BLUE}${BOLD}$1${RESET}"
}

box_text() {
    local content="$1"
    local color="${2:-}"
    local padding=$(( COLS - ${#content} - 2 ))
    printf "  ${BLUE}${BOLD}│${RESET} ${color}%s${RESET}%*s${BLUE}${BOLD}│${RESET}\n" "$content" "$padding" ""
}

section_header() {
    local title="$1"
    echo ""
    echo -e "  ${BLUE}${BOLD}◆ ${title}${RESET}"
    echo -e "  ${BLUE}${DIM}$(make_line)${RESET}"
    echo ""
}

check_item() {
    local label="$1"
    local status="$2"
    local detail="${3:-}"

    if [ "$status" = "ok" ]; then
        printf "  ${GREEN}✔${RESET} ${BOLD}%-34s${RESET}" "$label"
    elif [ "$status" = "skip" ]; then
        printf "  ${DIM}−${RESET} ${DIM}%-34s${RESET}" "$label"
    else
        printf "  ${YELLOW}⬡${RESET} ${BOLD}%-34s${RESET}" "$label"
    fi

    if [ -n "$detail" ]; then
        echo -e "${DIM}${detail}${RESET}"
    else
        echo ""
    fi
}

# ── Funciones de utilidad ───────────────────────────────────────────────────

cleanup() {
    if [ "$INSTALL_FAILED" = "true" ] && [ -d "$BACKUP_DIR" ]; then
        restore_backup
    fi
    rm -rf "$TMP_DIR" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

print_error() {
    echo -e "\n  ${RED}${BOLD}ERROR${RESET} ${1}"
    exit 1
}

print_info() {
    echo -e "  ${DIM}${1}${RESET}"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-S}"
    local yn

    printf "  %s " "$prompt"
    if [ "$default" = "S" ]; then
        printf "${BOLD}[S/n]${RESET}: "
    else
        printf "${BOLD}[s/N]${RESET}: "
    fi

    read -r yn
    yn="${yn:-$default}"

    case "$yn" in
        [Ss]*) return 0 ;;
        *) return 1 ;;
    esac
}

run_hidden() {
    local desc="$1"
    shift

    mkdir -p "$TMP_DIR"

    printf "  ⬡ ${BOLD}%-34s${RESET}" "$desc"

    echo "--- [$desc] $(date) ---" >> "$LOG_FILE"
    "$@" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    local spin='-\|/'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${WHITE}${BOLD}⬡${RESET} ${BOLD}%-34s${RESET} ${DIM}%s${RESET}" "$desc" "${spin:$i:1}"
        i=$(( (i + 1) % 4 ))
        sleep 0.1
    done

    wait "$pid"
    local exit_code=$?

    printf "\r"

    if [ "$exit_code" -eq 0 ]; then
        printf "  ${GREEN}✔${RESET} ${BOLD}%-34s${RESET} ${GREEN}hecho${RESET}\n" "$desc"
    else
        printf "  ${RED}✘${RESET} ${BOLD}%-34s${RESET} ${RED}fallo${RESET}\n" "$desc"
        echo ""
        echo -e "  ${DIM}Ultimas lineas del log:${RESET}"
        tail -5 "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
            echo -e "  ${DIM}  ${line}${RESET}"
        done
        exit 1
    fi
}

detect_installed_version() {
    if command -v agy &>/dev/null; then
        agy --version 2>/dev/null || echo ""
    fi
}

# ── Banner principal ────────────────────────────────────────────────────────

print_banner() {
    echo ""
    box_line "┌$(make_line)┐"
    box_text "" ""
    box_text "Antigravity CLI — Termux" "$WHITE${BOLD}"
    box_text "Script de instalacion  v${SCRIPT_VERSION}" "${DIM}"
    box_text "" ""
    box_text "Sebastian Laguna" "${BOLD}"
    box_text "${SCRIPT_REPO}" "${DIM}"
    box_text "" ""
    box_line "├$(make_line)┤"
}

# ── Funciones del instalador ────────────────────────────────────────────────

check_environment() {
    section_header "Preparacion"

    local env_ok=true
    local arch_ok=true
    local glibc_ok=true
    local cert_ok=true
    local dns_ok=true

    if [ -n "${TERMUX_VERSION:-}" ]; then
        check_item "Entorno Termux" "ok" ""
    else
        check_item "Entorno Termux" "skip" ""
        env_ok=false
    fi

    if [ "$(uname -m)" = "aarch64" ]; then
        check_item "Arquitectura aarch64" "ok" ""
    else
        check_item "Arquitectura aarch64" "skip" "$(uname -m)"
        arch_ok=false
    fi

    if [ -x "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" ]; then
        check_item "Librerias glibc" "ok" ""
    else
        check_item "Librerias glibc" "skip" "instalando..."
        glibc_ok=false
    fi

    if [ -s "$PREFIX/etc/tls/cert.pem" ]; then
        check_item "Certificados TLS" "ok" ""
    else
        check_item "Certificados TLS" "skip" ""
        cert_ok=false
    fi

    if [ -r "$PREFIX/etc/resolv.conf" ]; then
        check_item "Resolucion DNS" "ok" ""
    else
        check_item "Resolucion DNS" "skip" ""
        dns_ok=false
    fi

    echo ""

    if [ "$env_ok" != "true" ] || [ "$arch_ok" != "true" ]; then
        print_error "Este instalador solo funciona en Termux ARM64 (aarch64)."
    fi

    local needs_install=false
    if [ "$glibc_ok" != "true" ] || [ "$cert_ok" != "true" ] || [ "$dns_ok" != "true" ]; then
        if ask_yes_no "¿Instalar dependencias faltantes?" "S"; then
            needs_install=true
        fi
    fi

    if [ "$needs_install" = "true" ]; then
        if [ "$glibc_ok" != "true" ]; then
            run_hidden "Actualizar repositorios" pkg update -y
            run_hidden "Instalar glibc-repo" pkg install -y glibc-repo
            run_hidden "Actualizar repositorios" pkg update -y
            run_hidden "Instalar glibc" pkg install -y glibc-runner glibc
        fi
        if [ "$cert_ok" != "true" ]; then
            run_hidden "Instalar ca-certificates" pkg install -y ca-certificates
        fi
        if [ "$dns_ok" != "true" ]; then
            run_hidden "Instalar resolv-conf" pkg install -y resolv-conf
        fi
    elif [ "$glibc_ok" != "true" ] || [ "$cert_ok" != "true" ] || [ "$dns_ok" != "true" ]; then
        print_error "Dependencias faltantes. Instalalas manualmente con: pkg install glibc-repo glibc-runner ca-certificates resolv-conf"
    fi
}

check_dependencies() {
    if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
        run_hidden "Actualizar repositorios" pkg update -y
    fi
    if ! command -v curl &>/dev/null; then
        run_hidden "Instalar curl" pkg install -y curl
    fi
    if ! command -v tar &>/dev/null; then
        run_hidden "Instalar tar" pkg install -y tar
    fi
}

check_existing() {
    local current_version="$1"

    section_header "Estado actual"

    check_item "Antigravity CLI" "ok" "$current_version"
    check_item "Origen" "ok" "$AGY_BIN_DIR/agy"

    if ! ask_yes_no "¿Reinstalar agy?" "N"; then
        if ask_yes_no "¿Configurar solo opencode?" "S"; then
            setup_opencode_flow
            print_summary
        fi
        echo ""
        print_info "Instalacion omitida."
        return 1
    fi
}

backup_existing() {
    section_header "Respaldo"

    local has_backup=false

    if [ -f "$AGY_BIN_DIR/agy" ]; then
        mkdir -p "$BACKUP_DIR"
        local ts
        ts=$(date +%Y%m%d-%H%M%S)
        mv "$AGY_BIN_DIR/agy" "$BACKUP_DIR/agy.backup.$ts"
        has_backup=true
    fi

    if [ -f "$AGY_BIN_DIR/agy.va39" ]; then
        mkdir -p "$BACKUP_DIR"
        local ts
        ts=$(date +%Y%m%d-%H%M%S)
        mv "$AGY_BIN_DIR/agy.va39" "$BACKUP_DIR/agy.va39.backup.$ts"
        has_backup=true
    fi

    if [ "$has_backup" = "true" ]; then
        check_item "Respaldo creado" "ok" "$BACKUP_DIR/"
    else
        check_item "Sin instalacion previa" "ok" ""
    fi
}

restore_backup() {
    local restored=false
    local f
    for f in "$BACKUP_DIR"/agy.backup.*; do
        [ -f "$f" ] || continue
        cp "$f" "$AGY_BIN_DIR/agy" 2>/dev/null && restored=true
    done
    for f in "$BACKUP_DIR"/agy.va39.backup.*; do
        [ -f "$f" ] || continue
        cp "$f" "$AGY_BIN_DIR/agy.va39" 2>/dev/null && restored=true
    done
    if [ "$restored" = "true" ]; then
        {
            echo "--- [restore_backup] $(date) ---"
            echo "Binarios restaurados desde $BACKUP_DIR"
        } >> "$LOG_FILE"
        echo -e "\n  ${YELLOW}⬡${RESET} Binarios anteriores restaurados desde backup." >&2
    fi
}

install_agy() {
    section_header "Instalacion"

    mkdir -p "$TMP_DIR"
    rm -rf "$EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"

    run_hidden "Descargar binarios" curl -fsSL --proto =https "$AGY_URL" -o "$TARBALL"

    run_hidden "Verificar integridad" gzip -t "$TARBALL"

    run_hidden "Extraer archivos" tar -xz -C "$EXTRACT_DIR" -f "$TARBALL" agy agy.va39

    if [ ! -f "$EXTRACT_DIR/agy" ] || [ ! -f "$EXTRACT_DIR/agy.va39" ]; then
        print_error "Los archivos extraidos no contienen los binarios esperados."
    fi

    run_hidden "Instalar bootstrapper" install -m 0755 "$EXTRACT_DIR/agy" "$AGY_BIN_DIR/agy"
    run_hidden "Instalar motor agy.va39" install -m 0755 "$EXTRACT_DIR/agy.va39" "$AGY_BIN_DIR/agy.va39"
}

verify_installation() {
    local version
    if version=$("$AGY_BIN_DIR/agy" --version 2>/dev/null); then
        check_item "Verificar instalacion" "ok" "${version}"
    else
        print_error "La verificacion de agy fallo. Revisa la instalacion."
    fi
}

setup_opencode_flow() {
    section_header "Integracion con opencode"

    if ! command -v opencode &>/dev/null; then
        check_item "opencode" "skip" "no instalado"
        echo ""
        echo -e "  ${DIM}Instala opencode con:${RESET}"
        echo -e "  ${DIM}  npm install -g opencode-ai${RESET}"
        echo ""
        return
    fi

    check_item "opencode detectado" "ok" "$(opencode --version 2>/dev/null)"

    mkdir -p "$OPCODE_CONFIG_DIR"

    local opencode_config='{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["opencode-antigravity-auth@latest"],
  "provider": {
    "google": {}
  },
  "model": "google/antigravity-gemini-3-pro"
}'

    if [ -f "$OPCODE_CONFIG_FILE" ]; then
        if grep -q "opencode-antigravity-auth" "$OPCODE_CONFIG_FILE" 2>/dev/null; then
            check_item "Plugin antigravity-auth" "ok" "ya configurado"
            return
        fi
        local bk="$OPCODE_CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$OPCODE_CONFIG_FILE" "$bk"
        check_item "Respaldo opencode" "ok" "${bk}"
    fi

    echo "$opencode_config" > "$OPCODE_CONFIG_FILE"
    check_item "Configurar plugin" "ok" "${OPCODE_CONFIG_FILE}"

    # Verificar que el plugin esta instalado en opencode
    if ! find "$HOME" -maxdepth 4 -type d -path "*/opencode-antigravity-auth" -print -quit &>/dev/null 2>&1; then
        echo ""
        echo -e "  ${DIM}Instalando plugin en opencode...${RESET}"
        opencode plugin opencode-antigravity-auth@latest &>/dev/null || true
    fi
}

# ── Resumen final ────────────────────────────────────────────────────────────

print_summary() {
    local line
    printf -v line "%*s" "$COLS" ""
    line="${line// /─}"

    echo ""
    box_line "├$(make_line)┤"
    box_text "" ""
    box_text "  Instalacion completada exitosamente" "${WHITE}${BOLD}"
    box_text "" ""
    box_line "└$(make_line)┘"
    echo ""

    # Informacion de los comandos
    echo -e "  ${BOLD}Comandos disponibles${RESET}"
    echo ""
    printf "    ${BOLD}%-26s${RESET} ${DIM}%s${RESET}\n" "agy" "Iniciar Antigravity CLI"
    printf "    ${BOLD}%-26s${RESET} ${DIM}%s${RESET}\n" "agy --version" "Version instalada"
    printf "    ${BOLD}%-26s${RESET} ${DIM}%s${RESET}\n" "agy login" "Autenticar con Google"
    printf "    ${BOLD}%-26s${RESET} ${DIM}%s${RESET}\n" "agy update" "Actualizar agy"
    echo ""

    # Archivos instalados
    echo -e "  ${BOLD}Archivos instalados${RESET}"
    echo ""
    printf "    ${DIM}%-30s ${RESET}%s\n" "Bootstrapper:" "$AGY_BIN_DIR/agy"
    printf "    ${DIM}%-30s ${RESET}%s\n" "Motor:" "$AGY_BIN_DIR/agy.va39"
    if [ -d "$BACKUP_DIR" ] && [ -n "$(find "$BACKUP_DIR" -maxdepth 1 -name 'agy*' -print -quit 2>/dev/null)" ]; then
        printf "    ${DIM}%-30s ${RESET}%s\n" "Respaldo:" "$BACKUP_DIR/"
    fi
    echo ""

    # Proximos pasos
    echo -e "  ${BOLD}Proximos pasos${RESET}"
    echo ""
    echo -e "  ${DIM}1.${RESET} ${BOLD}Autenticar agy${RESET}"
    echo -e "     ${DIM}Ejecuta:${RESET}  agy login"
    echo -e "     ${DIM}Esto abrira el navegador para completar el OAuth${RESET}"
    echo ""

    if command -v opencode &>/dev/null; then
        echo -e "  ${DIM}2.${RESET} ${BOLD}Autenticar opencode con Antigravity${RESET}"
        echo -e "     ${DIM}Ejecuta:${RESET}  opencode auth login"
        echo -e "     ${DIM}Selecciona: Google → OAuth with Google (Antigravity)${RESET}"
        echo -e "     ${DIM}Selecciona: Configure models in opencode.json${RESET}"
        echo ""

        echo -e "  ${DIM}3.${RESET} ${BOLD}Probar modelos en opencode${RESET}"
        echo -e "     ${DIM}Ejecuta:${RESET}  opencode run \"consulta\" --model google/antigravity-gemini-3-pro"
        echo ""
    fi

    # Creditos
    local sep
    printf -v sep "%*s" "$COLS" ""
    sep="${sep// /─}"
    echo -e "  ${DIM}${sep}${RESET}"
    echo -e "  ${BOLD}Script creado por Sebastian Laguna${RESET}"
    echo -e "  ${DIM}${SCRIPT_REPO}${RESET}"
    echo ""
}

# ── Desinstalacion ──────────────────────────────────────────────────────────

do_uninstall() {
    echo ""
    box_line "┌$(make_line)┐"
    box_text "Desinstalar Antigravity CLI" "$WHITE${BOLD}"
    box_line "└$(make_line)┘"
    echo ""

    if ! ask_yes_no "¿Esta seguro de desinstalar agy?" "N"; then
        echo -e "  ${DIM}Desinstalacion cancelada.${RESET}"
        exit 0
    fi
    echo ""

    local removed=false

    if [ -f "$AGY_BIN_DIR/agy" ]; then
        rm -f "$AGY_BIN_DIR/agy"
        echo -e "  ${GREEN}✔${RESET} Eliminado: ${AGY_BIN_DIR}/agy"
        removed=true
    fi

    if [ -f "$AGY_BIN_DIR/agy.va39" ]; then
        rm -f "$AGY_BIN_DIR/agy.va39"
        echo -e "  ${GREEN}✔${RESET} Eliminado: ${AGY_BIN_DIR}/agy.va39"
        removed=true
    fi

    if [ "$removed" != "true" ]; then
        echo -e "  ${YELLOW}−${RESET} No se encontro instalacion de agy."
    fi

    echo ""
    echo -e "  ${BOLD}Para eliminar configuracion de opencode:${RESET}"
    echo -e "  ${DIM}  rm -i ${OPCODE_CONFIG_FILE}${RESET}"
    echo ""
    echo -e "  ${BOLD}Para eliminar respaldos:${RESET}"
    echo -e "  ${DIM}  rm -rf ${BACKUP_DIR}/agy.backup.*${RESET}"
    echo ""

    local sep
    printf -v sep "%*s" "$COLS" ""
    sep="${sep// /─}"
    echo -e "  ${DIM}${sep}${RESET}"
    echo -e "  ${BOLD}Script creado por Sebastian Laguna${RESET}"
    echo -e "  ${DIM}${SCRIPT_REPO}${RESET}"
    echo ""

    exit 0
}

# ── Ayuda ───────────────────────────────────────────────────────────────────

show_help() {
    echo ""
    box_line "┌$(make_line)┐"
    box_text "Antigravity CLI - Termux" "$WHITE${BOLD}"
    box_text "Script de instalacion v${SCRIPT_VERSION}" ""
    box_line "└$(make_line)┘"
    echo ""
    echo -e "  ${BOLD}Uso:${RESET}"
    echo ""
    printf "  ${BOLD}%-28s${RESET} ${DIM}%s${RESET}\n" "bash install.sh" "Instalacion completa"
    printf "  ${BOLD}%-28s${RESET} ${DIM}%s${RESET}\n" "bash install.sh --help" "Muestra esta ayuda"
    printf "  ${BOLD}%-28s${RESET} ${DIM}%s${RESET}\n" "bash install.sh --version" "Muestra la version"
    printf "  ${BOLD}%-28s${RESET} ${DIM}%s${RESET}\n" "bash install.sh --uninstall" "Desinstala agy"
    echo ""
    echo -e "  ${BOLD}Descripcion:${RESET}"
    echo -e "  ${DIM}Instala Antigravity CLI (agy) de forma nativa en Termux."
    echo -e "  ${DIM}Utiliza el fork wallentx/antigravity-cli-termux que incluye:"
    echo -e "  ${DIM}  - Bootstrapper nativo compilado para Android/Bionic"
    echo -e "  ${DIM}  - Engine glibc parcheado (VA39, DNS, TLS)"
    echo -e "  ${DIM}  - Sin necesidad de proot, wrappers ni VMs${RESET}"
    echo ""
    echo -e "  ${BOLD}Script creado por Sebastian Laguna${RESET}"
    echo -e "  ${DIM}${SCRIPT_REPO}${RESET}"
    echo ""
    exit 0
}

# ── Main ────────────────────────────────────────────────────────────────────

main() {
    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --version|-v)
            echo "antigravity-termux v${SCRIPT_VERSION}"
            exit 0
            ;;
        --uninstall)
            do_uninstall
            ;;
        "")
            ;;
        *)
            echo -e "  ${RED}[ERR]${RESET} Opcion desconocida: ${1}"
            echo "  Usa: bash install.sh --help"
            exit 1
            ;;
    esac

    print_banner

    if ! ask_yes_no "¿Deseas continuar con la instalacion?" "S"; then
        echo -e "  ${DIM}Instalacion cancelada.${RESET}"
        exit 0
    fi

    check_environment
    check_dependencies

    local current_version
    current_version=$(detect_installed_version)
    if [ -n "$current_version" ] && ! check_existing "$current_version"; then
        exit 0
    fi

    backup_existing

    INSTALL_FAILED=true
    install_agy
    verify_installation
    INSTALL_FAILED=false

    echo ""
    if ask_yes_no "¿Deseas integrar agy con opencode?" "S"; then
        setup_opencode_flow
    fi

    print_summary
}

main "$@"
