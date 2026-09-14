# wg-easy

Helm chart for [wg-easy](https://github.com/wg-easy/wg-easy) — a WireGuard VPN server with an integrated web UI.

Uses the official `ghcr.io/wg-easy/wg-easy` image. Supports Init Mode for unattended setup and almost any wg-easy environment variable.

> **Attribution:** chart originally authored by [slydlake](https://github.com/slydlake/helm-charts). Rebased and maintained in this repository.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- `NET_ADMIN` capability available on the node (required by WireGuard)
- UDP port reachable from the internet (default 51820)

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-wg opentree/wg-easy \
  --set config.init.host=vpn.example.org \
  --namespace wg-easy \
  --create-namespace
```

## Upgrading

```bash
helm upgrade my-wg opentree/wg-easy --namespace wg-easy
```

## Uninstalling

```bash
helm uninstall my-wg --namespace wg-easy
```

## Configuration

See [`values.yaml`](./values.yaml) for the full list of parameters.

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `image.repository` | string | `ghcr.io/wg-easy/wg-easy` | Image repository |
| `image.tag` | string | `""` (appVersion) | Image tag |
| `image.pullPolicy` | string | `IfNotPresent` | Pull policy |
| `config.init.enabled` | bool | `true` | Enable unattended setup |
| `config.init.host` | string | `vpn.example.com` | Host clients connect to |
| `config.init.existingSecret` | string | `""` | Existing secret with `username`/`password` keys |
| `config.init.dns` | string | `1.1.1.1,8.8.8.8` | DNS for WireGuard clients |
| `config.init.ipv4_cidr` | string | `10.8.0.0/24` | IPv4 CIDR for WireGuard |
| `persistence.enabled` | bool | `true` | Persist WireGuard config |
| `persistence.size` | string | `100Mi` | PVC size |
| `serviceAccount.create` | bool | `true` | Create a ServiceAccount |

## Testing

```bash
helm lint charts/wg-easy
helm template my-wg charts/wg-easy
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/wg-easy
```

## Sources

- Docker image: [wg-easy/wg-easy](https://github.com/wg-easy/wg-easy)
- Original chart: [slydlake/helm-charts](https://github.com/slydlake/helm-charts/tree/main/charts/wg-easy)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
