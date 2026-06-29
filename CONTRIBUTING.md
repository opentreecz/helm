# Contributing

Thanks for contributing to the opentree Helm chart repository.

## Adding a new chart

1. Create a new directory under `charts/` named after your chart. The fastest
   way to scaffold one is:

   ```bash
   helm create charts/<chart-name>
   ```

   You can use the existing [`example-app`](./charts/example-app) chart as a
   reference for repository conventions.

2. Fill in `Chart.yaml` with an accurate `name`, `description`, `version`,
   `appVersion`, and `maintainers`.

3. Document configurable values in the chart's `README.md`.

## Versioning

- Every chart follows [Semantic Versioning](https://semver.org).
- **You must bump the `version` field in `Chart.yaml` for any change to a
  chart.** CI enforces this (`check-version-increment`), and the release
  workflow only publishes a new package when the chart version changes.
- Bump `appVersion` when the version of the packaged application changes.

## Testing locally

Lint and render a chart:

```bash
helm lint charts/<chart-name>
helm template charts/<chart-name>
```

Run the full chart-testing suite (requires
[chart-testing](https://github.com/helm/chart-testing) and a Kubernetes
cluster such as [kind](https://kind.sigs.k8s.io)):

```bash
ct lint --config ct.yaml
ct install --config ct.yaml
```

To exercise non-default paths during `ct install`, add values files under
`charts/<chart-name>/ci/*-values.yaml`.

## Pull requests

- Open a pull request against `main`.
- The **Lint and Test Charts** workflow runs automatically on changed charts.
- On merge to `main`, the **Release Charts** workflow packages changed charts
  and publishes them to GitHub Pages.
