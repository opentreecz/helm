# example-app

A starter Helm chart for deploying a generic web application on Kubernetes.

Use this chart as a template for creating new charts in this repository.

## Installing the Chart

Add the repository (see the [repository README](../../README.md) for the
published URL), then install:

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update
helm install my-release opentree/example-app
```

## Uninstalling the Chart

```bash
helm uninstall my-release
```

## Configuration

The following table lists the most commonly used configurable parameters.
See [`values.yaml`](./values.yaml) for the full list.

| Parameter            | Description                          | Default        |
| -------------------- | ------------------------------------ | -------------- |
| `replicaCount`       | Number of replicas                   | `1`            |
| `image.repository`   | Container image repository           | `nginx`        |
| `image.tag`          | Container image tag                  | `""` (appVersion) |
| `image.pullPolicy`   | Image pull policy                    | `IfNotPresent` |
| `service.type`       | Kubernetes Service type              | `ClusterIP`    |
| `service.port`       | Service port                         | `80`           |
| `ingress.enabled`    | Enable ingress                       | `false`        |
| `resources`          | CPU/memory resource requests/limits  | `{}`           |
| `autoscaling.enabled`| Enable HorizontalPodAutoscaler       | `false`        |

Override values with `--set` or a custom values file:

```bash
helm install my-release opentree/example-app -f my-values.yaml
```

## Testing

```bash
# Static checks
helm lint charts/example-app
helm template charts/example-app

# Unit tests (requires the helm-unittest plugin)
helm plugin install https://github.com/helm-unittest/helm-unittest
helm unittest charts/example-app

# Smoke test a live release
helm test my-release
```

Unit test suites live in [`tests/`](./tests) and are run automatically in CI.
