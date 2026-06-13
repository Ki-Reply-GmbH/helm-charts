# Warning - Outdated

Don't use this, it is heavely outdated. It was originally written whhen the prerelease workflow used and not a loca OCI registry. The approach and code has changed a lot since  then.

Some sections were updated, most is still outdated!

Read README_LOCAL_SETUP.md instead!

# OpenBao Provider - Local Setup Guide

## Overview

The OpenBao provider integration brings secrets management capabilities to Platform Mesh. This guide walks you through deploying OpenBao in the local-setup environment and creating your first tenant.

**What gets deployed:**
- **OpenBao Instance** - Secrets management server running in dev mode
- **OpenBao Operator** - Kubernetes controller with built-in multicluster runtime that manages `OpenBaoTenant` resources

**Key Feature:** The operator uses native multicluster runtime support (no separate api-syncagent needed) to watch for OpenBaoTenant resources across all KCP logical clusters.

## Prerequisites

Before starting, ensure you have:

- `kubectl` CLI tool (v1.29+)
- `helm` CLI tool (v3.x)
- `docker` or `podman` (for operator image builds)
- and `kind` CLI tools (for building operator locally)
- Optional: `bao` CLI tool for testing (download from https://openbao.org/docs/install/)

### Install KCP kubectl plugin

```sh
# Via krew
kubectl krew index add kcp-dev https://github.com/kcp-dev/krew-index.git
kubectl krew install kcp-dev/kcp
kubectl krew install kcp-dev/ws
kubectl krew install kcp-dev/create-workspace

# Verify
kubectl create-workspace --help
kubectl ws --help
```

### Creating platform mesh cluster

From the root of the helm-charts repository:

```sh
# Full setup (recommended, deletes existing cluster and creates new one)
task local-setup:example-data

# Iterate on existing cluster (faster, preserves cluster state)
task local-setup:example-data:iterate
```

## Deployment Steps

### Step 1: Deploy Local-Setup with OpenBao Provider

```bash
cd /home/ldeppewsl/docs/openbao/platform-mesh/git/helm-charts/local-setup

# Start local-setup with example data (includes OpenBao provider)
./scripts/start.sh --example-data
```

**What happens:**
1. Kind cluster created with Flux and KCP
2. KCP workspace `root:providers:openbao-provider` created
3. OpenBao instance deployed in dev mode (namespace: `openbao-provider`)
4. Init job configures Kubernetes authentication in OpenBao
5. OpenBao operator deployed with multicluster runtime
6. Operator discovers KCP APIExport and begins watching for tenants

**Expected Duration:** 5-10 minutes (depending on your machine and internet speed)

### Step 2: Verify Deployment

#### Check Pods Running

```bash
kubectl get pods -n openbao-provider
```

**Expected output:**
```
NAME                                    READY   STATUS    RESTARTS   AGE
openbao-instance-xxxxxx                 1/1     Running   0          2m
openbao-operator-xxxxxx                 1/1     Running   0          1m
```

#### Check HelmReleases

```bash
kubectl get helmreleases -n default | grep openbao
```

**Expected output:**
```
openbao-instance   True     Release reconciliation succeeded
openbao-operator   True     Release reconciliation succeeded
```

#### Check OpenBao Status

```bash
kubectl exec -n openbao-provider deployment/openbao-instance -- bao status
```

**Expected output:**
```
Sealed: false
Initialized: true
...
```

#### Verify Init Job Success

```bash
kubectl get jobs -n openbao-provider
```

**Expected output:**
```
NAME                                COMPLETIONS   DURATION   AGE
openbao-instance-init-k8s-auth      1/1           15s        2m
```

#### Check KCP Workspace

```bash
cd /home/ldeppewsl/docs/openbao/platform-mesh/git/helm-charts/local-setup

KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get workspace openbao-provider \
  --server=https://localhost:8443/clusters/root:providers
```

**Expected output:**
```
NAME               TYPE           PHASE   URL
openbao-provider   root:provider  Ready   https://localhost:8443/clusters/root:providers:openbao-provider
```

#### Verify APIExport

```bash
KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get apiexport openbao.apeiro.dev \
  --server=https://localhost:8443/clusters/root:providers:openbao-provider
```

**Expected output:**
```
NAME                 AGE
openbao.apeiro.dev   3m
```

## Creating Your First Tenant

An OpenBaoTenant creates an isolated namespace in OpenBao with its own authentication and policies.

### Step 1: Create Tenant Resource

Create a file `my-first-tenant.yaml`:

```yaml
apiVersion: openbao.apeiro.dev/v1
kind: OpenBaoTenant
metadata:
  name: my-app-secrets
spec:
  namespace: my-app-secrets
  auth:
    appRole:
      enabled: true
      secretRef:
        name: my-app-approle
        namespace: default
```

Apply it to the KCP org workspace:

```bash
cd /home/ldeppewsl/docs/openbao/platform-mesh/git/helm-charts/local-setup

KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl apply -f my-first-tenant.yaml \
  --server=https://localhost:8443/clusters/root:orgs
```

**Expected output:**
```
openbaotenant.openbao.apeiro.dev/my-app-secrets created
```

### Step 2: Wait for Tenant to be Ready

```bash
KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl wait \
  --for=condition=Ready openbaotenant/my-app-secrets \
  --timeout=2m \
  --server=https://localhost:8443/clusters/root:orgs
```

**Expected output:**
```
openbaotenant.openbao.apeiro.dev/my-app-secrets condition met
```

### Step 3: Check Tenant Status

```bash
KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get openbaotenant my-app-secrets -o yaml \
  --server=https://localhost:8443/clusters/root:orgs
```

**Look for in status:**
```yaml
status:
  phase: Ready
  ready: true
  access:
    authMethod: approle
    openbaoURL: http://openbao.openbao-provider.svc:8200
    openbaoNamespace: my-app-secrets
    appRoleSecretRef:
      name: my-app-approle
      namespace: default
```

### Step 4: Verify Tenant Provisioning

Check that the OpenBao namespace was created:

```bash
kubectl exec -n openbao-provider deployment/openbao-instance -- bao namespace list
```

**Expected output should include:**
```
my-app-secrets/
```

Check that AppRole auth method is enabled:

```bash
kubectl exec -n openbao-provider deployment/openbao-instance -- \
  env BAO_NAMESPACE=my-app-secrets bao auth list
```

**Expected output:**
```
Path        Type       ...
----        ----       ...
approle/    approle    ...
token/      token      ...
```

## Using Secrets

Now that your tenant is provisioned, let's use it to store and retrieve secrets.

### Step 1: Retrieve AppRole Credentials

```bash
KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get secret my-app-approle \
  --server=https://localhost:8443/clusters/root:orgs \
  -o jsonpath='{.data.roleId}' | base64 -d && echo

KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get secret my-app-approle \
  --server=https://localhost:8443/clusters/root:orgs \
  -o jsonpath='{.data.secretId}' | base64 -d && echo
```

**Save these values** - you'll need them to authenticate.

### Step 2: Port-Forward to OpenBao

In a separate terminal:

```bash
kubectl port-forward -n openbao-provider svc/openbao 8200:8200
```

**Keep this running** in the background.

### Step 3: Authenticate with bao CLI

In your main terminal, set environment variables:

```bash
export BAO_ADDR=http://localhost:8200
export BAO_NAMESPACE=my-app-secrets

# Replace with your actual credentials from Step 1
export ROLE_ID="<your-roleId>"
export SECRET_ID="<your-secretId>"

# Authenticate and get a token
TOKEN=$(bao write -field=token auth/approle/login \
  role_id="$ROLE_ID" \
  secret_id="$SECRET_ID")

export BAO_TOKEN=$TOKEN
echo "Authenticated successfully!"
```

### Step 4: Create a Secret

```bash
bao kv put secret/database/config \
  username=dbuser \
  password=supersecret123 \
  host=db.example.com \
  port=5432
```

**Expected output:**
```
Success! Data written to: secret/database/config
```

### Step 5: Read the Secret

```bash
bao kv get secret/database/config
```

**Expected output:**
```
====== Data ======
Key         Value
---         -----
host        db.example.com
password    supersecret123
port        5432
username    dbuser
```

### Step 6: Read Secret as JSON

```bash
bao kv get -format=json secret/database/config | jq '.data'
```

**Expected output:**
```json
{
  "host": "db.example.com",
  "password": "supersecret123",
  "port": "5432",
  "username": "dbuser"
}
```

### Step 7: Using with curl (Alternative to bao CLI)

If you don't have the `bao` CLI, you can use `curl`:

```bash
# Authenticate
TOKEN=$(curl -s -X POST \
  -H "X-Vault-Namespace: my-app-secrets" \
  http://localhost:8200/v1/auth/approle/login \
  -d "{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" \
  | jq -r '.auth.client_token')

# Create a secret
curl -X POST \
  -H "X-Vault-Token: $TOKEN" \
  -H "X-Vault-Namespace: my-app-secrets" \
  http://localhost:8200/v1/secret/data/my-secret \
  -d '{"data": {"key1": "value1", "key2": "value2"}}'

# Read the secret
curl -s \
  -H "X-Vault-Token: $TOKEN" \
  -H "X-Vault-Namespace: my-app-secrets" \
  http://localhost:8200/v1/secret/data/my-secret | jq '.data.data'
```

## Cleanup

### Delete the Tenant

```bash
KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl delete openbaotenant my-app-secrets \
  --server=https://localhost:8443/clusters/root:orgs
```

**What happens:**
- Operator receives deletion event
- Operator runs finalizer to clean up OpenBao resources
- OpenBao namespace and auth methods are deleted
- Kubernetes Secret with credentials is deleted

### Verify Cleanup

```bash
kubectl exec -n openbao-provider deployment/openbao-instance -- bao namespace list
```

**Expected:** `my-app-secrets/` should NOT be in the list.

## Troubleshooting

### OpenBao Pod Not Starting

**Symptoms:** Pod in CrashLoopBackOff or Pending

**Check:**
```bash
kubectl describe pod -n openbao-provider -l app=openbao
kubectl logs -n openbao-provider -l app=openbao
```

**Common causes:**
- Image pull failure (check image name in HelmRelease)
- Resource limits too low
- Port 8200 already in use

**Fix:**
```bash
# Check events
kubectl get events -n openbao-provider --sort-by='.lastTimestamp'

# If resource limits too low, increase in HelmRelease values
# If image issue, verify image exists: docker pull openbao/openbao:2.1.0
```

### Init Job Failed

**Symptoms:** Job shows 0/1 completions

**Check:**
```bash
kubectl logs -n openbao-provider job/openbao-instance-init-k8s-auth
```

**Common causes:**
- OpenBao not ready when job ran
- Root token incorrect
- Network connectivity issue

**Fix:**
```bash
# Delete and re-run job (it's a Helm hook, will recreate on upgrade)
kubectl delete job -n openbao-provider openbao-instance-init-k8s-auth
helm upgrade openbao-instance charts/openbao-instance -n openbao-provider
```

### Operator Can't Authenticate

**Symptoms:** Operator logs show "403 Forbidden"

**Check:**
```bash
kubectl logs -n openbao-provider deployment/openbao-operator | grep -i "auth\|error"
```

**Common causes:**
- Init job didn't complete
- Kubernetes auth role not configured

**Fix:**
```bash
# Verify init job completed
kubectl get jobs -n openbao-provider

# Manually check if K8s auth is configured
kubectl exec -n openbao-provider deployment/openbao-instance -- bao auth list

# Check if operator role exists
kubectl exec -n openbao-provider deployment/openbao-instance -- \
  bao read auth/kubernetes/role/openbao-operator
```

### Tenant Stuck in Pending

**Symptoms:** OpenBaoTenant never reaches Ready status

**Check:**
```bash
KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl describe openbaotenant my-app-secrets \
  --server=https://localhost:8443/clusters/root:orgs

kubectl logs -n openbao-provider deployment/openbao-operator | grep my-app-secrets
```

**Common causes:**
- Operator authentication issues
- Invalid namespace name in spec
- Namespace already exists

**Fix:**
```bash
# Check operator can authenticate
kubectl logs -n openbao-provider deployment/openbao-operator | tail -20

# Check if namespace already exists
kubectl exec -n openbao-provider deployment/openbao-instance -- bao namespace list

# Restart operator if needed
kubectl rollout restart -n openbao-provider deployment/openbao-operator
```

### Can't Authenticate to OpenBao

**Symptoms:** "permission denied" when using AppRole credentials

**Check:**
```bash
# Verify credentials secret exists
KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get secret my-app-approle \
  --server=https://localhost:8443/clusters/root:orgs

# Verify AppRole is enabled in tenant namespace
kubectl exec -n openbao-provider deployment/openbao-instance -- \
  env BAO_NAMESPACE=my-app-secrets bao auth list
```

**Fix:**
```bash
# Get fresh credentials
ROLE_ID=$(KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get secret my-app-approle \
  -o jsonpath='{.data.roleId}' --server=https://localhost:8443/clusters/root:orgs | base64 -d)

SECRET_ID=$(KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get secret my-app-approle \
  -o jsonpath='{.data.secretId}' --server=https://localhost:8443/clusters/root:orgs | base64 -d)

# Try authenticating again with fresh credentials
```

### KCP Workspace Not Found

**Symptoms:** "workspace openbao-provider not found"

**Check:**
```bash
KUBECONFIG=.secret/kcp/admin.kubeconfig kubectl get workspaces \
  --server=https://localhost:8443/clusters/root:providers
```

**Fix:**
```bash
# Re-run start.sh to create workspace
./scripts/start.sh --example-data
```

## Next Steps

- **Learn More:** Check [/helm-charts/CLAUDE.md](../../CLAUDE.md) for detailed architecture and implementation details
- **Production Deployment:** See CLAUDE.md section on production considerations (Raft storage, HA, auto-unseal)
- **Advanced Auth Methods:** Explore OIDC authentication for human users
- **Monitoring:** Set up Prometheus ServiceMonitor for operator metrics

## Additional Resources

- OpenBao Documentation: https://openbao.org/docs/
- OpenBao Operator Source: `/home/ldeppewsl/docs/openbao/platform-mesh/git/openbao-operator/`
- Helm Charts: `/home/ldeppewsl/docs/openbao/platform-mesh/git/helm-charts/charts/openbao-*`
- KCP Documentation: https://docs.kcp.io/

## Support

For issues or questions:
- Check operator logs: `kubectl logs -n openbao-provider deployment/openbao-operator`
- Check OpenBao logs: `kubectl logs -n openbao-provider deployment/openbao-instance`
- Review CLAUDE.md troubleshooting section for detailed debugging steps
