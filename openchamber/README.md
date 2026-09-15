# OpenChamber en Docker Compose

Despliegue persistente de OpenChamber para un VPS usando el método
`official-source`. El código se obtiene del repositorio oficial y la imagen se
construye con el `Dockerfile` y el `scripts/docker-entrypoint.sh` que contiene
ese checkout. No se instala OpenChamber mediante CLI dentro del contenedor.

## Instalación

Requisitos: Git, Docker Engine y el plugin `docker compose`.

```sh
cp .env.example .env
${EDITOR:-vi} .env
```

Define `OPENCHAMBER_UI_PASSWORD` con una contraseña larga y aleatoria. Por
defecto el puerto se publica solo en `127.0.0.1`, que es adecuado cuando un
proxy inverso vive en el mismo VPS. Para acceso directo desde una VPN o LAN
de confianza, configura `OPENCHAMBER_BIND_ADDRESS=0.0.0.0` y limita el acceso
con el firewall.

Instala y arranca:

```sh
./scripts/install.sh
```

El script clona `https://github.com/openchamber/openchamber.git` en
`OPENCHAMBER_SOURCE_DIR`, crea los directorios persistentes y ejecuta la
construcción oficial con `docker compose build --pull`.

## Datos persistentes

Las rutas del host se definen en `.env` y se montan así:

| Variable | Destino en el contenedor |
| --- | --- |
| `OPENCHAMBER_CONFIG_DIR` | `/home/openchamber/.config/openchamber` |
| `OPENCODE_SHARE_DIR` | `/home/openchamber/.local/share/opencode` |
| `OPENCODE_STATE_DIR` | `/home/openchamber/.local/state/opencode` |
| `OPENCODE_CONFIG_DIR` | `/home/openchamber/.config/opencode` |
| `OPENCHAMBER_SSH_DIR` | `/home/openchamber/.ssh` |
| `OPENCHAMBER_WORKSPACES_DIR` | `/home/openchamber/workspaces` |

El último montaje es el directorio de proyectos del host. El entrypoint
oficial puede generar una clave Ed25519 dentro del directorio SSH persistente
si todavía no existe. Protege ese directorio y no lo publiques en Git.

## Actualización

La actualización se hace siempre desde el checkout oficial:

```sh
./scripts/update.sh
```

Ese script ejecuta `git pull`, `docker compose build --pull` y
`docker compose up -d`, en ese orden. No se usa Watchtower. Para consultar el
estado y las últimas líneas del servicio:

```sh
./scripts/status.sh
```

El servicio usa `restart: unless-stopped`, por lo que vuelve a iniciarse tras
un reinicio del VPS mientras no se haya detenido explícitamente.

## Acceso remoto

- **Private Relay:** empareja el dispositivo desde OpenChamber eligiendo
  `Anywhere`, o genera un enlace con `openchamber connect-url --relay --qr` en
  el servidor. El Relay usa una conexión saliente y no requiere abrir puertos.
- **SSH:** conserva las claves en `OPENCHAMBER_SSH_DIR` y usa las funciones de
  conexión SSH de OpenChamber. El directorio se monta como `/home/openchamber/.ssh`.
- **VPN/LAN:** cambia `OPENCHAMBER_BIND_ADDRESS` a `0.0.0.0` o a una dirección
  específica de la interfaz de confianza y permite solo el puerto configurado
  desde la VPN en el firewall.
- **HTTPS público:** coloca un proxy inverso delante del puerto local y exige
  HTTPS. La contraseña de UI sigue siendo obligatoria aunque exista proxy.

## Claves SSH

El directorio `OPENCHAMBER_SSH_DIR` se monta como `/home/openchamber/.ssh`
dentro del contenedor.

El archivo público debe estar junto a la clave privada, con el sufijo
`.pub`. Reinicia el servicio después de instalar una clave:

```sh
docker compose restart openchamber
```

En OpenChamber, abre **Settings > Git identities** y crea una identidad con:

- **Método de autenticación:** `SSH`.
- **Ruta de la clave SSH:** `/home/openchamber/.ssh/id_rsa.pem`.
- **Firma de commits:** activa la opción si quieres firmar los commits.
- **Clave de firma:** `/home/openchamber/.ssh/id_rsa.pub`.

