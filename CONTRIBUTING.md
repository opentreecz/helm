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
- **Patch bumps are automatic.** When your change lands on `main`, the release
  workflow auto-increments the chart `version` (e.g. `0.1.0` → `0.1.1`) for
  every chart you touched. You do not need to edit `version` for routine
  changes.
- **Bump `version` yourself for `minor`/`major` changes** (new features or
  breaking changes). A manual bump in your PR is respected and the auto-bump is
  skipped for that chart.
- Bump `appVersion` when the version of the packaged application changes.

## Testing locally

Lint and render a chart:

```bash
helm lint charts/<chart-name>
helm template charts/<chart-name>
```

Run the chart unit tests (templates rendered and asserted with
[helm-unittest](https://github.com/helm-unittest/helm-unittest)):

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
helm unittest charts/<chart-name>
```

Add test suites under `charts/<chart-name>/tests/*_test.yaml`. They run on every
pull request via the **Lint and Test Charts** workflow.

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
- On merge to `main`, the **Release Charts** workflow auto-bumps versions,
  packages changed charts and publishes them to GitHub Pages.

See the [README automation section](./README.md#automation) for the full list
of workflows (including the weekly scheduled build and Dependabot updates).
