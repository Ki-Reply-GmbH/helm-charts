# Adding a New Provider (OpenBao Provider Example)

This guide documents the step-by-step process of adding a new provider to the platform-mesh local setup, using the **openbao-provider** as a concrete example. It follows the pattern established by the existing **httpbin-provider**.

## Architecture Overview

A provider in platform-mesh consists of several components working together:

```
KCP (multi-tenant control plane)                    Local Cluster (kind)
+------------------------------------------+       +------------------------------------------+
| root:providers:<provider-name> workspace |       |                                          |
|   - APIExport (defines the API)          |       |  <provider-name> namespace               |
|   - RBAC (allows binding)                |       |    - api-syncagent pods (2 replicas)      |
|   - ProviderMetadata (UI display)        |       |    - kubeconfig secret (managed by        |
+------------------------------------------+       |      PlatformMesh operator)               |
                                                    |    - PublishedResource (what to sync)     |
Consumer Workspaces                                |    - ClusterRole/Binding (RBAC for SA)    |
+------------------------------------------+       |                                          |
| root:<org>:<workspace>                   |       |  CRD installed cluster-wide               |
|   - APIBinding to the provider           |  ---> |    - e.g. OpenBaoTenant                   |
|   - Custom resources (e.g. OpenBaoTenant)|  sync |    - synced copies appear here             |
+------------------------------------------+       +------------------------------------------+
```

**Key flow**: Consumer workspaces bind to the provider's APIExport and create custom resources. The api-syncagent watches for these resources via KCP and syncs them to the local cluster, where the operator can pick them up and fulfill them.

## Prerequisites

- A running platform-mesh local setup (via `start.sh --example-data`)
- The CRD for your custom resource (e.g. `OpenBaoTenant`)
- Understanding of the API group and resource kind you want to expose

## Step-by-Step Guide

### Step 1: Create the KCP Example Data

These files define the provider's presence in KCP.

Create directory: `local-setup/example-data/root/providers/<provider-name>/`

#### 1.1 APIExport (`apiexport.yaml`)

Defines the API that consumer workspaces can bind to.

```yaml
# local-setup/example-data/root/providers/openbao-provider/apiexport.yaml
apiVersion: apis.kcp.io/v1alpha1
kind: APIExport
metadata:
  name: openbao.apeiro.dev
  labels:
    ui.platform-mesh.io/content-for: openbao.apeiro.dev
```

> The `name` must match the API group of your CRD. The label is used by the portal UI.

#### 1.2 RBAC (`rbac.yaml`)

Allows workspaces to bind to the APIExport.

```yaml
# local-setup/example-data/root/providers/openbao-provider/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: apiexport-bind
rules:
  - apiGroups: ["apis.kcp.io"]
    resources: ["apiexports"]
    verbs: ["bind"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: anonymous-view
subjects:
  - kind: User
    name: system:anonymous
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: apiexport-bind
  apiGroup: rbac.authorization.k8s.io
```

#### 1.3 Provider Metadata (`providermetadata.yaml`)

Display information for the portal UI.

```yaml
# local-setup/example-data/root/providers/openbao-provider/providermetadata.yaml
apiVersion: ui.platform-mesh.io/v1alpha1
kind: ProviderMetadata
metadata:
  name: openbao.apeiro.dev
spec:
  displayName: OpenBao Provider
  description: |
    OpenBao secrets management provider for tenant secret engines.
```

#### 1.4 Kustomization (`kustomization.yaml`)

```yaml
# local-setup/example-data/root/providers/openbao-provider/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - apiexport.yaml
  - providermetadata.yaml
  - rbac.yaml
```

---

### Step 2: Create the Kustomize Component

These files define what gets deployed on the local cluster.

Create directory: `local-setup/kustomize/components/<provider-name>/`

#### 2.1 HelmReleases (`helmreleases.yaml`)

Contains the Namespace, RBAC, and api-syncagent HelmRelease.

