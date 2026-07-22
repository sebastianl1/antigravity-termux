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
SCRIPT_REPO="https://github.com/tuusuario/antigravity-termux"

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

# ── Estilos ──────────────────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ── Funciones de utilidad ────────────────────────────────────────────────────

cleanup() {
    rm -rf "$EXTRACT_DIR" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

print_banner() {
    local width=68
    local line=""
    printf -v line "%*s" "$width" ""
    line="${line// /─}"

    echo ""
    echo "  ${BOLD}┌${line}┐${RESET}"
    echo "  ${BOLD}│${RESET}  Antigravity CLI - Termux                                    ${BOLD}│${RESET}"
    echo "  ${BOLD}│${RESET}  Script de instalacion                                       ${BOLD}│${RESET}"
    echo "  ${BOLD}│${RESET}  v${SCRIPT_VERSION}                                                  ${BOLD}│${RESET}"
    echo "  ${BOLD}└${line}┘${RESET}"
    echo ""
}

print_step() {
    local current="$1"
    local total="$2"
    local msg="$3"
    printf "  ${BOLD}[%s/%s]${RESET} %s" "$current" "$total" "$msg"
}

print_ok() {
    printf " ${GREEN}[ OK ]${RESET}\n"
}

print_info() {
    echo -e "  ${DIM}${1}${RESET}"
}

print_warn() {
    echo -e "  ${YELLOW}[WARN]${RESET} ${1}"
}

print_error() {
    echo -e "\n  ${RED}[ERR]${RESET} ${1}"
    exit 1
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-S}"
    local yn

    if [ "$default" = "S" ]; then
        echo -n "  ${prompt} [S/n]: "
    else
        echo -n "  ${prompt} [s/N]: "
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
    printf "  ${BOLD}[ ]${RESET} %s" "$desc"

    "$@" > "$LOG_FILE" 2>&1 &
    local pid=$!
    local spin='-\|/'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        printf "\b\b\b\b\b${BOLD}[%c]${RESET}" "${spin:$i:1}"
        i=$(( (i + 1) % 4 ))
        sleep 0.1
    done

    wait $pid
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        printf "\b\b\b\b\b${GREEN}[ OK ]${RESET}\n"
    else
        printf "\b\b\b\b\b${RED}[ERR]${RESET}\n"
        echo ""
        print_error "Fallo: ${desc}"
        echo ""
        echo "  Ultimas lineas del log:"
        tail -5 "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
            echo "    $line"
        done
        exit 1
    fi
}

# ── Funciones del instalador ─────────────────────────────────────────────────

check_environment() {
    print_step 1 7 "Verificando entorno..."

    if [ -z "${TERMUX_VERSION:-}" ]; then
        print_ok
        print_warn "No se detecto Termux. Continuando de todas formas..."
        return 0
    fi

    if [ "$(uname -m)" != "aarch64" ]; then
        print_ok
        print_warn "Arquitectura: $(uname -m) (se esperaba aarch64)"
        print_info "El binario oficial solo esta disponible para ARM64."
        if ! ask_yes_no "¿Deseas continuar de todas formas?" "N"; then
            print_info "Instalacion cancelada."
            exit 0
        fi
        return 0
    fi

    if [ ! -x "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" ]; then
        print_ok
        print_warn "glibc no encontrado. Instalando..."
        run_hidden "Instalando glibc" pkg install -y glibc-repo glibc-runner
    fi

    if [ ! -s "$PREFIX/etc/tls/cert.pem" ]; then
        print_ok
        print_warn "ca-certificates no encontrado. Instalando..."
        run_hidden "Instalando ca-certificates" pkg install -y ca-certificates
    fi

    if [ ! -r "$PREFIX/etc/resolv.conf" ]; then
        print_ok
        print_warn "resolv-conf no encontrado. Instalando..."
        run_hidden "Instalando resolv-conf" pkg install -y resolv-conf
    fi

    print_ok
}

