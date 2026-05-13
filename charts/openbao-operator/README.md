# OpenBao Operator Helm Chart

Kubernetes operator with built-in multicluster runtime for managing OpenBaoTenant resources.

## Purpose

This chart deploys the OpenBao operator which:
- Manages `OpenBaoTenant` custom resources
- Creates isolated OpenBao namespaces per tenant
- Provisions authentication methods (AppRole, OIDC)
- Generates credentials and stores them as Kubernetes Secrets
- **Native multicluster support** via KCP integration (no api-syncagent needed)

## Key Feature: Built-in Multicluster Runtime

Unlike other operators, this operator has **native KCP support**:
- Uses `github.com/kcp-dev/multicluster-provider` for APIExport discovery
- Uses `sigs.k8s.io/multicluster-runtime` for cross-cluster reconciliation
- Watches `APIExportEndpointSlice` to discover logical clusters
- Reconciles OpenBaoTenant resources in any workspace where APIExport is bound

**No api-syncagent required!**

## Installation

```bash
# Requires openbao-instance to be running
helm install openbao-operator charts/openbao-operator \
  -n openbao-provider
```

## Configuration

### Key Values

```yaml
# Operator configuration
operator:
  # OpenBao connection
  openbaoAddress: "http://openbao.openbao-provider.svc:8200"
  openbaoAuthMethod: "kubernetes"  # kubernetes or token
  openbaoK8sRole: "openbao-operator"

  # Multicluster runtime
  apiexportEndpointsliceName: "openbao.apeiro.dev"  # APIExportEndpointSlice to watch

  # Resources
  resources:
    limits:
      cpu: 500m
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 64Mi

# RBAC
rbac:
  enable: true

# Leader election
leaderElection:
  enabled: true
```

## OpenBaoTenant CRD

The operator reconciles `OpenBaoTenant` resources:

```yaml
apiVersion: openbao.apeiro.dev/v1
kind: OpenBaoTenant
metadata:
  name: my-app
spec:
  namespace: my-app          # OpenBao namespace to create
  auth:
    appRole:                 # Machine authentication
      enabled: true
      secretRef:
        name: my-app-approle
        namespace: default
```

**Operator Actions:**
1. Creates OpenBao namespace `my-app/`
2. Enables AppRole auth method in that namespace
3. Generates RoleID and SecretID
4. Stores credentials in Kubernetes Secret `my-app-approle`
5. Updates tenant status with access information

## How Multicluster Works

### 1. APIExport in KCP

APIExport created in `root:providers:openbao-provider` workspace:

```yaml
apiVersion: apis.kcp.io/v1alpha1
kind: APIExport
metadata:
  name: openbao.apeiro.dev
```

### 2. Operator Discovery

Operator watches for APIExportEndpointSlice with name `openbao.apeiro.dev`:

```bash
--apiexport-endpointslice-name=openbao.apeiro.dev
```

### 3. Logical Cluster Resolution

When OpenBaoTenant created in org workspace:
1. KCP binds APIExport to org workspace via APIBinding
2. APIExportEndpointSlice updated with org workspace endpoint
3. Operator discovers the new logical cluster
4. Operator watches for OpenBaoTenant in that cluster
5. Operator reconciles tenant against OpenBao instance

## Authentication Methods

### Kubernetes Auth (Default)

Operator uses its ServiceAccount token to authenticate to OpenBao:

```yaml
operator:
  openbaoAuthMethod: "kubernetes"
  openbaoK8sRole: "openbao-operator"
```

**Prerequisites:**
- Init job must configure Kubernetes auth in OpenBao
- Operator role must be created with appropriate permissions

### Token Auth (Development Only)

For testing, you can use a static token:

```yaml
operator:
  openbaoAuthMethod: "token"
env:
  - name: OPENBAO_TOKEN
    value: "root"  # or from secret
```

**Not recommended for production!**

## Verification

```bash
# Check operator is running
kubectl get pods -n openbao-provider -l control-plane=controller-manager

# Check operator logs
kubectl logs -n openbao-provider deployment/openbao-operator

# Expected: "OpenBao health check OK" and "starting manager"

# Check CRD is installed
kubectl get crd openbaotenants.openbao.apeiro.dev

# Create a test tenant
kubectl apply -f examples/tenant.yaml

# Check tenant status
kubectl get openbaotenant my-app -o yaml
```

## Troubleshooting

### Operator Can't Authenticate to OpenBao

**Symptoms:** Logs show "403 Forbidden"

**Check:**
```bash
kubectl logs -n openbao-provider deployment/openbao-operator | grep -i auth
```

**Verify K8s auth is configured:**
```bash
kubectl exec -n openbao-provider deployment/openbao-instance -- bao auth list
kubectl exec -n openbao-provider deployment/openbao-instance -- \
  bao read auth/kubernetes/role/openbao-operator
```

**Fix:** Ensure init job completed successfully.

### Tenant Stuck in Pending

**Symptoms:** OpenBaoTenant never reaches Ready status

**Check:**
```bash
kubectl describe openbaotenant my-app
kubectl logs -n openbao-provider deployment/openbao-operator | grep my-app
```

**Common causes:**
- Operator authentication issues
- Invalid namespace name
- Namespace already exists in OpenBao

### Multicluster Discovery Not Working

**Symptoms:** Operator doesn't see tenants created in KCP

**Check:**
```bash
kubectl logs -n openbao-provider deployment/openbao-operator | grep -i "apiexport\|cluster"
```

**Verify APIExport exists:**
```bash
KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get apiexport openbao.apeiro.dev \
  --server=https://localhost:8443/clusters/root:providers:openbao-provider
```

**Check operator flag:**
```bash
kubectl get deployment openbao-operator -n openbao-provider -o yaml | \
  grep apiexport-endpointslice-name
```

## RBAC Permissions

The operator requires:

- **OpenBaoTenant**: Full CRUD + status/finalizers
- **Secrets**: Create, read, update, delete (for storing credentials)
- **Events**: Create, patch (for recording events)
- **Leases** (coordination.k8s.io): Leader election

See [templates/rbac/](templates/rbac/) for complete RBAC manifests.

## Chart Values Reference

See [values.yaml](values.yaml) for complete list of configurable values.

## Related Charts

- [openbao-instance](../openbao-instance/README.md) - OpenBao server deployment

## Resources

- OpenBao Operator Source: `/home/ldeppewsl/docs/openbao/platform-mesh/git/openbao-operator/`
- Multicluster Runtime: https://github.com/kubernetes-sigs/multicluster-runtime
- KCP Multicluster Provider: https://github.com/kcp-dev/multicluster-provider