```yaml
# local-setup/kustomize/components/openbao-provider/helmreleases.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openbao-provider
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: api-syncagent:openbaotenant-provider
rules:
  - apiGroups:
      - openbao.apeiro.dev
    resources:
      - openbaotenants
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete
  - apiGroups:
      - openbao.apeiro.dev
    resources:
      - openbaotenants/status
    verbs:
      - get
      - update
      - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: api-syncagent:openbaotenant-provider
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: api-syncagent:openbaotenant-provider
subjects:
  - kind: ServiceAccount
    name: openbao-api-syncagent  # Must match the Helm release name!
    namespace: openbao-provider
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: openbao-api-syncagent
  namespace: default
spec:
  chart:
    spec:
      chart: api-syncagent
      version: "0.4.4"
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: HelmRepository
        name: api-syncagent
  interval: 1m
  releaseName: openbao-api-syncagent
  targetNamespace: openbao-provider
  timeout: 15m
  values:
    apiExportName: openbao.apeiro.dev
    agentName: openbao-api-syncagent
    kcpKubeconfig: openbao-kubeconfig
    hostAliases:
      enabled: true
      values:
        - ip: "10.96.188.4"
          hostnames:
          - "kcp.api.portal.dev.local"
```

**Important notes:**
- The **ServiceAccount name** in the ClusterRoleBinding must match the `releaseName` of the HelmRelease (the Helm chart creates the SA with this name).
- Do **NOT** include a Secret for the kubeconfig -- the PlatformMesh operator manages it automatically via `extraProviderConnections`.
- Pin the api-syncagent chart to `v0.4.4` -- v0.5.0 introduced a breaking change requiring `APIExportEndpointSlice` configuration.
- The `hostAliases` section is required for the local setup so the syncagent pods can resolve `kcp.api.portal.dev.local`.

#### 2.2 PublishedResource (`published-resource.yaml`)

This file is kept **separate** because it depends on the `PublishedResource` CRD which is only installed when the api-syncagent HelmRelease is ready. It is applied later in `start.sh`.

```yaml
# local-setup/kustomize/components/openbao-provider/published-resource.yaml
apiVersion: syncagent.kcp.io/v1alpha1
kind: PublishedResource
metadata:
  name: openbaotenant-provider
  namespace: openbao-provider
spec:
  resource:
    kind: OpenBaoTenant
    apiGroup: openbao.apeiro.dev
    version: v1
  naming:
    name: "{{ .ClusterName }}-{{ .Object.metadata.name | sha3short }}"
```

**Critical: Naming for cluster-scoped resources**

The default naming template is:
```
Name:      {{ .Object.metadata.namespace | sha3short }}-{{ .Object.metadata.name | sha3short }}
Namespace: {{ .ClusterName }}
```

This fails for **cluster-scoped** resources because `.Object.metadata.namespace` is nil. You **must** provide an explicit `naming` section that doesn't reference namespace. The recommended pattern is:

```yaml
naming:
  name: "{{ .ClusterName }}-{{ .Object.metadata.name | sha3short }}"
```

This includes the KCP cluster name to avoid naming collisions when multiple consumer workspaces create resources with the same name.

> For **namespace-scoped** resources (like HttpBin), the default naming works fine and no `naming` section is needed.

#### 2.3 Kustomization (`kustomization.yaml`)

```yaml
# local-setup/kustomize/components/openbao-provider/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - helmreleases.yaml
```

> Note: `published-resource.yaml` is intentionally **not** included here. It is applied separately in `start.sh` after the syncagent CRD exists.

---

### Step 3: Register in the Example Data Overlay

Modify `local-setup/kustomize/overlays/example-data/kustomization.yaml` to include the new provider:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../components/platform-mesh-operator-resource
  - ../../components/example-httpbin-provider
  - ../../components/openbao-provider               # <-- ADD THIS

