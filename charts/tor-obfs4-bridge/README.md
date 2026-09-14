# tor-obfs4-bridge Helm chart

Helm chart for running a [Tor](https://www.torproject.org/) bridge with the
[obfs4](https://gitlab.com/yawning/obfs4) pluggable transport on Kubernetes.

Bridges help censored users reach the Tor network by disguising traffic.
This chart deploys a **StatefulSet** (for stable identity and persistent storage),
a **LoadBalancer Service** (two TCP ports), and a **ServiceAccount**, with
security hardening baked in by default.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- A LoadBalancer-capable cluster (or use `service.type=NodePort`)
- Two inbound TCP ports reachable from the internet (`orPort` and `ptPort`)

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-bridge opentree/tor-obfs4-bridge \
  --set config.email=you@example.org \
  --namespace tor \
  --create-namespace
```

## Getting the bridge line

After the pod has bootstrapped (~2 minutes):

```bash
kubectl exec -n tor my-bridge-tor-obfs4-bridge-0 -- get-bridge-line
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `image.repository` | string | `ghcr.io/zetneteork/docker-tor-obfs4-bridge` | Container image repository |
| `image.tag` | string | `""` (chart appVersion) | Image tag override |
| `image.pullPolicy` | string | `Always` | Image pull policy |
| `config.orPort` | int | `2123` | OR port (must be open inbound) |
| `config.ptPort` | int | `2133` | obfs4 PT port (must be open inbound) |
| `config.email` | string | `""` | Operator contact e-mail (**required**) |
| `config.ipv4Only` | string | `"1"` | `"1"` = IPv4 only, `"0"` = dual-stack |
| `config.exitRelay` | string | `"0"` | `"1"` to enable exit relay mode |
| `config.bridgeRelay` | string | `"1"` | `"1"` to enable bridge relay mode |
| `persistence.enabled` | bool | `true` | Enable persistent storage for `/var/lib/tor` |
| `persistence.size` | string | `2Gi` | PVC size |
| `persistence.storageClass` | string | `""` | StorageClass (blank = cluster default) |
| `persistence.existingClaim` | string | `""` | Use an existing PVC |
| `service.type` | string | `LoadBalancer` | Kubernetes Service type |
| `service.externalTrafficPolicy` | string | `Local` | Preserve source IP |
| `service.annotations` | object | `{}` | Extra Service annotations |
| `resources.requests.cpu` | string | `50m` | CPU request |
| `resources.requests.memory` | string | `64Mi` | Memory request |
| `resources.limits.cpu` | string | `500m` | CPU limit |
| `resources.limits.memory` | string | `256Mi` | Memory limit |
| `podSecurityContext.runAsUser` | int | `101` | debian-tor uid |
| `serviceAccount.create` | bool | `true` | Create a ServiceAccount |
| `replicaCount` | int | `1` | Must stay 1 – see statefulset notes |

## Source

- Docker image: [zetneteork/docker-tor-obfs4-bridge](https://github.com/zetneteork/docker-tor-obfs4-bridge)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
