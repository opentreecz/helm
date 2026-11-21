# openrepo

Helm chart for [OpenRepo](https://github.com/opentreecz/openrepo), a self-hosted
package repository server for APT (`.deb`), RPM, Alpine APK and generic files.
It includes a web UI, a REST API, PGP signing and retention policies.

## Architecture

All OpenRepo containers use the same image (`ghcr.io/opentreecz/openrepo`):

| Workload | Containers | Purpose |
| -------- | ---------- | ------- |
| Deployment `<release>-openrepo` | `nginx` (8080), `django` (8000), `worker` | Web UI, repo file serving, REST API, Celery worker |
| Deployment `<release>-openrepo-beat` | `beat` | Celery beat periodic scheduler (single instance) |
| StatefulSet `<release>-openrepo-postgresql` | `postgresql` | Built-in PostgreSQL 16 (optional) |
| Deployment `<release>-openrepo-redis` | `redis` | Built-in Redis 7 Celery broker (optional) |

nginx, django and the worker all read and write `/var/lib/openrepo`
(packages, repo metadata, GPG keyrings). They run in **one pod** so a regular
`ReadWriteOnce` volume works. The pod is replaced with the `Recreate`
strategy, so expect a short outage during upgrades.

Database migrations run automatically when the `django` container starts.

## Installing the Chart

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update
helm install openrepo opentree/openrepo \
  --namespace openrepo --create-namespace \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=repo.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix \
  --set superuser.create=true
```

Read the generated admin password:

```bash
kubectl -n openrepo get secret openrepo -o jsonpath='{.data.superuser-password}' | base64 -d; echo
```

Or create a user interactively:

```bash
kubectl -n openrepo exec -it deploy/openrepo -c django -- /app/django/manage.py createsuperuser
```

### Ingress and large uploads

Packages can be large. Raise the body size limit on your ingress controller
to match `openrepo.maxUploadSize`. For ingress-nginx:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "2048m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
```

### Host names

Django only accepts requests for known host names. The chart sets them
automatically:

- `OPENREPO_DOMAIN` is set to `openrepo.domain`. If that is empty, it uses the
  first ingress host, or `localhost:8080` when there is no ingress.
- `ALLOWED_HOSTS` always includes the in-cluster Service names
  (`<svc>`, `<svc>.<ns>`, `<svc>.<ns>.svc` and `<svc>.<ns>.svc.cluster.local`).
  It also includes every ingress host and anything in `openrepo.allowedHosts`.
  Other workloads in the cluster, such as
  [openrepo-sync](../openrepo-sync), can therefore call
  `http://<svc>.<ns>.svc.cluster.local` directly.
- `CSRF_TRUSTED_ORIGINS` defaults to the ingress hosts. Hosts listed under
  `ingress.tls` use `https`, and all others use `http`.

### Secrets

The chart generates the Django secret key, the PostgreSQL password and the
optional superuser password when you do not provide them. It stores them in the
`<release>-openrepo` Secret and keeps them across upgrades (via `lookup`).

> **Note:** the PostgreSQL password is only applied when the database is first
> initialised. Changing `postgresql.auth.password` later does not change it
> inside an existing database.

### External PostgreSQL / Redis

```yaml
postgresql:
  enabled: false
externalDatabase:
  host: postgres.db.svc
  database: openrepo
  username: openrepo
  existingSecret: openrepo-db        # key: password
redis:
  enabled: false
externalRedis:
  existingSecret: openrepo-redis     # key: redis-url, e.g. redis://:pass@redis:6379/0
```

## Uninstalling the Chart

```bash
helm uninstall openrepo -n openrepo
```

The data PVC (`<release>-openrepo-data`) is annotated with
`helm.sh/resource-policy: keep`, and the PostgreSQL StatefulSet PVC is not
removed either. Delete them manually if you no longer need the data.

## Configuration

See [`values.yaml`](./values.yaml) for the full list.

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `image.repository` | OpenRepo image | `ghcr.io/opentreecz/openrepo` |
| `image.tag` | Image tag | `""` (appVersion) |
| `openrepo.domain` | Public host name | `""` (first ingress host) |
| `openrepo.allowedHosts` | Extra Django `ALLOWED_HOSTS` | `[]` |
| `openrepo.csrfTrustedOrigins` | CSRF trusted origins | `[]` (derived from ingress) |
| `openrepo.secretKey` | Django secret key | `""` (generated) |
| `openrepo.existingSecret` | Existing Secret with the secret key | `""` |
| `openrepo.debug` | Django debug mode | `false` |
| `openrepo.logLevel` | Log level | `INFO` |
| `openrepo.maxUploadSize` | Max upload size in bytes (also nginx limit) | `2147483648` |
| `openrepo.env` | Extra `OPENREPO_*` settings (map) | `{}` |
| `openrepo.extraEnv` | Extra raw env entries | `[]` |
| `superuser.create` | Create a Django superuser (post-install hook) | `false` |
| `superuser.username` / `superuser.email` | Superuser identity | `admin` / `admin@example.com` |
| `superuser.password` | Superuser password | `""` (generated) |
| `worker.concurrency` | Celery worker concurrency | `4` |
| `beat.enabled` | Run Celery beat | `true` |
| `nginx.resources`, `django.resources`, `worker.resources`, `beat.resources` | Container resources | `{}` |
| `persistence.enabled` | Persist `/var/lib/openrepo` | `true` |
| `persistence.size` | Data volume size | `20Gi` |
| `persistence.storageClass` | Storage class (`-` for none) | `""` |
| `persistence.existingClaim` | Use an existing PVC | `""` |
| `service.type` / `service.port` | Service type / port | `ClusterIP` / `80` |
| `ingress.enabled` | Enable ingress | `false` |
| `postgresql.enabled` | Deploy built-in PostgreSQL | `true` |
| `postgresql.auth.username` / `database` | Database user / name | `openrepo` / `openrepo` |
| `postgresql.auth.password` | Database password | `""` (generated) |
| `postgresql.persistence.size` | Database volume size | `8Gi` |
| `externalDatabase.*` | External PostgreSQL connection | see values |
| `redis.enabled` | Deploy built-in Redis | `true` |
| `externalRedis.url` / `externalRedis.existingSecret` | External Redis URL | `""` |

The `OPENREPO_*` settings are documented in the upstream
[`.env.example`](https://github.com/opentreecz/openrepo/blob/main/.env.example).
Set them with `openrepo.env`, for example:

```yaml
openrepo:
  env:
    OPENREPO_CLEANUP_INTERVAL: "86400"
    OPENREPO_CLEANUP_GRACE_HOURS: "24"
```
