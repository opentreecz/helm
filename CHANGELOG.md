# Changelog

All notable changes to this repository are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Chart versions follow [Semantic Versioning](https://semver.org).

---

## [Unreleased]

### Fixed — tor-obfs4-bridge
- **`runAsUser: 101` → `100`** in `values.yaml` — critical bug: `debian-tor`
  in the Debian `tor` package is **uid=100, gid=101**. Running as uid 101
  caused `start-tor.sh: /etc/tor/torrc: Permission denied` because `/etc/tor`
  is owned by uid 100 (mode 755). Docker was unaffected (`USER debian-tor`
  resolves the name to uid 100). Kubernetes uses the numeric uid directly.
- **Hard-fail email guard** added to `templates/statefulset.yaml`: `helm install`
  now fails immediately with a clear message when `config.email` is empty,
  instead of the pod crashing after start.

### Added — tor-obfs4-bridge tests
- `tests/statefulset_test.yaml`: folded in full securityContext regression
  suite — `runAsUser: 100`, `runAsGroup: 101`, `fsGroup: 101`,
  `runAsNonRoot: true`, `seccompProfile: RuntimeDefault`,
  `allowPrivilegeEscalation: false`, cap drop ALL / add NET_BIND_SERVICE.
  These tests fail if `runAsUser` is ever reset to 101.
- `tests/email-required_test.yaml` (new): `failedTemplate` asserts when
  `config.email` is empty or unset; renders correctly when set.

### Changed — tor-obfs4-bridge documentation
- `README.md`: updated security-defaults table (`runAsUser 100`); added
  uid=100/gid=101 explanation and warning; added `Permission denied`
  troubleshooting entry; `config.email` hard-fail note updated.
- `values.yaml`: comment updated to explain uid=100/gid=101 and the
  consequence of using the wrong value.

### Added
- **8 charts imported** from external repositories (rebased to repo conventions):
  - `wg-easy` (0.6.3) — WireGuard + web UI, from [slydlake/helm-charts](https://github.com/slydlake/helm-charts)
  - `wireguard` (0.4.3) — WireGuard server/client, from [slydlake/helm-charts](https://github.com/slydlake/helm-charts)
  - `wordpress` (3.6.10) — WordPress CMS with optional MariaDB/Redis/Valkey/Memcached subcharts, from [slydlake/helm-charts](https://github.com/slydlake/helm-charts)
  - `mc-router` (1.5.0) — Minecraft Java router, from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
  - `minecraft` (5.2.0) — Minecraft Java server, from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
  - `minecraft-bedrock` (2.9.0) — Minecraft Bedrock server, from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
  - `minecraft-proxy` (3.10.0) — BungeeCord/Velocity proxy, from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
  - `rcon-web-admin` (1.2.1) — RCON web admin panel, from [itzg/minecraft-server-charts](https://github.com/itzg/minecraft-server-charts)
- All imported charts normalized to repo conventions:
  - `apiVersion: v2` (mc-router/minecraft/minecraft-bedrock/minecraft-proxy upgraded from v1)
  - Concrete `appVersion` replacing `SeeValues` placeholder
  - `ci/ct-values.yaml` for kind-installable chart-testing
  - helm-unittest suites (`tests/*_test.yaml`) — 52 new tests across 16 new suites
  - Standardized `Chart.yaml` (maintainers include opentreecz; original authors credited; `sources` preserved)
  - Chart-specific `README.md` (install/upgrade/uninstall/values/testing)
- Attribution section added to root `README.md`.
- `lint-test.yaml`: added `helm dependency update` step for OCI subchart dependencies.
- `build.yaml`: updated lint step to pass `ci/ct-values.yaml` for charts with required values.
- `release.yaml`: added `helm dependency update` step so chart-releaser packages subcharts correctly.

### Changed
- `README.md`: updated Available Charts table (10 charts), layout tree, attribution section.
- `CHANGELOG.md`: this entry.

### Changed
- `README.md` — added CI badges, full table of contents, updated automation
  table to include `unit-test` job, updated repository layout tree, improved
  developing-charts quick reference.
- `CONTRIBUTING.md` — added prerequisites table with version pins, chart
  conventions section, full testing guide (lint / unittest / ct lint /
  ct install), versioning decision table.
- `charts/example-app/README.md` — expanded to full values reference table,
  install/upgrade/uninstall instructions, testing section.
- `charts/tor-obfs4-bridge/README.md` — added architecture diagram, security
  defaults table, full values reference, upgrade/uninstall notes, bridge-line
  retrieval instructions, troubleshooting guide.

---

## [tor-obfs4-bridge-0.1.1] – 2026-09-14

### Added
- Initial release of `tor-obfs4-bridge` chart.
- StatefulSet with `volumeClaimTemplate` for `/var/lib/tor` persistence.
- LoadBalancer Service exposing OR port and PT port with
  `externalTrafficPolicy: Local`.
- ServiceAccount.
- Hardened security defaults: non-root (`runAsUser: 101`), `capabilities drop
  ALL + NET_BIND_SERVICE`, `seccompProfile: RuntimeDefault`,
  `allowPrivilegeEscalation: false`.
- Resource requests/limits (50m/64Mi → 500m/256Mi).
- Liveness probe (`pgrep tor`) and readiness probe (`Bootstrapped 100%` in
  log).
- `ci/ct-values.yaml` for kind-installable chart-testing.
- 19 `helm-unittest` test cases across `statefulset_test.yaml` and
  `service_test.yaml`.

### CI
- `lint-test.yaml`: added `push: branches: [main]` trigger so `unit-test` job
  runs on every merge to `main`, not just on PRs; added per-chart exit-code
  capture.
- `build.yaml`: added `unit-test-all` job that runs `helm unittest` on all
  charts in the weekly scheduled build.

---

## [example-app-0.1.1] – 2026-09-07

### Changed
- Bumped GitHub Actions dependencies (Dependabot PR #9).

---

## [example-app-0.1.0] – initial

### Added
- Initial `example-app` starter chart.
- Deployment, Service, Ingress, HPA, ServiceAccount templates.
- `helm-unittest` test suites for Deployment and Service.
- `ci/ct-values.yaml` for chart-testing.

### CI
- `lint-test.yaml`: Lint and Test workflow (ct lint + ct install on PRs).
- `build.yaml`: Weekly scheduled build of all charts.
- `release.yaml`: Auto-bump + chart-releaser publishing on push to `main`.
- `dependabot.yml`: Weekly GitHub Actions updates.
