# Changelog

All notable changes to this repository are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Chart versions follow [Semantic Versioning](https://semver.org).

---

## [Unreleased]

### Added
- `CHANGELOG.md` — this file.
- `SECURITY.md` — vulnerability reporting policy.

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
