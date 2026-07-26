# Antigravity CLI - Termux

<p align="center">
  <img src="imagenes/Antigravity.jpg" alt="Antigravity CLI" width="600">
</p>

<p align="center">
  <img src="imagenes/Antigravity2.jpg" alt="Antigravity CLI" width="600">
</p>

Instalacion nativa de **Antigravity CLI (agy)** en Termux para Android ARM64.
Sin proot, sin VMs, sin Cloud Shell.

Este proyecto utiliza el fork comunitario
[wallentx/antigravity-cli-termux](https://github.com/wallentx/antigravity-cli-termux)
que proporciona un bootstrapper compilado para Android/Bionic y un engine glibc
parcheado para funcionar correctamente en Termux.

---

## Requisitos

- **Termux** instalado desde [F-Droid](https://f-droid.org/packages/com.termux/)
  (no desde Google Play)
- **Dispositivo Android ARM64** (aarch64)
- **Conexion a internet** para descargar los binarios
- Espacio libre: ~180MB

---

## Instalacion

```bash
# Clonar el repositorio
git clone https://github.com/sebastianl1/antigravity_termux.git
cd antigravity-termux

# Ejecutar el instalador
bash install.sh
```

El instalador es interactivo y te guiara paso a paso:

1. Verifica el entorno (Termux, arquitectura, dependencias)
2. Descarga e instala los binarios de agy
3. Configura el PATH en tu shell
4. Verifica la instalacion
5. Integra con opencode (opcional)

---

## Que instala

| Componente | Ruta | Descripcion |
|------------|------|-------------|
| `agy` | `$PREFIX/bin/agy` | Bootstrapper nativo Android (~30KB) |
| `agy.va39` | `$PREFIX/bin/agy.va39` | Engine glibc parcheado para Termux (~160MB) |

### Como funciona

El binario `agy` es un bootstrapper compilado nativamente para Android (Bionic libc)
que se encarga de:

- Limpiar variables de entorno que interfieren (`LD_PRELOAD`, `LD_LIBRARY_PATH`)
- Configurar la resolucion DNS correcta para Termux (`GODEBUG=netdns=cgo`)
- Apuntar al almacen de certificados TLS de Termux (`SSL_CERT_FILE`)
- Ejecutar el engine `agy.va39` a traves del loader glibc

Todo esto sin necesidad de `proot`, wrappers ni configuraciones manuales.

---

## Uso

### Iniciar Antigravity CLI

```bash
agy
```

### Verificar version

```bash
agy --version
```

### Autenticar con Google

```bash
agy login
```

Esto abrira tu navegador o mostrara una URL para completar la autenticacion
OAuth con tu cuenta de Google.

### Comandos principales

| Comando | Descripcion |
|---------|-------------|
| `agy` | Iniciar la CLI interactiva |
| `agy login` | Autenticar con Google |
| `agy --version` | Mostrar version |
| `agy update` | Actualizar a la ultima version |

---

## Integracion con opencode

Si tienes [opencode](https://opencode.ai) instalado, el instalador puede
configurar automaticamente el plugin `opencode-antigravity-auth` para que
puedas usar los modelos de Antigravity directamente desde opencode.

### Configuracion manual

Si elegiste no integrar durante la instalacion o si necesitas configurarlo
despues:

1. Ejecuta en tu terminal:
   ```bash
   opencode auth login
   ```
2. Selecciona **Google**
3. Selecciona **OAuth with Google (Antigravity)**
4. Selecciona **"Configure models in opencode.json"**

### Modelos disponibles

| ID | Modelo |
|----|--------|
| `google/antigravity-gemini-3-pro` | Gemini 3 Pro |
| `google/antigravity-gemini-3.1-pro` | Gemini 3.1 Pro |
| `google/antigravity-gemini-3-flash` | Gemini 3 Flash |
| `google/antigravity-claude-sonnet-4-6` | Claude Sonnet 4.6 |
| `google/antigravity-claude-opus-4-6-thinking` | Claude Opus 4.6 Thinking |

### Uso con opencode

```bash
opencode run "Escribe un script en Python" --model google/antigravity-gemini-3-pro
```

---

## Desinstalacion

Para desinstalar agy:

```bash
bash install.sh --uninstall
```

Esto elimina los binarios de `$PREFIX/bin/`. Si tambien quieres eliminar
la configuracion de opencode:

```bash
rm -i ~/.config/opencode/opencode.json
```

Para eliminar los respaldos:

```bash
rm -rf ~/backups/agy.backup.*
```

---

## Estructura del proyecto

```
antigravity-termux/
├── imagenes/
│   └── Antigravity.jpg   # Banner del proyecto
├── install.sh            # Script de instalacion
├── README.md             # Este archivo
└── LICENSE               # Licencia MIT
```

---

## Autor

**Sebastian Laguna** — Creador y mantenedor del proyecto

---

## Creditos

- **[wallentx/antigravity-cli-termux](https://github.com/wallentx/antigravity-cli-termux)**
  — Fork comunitario con parches de compatibilidad para Termux (VA39, DNS, TLS)
- **[NoeFabris/opencode-antigravity-auth](https://github.com/NoeFabris/opencode-antigravity-auth)**
  — Plugin de integracion con opencode

---

## Licencia

Este proyecto esta bajo la licencia MIT. Ver el archivo [LICENSE](LICENSE).
