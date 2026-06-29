# opentree Helm Charts

A Kubernetes [Helm](https://helm.sh) chart repository maintained by opentreecz.

Charts are linted and tested on every pull request, then automatically packaged
and published to GitHub Pages on merge to `main` using
[chart-releaser](https://github.com/helm/chart-releaser-action).

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
helm install my-release opentree/example-app
```

> **Note:** Publishing to `https://opentreecz.github.io/helm` requires GitHub
> Pages to be enabled for this repository, serving from the `gh-pages` branch.
> The `gh-pages` branch is created automatically by the release workflow on the
> first successful run.

## Available Charts

| Chart                               | Description                                              |
| ----------------------------------- | ------------------------------------------------------- |
| [example-app](./charts/example-app) | A starter chart for deploying a generic web application |

## Repository Layout

```
.
├── charts/                  # One directory per chart
│   └── example-app/         # Example/starter chart
├── scripts/
│   └── bump-chart-versions.sh  # Auto-bump helper used by the release workflow
├── ct.yaml                  # chart-testing configuration
└── .github/
    ├── dependabot.yml       # Weekly updates for GitHub Actions
    └── workflows/
        ├── lint-test.yaml   # Lint + kind install test on pull requests
        ├── build.yaml       # Weekly scheduled build of all charts
        └── release.yaml     # Auto-version, package + publish on push to main
```

## Automation

This repository is fully automated via GitHub Actions:

| Workflow                 | Trigger                          | What it does                                                                 |
| ------------------------ | -------------------------------- | --------------------------------------------------------------------------- |
| **Lint and Test**        | Pull requests touching `charts/` | Lints changed charts and installs them into a [kind](https://kind.sigs.k8s.io) cluster. |
| **Scheduled Build**      | Weekly (Mon 06:00 UTC) + manual  | Lints, templates and packages **all** charts with the latest Helm to catch drift. |
| **Release Charts**       | Push to `main` touching `charts/` + manual | Auto-bumps chart versions, then packages and publishes via [chart-releaser](https://github.com/helm/chart-releaser-action). |
| **Dependabot**           | Weekly                           | Opens PRs to keep the GitHub Actions used in these workflows up to date.     |

### Versioning (auto-bump)

You do **not** need to bump a chart's `version` manually. When a change to a
chart lands on `main`, the release workflow runs
[`scripts/bump-chart-versions.sh`](./scripts/bump-chart-versions.sh), which:

- detects every chart whose files changed in the push, and
- increments its patch version (e.g. `0.1.0` → `0.1.1`) **unless** you already
  bumped it in the same change — manual `minor`/`major` bumps are respected.

The bump is committed back to `main` as `chore(release): auto-bump chart
versions [skip ci]`, and the new version is released immediately afterward.

### Update procedure

- **GitHub Actions** are updated automatically by Dependabot
  ([`.github/dependabot.yml`](./.github/dependabot.yml)) — review and merge the
  weekly PRs.
- **Helm version** is pinned in the workflows (`azure/setup-helm`). Bump it
  there when you want to adopt a newer Helm.
- **Chart application versions** (`appVersion`) and any chart dependencies are
  updated by editing the chart and opening a PR; the auto-bump then takes care
  of the chart `version`. (Dependabot does not track Helm subchart
  dependencies; if you add them, consider a scheduled `helm dependency update`
  workflow.)

## Developing Charts

See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to add a new chart, test
changes locally, and the versioning policy.

Quick local checks:

```bash
helm lint charts/example-app
helm template charts/example-app
```

## License

This repository is licensed under the [Apache License 2.0](./LICENSE).
