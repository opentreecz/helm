# minecraft

Helm chart for a Minecraft Java Edition server using the official
[itzg/minecraft-server](https://github.com/itzg/docker-minecraft-server) image.

Supports hundreds of server types (Vanilla, Paper, Forge, Fabric, Spigot, etc.),
automatic downloads, mod/plugin management, backup via rclone, and RCON access.

> **Important:** You must accept the Minecraft EULA by setting `minecraftServer.eula: "TRUE"`.

> **Attribution:** chart originally from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts). Upgraded to apiVersion v2 and maintained in this repository.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- Persistent storage for the Minecraft world data

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-minecraft opentree/minecraft \
  --set minecraftServer.eula=TRUE \
  --set minecraftServer.type=PAPER \
  --namespace minecraft \
  --create-namespace
```

## Upgrading

```bash
helm upgrade my-minecraft opentree/minecraft --namespace minecraft
```

## Uninstalling

```bash
helm uninstall my-minecraft --namespace minecraft
```

## EULA requirement

Mojang requires acceptance of the [Minecraft End User License Agreement](https://www.minecraft.net/en-us/eula). Set `minecraftServer.eula: "TRUE"` to accept it. The server will not start otherwise.

## Configuration

See [`values.yaml`](./values.yaml) for the full parameter list (200+ options).

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `minecraftServer.eula` | string | `"FALSE"` | **Must be `"TRUE"`** to accept the Minecraft EULA |
| `minecraftServer.type` | string | `VANILLA` | Server type (VANILLA, PAPER, FORGE, FABRIC, etc.) |
| `minecraftServer.version` | string | `LATEST` | Minecraft version |
| `minecraftServer.serviceType` | string | `ClusterIP` | Service type |
| `minecraftServer.servicePort` | int | `25565` | Service port |
| `minecraftServer.memory` | string | `1024M` | JVM memory (`-Xmx`) |
| `workloadAsStatefulSet` | bool | `false` | Use StatefulSet instead of Deployment |
| `persistence.dataDir.enabled` | bool | `true` | Persist the world data directory |
| `persistence.dataDir.Size` | string | `1Gi` | PVC size |

## Testing

```bash
helm lint charts/minecraft --set minecraftServer.eula=TRUE
helm template my-minecraft charts/minecraft --set minecraftServer.eula=TRUE
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/minecraft
```

## Sources

- Docker image: [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)
- Original chart: [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