check_dependencies() {
    print_step 2 7 "Verificando dependencias..."

    local missing=0

    if ! command -v curl >/dev/null 2>&1; then
        print_ok
        print_warn "curl no instalado. Instalando..."
        run_hidden "Instalando curl" pkg install -y curl
        print_ok
        return
    fi

    if ! command -v tar >/dev/null 2>&1; then
        print_ok
        print_warn "tar no instalado. Instalando..."
        run_hidden "Instalando tar" pkg install -y tar
        print_ok
        return
    fi

    print_ok
}

backup_existing() {
    print_step 3 7 "Respaldando instalacion previa..."

    local has_backup=0

    if [ -f "$AGY_BIN_DIR/agy" ]; then
        mkdir -p "$BACKUP_DIR"
        local timestamp
        timestamp=$(date +%Y%m%d-%H%M%S)
        mv "$AGY_BIN_DIR/agy" "$BACKUP_DIR/agy.backup.$timestamp"
        has_backup=1
    fi

    if [ -f "$AGY_BIN_DIR/agy.va39" ]; then
        mkdir -p "$BACKUP_DIR"
        local timestamp
        timestamp=$(date +%Y%m%d-%H%M%S)
        mv "$AGY_BIN_DIR/agy.va39" "$BACKUP_DIR/agy.va39.backup.$timestamp"
        has_backup=1
    fi

    if [ "$has_backup" -eq 1 ]; then
        print_ok
        print_info "Respaldo guardado en: $BACKUP_DIR"
    else
        print_ok
        print_info "No se encontro instalacion previa."
    fi
}

install_agy() {
    print_step 4 7 "Descargando e instalando agy..."

    mkdir -p "$TMP_DIR"
    rm -rf "$EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"

    run_hidden "Descargando binarios" curl -fsSL "$AGY_URL" -o "$TARBALL"

    run_hidden "Extrayendo archivos" tar -xz -C "$EXTRACT_DIR" -f "$TARBALL" agy agy.va39

    if [ ! -f "$EXTRACT_DIR/agy" ] || [ ! -f "$EXTRACT_DIR/agy.va39" ]; then
        print_error "Archivos extraidos no encontrados."
    fi

    run_hidden "Instalando agy en ${AGY_BIN_DIR}" install -m 0755 "$EXTRACT_DIR/agy" "$AGY_BIN_DIR/agy"

    run_hidden "Instalando agy.va39 en ${AGY_BIN_DIR}" install -m 0755 "$EXTRACT_DIR/agy.va39" "$AGY_BIN_DIR/agy.va39"

    print_ok
}

configure_shell_path() {
    print_step 5 7 "Configurando PATH en el shell..."

    local path_line='export PATH="$HOME/.local/bin:$PATH"'
    local fish_path_line='fish_add_path $HOME/.local/bin'
    local configured=0

    if [ -f "$HOME/.config/fish/config.fish" ]; then
        if grep -q 'fish_add_path $HOME/.local/bin' "$HOME/.config/fish/config.fish" 2>/dev/null; then
            print_ok
            print_info "PATH ya configurado en fish."
            return
        fi
        echo "$fish_path_line" >> "$HOME/.config/fish/config.fish"
        configured=1
        print_ok
        print_info "Configurado en: ~/.config/fish/config.fish"
        return
    fi

    if [ -f "$HOME/.zshrc" ]; then
        if grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null; then
            print_ok
            print_info "PATH ya configurado en zsh."
            return
        fi
        echo "" >> "$HOME/.zshrc"
        echo "# Agregado por antigravity-termux" >> "$HOME/.zshrc"
        echo "$path_line" >> "$HOME/.zshrc"
        configured=1
        print_ok
        print_info "Configurado en: ~/.zshrc"
        return
    fi

    if [ -f "$HOME/.bashrc" ]; then
        if grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
            print_ok
            print_info "PATH ya configurado en bash."
            return
        fi
        echo "" >> "$HOME/.bashrc"
        echo "# Agregado por antigravity-termux" >> "$HOME/.bashrc"
        echo "$path_line" >> "$HOME/.bashrc"
        configured=1
        print_ok
        print_info "Configurado en: ~/.bashrc"
        return
    fi

    print_ok
    print_warn "No se detecto un archivo de configuracion de shell."
    print_info "Agrega manualmente al archivo de tu shell:"
    print_info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
}