Usa siempre la ruta absoluta dentro del contenedor. No uses `~/.ssh/...`:
OpenChamber valida esa ruta antes de ejecutarla y `~` se rechaza como carácter
no válido. El nombre `.pem` no es un problema; la clave privada debe ser
legible por el usuario del contenedor y su archivo `.pub` debe corresponderle.

La clave pública debe agregarse en GitHub en **Settings > SSH and GPG keys**.
Para usarla para acceder a repositorios, agrégala como **Authentication Key**.
Si también quieres que los commits aparezcan como `Verified`, agrégala como
**Signing Key**. La ruta de firma es la clave pública, pero la firma usa la
clave privada que permanece dentro del volumen SSH.

Comprueba la conexión desde el contenedor sin mostrar la clave privada:

```sh
docker compose exec -T openchamber ssh \
  -o BatchMode=yes \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=accept-new \
  -i /home/openchamber/.ssh/id_rsa.pem \
  -T git@github.com
```

Una autenticación correcta termina normalmente con un mensaje de GitHub que
indica que la autenticación tuvo éxito pero que no ofrece acceso de shell. Si
recibes `Permission denied (publickey)`, comprueba que `id_rsa.pub` sea la
clave pública derivada de `id_rsa.pem` y que esa misma clave esté agregada en
GitHub como **Authentication Key** para la cuenta propietaria del repositorio.

Puedes comparar las huellas sin imprimir la clave privada:

```sh
docker compose exec -T openchamber sh -c \
  'ssh-keygen -lf /home/openchamber/.ssh/id_rsa.pub && \
   ssh-keygen -y -f /home/openchamber/.ssh/id_rsa.pem | ssh-keygen -lf -'
```

Usa rutas absolutas en la identidad, porque son las rutas que existen dentro
del contenedor y funcionan tanto para clones como para firmas.

El Relay, SSH y VPN son opciones de acceso distintas; no es necesario activar
un túnel Cloudflare para usar el Compose. Las variables oficiales de túnel
están disponibles en `.env.example` para quien las necesite.

## Nginx Proxy Manager externo

Nginx Proxy Manager no forma parte de este Compose. Crea un Proxy Host con:

1. `Forward Hostname/IP`: `127.0.0.1`.
2. `Forward Port`: el valor de `OPENCHAMBER_PORT`.
3. `Websockets Support`: activado.
4. Un certificado Let's Encrypt o un certificado válido, y redirección a
   HTTPS.

Pega [docs/nginx-proxy-manager-advanced.conf](docs/nginx-proxy-manager-advanced.conf)
en la pestaña **Advanced** y cambia el puerto `3000` si usas otro. La
configuración incluye:

- upgrades WebSocket para `/api/terminal/ws`, `/api/global/event/ws` y
  `/api/event/ws`;
- buffering y caché desactivados para SSE en `/api/event`,
  `/api/global/event`, `/api/notifications/stream` y
  `/api/openchamber/events`;
- `gzip off` en las rutas en tiempo real;
- `client_max_body_size 50M` para adjuntos y operaciones de archivos;
- timeouts de lectura y escritura de una hora para streams y terminales;
- cabeceras `Host`, `X-Forwarded-*` y `X-Accel-Buffering`.

Comprueba primero el acceso directo al puerto local y añade Nginx Proxy
Manager después. Si colocas además un CDN, evita comprimir dos veces y
verifica que no almacene en buffer las respuestas SSE.

## Fuentes oficiales

- [Repositorio OpenChamber](https://github.com/openchamber/openchamber)
- [Dockerfile oficial](https://github.com/openchamber/openchamber/blob/main/Dockerfile)
- [Compose oficial](https://github.com/openchamber/openchamber/blob/main/docker-compose.yml)
- [Guía oficial de reverse proxy](https://github.com/openchamber/openchamber/blob/main/docs/REVERSE_PROXY.md)
- [Private Relay](https://github.com/openchamber/openchamber/blob/main/packages/docs/content/docs/private-relay.mdx)
