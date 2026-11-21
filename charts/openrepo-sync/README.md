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
2. Write a values file. The [bundled projects](#bundled-projects) are synced
   by default; add your own under `projects:`.

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

## Bundled projects

The chart ships the 51 project definitions from the upstream
[`projects/`](https://github.com/opentreecz/openrepo-sync/tree/main/projects)
directory in [`projects/`](./projects). They are **enabled by default** and
all target the OpenRepo repository `deb`, so create that repo (type `deb`) in
OpenRepo first, or retarget everything with `bundledProjects.repoUid`.

```yaml
bundledProjects:
  enabled: true
  repoUid: apt                 # override repo_uid for all bundled projects
  exclude:                     # file key or project name
    - minecraft-launcher
    - spotify-client

projects:
  docker-ce: null              # remove a bundled project
  github-cli:                  # replace a bundled project
    name: github-cli
    repo_uid: tools
    source:
      type: deb_repo
      url: https://cli.github.com/packages
      suites: stable
      components: main
      package_filter: gh
```

Set `bundledProjects.enabled: false` to sync only the entries under `projects:`.
`helm install --dry-run` prints the final project list in the release notes.

> `rp-bookshelf` (archive.raspberrypi.org) is reachable over IPv6 only; it
> fails on clusters without IPv6 egress. Exclude it there.

<details>
<summary>List of bundled projects</summary>

| File key | Project name | Source type |
| -------- | ------------ | ----------- |
| `appimagelauncher` | `appimagelauncher` | `github` |
| `balena-etcher` | `balena-etcher` | `github` |
| `bluemail` | `bluemail` | `deb_repo` |
| `chrome-remote-desktop` | `chrome-remote-desktop` | `deb_repo` |
| `claude` | `claude-desktop` | `deb_repo` |
| `cursor` | `cursor` | `direct_url_latest` |
| `datovka` | `datovka` | `deb_repo` |
| `deb-multimedia-keyring` | `deb-multimedia-keyring` | `direct_url` |
| `devin-desktop` | `devin-desktop` | `deb_repo` |
| `discord-direct-url-latest` | `discord` | `direct_url_latest` |
| `docker-ce` | `docker-ce` | `deb_repo` |
| `drawio` | `drawio` | `github` |
| `duplicati` | `duplicati` | `github` |
| `element-desktop` | `element-desktop` | `deb_repo` |
| `eobcanka` | `eobcanka` | `direct_url_latest` |
| `flexibee-client-direct-url-latest` | `flexibee-client` | `direct_url_latest` |
| `flexibee-server-direct-url-latest` | `flexibee` | `direct_url_latest` |
| `github-cli` | `github-cli` | `deb_repo` |
| `google-chrome-stable` | `google-chrome-stable` | `direct_url_latest` |
| `google-earth-ec` | `google-earth-ec` | `deb_repo` |
| `google-earth-pro` | `google-earth-pro` | `deb_repo` |
| `helm` | `helm` | `deb_repo` |
| `infra` | `infra` | `direct_url_latest` |
| `insync` | `insync` | `deb_repo` |
| `kubectl` | `kubectl` | `deb_repo` |
| `lens` | `lens` | `deb_repo` |
| `lexmark-aey-ppd-files` | `lexmark-aey-ppd-files` | `deb_repo` |
| `microsoft-edge-stable` | `microsoft-edge-stable` | `deb_repo` |
| `minecraft-launcher` | `minecraft-launcher` | `direct_url_latest` |
| `minikube-direct-url-latest` | `minikube` | `direct_url_latest` |
| `obsidian` | `obsidian` | `github` |
| `opencode-desktop-direct-url-latest` | `opencode-desktop` | `direct_url_latest` |
| `orca-ide` | `orca-ide` | `github` |
| `parsec` | `parsec` | `direct_url_latest` |
| `rambox-github` | `rambox` | `github` |
| `rp-bookshelf` | `rp-bookshelf` | `deb_repo` |
| `rpi-imager` | `rpi-imager` | `github` |
| `rustdesk` | `rustdesk` | `github` |
| `signal-desktop` | `signal-desktop` | `deb_repo` |
| `slack-desktop` | `slack-desktop` | `deb_repo` |
| `spotify-client` | `spotify-client` | `deb_repo` |
| `temurin-17-jdk` | `temurin-17-jdk` | `deb_repo` |
| `temurin-17-jre` | `temurin-17-jre` | `deb_repo` |
| `temurin-18-jdk` | `temurin-18-jdk` | `deb_repo` |
| `temurin-18-jre` | `temurin-18-jre` | `deb_repo` |
| `temurin-21-jdk` | `temurin-21-jdk` | `deb_repo` |
| `temurin-21-jre` | `temurin-21-jre` | `deb_repo` |
| `terraform` | `terraform` | `deb_repo` |
| `vscode` | `code` | `direct_url_latest` |
| `vscodium` | `vscodium` | `github` |
| `winboat` | `winboat` | `github` |

</details>

To refresh the bundled files from upstream:

```bash
cp ../openrepo-sync/projects/*.yaml charts/openrepo-sync/projects/
```

### Managing many projects

You can keep project files outside Helm values. Put them in a ConfigMap and
point the chart at it. This replaces both the bundled projects and `projects:`:

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
| `bundledProjects.enabled` | Sync the projects bundled in the chart | `true` |
| `bundledProjects.exclude` | Bundled projects to skip (file key or name) | `[]` |
| `bundledProjects.repoUid` | Override `repo_uid` of all bundled projects | `""` |
| `projects` | Extra/overriding projects (key → definition, `null` removes) | `{}` |
| `existingProjectsConfigMap` | Existing ConfigMap with project `*.yaml` files | `""` |
| `extraArgs` | Extra CLI args (e.g. `--dry-run`, `--verbose`) | `[]` |
| `logLevel` | `RUST_LOG` filter | `info` |
| `timezone` | `TZ` for log timestamps | `UTC` |
| `downloadVolume.sizeLimit` | Scratch space for downloads (`/tmp`) | `10Gi` |
| `extraEnv` / `extraEnvFrom` | Extra environment | `[]` |
| `resources` | CPU/memory requests/limits | `{}` |

The container runs as non-root (uid 1000) with a read-only root filesystem.
`/tmp` (downloads) and `/home/openrepo` (GnuPG home) are `emptyDir` volumes.
