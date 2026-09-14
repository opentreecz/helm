# minecraft-proxy

Helm chart for a Minecraft proxy server using the official
[itzg/bungeecord](https://github.com/itzg/docker-bungeecord) image.

Supports **BungeeCord**, **Waterfall**, **Velocity**, and other proxy types.
Use this chart to route players across multiple backend Minecraft servers.

> **Attribution:** chart originally from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts). Upgraded to apiVersion v2 and maintained in this repository.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-proxy opentree/minecraft-proxy \
  --set minecraftProxy.type=VELOCITY \
  --namespace minecraft-proxy \
  --create-namespace
```

## Upgrading

```bash
helm upgrade my-proxy opentree/minecraft-proxy --namespace minecraft-proxy
```

## Uninstalling

```bash
helm uninstall my-proxy --namespace minecraft-proxy
```

## Configuration

See [`values.yaml`](./values.yaml) for the full parameter list.

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `image.repository` | string | `itzg/bungeecord` | Image repository |
| `minecraftProxy.type` | string | `BUNGEECORD` | Proxy type (BUNGEECORD, WATERFALL, VELOCITY, etc.) |
| `minecraftProxy.serviceType` | string | `ClusterIP` | Service type |
| `minecraftProxy.servicePort` | int | `25565` | Proxy listen port |
| `persistence.dataDir.enabled` | bool | `false` | Persist proxy config |

## Testing

```bash
helm lint charts/minecraft-proxy
helm template my-proxy charts/minecraft-proxy
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/minecraft-proxy
```

## Sources

- Docker image: [itzg/docker-bungeecord](https://github.com/itzg/docker-bungeecord)
- Original chart: [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
