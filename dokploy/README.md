# Dokploy con Docker nativo

Esta carpeta prepara Dokploy usando el instalador Docker oficial. Dokploy no instala su control plane mediante Docker Compose: la arquitectura oficial usa Docker Swarm para `dokploy` y PostgreSQL, y un contenedor Docker independiente para Traefik.

## Requisitos

- Linux.
- Docker Engine instalado o permisos para que el instalador oficial lo instale.
- Ejecutar como root o mediante un usuario con sudo.
- Host dedicado o Docker Swarm sin servicios que deban conservarse.
- Puertos libres: `80`, `443` y `3000`.
- Recomendado: 2 GB RAM y 30 GB de disco.

**Importante:** el instalador oficial ejecuta `docker swarm leave --force` y después inicializa un Swarm nuevo. No lo ejecutes en un host que ya pertenezca a un Swarm con servicios que quieras conservar. Tampoco lo ejecutes dentro de un contenedor.

## Instalación

Desde esta carpeta:

```sh
./scripts/install.sh
```

El wrapper descarga el instalador actual desde `https://dokploy.com/install.sh` y lo ejecuta con privilegios. El instalador oficial:

- inicializa Docker Swarm;
- crea la red overlay `dokploy-network`;
- crea los secrets Docker para PostgreSQL y la autenticación;
- crea los servicios Swarm `dokploy` y `dokploy-postgres`;
- crea el contenedor `dokploy-traefik`;
- persiste la configuración en `/etc/dokploy`;
- mantiene datos en los volúmenes `dokploy` y `dokploy-postgres`.

Al finalizar, abre:

```text
http://IP_DEL_SERVIDOR:3000
```

Crea la cuenta administradora y configura el dominio HTTPS desde Dokploy antes de exponer aplicaciones públicamente.

### Dirección anunciada de Swarm

Si el servidor tiene varias interfaces, una VPN o no puede detectar correctamente su IP, establece `ADVERTISE_ADDR` inline al ejecutar el instalador oficial. Desde este wrapper:

```sh
sudo ADVERTISE_ADDR=192.168.1.100 ./scripts/install.sh
```

La dirección debe ser accesible para los nodos que se unan al Swarm.

## Estado y logs

```sh
./scripts/status.sh
docker service ps dokploy
docker service logs -f dokploy
docker service logs -f dokploy-postgres
docker logs -f dokploy-traefik
```

## Actualización

Usa el actualizador oficial, que actualiza el servicio Dokploy sin tocar Traefik automáticamente:

```sh
./scripts/update.sh
```

El script oficial indica que Traefik se actualiza manualmente para evitar interrupciones inesperadas. Revisa las notas de la versión antes de cambiarlo.

Para diagnosticar una instalación sin ocultar comandos:

```sh
DOKPLOY_INSTALL_TRACE=1 ./scripts/install.sh
```

## Desinstalación

La desinstalación elimina servicios, secrets, volúmenes, red, Swarm y `/etc/dokploy`. Los comandos oficiales son destructivos y no se incluyen en un script automático para evitar borrar un Swarm que contenga otros servicios. Consulta la [guía oficial de desinstalación](https://docs.dokploy.com/docs/core/uninstall) y verifica cada recurso antes de eliminarlo.

## CI/CD con Forgejo

Dokploy documenta auto-deploy mediante webhooks para GitHub, GitLab, Bitbucket y Gitea. Forgejo es compatible con el flujo de webhook de Gitea en muchos casos, pero conviene probarlo con un repositorio de prueba. La alternativa universal es llamar desde Forgejo Actions al webhook de despliegue de Dokploy o a su API.

El flujo recomendado es:

```text
push en Forgejo -> webhook de Forgejo -> Dokploy -> build/deploy Docker Compose
```

## Fuentes oficiales

- [Instalación](https://docs.dokploy.com/docs/core/installation)
- [Instalación manual](https://docs.dokploy.com/docs/core/manual-installation)
- [Actualización](https://docs.dokploy.com/docs/core/installation#manual-upgrade)
- [Auto-deploy](https://docs.dokploy.com/docs/core/auto-deploy)
- [Docker Compose en Dokploy](https://docs.dokploy.com/docs/core/docker-compose)
- [Desinstalación](https://docs.dokploy.com/docs/core/uninstall)
