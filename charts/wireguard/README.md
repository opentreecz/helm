# wireguard

Helm chart for [WireGuard](https://www.wireguard.com/) using the official
[linuxserver/wireguard](https://github.com/linuxserver/docker-wireguard) image.

Supports both **server mode** (full VPN endpoint) and **client mode** (peer connection). Exposes almost any linuxserver environment variable as a Helm value.

> **Attribution:** chart originally authored by [slydlake](https://github.com/slydlake/helm-charts). Rebased and maintained in this repository.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- `NET_ADMIN` + `SYS_MODULE` capabilities (or kernel modules loaded on host)
- UDP port reachable from the internet for server mode (default 51820)

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-wireguard opentree/wireguard \
  --set wireguard.server.enabled=true \
  --set wireguard.server.storage.storageClass=standard \
  --namespace wireguard \
  --create-namespace
```

## Upgrading

```bash
helm upgrade my-wireguard opentree/wireguard --namespace wireguard
```

## Uninstalling

```bash
helm uninstall my-wireguard --namespace wireguard
```

## Configuration

See [`values.yaml`](./values.yaml) for the full annotated parameter list.

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `image.repository` | string | `linuxserver/wireguard` | Image repository |
| `image.tag` | string | pinned digest | Image tag (SHA-pinned for reproducibility) |
| `wireguard.server.enabled` | bool | `false` | Enable server mode |
| `wireguard.server.storage.storageClass` | string | `""` | StorageClass for config PVC |
| `wireguard.server.storage.size` | string | `100Mi` | PVC size |
| `wireguard.client.enabled` | bool | `false` | Enable client mode |
| `service.type` | string | `NodePort` | Service type |
| `service.port` | int | `51820` | WireGuard UDP port |
| `serviceAccount.create` | bool | `true` | Create a ServiceAccount |
| `autoscaling.enabled` | bool | `false` | Enable HPA |

## Testing

```bash
helm lint charts/wireguard
helm template my-wireguard charts/wireguard
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/wireguard
```

## Sources

- Docker image: [linuxserver/docker-wireguard](https://github.com/linuxserver/docker-wireguard)
- Original chart: [slydlake/helm-charts](https://github.com/slydlake/helm-charts/tree/main/charts/wireguard)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
