# Changelog

Todas las versiones notables de Antigravity CLI para Termux se documentan aqui.
Formato basado en [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- CI/CD: workflow de lint (bash -n, shellcheck, node --check lang, validacion
  de `versions.json` y claves i18n) y job de tests (pytest).
- CD: workflow de despliegue de GitHub Pages (docs/).
- Tests (`tests/`) para `versions.json` (sha256 hex, urls https) e i18n.
- `docs/llms.txt` (AEO) y `sitemap.xml` corregido.
- Documentacion de comunidad: `SECURITY.md`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md` y este `CHANGELOG.md`.
- `.gitignore` raiz (`.opencode/`, `*.log`, `__pycache__`).

### Fixed
- `install.sh`: URL del repositorio en la cabecera (placeholder corregido).
- `README.md`: estructura del proyecto incluye `docs/`; ejemplo de mirror
  corregido (v1.1.10).
- `.opencode/` fuera del tracking.

## [1.2.0] - 2026-07-25

- Instalador v1.2 con mejoras de robustez.

## [1.1.0] - 2026-07-22

- Instalador v1.1, banner e integracion con opencode.

## [1.0.0] - 2026-07-22

- Instalador inicial de Antigravity CLI para Termux.
