# Security Policy

## Supported versions

Only charts on the **latest release** (published from `main`) are actively
maintained with security fixes.

| Chart | Supported |
| ----- | --------- |
| `tor-obfs4-bridge` — latest release | yes |
| `example-app` — latest release | yes |
| Any older chart version | no |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Report privately via one of:

- **GitHub Security Advisories** — use the
  [Report a vulnerability](https://github.com/opentreecz/helm/security/advisories/new)
  button on the Security tab of this repository.
- **E-mail** — `tor@opentree.cz`

Please include:
- A clear description of the vulnerability and which chart / template is
  affected.
- Steps to reproduce or a proof-of-concept (manifests, Helm values, etc.).
- Potential impact.

We aim to acknowledge reports within **48 hours** and publish a fixed chart
release within **14 days** for critical issues.

## Upstream security

Charts in this repository bundle third-party software. Monitor upstream
advisories:

| Chart | Upstream advisory source |
| ----- | ------------------------ |
| `tor-obfs4-bridge` | [Tor security advisories](https://www.torproject.org/security/advisories/) · [Debian security tracker – tor](https://security-tracker.debian.org/tracker/source-package/tor) |
| `example-app` (nginx) | [nginx security advisories](https://nginx.org/en/security_advisories.html) |

The Docker base image (`debian:stable-slim`) used by `tor-obfs4-bridge` is
tracked by Dependabot in the
[docker-tor-obfs4-bridge](https://github.com/zetneteork/docker-tor-obfs4-bridge)
repository.

GitHub Actions used in CI workflows are kept up to date automatically via
Dependabot (see [`.github/dependabot.yml`](.github/dependabot.yml)).