verify_installation() {
    print_step 6 7 "Verificando instalacion..."

    local version
    if version=$("$AGY_BIN_DIR/agy" --version 2>/dev/null); then
        print_ok
        print_info "Version instalada: ${version}"
    else
        print_error "La verificacion de agy fallo."
    fi
}

setup_opencode() {
    print_step 7 7 "Configurando integracion con opencode..."

    if ! command -v opencode >/dev/null 2>&1; then
        print_ok
        print_warn "opencode no esta instalado. Omitiendo integracion."
        print_info "Instala opencode con: npm install -g opencode-ai"
        return
    fi

    mkdir -p "$OPCODE_CONFIG_DIR"

    if [ -f "$OPCODE_CONFIG_FILE" ]; then
        if grep -q "opencode-antigravity-auth" "$OPCODE_CONFIG_FILE" 2>/dev/null; then
            print_ok
            print_info "Plugin antigravity-auth ya configurado en opencode."
            return
        fi

        local backup_config="$OPCODE_CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$OPCODE_CONFIG_FILE" "$backup_config"
        print_info "Respaldo de configuracion: ${backup_config}"
    fi

    cat > "$OPCODE_CONFIG_FILE" << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["opencode-antigravity-auth@latest"],
  "provider": {
    "google": {}
  },
  "model": "google/antigravity-gemini-3-pro"
}
EOF

    print_ok
    print_info "Archivo creado: ${OPCODE_CONFIG_FILE}"
}

print_summary() {
    local width=68
    local line=""
    printf -v line "%*s" "$width" ""
    line="${line// /─}"

    echo ""
    echo "  ${BOLD}┌${line}┐${RESET}"
    echo "  ${BOLD}│${RESET}  ${GREEN}Instalacion completada exitosamente${RESET}                    ${BOLD}│${RESET}"
    echo "  ${BOLD}└${line}┘${RESET}"
    echo ""
    echo "  ${BOLD}Comandos disponibles:${RESET}"
    echo "    agy              ${DIM}Iniciar Antigravity CLI${RESET}"
    echo "    agy --version    ${DIM}Version instalada${RESET}"
    echo "    agy login        ${DIM}Autenticar con Google${RESET}"
    echo ""
    echo "  ${BOLD}Proximos pasos:${RESET}"
    echo "    1. Ejecuta en tu terminal:${DIM} agy login${RESET}"
    echo "    2. Completa la autenticacion en el navegador"
    echo "    3. Disfruta de Antigravity CLI en Termux"
    echo ""

    if command -v opencode >/dev/null 2>&1; then
        echo "  ${BOLD}Integracion con opencode:${RESET}"
        echo "    1. Ejecuta en tu terminal:${DIM} opencode auth login${RESET}"
        echo "    2. Selecciona:${DIM} Google${RESET}"
        echo "    3. Selecciona:${DIM} OAuth with Google (Antigravity)${RESET}"
        echo "    4. Selecciona:${DIM} Configure models in opencode.json${RESET}"
        echo "    5. Usa:${DIM} opencode run \"mensaje\" --model google/antigravity-gemini-3-pro${RESET}"
        echo ""
    fi

    echo "  ${BOLD}Ubicacion de los archivos:${RESET}"
    echo "    agy:        ${DIM}${AGY_BIN_DIR}/agy${RESET}"
    echo "    agy.va39:   ${DIM}${AGY_BIN_DIR}/agy.va39${RESET}"
    echo "    respaldo:   ${DIM}${BACKUP_DIR}/${RESET}"
    echo ""

    echo "  ${line//─/─}"
    echo "  ${BOLD}Script creado por Sebastian Laguna${RESET}"
    echo "  ${DIM}${SCRIPT_REPO}${RESET}"
    echo ""
}

