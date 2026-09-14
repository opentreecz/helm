# minecraft-bedrock

Helm chart for a Minecraft Bedrock Edition server using the official
[itzg/minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server) image.

Supports automatic game updates, cross-platform play (Windows, iOS, Android, console), and persistent world data.

> **Important:** You must accept the Minecraft EULA by setting `minecraftServer.eula: "TRUE"`.

> **Attribution:** chart originally from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts). Upgraded to apiVersion v2 and maintained in this repository.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- Persistent storage for world data

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-mcbe opentree/minecraft-bedrock \
  --set minecraftServer.eula=TRUE \
  --namespace minecraft-bedrock \
  --create-namespace
```

## Upgrading

```bash
helm upgrade my-mcbe opentree/minecraft-bedrock --namespace minecraft-bedrock
```

## Uninstalling

```bash
helm uninstall my-mcbe --namespace minecraft-bedrock
```

## Configuration

See [`values.yaml`](./values.yaml) for the full parameter list.

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `minecraftServer.eula` | string | `"FALSE"` | **Must be `"TRUE"`** to accept the EULA |
| `minecraftServer.version` | string | `LATEST` | Bedrock server version |
| `minecraftServer.difficulty` | string | `easy` | Difficulty level |
| `minecraftServer.serviceType` | string | `ClusterIP` | Service type |
| `workloadAsStatefulSet` | bool | `false` | Use StatefulSet instead of Deployment |
| `persistence.dataDir.enabled` | bool | `true` | Persist world data |
| `persistence.dataDir.Size` | string | `1Gi` | PVC size |

## Testing

```bash
helm lint charts/minecraft-bedrock
helm template my-mcbe charts/minecraft-bedrock
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/minecraft-bedrock
```

## Sources

- Docker image: [itzg/docker-minecraft-bedrock-server](https://github.com/itzg/docker-minecraft-bedrock-server)
- Original chart: [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
