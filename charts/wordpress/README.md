# wordpress

Helm chart for [WordPress](https://wordpress.org/) using the official `docker.io/wordpress` image.

Provides automation for WordPress installation, admin user creation, plugin installation, and Prometheus metrics via Apache exporter and the [SlyMetrics plugin](https://github.com/slydlake/slymetrics).

Optional subchart dependencies (all disabled by default): **MariaDB**, **Redis**, **Valkey**, **Memcached** — fetched from OCI registry on `helm dependency update`.

> **Attribution:** chart originally authored by [slydlake](https://github.com/slydlake/helm-charts). Rebased and maintained in this repository.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- Internet access from CI for OCI subchart dependencies (`registry-1.docker.io`)

## Fetching subchart dependencies

Before installing or packaging with subcharts enabled, run:

```bash
helm dependency update charts/wordpress
```

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-wp opentree/wordpress \
  --set wordpress.url=https://myblog.example.org \
  --set wordpress.admin.email=admin@example.org \
  --set wordpress.admin.password=changeme \
  --set mariadb.enabled=true \
  --namespace wordpress \
  --create-namespace
```

## Upgrading

```bash
helm upgrade my-wp opentree/wordpress --namespace wordpress
```

## Uninstalling

```bash
helm uninstall my-wp --namespace wordpress
```

## Required value

`wordpress.url` is required by the values schema (minLength=1). The chart will refuse to install without it.

## Configuration

See [`values.yaml`](./values.yaml) for the full annotated parameter list.

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `image.repository` | string | `wordpress` | Image repository |
| `image.tag` | string | `""` (appVersion) | Image tag |
| `wordpress.url` | string | `""` | **Required.** WordPress URL (WP_HOME / WP_SITEURL) |
| `wordpress.admin.user` | string | `admin` | Admin username |
| `wordpress.admin.password` | string | `""` | Admin password |
| `wordpress.admin.email` | string | `""` | Admin email |
| `mariadb.enabled` | bool | `false` | Deploy MariaDB subchart |
| `redis.enabled` | bool | `false` | Deploy Redis subchart |
| `valkey.enabled` | bool | `false` | Deploy Valkey subchart |
| `memcached.enabled` | bool | `false` | Deploy Memcached subchart |
| `persistence.enabled` | bool | `true` | Persist WordPress data |
| `service.type` | string | `ClusterIP` | Service type |
| `ingress.enabled` | bool | `false` | Enable Ingress |

## Testing

```bash
helm dependency update charts/wordpress   # fetch OCI subcharts
helm lint charts/wordpress --set wordpress.url=https://example.org
helm template my-wp charts/wordpress --set wordpress.url=https://example.org
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/wordpress
```

## Sources

- Docker image: [docker-library/wordpress](https://github.com/docker-library/wordpress)
- Original chart: [slydlake/helm-charts](https://github.com/slydlake/helm-charts/tree/main/charts/wordpress)
- SlyMetrics plugin: [slydlake/slymetrics](https://github.com/slydlake/slymetrics)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