do_uninstall() {
    echo ""
    echo "  ${BOLD}Desinstalando Antigravity CLI...${RESET}"
    echo ""

    local removed=0

    if [ -f "$AGY_BIN_DIR/agy" ]; then
        rm -f "$AGY_BIN_DIR/agy"
        echo "  ${GREEN}[ OK ]${RESET} Eliminado: ${AGY_BIN_DIR}/agy"
        removed=1
    fi

    if [ -f "$AGY_BIN_DIR/agy.va39" ]; then
        rm -f "$AGY_BIN_DIR/agy.va39"
        echo "  ${GREEN}[ OK ]${RESET} Eliminado: ${AGY_BIN_DIR}/agy.va39"
        removed=1
    fi

    if [ "$removed" -eq 0 ]; then
        echo "  ${YELLOW}[WARN]${RESET} No se encontro instalacion de agy."
    fi

    echo ""
    echo "  ${BOLD}Para eliminar la configuracion de opencode:${RESET}"
    echo "    rm -i ${OPCODE_CONFIG_FILE}"
    echo ""
    echo "  ${BOLD}Para eliminar los respaldos:${RESET}"
    echo "    rm -rf ${BACKUP_DIR}/agy.backup.*"
    echo ""
    echo "  ${line//─/─}"
    echo "  ${BOLD}Script creado por Sebastian Laguna${RESET}"
    echo ""

    exit 0
}

show_help() {
    echo ""
    echo "  ${BOLD}Antigravity CLI - Termux${RESET}"
    echo "  Script de instalacion v${SCRIPT_VERSION}"
    echo ""
    echo "  ${BOLD}Uso:${RESET}"
    echo "    bash install.sh              ${DIM}Instalacion completa${RESET}"
    echo "    bash install.sh --help       ${DIM}Muestra esta ayuda${RESET}"
    echo "    bash install.sh --version    ${DIM}Muestra la version${RESET}"
    echo "    bash install.sh --uninstall  ${DIM}Desinstala agy${RESET}"
    echo ""
    echo "  ${BOLD}Descripcion:${RESET}"
    echo "    Instala Antigravity CLI (agy) de forma nativa en Termux."
    echo "    Utiliza el fork wallentx/antigravity-cli-termux que incluye:"
    echo "      - Bootstrapper nativo compilado para Android/Bionic"
    echo "      - Engine glibc parcheado (VA39, DNS, TLS)"
    echo "      - Sin necesidad de proot, wrappers ni VMs"
    echo ""
    echo "  ${BOLD}Script creado por Sebastian Laguna${RESET}"
    echo "  ${DIM}${SCRIPT_REPO}${RESET}"
    echo ""

    exit 0
}

# ── Main ──────────────────────────────────────────────────────────────────────

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
            # Instalacion normal
            ;;
        *)
            echo "  ${RED}[ERR]${RESET} Opcion desconocida: ${1}"
            echo "  Usa: bash install.sh --help"
            exit 1
            ;;
    esac

    print_banner

    if ! ask_yes_no "¿Deseas continuar con la instalacion?" "S"; then
        print_info "Instalacion cancelada."
        exit 0
    fi
    echo ""

    check_environment

    check_dependencies

    backup_existing

    install_agy

    configure_shell_path

    verify_installation

    echo ""
    if ask_yes_no "¿Deseas integrar agy con opencode?" "S"; then
        setup_opencode
    else
        print_step 7 7 "Omitiendo integracion con opencode..."
        print_ok
    fi

    print_summary
}

main "$@"
