# mc-router

Helm chart for [mc-router](https://github.com/itzg/mc-router) — a Minecraft Java Edition connection router that forwards client connections to backend servers based on the requested hostname.

Uses the official `itzg/mc-router` image. Supports SNI-based routing, auto-scaling, and the mc-router REST API.

> **Attribution:** chart originally from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts). Upgraded to apiVersion v2 and maintained in this repository.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-mc-router opentree/mc-router \
  --namespace mc-router \
  --create-namespace
```

## Upgrading

```bash
helm upgrade my-mc-router opentree/mc-router --namespace mc-router
```

## Uninstalling

```bash
helm uninstall my-mc-router --namespace mc-router
```

## Configuration

See [`values.yaml`](./values.yaml) for the full parameter list.

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `image.repository` | string | `itzg/mc-router` | Image repository |
| `image.tag` | string | `latest` | Image tag |
| `services.minecraft.type` | string | `NodePort` | Service type for Minecraft connections |
| `services.minecraft.port` | int | `25565` | Minecraft service port |
| `serviceAccount.create` | bool | `true` | Create a ServiceAccount |
| `autoscaling.enabled` | bool | `false` | Enable HPA |

## Testing

```bash
helm lint charts/mc-router
helm template my-mc-router charts/mc-router
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/mc-router
```

## Sources

- Docker image: [itzg/mc-router](https://github.com/itzg/mc-router)
- Original chart: [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
