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
├── ct.yaml                  # chart-testing configuration
└── .github/workflows/
    ├── lint-test.yaml       # Lint + install test on pull requests
    └── release.yaml         # Package + publish on push to main
```

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
