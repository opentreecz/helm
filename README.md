# opentree Helm Charts

[![Lint and Test Charts](https://github.com/opentreecz/helm/actions/workflows/lint-test.yaml/badge.svg)](https://github.com/opentreecz/helm/actions/workflows/lint-test.yaml)
[![Release Charts](https://github.com/opentreecz/helm/actions/workflows/release.yaml/badge.svg)](https://github.com/opentreecz/helm/actions/workflows/release.yaml)
[![Scheduled Build](https://github.com/opentreecz/helm/actions/workflows/build.yaml/badge.svg)](https://github.com/opentreecz/helm/actions/workflows/build.yaml)

A Kubernetes [Helm](https://helm.sh) chart repository maintained by
[opentreecz](https://github.com/opentreecz).

Charts are linted, unit-tested, and smoke-tested on every pull request, then
automatically packaged and published to GitHub Pages on merge to `main` using
[chart-releaser](https://github.com/helm/chart-releaser-action).

---

## Table of contents

- [Usage](#usage)
- [Available Charts](#available-charts)
- [Attribution](#attribution)
- [Repository Layout](#repository-layout)
- [Automation](#automation)
- [Versioning](#versioning-auto-bump)
- [Developing Charts](#developing-charts)
- [License](#license)

---

## Usage

Make sure you have [Helm](https://helm.sh) installed, then add the repository:

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update
```

Search for available charts:

```bash
helm search repo opentree
```

Install a chart:

```bash
# Example web application
helm install my-release opentree/example-app

# Tor obfs4 bridge
helm install my-bridge opentree/tor-obfs4-bridge \
  --set config.email=you@example.org \
  --namespace tor \
  --create-namespace
```

> **Note:** Publishing to `https://opentreecz.github.io/helm` requires GitHub
> Pages to be enabled for this repository, serving from the `gh-pages` branch.
> The `gh-pages` branch is created automatically by the release workflow on the
> first successful run.

---

## Available Charts

| Chart | Version | Description |
| ----- | ------- | ----------- |
| [example-app](./charts/example-app) | 0.1.2 | Starter chart for a generic web application |
| [tor-obfs4-bridge](./charts/tor-obfs4-bridge) | 0.1.2 | Tor obfs4 pluggable-transport bridge (StatefulSet + LoadBalancer) |
| [wg-easy](./charts/wg-easy) | 0.6.3 | WireGuard VPN server with web UI (wg-easy) |
| [wireguard](./charts/wireguard) | 0.4.3 | WireGuard VPN via linuxserver/wireguard (server + client mode) |
| [wordpress](./charts/wordpress) | 3.6.10 | WordPress CMS with MariaDB/Redis/Valkey/Memcached subcharts |
| [mc-router](./charts/mc-router) | 1.5.0 | Minecraft Java Edition connection router (itzg/mc-router) |
| [minecraft](./charts/minecraft) | 5.2.0 | Minecraft Java Edition server (itzg/minecraft-server) |
| [minecraft-bedrock](./charts/minecraft-bedrock) | 2.9.0 | Minecraft Bedrock Edition server (itzg/minecraft-bedrock-server) |
| [minecraft-proxy](./charts/minecraft-proxy) | 3.10.0 | Minecraft proxy (BungeeCord/Velocity/Waterfall via itzg/bungeecord) |
| [rcon-web-admin](./charts/rcon-web-admin) | 1.2.1 | Web RCON admin panel for game servers (itzg/rcon-web-admin) |

---

## Attribution

Charts in this repository are sourced from the following upstream projects and
maintained under the terms of their respective licenses (all MIT or Apache-2.0):

| Chart(s) | Original repository | Original author |
| -------- | ------------------- | --------------- |
| `wg-easy`, `wireguard`, `wordpress` | [slydlake/helm-charts](https://github.com/slydlake/helm-charts) | [slydlake](https://github.com/slydlake) |
| `mc-router`, `minecraft`, `minecraft-bedrock`, `minecraft-proxy`, `rcon-web-admin` | [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts) | [itzg](https://github.com/itzg) and contributors |

Charts have been rebased to conform to this repository's conventions (apiVersion v2,
standardized maintainers, `ci/ct-values.yaml`, helm-unittest suites). The original
`sources:` URLs are preserved in each chart's `Chart.yaml`.

---

## Repository Layout

```
.
├── charts/                          # One directory per chart
│   ├── example-app/                 # Starter/reference chart
│   ├── tor-obfs4-bridge/            # Tor obfs4 bridge
│   ├── wg-easy/                     # WireGuard + web UI (wg-easy)
│   ├── wireguard/                   # WireGuard (linuxserver)
│   ├── wordpress/                   # WordPress CMS
│   ├── mc-router/                   # Minecraft Java router
│   ├── minecraft/                   # Minecraft Java server
│   ├── minecraft-bedrock/           # Minecraft Bedrock server
│   ├── minecraft-proxy/             # Minecraft proxy (BungeeCord/Velocity)
│   └── rcon-web-admin/              # RCON web admin panel
│
│   Each chart contains:
│   ├── ci/ct-values.yaml            # Override values for chart-testing in kind
│   ├── templates/                   # Kubernetes manifest templates
│   ├── tests/*_test.yaml            # helm-unittest suites
│   ├── Chart.yaml
│   ├── values.yaml
│   └── README.md
│
├── scripts/
│   └── bump-chart-versions.sh       # Auto-bump helper used by the release workflow
├── ct.yaml                          # chart-testing configuration
├── CHANGELOG.md                     # Repository-level changelog
├── CONTRIBUTING.md                  # How to add charts and contribute
├── SECURITY.md                      # Vulnerability reporting policy
└── .github/
    ├── dependabot.yml               # Weekly updates for GitHub Actions
    └── workflows/
        ├── lint-test.yaml           # Lint + unit-test + kind install on PRs and push to main
        ├── build.yaml               # Weekly scheduled build + unit tests of all charts
        └── release.yaml             # Auto-version, package + publish on push to main
```

---

## Automation

This repository is fully automated via GitHub Actions:

| Workflow | Trigger | What it does |
| -------- | ------- | ------------ |
| **Lint and Test** | PR / push to `main` touching `charts/` | Lints changed charts with `ct lint`, runs `helm unittest` on all charts with test suites, and installs changed charts into a [kind](https://kind.sigs.k8s.io) cluster via `ct install`. |
| **Scheduled Build** | Weekly (Mon 06:00 UTC) + manual | Lints, templates, packages, and **unit-tests all charts** with the latest Helm to catch drift from upstream API or Helm changes. |
| **Release Charts** | Push to `main` touching `charts/` + manual | Auto-bumps chart versions, then packages and publishes via [chart-releaser](https://github.com/helm/chart-releaser-action). |
| **Dependabot** | Weekly (Mon 06:00 UTC) | Opens PRs to keep GitHub Actions versions up to date. |

---

## Versioning (auto-bump)

You do **not** need to bump a chart's `version` manually for routine changes.
When a change to a chart lands on `main`, the release workflow runs
[`scripts/bump-chart-versions.sh`](./scripts/bump-chart-versions.sh), which:

- detects every chart whose files changed in the push, and
- increments its **patch** version (e.g. `0.1.1` → `0.1.2`) **unless** you
  already bumped `version` in the same change — manual `minor`/`major` bumps
  are always respected.

The bump is committed back to `main` as
`chore(release): auto-bump chart versions [skip ci]`,
and the new version is published immediately afterward.

### When to bump manually

| Change type | What to bump |
| ----------- | ------------ |
| Bug fix / minor template tweak | Nothing — auto-bump handles it |
| New feature / new value | `version` minor (e.g. `0.1.x` → `0.2.0`) |
| Breaking change (rename/remove values) | `version` major (e.g. `0.x.y` → `1.0.0`) |
| New version of the packaged application | `appVersion` |

### Keeping dependencies current

- **GitHub Actions** — updated automatically by Dependabot weekly.
- **Helm version** — pinned in each workflow via `azure/setup-helm`. Bump
  the pin when adopting a newer Helm release.
- **Chart `appVersion`** — updated manually when the packaged application
  releases a new version (open a PR and let auto-bump handle the chart `version`).

---

## Developing Charts

See [CONTRIBUTING.md](./CONTRIBUTING.md) for a full guide. Quick reference:

```bash
# Lint and render a single chart
helm lint charts/example-app
helm template my-release charts/example-app

# Run unit tests for a chart (requires helm-unittest plugin)
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/example-app

# Run unit tests for all charts at once
for chart in charts/*/; do helm unittest "$chart"; done

# Full chart-testing lint (requires ct CLI)
ct lint --config ct.yaml

# chart-testing install into a local kind cluster
kind create cluster
ct install --config ct.yaml
```

---

## License

This repository is licensed under the [Apache License 2.0](./LICENSE).
