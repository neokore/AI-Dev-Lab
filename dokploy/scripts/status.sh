#!/usr/bin/env bash
set -euo pipefail

echo '--- Swarm services ---'
docker service ls --filter name=dokploy
printf '\n--- Containers ---\n'
docker ps -a --filter 'name=^dokploy(-traefik|-postgres|-redis)?$' --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
printf '\n--- Volumes ---\n'
docker volume ls --format '{{.Name}}' | grep -E '^dokploy(-postgres|-redis)?$' || true
