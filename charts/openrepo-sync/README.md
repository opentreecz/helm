# openrepo-sync

Helm chart for [openrepo-sync](https://github.com/opentreecz/openrepo-sync).
It keeps an [OpenRepo](https://github.com/opentreecz/openrepo) server up to date
with packages from upstream sources: GitHub Releases, APT and RPM repositories,
direct URLs and SourceForge.

openrepo-sync is a client only. It exposes no ports and keeps no state, and
talks to the OpenRepo REST API. Deploy OpenRepo itself with the
[openrepo](../openrepo) chart.

## Modes

| `mode` | Workload | How it runs |
| ------ | -------- | ----------- |
| `schedule` (default) | Deployment (1 replica) | Built-in scheduler (`--schedule`). It syncs every `config.schedule.interval` and also on start when `run_on_start: true`. |
| `cronjob` | CronJob | One-shot sync on `cronjob.schedule`. The Job fails when any project fails. |

## Installing the Chart

1. Create an API token in the OpenRepo web UI (user profile).
2. Write a values file with your projects:

```yaml
# my-values.yaml
openrepo:
  # In-cluster OpenRepo installed with the openrepo chart:
  apiUrl: http://openrepo.openrepo.svc.cluster.local
  existingSecret: openrepo-sync-token   # or apiKey: <token>

config:
  arch_filter: [amd64, arm64]
  schedule:
    interval: 12h

projects:
  github-cli:
    name: github-cli
    repo_uid: deb
    keep_versions: 3
    on_conflict: skip
    source:
      type: deb_repo
      url: https://cli.github.com/packages
      suites: stable
      components: main
      package_filter: gh
      verify_gpg: true
      gpg_key: https://cli.github.com/packages/githubcli-archive-keyring.gpg
```

```bash
kubectl -n openrepo create secret generic openrepo-sync-token --from-literal=api-key=<token>

helm repo add opentree https://opentreecz.github.io/helm
helm repo update
helm install openrepo-sync opentree/openrepo-sync -n openrepo -f my-values.yaml
```

The project file format (`github`, `deb_repo`, `rpm_repo`, `direct_url`,
`direct_url_latest`, `sourceforge`) is documented in the upstream
[docs/sources.md](https://github.com/opentreecz/openrepo-sync/blob/main/docs/sources.md).
The upstream [`projects/`](https://github.com/opentreecz/openrepo-sync/tree/main/projects)
directory has ready-made examples.

### Managing many projects

You can keep project files outside Helm values. Put them in a ConfigMap and
point the chart at it:

```bash
kubectl -n openrepo create configmap openrepo-sync-projects --from-file=projects/
helm upgrade --install openrepo-sync opentree/openrepo-sync -n openrepo \
  --set existingProjectsConfigMap=openrepo-sync-projects ...
```

### GitHub rate limits

To pass a GitHub token, use `extraEnv`:

```yaml
extraEnv:
  - name: GITHUB_TOKEN
    valueFrom:
      secretKeyRef:
        name: github-token
        key: token
```

## Operations

```bash
# Follow logs (schedule mode)
kubectl -n openrepo logs -f deploy/openrepo-sync

# Dry run now (schedule mode)
kubectl -n openrepo exec deploy/openrepo-sync -- \
  openrepo-sync --config /config/config.yaml --projects /projects --dry-run

# Run now (cronjob mode)
kubectl -n openrepo create job --from=cronjob/openrepo-sync openrepo-sync-manual
```

The pod restarts automatically when `config`, `projects` or the API key change.

## Uninstalling the Chart

```bash
helm uninstall openrepo-sync -n openrepo
```

## Configuration

See [`values.yaml`](./values.yaml) for the full list.

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `image.repository` | Image repository | `ghcr.io/opentreecz/openrepo-sync` |
| `image.tag` | Image tag | `""` (`v` + appVersion) |
| `mode` | `schedule` or `cronjob` | `schedule` |
| `cronjob.schedule` | Cron expression (cronjob mode) | `0 3 * * *` |
| `cronjob.timeZone` | CronJob time zone | `""` |
| `openrepo.apiUrl` | OpenRepo base URL (no trailing slash) | `https://openrepo.example.com` |
| `openrepo.apiKey` | API token (chart creates a Secret) | `""` |
| `openrepo.existingSecret` | Existing Secret with the token | `""` |
| `openrepo.existingSecretKey` | Key inside the Secret | `api-key` |
| `config` | Global `config.yaml` (except `openrepo:`) | see values |
| `config.arch_filter` | Architecture preference | `amd64` |
| `config.schedule.interval` | Sync interval (schedule mode) | `24h` |
| `config.cleanup.server` | Server-side cleanup: `off`, `report`, `apply` | `off` |
| `existingConfigConfigMap` | Existing ConfigMap with `config.yaml` | `""` |
| `projects` | Map of project name → project definition | `{}` |
| `existingProjectsConfigMap` | Existing ConfigMap with project `*.yaml` files | `""` |
| `extraArgs` | Extra CLI args (e.g. `--dry-run`, `--verbose`) | `[]` |
| `logLevel` | `RUST_LOG` filter | `info` |
| `timezone` | `TZ` for log timestamps | `UTC` |
| `downloadVolume.sizeLimit` | Scratch space for downloads (`/tmp`) | `10Gi` |
| `extraEnv` / `extraEnvFrom` | Extra environment | `[]` |
| `resources` | CPU/memory requests/limits | `{}` |

The container runs as non-root (uid 1000) with a read-only root filesystem.
`/tmp` (downloads) and `/home/openrepo` (GnuPG home) are `emptyDir` volumes.