patches:
  - target:
      kind: PlatformMesh
      name: platform-mesh
      namespace: platform-mesh-system
    patch: |-
      apiVersion: your.api.version
      kind: PlatformMesh
      metadata:
        name: platform-mesh
        namespace: platform-mesh-system
      spec:
        kcp:
          extraProviderConnections:
            - endpointSliceName: ""
              path: root:providers:httpbin-provider
              secret: httpbin-kubeconfig
              namespace: example-httpbin-provider
              external: false
            - endpointSliceName: ""                  # <-- ADD THIS BLOCK
              path: root:providers:openbao-provider
              secret: openbao-kubeconfig
              namespace: openbao-provider
              external: false
          extraDefaultAPIBindings:
            - workspaceTypePath: root:account
              export: orchestrate.platform-mesh.io
              path: root:providers:httpbin-provider
            - workspaceTypePath: root:account         # <-- ADD THIS BLOCK
              export: openbao.apeiro.dev
              path: root:providers:openbao-provider
```

**What each section does:**

- **`extraProviderConnections`**: Tells the PlatformMesh operator to create a kubeconfig secret (`openbao-kubeconfig`) in the `openbao-provider` namespace, pointing to the KCP provider workspace. This is how the syncagent authenticates to KCP.
- **`extraDefaultAPIBindings`**: Automatically creates an APIBinding in new `root:account` workspaces so they can use the provider's API without manual binding.

---

### Step 4: Update the Start Script

Add the following to `local-setup/scripts/start.sh` inside the `if [ "$EXAMPLE_DATA" = true ]` block:

```bash
# Create KCP workspace for the provider
kubectl create-workspace openbao-provider --type=root:provider --ignore-existing \
  --server="https://kcp.api.portal.dev.local:8443/clusters/root:providers"

# Apply the KCP example data (APIExport, RBAC, ProviderMetadata)
kubectl apply -k $SCRIPT_DIR/../example-data/root/providers/openbao-provider \
  --server="https://kcp.api.portal.dev.local:8443/clusters/root:providers:openbao-provider"
```

Also add a wait for the HelmRelease and then apply the PublishedResource:

```bash
# Wait for the syncagent to be ready (this also installs the PublishedResource CRD)
kubectl wait --namespace default \
  --for=condition=Ready helmreleases \
  --timeout=280s openbao-api-syncagent

# Apply the PublishedResource AFTER the CRD exists
echo -e "${COL}[$(date '+%H:%M:%S')] Applying openbao PublishedResource (requires api-syncagent CRD) ${COL_RES}"
kubectl apply -f $SCRIPT_DIR/../kustomize/components/openbao-provider/published-resource.yaml
```

> **Order matters**: The `PublishedResource` CRD is created by the api-syncagent Helm chart. If you try to apply the PublishedResource before the HelmRelease is ready, you'll get: `no matches for kind "PublishedResource" in version "syncagent.kcp.io/v1alpha1"`.

---

### Step 5: Install the CRD on the Local Cluster

The syncagent needs the CRD to be present on the local cluster so it can create synced copies. Make sure your CRD (e.g. `OpenBaoTenant`) is applied to the local cluster:

```bash
kubectl apply -f path/to/your/crd.yaml
```

Without the CRD, the syncagent will log: `could not find OpenBaoTenant.openbao.apeiro.dev in APIs`.

> In a production setup, the CRD would typically be installed by the operator's Helm chart or OCM component. For local dev, you may need to install it manually.

---

## Verification

### 1. Check the syncagent pods are running

```bash
kubectl get pods -n openbao-provider
# Expected: 2 pods, 1/1 Ready
```

### 2. Check the PublishedResource is applied

```bash
kubectl get publishedresource -n openbao-provider
# Expected: openbaotenant-provider
```

### 3. Check syncagent logs for errors

```bash
kubectl logs -n openbao-provider -l app.kubernetes.io/instance=openbao-api-syncagent --tail=30
# Look for: "engaging cluster" (good) or errors (bad)
```

### 4. Test end-to-end sync

```bash
# Set KCP kubeconfig
export KUBECONFIG=.secret/kcp/admin.kubeconfig

# Create a test consumer workspace
kubectl create-workspace test-consumer --type=root:account --ignore-existing \
  --server="https://kcp.api.portal.dev.local:8443/clusters/root"

