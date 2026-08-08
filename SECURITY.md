# Politica de seguridad

Antigravity CLI para Termux instala binarios de terceros (fork comunitario
`wallentx/antigravity-cli-termux`) en tu dispositivo. La seguridad de ese
proceso es nuestra prioridad.

## Reportar una vulnerabilidad

**NO abras un issue publico** para vulnerabilidades. Contacta a los mantenedores
en privado por el canal de GitHub Security Advisories o por correo a los
mantenedores del repositorio.

Incluye en tu reporte:

- Descripcion de la vulnerabilidad y su impacto.
- Pasos para reproducirla.
- Plataforma afectada (Termux/Android ARM64).
- Version de Antigravity/install.sh afectada.

## Consideraciones de seguridad del proyecto

- **Descargas solo HTTPS**: `install.sh` y `scripts/mirror.sh` usan
  `curl --proto =https` y `--max-time`. No se descarga nada por HTTP.
- **Verificacion SHA256**: cada tarball se valida contra `versions.json`
  antes de instalar.
- **Fallo seguro**: si la integridad no coincide, la instalacion se aborta
  y se restaura el respaldo anterior (`~/backups/agy.backup.*`).
- **Multi-fuente con cache**: wallentx → mirror propio → cache local, para
  no depender de un unico punto de fallo.
- **Sin secretos en el repositorio**: no se commitean tokens, API keys ni
  configuraciones personales. Reporta cualquier excepcion.

## Alcance

Este proyecto se distribuye SIN GARANTIA (licencia MIT). Usalo bajo tu
responsabilidad. Los binarios de `agy` pertenecen a sus autores originales.
