# example-app

A starter Helm chart for deploying a generic web application on Kubernetes.

Use this chart as a **template and reference** when creating new charts in
this repository. It demonstrates the repository conventions for labels,
helpers, security context, ingress, HPA, and unit tests.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-release opentree/example-app
```

To install into a specific namespace:

```bash
helm install my-release opentree/example-app \
  --namespace my-namespace \
  --create-namespace
```

## Upgrading

```bash
helm upgrade my-release opentree/example-app
```

## Uninstalling

```bash
helm uninstall my-release
```

## Configuration

All parameters are listed below. Override them with `--set` or a values file:

```bash
helm install my-release opentree/example-app \
  --set replicaCount=2 \
  --set image.repository=myapp \
  --set image.tag=1.2.3
```

Or with a file:

```bash
helm install my-release opentree/example-app -f my-values.yaml
```

### Values reference

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `replicaCount` | int | `1` | Number of pod replicas |
| `image.repository` | string | `nginx` | Container image repository |
| `image.tag` | string | `""` | Image tag; defaults to the chart `appVersion` |
| `image.pullPolicy` | string | `IfNotPresent` | Image pull policy |
| `imagePullSecrets` | list | `[]` | List of image pull secret names |
| `nameOverride` | string | `""` | Override the chart name used in labels |
| `fullnameOverride` | string | `""` | Override the fully-qualified app name |
| `serviceAccount.create` | bool | `true` | Create a dedicated ServiceAccount |
| `serviceAccount.annotations` | object | `{}` | Annotations to add to the ServiceAccount |
| `serviceAccount.name` | string | `""` | ServiceAccount name; auto-generated if empty |
| `podAnnotations` | object | `{}` | Extra annotations on the pod template |
| `podLabels` | object | `{}` | Extra labels on the pod template |
| `podSecurityContext` | object | `{}` | Pod-level security context (`fsGroup`, etc.) |
| `securityContext` | object | `{}` | Container-level security context (`runAsUser`, `readOnlyRootFilesystem`, etc.) |
| `service.type` | string | `ClusterIP` | Kubernetes Service type |
| `service.port` | int | `80` | Service port |
| `ingress.enabled` | bool | `false` | Enable an Ingress resource |
| `ingress.className` | string | `""` | Ingress class name |
| `ingress.annotations` | object | `{}` | Ingress annotations |
| `ingress.hosts` | list | `[{host: chart-example.local, paths: [{path: /, pathType: ImplementationSpecific}]}]` | Ingress host rules |
| `ingress.tls` | list | `[]` | Ingress TLS configuration |
| `resources` | object | `{}` | CPU/memory requests and limits |
| `livenessProbe` | object | `httpGet path=/ port=http` | Liveness probe definition |
| `readinessProbe` | object | `httpGet path=/ port=http` | Readiness probe definition |
| `autoscaling.enabled` | bool | `false` | Enable HorizontalPodAutoscaler |
| `autoscaling.minReplicas` | int | `1` | Minimum replicas for HPA |
| `autoscaling.maxReplicas` | int | `10` | Maximum replicas for HPA |
| `autoscaling.targetCPUUtilizationPercentage` | int | `80` | Target CPU utilisation for HPA |
| `volumes` | list | `[]` | Extra volumes to add to the pod |
| `volumeMounts` | list | `[]` | Extra volume mounts to add to the container |
| `nodeSelector` | object | `{}` | Node selector constraints |
| `tolerations` | list | `[]` | Tolerations |
| `affinity` | object | `{}` | Affinity rules |

## Testing

```bash
# Lint and render
helm lint charts/example-app
helm template my-release charts/example-app

# Unit tests (requires helm-unittest plugin — Helm >= 3.18)
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/example-app

# Full chart-testing install into a kind cluster
kind create cluster
ct install --config ct.yaml
```

Unit test suites live in [`tests/`](./tests) and run automatically in CI on
every PR and push to `main`.

## Source

- Chart: [opentreecz/helm](https://github.com/opentreecz/helm)
