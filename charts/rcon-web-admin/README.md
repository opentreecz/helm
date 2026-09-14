# rcon-web-admin

Helm chart for [rcon-web-admin](https://github.com/rcon-web-admin/rcon-web-admin) — a web-based admin panel for game servers that support the RCON protocol (Minecraft, etc.).

Uses the official `itzg/rcon-web-admin` image.

> **Attribution:** chart originally from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts). Maintained in this repository.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- A game server with RCON enabled (e.g. the `minecraft` chart in this repo)

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-rcon opentree/rcon-web-admin \
  --set rconWeb.password=changeme \
  --namespace rcon-web-admin \
  --create-namespace
```

## Upgrading

```bash
helm upgrade my-rcon opentree/rcon-web-admin --namespace rcon-web-admin
```

## Uninstalling

```bash
helm uninstall my-rcon --namespace rcon-web-admin
```

## Configuration

See [`values.yaml`](./values.yaml) for the full parameter list.

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `image.repository` | string | `docker.io/itzg/rcon` | Image repository |
| `image.tag` | string | `""` (appVersion) | Image tag |
| `rconWeb.password` | string | `""` | rcon-web-admin admin password |
| `rconWeb.rconHost` | string | `""` | RCON server hostname |
| `rconWeb.rconPort` | int | `25575` | RCON port |
| `service.type` | string | `ClusterIP` | HTTP service type |
| `ingress.enabled` | bool | `false` | Enable Ingress |

## Testing

```bash
helm lint charts/rcon-web-admin
helm template my-rcon charts/rcon-web-admin
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/rcon-web-admin
```

## Sources

- Docker image: [itzg/rcon-web-admin](https://hub.docker.com/r/itzg/rcon)
- Original chart: [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
