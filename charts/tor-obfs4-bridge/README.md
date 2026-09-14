# tor-obfs4-bridge

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/opentree)](https://artifacthub.io/packages/search?repo=opentree)

Helm chart for running a [Tor](https://www.torproject.org/) bridge with the
[obfs4](https://gitlab.com/yawning/obfs4) pluggable transport on Kubernetes.

Bridges help censored users reach the Tor network by disguising Tor traffic as
ordinary traffic. Running one is safe, legal in most jurisdictions, and only
requires two open TCP ports.

## Architecture

```
Internet
  │
  ├─► OR_PORT  (TCP, default 2123) ──► Tor OR listener
  └─► PT_PORT  (TCP, default 2133) ──► obfs4proxy ──► Tor ExtOR port
                                                          │
                                             /var/lib/tor (persistent PVC)
                                             /var/log/tor (emptyDir)
```

This chart deploys:

| Resource | Kind | Purpose |
| -------- | ---- | ------- |
| `tor-obfs4-bridge` | StatefulSet | Runs the Tor + obfs4proxy process; single replica with stable identity |
| `tor-obfs4-bridge` | Service | LoadBalancer exposing OR port + PT port |
| `tor-obfs4-bridge` | ServiceAccount | Least-privilege identity for the pod |
| `datadir` | volumeClaimTemplate | Persists `/var/lib/tor` (bridge keys, state) across pod restarts |

**Why StatefulSet?** A Tor bridge must keep a stable identity (key pair). Losing
`/var/lib/tor` means the bridge gets a new fingerprint and all users need a new
bridge line. StatefulSet with `volumeClaimTemplate` gives the pod a stable PVC
bound to the pod identity.

**Volume ownership — initContainer:** Kubernetes mounts PVCs and `emptyDir`
volumes owned by **root (uid 0)**. Tor explicitly refuses to use a
`DataDirectory` that is not owned by the running user (uid 100). Since
`fsGroup` only sets the **group** (not the owner uid), an `initContainer`
(`fix-volume-ownership`) runs as root before the main container to
`chown -R 100:101 /var/lib/tor /var/log/tor`. This is the standard Kubernetes
pattern for fixing volume ownership for non-root workloads.

## Security defaults

All security hardening is enabled out of the box:

| Setting | Value | Why |
| ------- | ----- | --- |
| `runAsNonRoot` | `true` | Container never runs as root |
| `runAsUser` | `100` | debian-tor uid (uid=100 in the Debian `tor` package) |
| `runAsGroup` | `101` | debian-tor gid (gid=101 in the Debian `tor` package) |
| `fsGroup` | `101` | PVC volume ownership group — grants the debian-tor group access |
| `capabilities.drop` | `["ALL"]` | Drop all Linux capabilities |
| `capabilities.add` | `["NET_BIND_SERVICE"]` | obfs4proxy needs to bind ports < 1024 |
| `allowPrivilegeEscalation` | `false` | Prevents privilege escalation via setuid |
| `seccompProfile` | `RuntimeDefault` | Restricts syscalls to the container runtime default |
| `readOnlyRootFilesystem` | `false` | Tor writes state files at runtime; not safe to lock |

> **Important:** `runAsUser` must be **100** (not 101). In the Debian `tor`
> package, `debian-tor` is uid=100, gid=101. `/etc/tor` is owned by uid 100
> (mode 755). Running as uid 101 causes
> `start-tor.sh: /etc/tor/torrc: Permission denied` and the pod crashes.
> The chart enforces the correct value; do not override it.

> **PodSecurity `restricted` namespaces:** the `fix-volume-ownership`
> initContainer runs as `runAsUser: 0` (root) to chown the volume mounts.
> If your namespace enforces the `restricted` PodSecurity standard, this
> initContainer will be rejected. In that case either:
> - Pre-provision the PVC with correct ownership using an external job, or
> - Use `fsGroupChangePolicy: OnRootMismatch` on the StorageClass / PVC
>   (supported by some CSI drivers), or
> - Deploy in a `baseline` namespace (recommended for a public-facing Tor bridge).

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- A LoadBalancer-capable cluster (or use `service.type=NodePort` with fixed `nodePort` values)
- Two inbound TCP ports reachable from the internet (`config.orPort` and `config.ptPort`)

## Installing

```bash
helm repo add opentree https://opentreecz.github.io/helm
helm repo update

helm install my-bridge opentree/tor-obfs4-bridge \
  --set config.email=you@example.org \
  --namespace tor \
  --create-namespace
```

### Required value

`config.email` is the only value without a safe default — it is published in
the Tor relay descriptor and is how the Tor Project contacts you about your
bridge. The container will refuse to start if it is empty.

### Common overrides

```bash
# Custom ports
helm install my-bridge opentree/tor-obfs4-bridge \
  --set config.email=you@example.org \
  --set config.orPort=9001 \
  --set config.ptPort=9002 \
  --namespace tor --create-namespace

# Pin a specific Tor image version
helm install my-bridge opentree/tor-obfs4-bridge \
  --set config.email=you@example.org \
  --set image.tag=0.4.9.12-1-d13.trixie-1 \
  --namespace tor --create-namespace

# Use a custom values file
helm install my-bridge opentree/tor-obfs4-bridge \
  -f my-bridge-values.yaml \
  --namespace tor --create-namespace
```

## Upgrading

```bash
helm repo update
helm upgrade my-bridge opentree/tor-obfs4-bridge --namespace tor
```

> **Important:** upgrading recreates the pod (the StatefulSet uses
> `RollingUpdate`). The PVC is retained so bridge identity keys are preserved.

## Uninstalling

```bash
helm uninstall my-bridge --namespace tor
```

> **Warning:** uninstalling does **not** delete the PVC. To also delete the
> bridge identity data:
>
> ```bash
> kubectl delete pvc -n tor datadir-my-bridge-tor-obfs4-bridge-0
> ```

## Getting the bridge line

After the pod has bootstrapped (watch for `Bootstrapped 100%` in the logs,
which typically takes 1–2 minutes):

```bash
# Watch bootstrap progress
kubectl logs -n tor statefulset/my-bridge-tor-obfs4-bridge -f

# Retrieve the bridge line
kubectl exec -n tor my-bridge-tor-obfs4-bridge-0 -- get-bridge-line
```

Example output:

```
obfs4 203.0.113.42:9002 AABBCCDDEEFF00112233445566778899AABBCCDD cert=xxxx iat-mode=0
```

Share this line with censored users or submit it to
[bridges.torproject.org](https://bridges.torproject.org/submit).

## Values reference

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `image.repository` | string | `ghcr.io/zetneteork/docker-tor-obfs4-bridge` | Container image repository |
| `image.tag` | string | `""` | Image tag; defaults to the chart `appVersion` |
| `image.pullPolicy` | string | `Always` | Image pull policy (`Always` ensures latest patch on restart) |
| `initImage.repository` | string | `busybox` | Image used by the `fix-volume-ownership` initContainer |
| `initImage.tag` | string | `1.36` | busybox image tag |
| `initImage.pullPolicy` | string | `IfNotPresent` | Pull policy for the initContainer image |
| `imagePullSecrets` | list | `[]` | Image pull secret names |
| `config.orPort` | int | `2123` | OR port — must be open inbound from the internet |
| `config.ptPort` | int | `2133` | obfs4 PT port — must be open inbound from the internet |
| `config.email` | string | `""` | **Required.** Operator contact e-mail published in the relay descriptor |
| `config.ipv4Only` | string | `"1"` | `"1"` = restrict OR port to IPv4 only; `"0"` = dual-stack |
| `config.exitRelay` | string | `"0"` | `"1"` to enable exit relay (not recommended for bridges) |
| `config.bridgeRelay` | string | `"1"` | `"1"` to enable bridge relay mode |
| `persistence.enabled` | bool | `true` | Persist `/var/lib/tor` via a volumeClaimTemplate |
| `persistence.size` | string | `2Gi` | PVC size |
| `persistence.storageClass` | string | `""` | StorageClass; blank = cluster default |
| `persistence.accessMode` | string | `ReadWriteOnce` | PVC access mode |
| `persistence.existingClaim` | string | `""` | Use an existing PVC instead of creating one |
| `service.type` | string | `LoadBalancer` | Kubernetes Service type |
| `service.externalTrafficPolicy` | string | `Local` | Preserve real client source IP |
| `service.annotations` | object | `{}` | Extra annotations on the Service (e.g. cloud LB annotations) |
| `replicaCount` | int | `1` | Must remain `1` — multiple replicas sharing one data dir are unsupported |
| `podSecurityContext.runAsNonRoot` | bool | `true` | Enforce non-root |
| `podSecurityContext.runAsUser` | int | `100` | debian-tor uid (uid=100 in Debian tor package — do NOT set to 101) |
| `podSecurityContext.runAsGroup` | int | `101` | debian-tor gid |
| `podSecurityContext.fsGroup` | int | `101` | Volume ownership group |
| `podSecurityContext.seccompProfile.type` | string | `RuntimeDefault` | Seccomp profile |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Block privilege escalation |
| `securityContext.capabilities.drop` | list | `["ALL"]` | Drop all capabilities |
| `securityContext.capabilities.add` | list | `["NET_BIND_SERVICE"]` | Allow binding low ports |
| `livenessProbe` | object | `pgrep -x tor` | Liveness probe — checks the tor process is running |
| `readinessProbe` | object | grep `Bootstrapped 100%` | Readiness probe — ready only after full bootstrap |
| `resources.requests.cpu` | string | `50m` | CPU request |
| `resources.requests.memory` | string | `64Mi` | Memory request |
| `resources.limits.cpu` | string | `500m` | CPU limit |
| `resources.limits.memory` | string | `256Mi` | Memory limit |
| `serviceAccount.create` | bool | `true` | Create a ServiceAccount |
| `serviceAccount.annotations` | object | `{}` | ServiceAccount annotations |
| `serviceAccount.name` | string | `""` | ServiceAccount name; auto-generated if empty |
| `nameOverride` | string | `""` | Override the chart name in resource names |
| `fullnameOverride` | string | `""` | Override the fully-qualified resource name |
| `podAnnotations` | object | `{}` | Extra pod annotations |
| `podLabels` | object | `{}` | Extra pod labels |
| `nodeSelector` | object | `{}` | Node selector constraints |
| `tolerations` | list | `[]` | Pod tolerations |
| `affinity` | object | `{}` | Pod affinity rules |

## Troubleshooting

**Pod is stuck in `Pending`**
- Check `kubectl describe pod -n tor` — most likely no LoadBalancer IP has been
  assigned, or the PVC cannot be provisioned.
- Use `service.type=NodePort` or `service.type=ClusterIP` if your cluster does
  not support LoadBalancer.

**Pod crashes with `/var/lib/tor is not owned by this user`**
- Root cause: Kubernetes mounted the PVC owned by root (uid 0). Tor refuses
  to use a `DataDirectory` not owned by the process user (uid 100).
- This chart (≥ 0.1.4) includes a `fix-volume-ownership` `initContainer` that
  runs `chown -R 100:101 /var/lib/tor /var/log/tor` before Tor starts.
- **If you are on ≤ 0.1.3 and seeing this crash:**
  ```bash
  helm repo update
  helm upgrade <release-name> opentree/tor-obfs4-bridge --namespace tor
  ```
  The initContainer will chown the existing PVC on the next pod start —
  no manual PVC deletion required.
- If you are already on ≥ 0.1.4 and still see this error, check the
  initContainer ran successfully:
  ```bash
  kubectl logs -n tor <pod-name> -c fix-volume-ownership
  ```
  If the initContainer itself is blocked (e.g. by PodSecurity `restricted`
  policy which forbids `runAsUser: 0`), see the note in the
  [Security defaults](#security-defaults) section.

**Pod crashes with `Permission denied` writing `/etc/tor/torrc`**
- Root cause: the pod is running as the wrong UID. In the Debian `tor` package,
  `debian-tor` is **uid=100, gid=101**. `/etc/tor` is owned by uid 100 (mode 755).
  Running as uid 101 (the gid, not the uid) cannot write torrc.
- This chart uses `runAsUser: 100` (correct). If you see this error, check that
  you have not overridden `podSecurityContext.runAsUser` to 101.
- Verify the image identity: `docker run --rm --entrypoint sh <image> -c 'id debian-tor'`
  should print `uid=100(debian-tor) gid=101(debian-tor)`.

**Pod starts but bridge line cannot be retrieved**
- The bridge has not finished bootstrapping yet. Run
  `kubectl logs -n tor statefulset/my-bridge-tor-obfs4-bridge -f` and wait
  for `Bootstrapped 100%`.
- If the log stops at `< 100%`, check that both ports are open inbound.

**Bridge was working, now users can't connect**
- Run `get-bridge-line` again — the external IP or port may have changed.
- If the PVC was deleted, the bridge has a new identity and all users need the
  new bridge line.

**`config.email` is empty — helm install/upgrade fails**
- `config.email` is required. The chart hard-fails at render time when it is empty.
- Set it with: `--set config.email=you@example.org`

## Testing the chart

```bash
# Lint and render
helm lint charts/tor-obfs4-bridge
helm template my-bridge charts/tor-obfs4-bridge --set config.email=test@example.org

# Unit tests (requires helm-unittest plugin — Helm >= 3.18)
helm plugin install https://github.com/helm-unittest/helm-unittest --version v1.1.1
helm unittest charts/tor-obfs4-bridge

# Full chart-testing install into a kind cluster
kind create cluster
ct install --config ct.yaml
```

Unit test suites live in [`tests/`](./tests) and run automatically in CI on
every PR and push to `main`.

## Source

- Docker image: [zetneteork/docker-tor-obfs4-bridge](https://github.com/zetneteork/docker-tor-obfs4-bridge)
- Helm chart: [opentreecz/helm](https://github.com/opentreecz/helm)
- Tor Project: [torproject.org](https://www.torproject.org/)