# Bind to the provider API
cat <<EOF | kubectl apply --server="https://kcp.api.portal.dev.local:8443/clusters/root:test-consumer" -f -
apiVersion: apis.kcp.io/v1alpha1
kind: APIBinding
metadata:
  name: openbao-binding
spec:
  reference:
    export:
      path: root:providers:openbao-provider
      name: openbao.apeiro.dev
EOF

# Create a test resource
cat <<EOF | kubectl apply --server="https://kcp.api.portal.dev.local:8443/clusters/root:test-consumer" -f -
apiVersion: openbao.apeiro.dev/v1
kind: OpenBaoTenant
metadata:
  name: test-tenant2
  namespace: test2
spec:
  namespace: test2
  workspaceRef:
    name: test
  auth:
    appRole:
      secretRef:
        name: my-approle-secret
EOF

# Switch back to local cluster and verify the sync
unset KUBECONFIG
kubectl get openbaotenants.openbao.apeiro.dev -A
# Expected: a synced copy with name like: <cluster-id>-<hash>
```

---

## Common Pitfalls and Troubleshooting

### 1. "No matches for kind PublishedResource"
**Cause**: Trying to apply the PublishedResource before the api-syncagent HelmRelease is ready.
**Fix**: Keep `published-resource.yaml` out of the kustomization and apply it in `start.sh` after waiting for the HelmRelease.

### 2. Pods stuck in ContainerCreating
**Cause**: The kubeconfig secret doesn't exist yet.
**Fix**: Don't create the secret manually. The PlatformMesh operator creates it automatically via `extraProviderConnections`. Make sure the PlatformMesh resource is ready first.

### 3. Kubeconfig secret gets overwritten
**Cause**: Re-running `kubectl apply -k` with a static secret in the kustomization overwrites the operator-managed secret.
**Fix**: Never include the kubeconfig Secret in your kustomization. If it happens, delete the stale secret and trigger PlatformMesh reconciliation:
```bash
kubectl delete secret openbao-kubeconfig -n openbao-provider
kubectl annotate platformmesh platform-mesh -n platform-mesh-system reconcile=$(date +%s) --overwrite
```

### 4. RBAC permission denied for the syncagent
**Cause**: The ServiceAccount name in the ClusterRoleBinding doesn't match the actual SA created by the Helm chart.
**Fix**: The SA name is derived from the `releaseName` in the HelmRelease. If your release name is `openbao-api-syncagent`, the SA will be `openbao-api-syncagent`. Check with:
```bash
kubectl get sa -n openbao-provider
```

### 5. "sha3short: invalid value; expected string" naming error
**Cause**: The resource is cluster-scoped (no namespace), and the default naming template tries to hash the namespace which is nil.
**Fix**: Add explicit `naming` to the PublishedResource:
```yaml
spec:
  naming:
    name: "{{ .ClusterName }}-{{ .Object.metadata.name | sha3short }}"
```

### 6. api-syncagent v0.5.0 breaking change
**Cause**: Chart version 0.5.0 requires `APIExportEndpointSlice` name configuration.
**Fix**: Pin the chart version to `"0.4.4"` in the HelmRelease spec.

---

## File Summary

| File | Purpose |
|------|---------|
| `example-data/root/providers/openbao-provider/apiexport.yaml` | KCP APIExport definition |
| `example-data/root/providers/openbao-provider/rbac.yaml` | KCP RBAC for APIExport binding |
| `example-data/root/providers/openbao-provider/providermetadata.yaml` | Portal UI metadata |
| `example-data/root/providers/openbao-provider/kustomization.yaml` | Kustomize for KCP resources |
| `kustomize/components/openbao-provider/helmreleases.yaml` | Namespace, RBAC, api-syncagent HelmRelease |
| `kustomize/components/openbao-provider/published-resource.yaml` | What resource to sync (applied separately) |
| `kustomize/components/openbao-provider/kustomization.yaml` | Kustomize for local cluster resources |
| `kustomize/overlays/example-data/kustomization.yaml` | Registers provider in PlatformMesh (modified) |
| `scripts/start.sh` | Creates KCP workspace, waits, applies PublishedResource (modified) |
