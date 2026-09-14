# Contributing

Thanks for contributing to the opentree Helm chart repository.

## Table of contents

- [Prerequisites](#prerequisites)
- [Adding a new chart](#adding-a-new-chart)
- [Modifying an existing chart](#modifying-an-existing-chart)
- [Versioning policy](#versioning-policy)
- [Testing locally](#testing-locally)
- [Chart conventions](#chart-conventions)
- [Pull requests](#pull-requests)

---

## Prerequisites

Install the following tools before working with this repository:

| Tool | Purpose | Install |
| ---- | ------- | ------- |
| [Helm](https://helm.sh) 3.18+ | Template, lint, package charts | [docs.helm.sh](https://helm.sh/docs/intro/install/) |
| [helm-unittest](https://github.com/helm-unittest/helm-unittest) | Run chart unit tests | `helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1` |
| [chart-testing (ct)](https://github.com/helm/chart-testing) | Lint + kind install integration tests | [github.com/helm/chart-testing](https://github.com/helm/chart-testing/releases) |
| [kind](https://kind.sigs.k8s.io) | Local Kubernetes cluster for `ct install` | [kind.sigs.k8s.io](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) |

> **Helm version note:** `helm-unittest` v1.1.x requires Helm ≥ 3.18 due to
> the `platformHooks` plugin field. The version pinned in CI workflows
> (`azure/setup-helm@v5` with `version: v3.21.2`) satisfies this.

---

## Adding a new chart

1. Scaffold a new chart directory:

   ```bash
   helm create charts/<chart-name>
   ```

   Use the existing [`tor-obfs4-bridge`](./charts/tor-obfs4-bridge) or
   [`example-app`](./charts/example-app) charts as reference for
   repository conventions.

2. Fill in `Chart.yaml` with:
   - `name`, `description`, `type: application`
   - `version: 0.1.0` (patch bumps are automatic — see [Versioning policy](#versioning-policy))
   - `appVersion` set to the version of the packaged application
   - `maintainers` with name and email
   - `home` and `sources` pointing to the upstream project

3. Write `values.yaml` with every configurable parameter commented.

4. Add a `README.md` inside the chart directory documenting:
   - What the chart deploys
   - Prerequisites
   - Install / upgrade / uninstall instructions
   - A full values table

5. Add unit tests under `charts/<chart-name>/tests/*_test.yaml`
   (see [Testing locally](#testing-locally)).

6. Add `charts/<chart-name>/ci/ct-values.yaml` with overrides that make the
   chart installable in a kind cluster (e.g. disable LoadBalancer, use
   ClusterIP, disable PVCs).

7. Add a row to the **Available Charts** table in the root
   [`README.md`](./README.md).

---

## Modifying an existing chart

1. Edit the relevant files under `charts/<chart-name>/`.
2. Update `README.md` if any values changed.
3. Run `make lint` / `helm lint` + `helm unittest` locally before pushing.
4. You do **not** need to bump `version` — the release workflow handles it
   automatically (see [Versioning policy](#versioning-policy)).

---

## Versioning policy

Every chart follows [Semantic Versioning](https://semver.org).

| Change type | Action required |
| ----------- | --------------- |
| Bug fix / template tweak | None — auto-bump increments the patch version |
| New feature / new value added | Manually bump `version` minor in your PR |
| Breaking change (rename/remove value, incompatible default) | Manually bump `version` major in your PR |
| New version of the packaged application | Bump `appVersion` in your PR |

**How auto-bump works:** on every push to `main` that touches a chart,
[`scripts/bump-chart-versions.sh`](./scripts/bump-chart-versions.sh) increments
the chart's patch version (e.g. `0.1.1` → `0.1.2`) and commits the change back
as `chore(release): auto-bump chart versions [skip ci]`. If you already bumped
`version` in your PR, the script skips that chart.

---

## Testing locally

### 1. Lint and render

```bash
helm lint charts/<chart-name>
helm template my-release charts/<chart-name>
```

### 2. Unit tests

Unit tests use [helm-unittest](https://github.com/helm-unittest/helm-unittest)
and live in `charts/<chart-name>/tests/*_test.yaml`.

```bash
# Install the plugin once (requires Helm >= 3.18)
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1

# Run tests for a single chart
helm unittest charts/<chart-name>

# Run tests for all charts
for chart in charts/*/; do helm unittest "$chart"; done
```

Test suites run automatically in CI on every PR and push to `main`
(**Lint and Test Charts** workflow, `unit-test` job), and in the
weekly **Scheduled Build** (`unit-test-all` job).

### 3. chart-testing lint (ct lint)

```bash
ct lint --config ct.yaml
```

`ct lint` validates changed charts against the chart-testing rules defined
in [`ct.yaml`](./ct.yaml).

### 4. chart-testing install (ct install)

Full integration test: renders the chart and installs it into a live cluster.

```bash
kind create cluster
ct install --config ct.yaml
```

Override values for CI installs go in `charts/<chart-name>/ci/ct-values.yaml`.
These are used automatically by both `ct install` locally and in CI.

---

## Chart conventions

Follow these conventions to keep all charts consistent:

- **Labels:** use the standard `app.kubernetes.io/*` label set, generated by
  `_helpers.tpl` macros (`*.labels`, `*.selectorLabels`). Do not add custom
  top-level labels directly in templates.
- **`_helpers.tpl`:** define `<chart>.name`, `<chart>.fullname`,
  `<chart>.chart`, `<chart>.labels`, `<chart>.selectorLabels`, and
  `<chart>.serviceAccountName` macros — see `example-app` for reference.
- **Security context:** default to non-root where possible.  Document any
  capability requirements in the chart `README.md`.
- **Resources:** always include `resources: {}` in values with commented
  example limits, so users know the field exists.
- **Probes:** include `livenessProbe` and `readinessProbe` in values when the
  workload supports them.
- **`ci/ct-values.yaml`:** every chart must include a CI values file that
  makes the chart installable in kind without external dependencies (no cloud
  LoadBalancer, no external PVC provisioner needed).
- **Tests:** every chart must have at least one `helm-unittest` suite under
  `tests/`. Tests run in CI automatically.

---

## Pull requests

1. Fork and branch from `main`.
2. Run `helm lint`, `helm unittest`, and `ct lint` before pushing.
3. Open a PR against `main`.
4. The **Lint and Test Charts** CI workflow runs automatically.
5. On merge to `main`, the **Release Charts** workflow auto-bumps chart
   versions, packages them, and publishes to GitHub Pages.

See the [README automation section](./README.md#automation) for the full CI
overview.
