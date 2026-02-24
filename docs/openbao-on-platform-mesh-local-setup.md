# OpenBao on Platform Mesh — Local Setup Guide

> Step-by-step guide for deploying OpenBao and the OpenBao Operator as a Managed Service Provider on a local Platform Mesh instance, including tenant provisioning and secret verification.

---

## Table of Contents

- [OpenBao on Platform Mesh — Local Setup Guide](#openbao-on-platform-mesh--local-setup-guide)
  - [Table of Contents](#table-of-contents)
  - [1. Prerequisites](#1-prerequisites)
    - [Install the KCP kubectl Plugin](#install-the-kcp-kubectl-plugin)
    - [Configure /etc/hosts](#configure-etchosts)
  - [2. Terminal Setup](#2-terminal-setup)
    - [Terminal 1 — Local Cluster (physical Kind cluster)](#terminal-1--local-cluster-physical-kind-cluster)
    - [Terminal 2 — KCP (virtual control plane)](#terminal-2--kcp-virtual-control-plane)
  - [3. Install the Local Platform Mesh](#3-install-the-local-platform-mesh)
  - [4. Install OpenBao in the Service Cluster](#4-install-openbao-in-the-service-cluster)
  - [5. Initialize and Unseal OpenBao](#5-initialize-and-unseal-openbao)
    - [Initialize](#initialize)
    - [Unseal](#unseal)
    - [Verify](#verify)
  - [6. Build and Load the OpenBao Operator Image](#6-build-and-load-the-openbao-operator-image)
  - [7. Deploy the OpenBao Operator](#7-deploy-the-openbao-operator)
    - [Verify](#verify-1)
  - [8. Configure the Operator with the OpenBao Root Token](#8-configure-the-operator-with-the-openbao-root-token)
    - [Verify the operator restarted with the new args](#verify-the-operator-restarted-with-the-new-args)
  - [9. Create an Organization and Account via the Portal](#9-create-an-organization-and-account-via-the-portal)
    - [Create an Organization](#create-an-organization)
    - [Create an Account](#create-an-account)
    - [Verify (Terminal 2)](#verify-terminal-2)
  - [10. Create the APIBinding for an Organization](#10-create-the-apibinding-for-an-organization)
    - [Verify](#verify-2)
  - [11. Create the APIBinding for an Account](#11-create-the-apibinding-for-an-account)
    - [Verify](#verify-3)
  - [12. Create an OpenBaoTenant (Organization Level)](#12-create-an-openbaotenant-organization-level)
  - [13. Create an OpenBaoTenant (Account Level)](#13-create-an-openbaotenant-account-level)
  - [14. Verify the Secret Was Synced to the Tenant Cluster](#14-verify-the-secret-was-synced-to-the-tenant-cluster)
    - [For the Organization](#for-the-organization)
    - [For the Account](#for-the-account)
  - [15. Use the Secret to Get a Token and Login via the UI](#15-use-the-secret-to-get-a-token-and-login-via-the-ui)
    - [Port-Forward OpenBao](#port-forward-openbao)
    - [Get a Token from OpenBao](#get-a-token-from-openbao)
      - [For the Organization Tenant](#for-the-organization-tenant)
      - [For the Account Tenant](#for-the-account-tenant)
    - [Login via the OpenBao UI](#login-via-the-openbao-ui)
  - [16. Troubleshooting](#16-troubleshooting)
    - [OpenBao pod stuck at 0/1 READY](#openbao-pod-stuck-at-01-ready)
    - [Operator pod is in ImagePullBackOff](#operator-pod-is-in-imagepullbackoff)
    - [APIBinding not becoming READY](#apibinding-not-becoming-ready)
    - [OpenBaoTenant not being processed](#openbaotenant-not-being-processed)
    - [Portal not reachable](#portal-not-reachable)
    - [KCP workspace commands not working](#kcp-workspace-commands-not-working)

---

## 1. Prerequisites

Before starting, ensure you have the following installed:

- **Docker** or **Podman** (for container image builds)
- **Kind** (Kubernetes in Docker — used by the local platform mesh)
- **kubectl** with the [KCP plugin](https://github.com/kcp-dev/kcp) (`kubectl kcp`, `kubectl ws`, `kubectl create-workspace`)
- **Helm** v3
- **Task** (taskfile runner — [taskfile.dev](https://taskfile.dev))
- **Make** (for building the operator)
- **Go** (for compiling the operator)
- **OpenBao CLI** (`bao`) — [install instructions](https://openbao.org/docs/install)
- **jq** (for JSON parsing)

### Install the KCP kubectl Plugin

```bash
# Via krew
kubectl krew index add kcp-dev https://github.com/kcp-dev/krew-index.git
kubectl krew install kcp-dev/kcp
kubectl krew install kcp-dev/ws
kubectl krew install kcp-dev/create-workspace

# Verify
kubectl create-workspace --help
kubectl ws --help
```

### Configure /etc/hosts

Ensure the following entries exist in `/etc/hosts`:

```
127.0.0.1 portal.dev.local default.portal.dev.local kcp.api.portal.dev.local
```

```bash
# Add if missing
sudo sh -c 'echo "127.0.0.1 portal.dev.local default.portal.dev.local kcp.api.portal.dev.local test.portal.dev.local" >> /etc/hosts'
```

---

## 2. Terminal Setup

Throughout this guide you will work with **two terminal windows** simultaneously. Set them up now and keep them open for the entire process.

### Terminal 1 — Local Cluster (physical Kind cluster)

This terminal is for interacting with the actual Kubernetes cluster where OpenBao and the operator run.

```bash
# Use the default Kind kubeconfig
kubectl config use-context kind-platform-mesh

# Verify
kubectl get nodes
```

### Terminal 2 — KCP (virtual control plane)

This terminal is for interacting with KCP workspaces where organizations, accounts, APIBindings, and tenants live.

```bash
# Set the KCP kubeconfig (from the helm-charts repo root)
export KUBECONFIG=$(pwd)/.secret/kcp/admin.kubeconfig

# Verify
kubectl ws tree
```

> **Important:** Never mix these up. If a command interacts with pods, deployments, or Helm — use **Terminal 1**. If it interacts with workspaces, APIBindings, or tenants — use **Terminal 2**.

---

## 3. Install the Local Platform Mesh

**Terminal 1** — From the root of the `helm-charts` repository:

```bash
task local-setup:example-data
```

This command:
- Creates a Kind cluster named `platform-mesh`
- Deploys the Platform Mesh operator, KCP, Keycloak, Traefik, and supporting infrastructure
- Sets up the example httpbin provider and the openbao-provider workspace in KCP
- Deploys the API Sync Agent

Wait for the installation to complete. Once finished, verify:

```bash
# Confirm the Kind cluster is running
kubectl cluster-info --context kind-platform-mesh

# Confirm platform-mesh pods are healthy
kubectl get pods -n platform-mesh-system

# Confirm the onboarding portal is reachable
curl -k https://portal.dev.local:8443
```

**Terminal 2** — Verify KCP is accessible:

```bash
export KUBECONFIG=$(pwd)/.secret/kcp/admin.kubeconfig
kubectl ws tree
```

You should see the workspace hierarchy including `root:providers:httpbin-provider` and `root:providers:openbao-provider`.

---

## 4. Install OpenBao in the Service Cluster

**Terminal 1:**

```bash
# Add the OpenBao Helm repo
helm repo add openbao https://openbao.github.io/openbao-helm
helm repo update

# Install OpenBao
helm install openbao openbao/openbao -n openbao --create-namespace

# Verify the pod is running (it will show 0/1 READY until initialized)
kubectl get pods -n openbao
```

Expected output:

```
NAME        READY   STATUS    RESTARTS   AGE
openbao-0   0/1     Running   0          30s
```

---

## 5. Initialize and Unseal OpenBao

**Terminal 1:**

### Initialize

```bash
kubectl exec -n openbao openbao-0 -- bao operator init -key-shares=1 -key-threshold=1
```

**Save the output!** You will need both values:

```
Unseal Key 1: <UNSEAL_KEY>
Initial Root Token: <ROOT_TOKEN>
```

> ⚠️ **Important:** Store these securely. The root token is needed to configure the operator and the unseal key is needed every time the pod restarts.

### Unseal

```bash
kubectl exec -n openbao openbao-0 -- bao operator unseal <UNSEAL_KEY>
```

### Verify

```bash
kubectl get pods -n openbao
```

Expected output — the pod should now be `1/1 READY`:

```
NAME        READY   STATUS    RESTARTS   AGE
openbao-0   1/1     Running   0          2m
```

---

## 6. Build and Load the OpenBao Operator Image

**Terminal 1** — From the root of the **openbao-operator** source repository:

```bash
# Build the container image
make docker-build IMG=localhost/openbao-operator:local

# Export and load into the Kind cluster
podman save localhost/openbao-operator:local -o /tmp/openbao-operator.tar
kind load image-archive /tmp/openbao-operator.tar --name platform-mesh
```

> **Note:** If you use Docker instead of Podman, replace `podman save` with `docker save`.

---

## 7. Deploy the OpenBao Operator

**Terminal 1** — Still from the openbao-operator repository:

```bash
# Install the CRDs (OpenBaoTenant etc.)
make install

# Deploy the operator
make deploy IMG=localhost/openbao-operator:local

# Patch the deployment to use the local image (prevent image pull attempts)
kubectl patch deployment -n openbao-operator-system openbao-operator-controller-manager \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"manager","imagePullPolicy":"Never"}]}}}}'
```

### Verify

```bash
kubectl get pods -n openbao-operator-system
```

Expected output:

```
NAME                                                       READY   STATUS    RESTARTS   AGE
openbao-operator-controller-manager-xxxxx-yyyyy            1/1     Running   0          30s
```

---

## 8. Configure the Operator with the OpenBao Root Token

**Terminal 1:**

The operator needs to know the OpenBao address and authentication token. Patch the deployment to inject these as CLI arguments:

```bash
kubectl patch deployment openbao-operator-controller-manager -n openbao-operator-system \
  --type='json' -p='[
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--openbao-address=http://openbao.openbao.svc.cluster.local:8200"},
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--openbao-token=<YOUR_ROOT_TOKEN>"}
  ]'
```

> Replace `<YOUR_ROOT_TOKEN>` with the root token from [Step 5](#5-initialize-and-unseal-openbao).

### Verify the operator restarted with the new args

```bash
kubectl get pods -n openbao-operator-system -w
```

Wait for the new pod to be `1/1 READY`.

---

## 9. Create an Organization and Account via the Portal

Open the Platform Mesh onboarding portal in your browser:

```
https://portal.dev.local:8443
```

> Accept the self-signed certificate warning.

### Create an Organization

1. Log in to the portal (default credentials depend on your Keycloak configuration)
2. Navigate to the organization creation page
3. Create a new organization, e.g. **`test`**

This creates a KCP workspace at `root:orgs:test`.

### Create an Account

1. Within the organization, create a new account, e.g. **`test-acc`**

This creates a nested KCP workspace at `root:orgs:test:test-acc`.

### Verify (Terminal 2)

```bash
kubectl ws tree
```

You should see `root:orgs:test` and `root:orgs:test:test-acc` in the workspace tree.

---

## 10. Create the APIBinding for an Organization

The APIBinding connects the consumer workspace to the OpenBao provider, making the `OpenBaoTenant` CRD available in that workspace.

**Terminal 2:**

```bash
# Switch to the organization workspace
kubectl ws root:orgs:test
```

Apply the APIBinding:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apis.kcp.io/v1alpha1
kind: APIBinding
metadata:
  name: openbao-binding
spec:
  reference:
    export:
      path: root:providers:openbao-provider
      name: openbao.apeiro.dev
  permissionClaims:
    - group: ""
      identityHash: ""
      resource: secrets
      state: Accepted
      all: true
    - group: ""
      identityHash: ""
      resource: namespaces
      state: Accepted
      all: true
    - group: ""
      identityHash: ""
      resource: events
      state: Accepted
      all: true
EOF
```

### Verify

```bash
kubectl get apibindings
```

The `openbao-binding` should show `READY: True`.

---

## 11. Create the APIBinding for an Account

**Terminal 2:**

```bash
# Switch to the account workspace
kubectl ws root:orgs:test:test-acc
```

Apply the APIBinding:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apis.kcp.io/v1alpha1
kind: APIBinding
metadata:
  name: openbao-account-binding
spec:
  reference:
    export:
      path: root:providers:openbao-provider
      name: openbao.apeiro.dev
  permissionClaims:
    - group: ""
      identityHash: ""
      resource: secrets
      state: Accepted
      all: true
    - group: ""
      identityHash: ""
      resource: namespaces
      state: Accepted
      all: true
    - group: ""
      identityHash: ""
      resource: events
      state: Accepted
      all: true
EOF
```

### Verify

```bash
kubectl get apibindings
```

---

## 12. Create an OpenBaoTenant (Organization Level)

With the APIBinding in place, the `OpenBaoTenant` CRD is now available in the organization workspace.

**Terminal 2:**

```bash
# Make sure you're in the org workspace
kubectl ws root:orgs:test
```

Create the tenant:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: openbao.apeiro.dev/v1
kind: OpenBaoTenant
metadata:
  name: test-org-tenant
  namespace: my-awesome-org
spec:
  namespace: my-awesome-org
  workspaceRef:
    name: test
  auth:
    appRole:
      secretRef:
        name: my-extra-awesome-secret
        namespace: default
EOF
```

The OpenBao operator (via the API Sync Agent) will:
1. Pick up this resource from KCP
2. Create a namespace in OpenBao for the tenant
3. Configure an AppRole auth method
4. Write the AppRole credentials (role_id and secret_id) into a Kubernetes Secret
5. Sync the secret back to the KCP workspace

---

## 13. Create an OpenBaoTenant (Account Level)

**Terminal 2:**

```bash
# Switch to the account workspace
kubectl ws root:orgs:test:test-acc
```

Create the tenant:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: openbao.apeiro.dev/v1
kind: OpenBaoTenant
metadata:
  name: test-account-tenant
  namespace: my-awesome-account
spec:
  namespace: my-awesome-account
  workspaceRef:
    name: test
  auth:
    appRole:
      secretRef:
        name: my-awesome-secret
        namespace: default
EOF
```

---

## 14. Verify the Secret Was Synced to the Tenant Cluster

After the operator processes the `OpenBaoTenant`, it creates a Kubernetes Secret containing the AppRole credentials.

**Terminal 2:**

### For the Organization

```bash
kubectl ws root:orgs:test
kubectl get secrets -n default
```

Look for a secret named `my-extra-awesome-secret`.

```bash
kubectl get secret my-extra-awesome-secret -n default -o yaml
```

### For the Account

```bash
kubectl ws root:orgs:test:test-acc
kubectl get secrets -n default
```

Look for a secret named `my-awesome-secret`.

```bash
kubectl get secret my-awesome-secret -n default -o yaml
```

The secret should contain `role-id` and `secret-id` keys.

---

## 15. Use the Secret to Get a Token and Login via the UI

### Port-Forward OpenBao

**Terminal 1:**

```bash
kubectl port-forward openbao-0 8200:8200 -n openbao
```

Leave this running.

### Get a Token from OpenBao

**Terminal 2:**

Make sure you set the `BAO_ADDR` environment variable:

```bash
export BAO_ADDR=http://localhost:8200
```

#### For the Organization Tenant

```bash
kubectl ws root:orgs:test

BAO_NAMESPACE=my-awesome-org bao write auth/approle/login \
  role_id=$(kubectl get secret my-extra-awesome-secret -o json | jq -r '.data["role-id"] | @base64d') \
  secret_id=$(kubectl get secret my-extra-awesome-secret -o json | jq -r '.data["secret-id"] | @base64d')
```

#### For the Account Tenant

```bash
kubectl ws root:orgs:test:test-acc

BAO_NAMESPACE=my-awesome-account bao write auth/approle/login \
  role_id=$(kubectl get secret my-awesome-secret -o json | jq -r '.data["role-id"] | @base64d') \
  secret_id=$(kubectl get secret my-awesome-secret -o json | jq -r '.data["secret-id"] | @base64d')
```

The output will contain a `client_token`:

```
Key                     Value
---                     -----
token                   hvs.CAESIG...
token_accessor          ...
token_duration          768h
token_renewable         true
token_policies          ["default", "my-awesome-account-policy"]
```

### Login via the OpenBao UI

1. Open **http://localhost:8200/ui** in your browser
2. Select the **Token** authentication method
3. Paste the `token` value from the previous step
4. Click **Sign In**

You should now be logged in with the tenant's scoped permissions, restricted to the tenant's namespace in OpenBao.

---

## 16. Troubleshooting

### OpenBao pod stuck at 0/1 READY

**Terminal 1** — The pod needs to be unsealed after every restart:

```bash
kubectl exec -n openbao openbao-0 -- bao operator unseal <UNSEAL_KEY>
```

### Operator pod is in ImagePullBackOff

**Terminal 1:**

```bash
kind load image-archive /tmp/openbao-operator.tar --name platform-mesh

kubectl patch deployment -n openbao-operator-system openbao-operator-controller-manager \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"manager","imagePullPolicy":"Never"}]}}}}'
```

### APIBinding not becoming READY

**Terminal 2:**

```bash
kubectl ws root:providers:openbao-provider
kubectl get apiexports
kubectl get apiexport openbao.apeiro.dev -o yaml
```

If the `latestResourceSchemas` field is empty, the sync agent hasn't populated it yet. Check the sync agent logs in **Terminal 1**:

```bash
kubectl logs -n openbao-provider -l app=api-syncagent --tail=100
```

### OpenBaoTenant not being processed

**Terminal 1** — Check the operator logs:

```bash
kubectl logs -n openbao-operator-system -l control-plane=controller-manager --tail=100
```

Verify the resource was synced from KCP to the physical cluster:

```bash
kubectl get openbaotenants -A
```

### Portal not reachable

**Terminal 1:**

```bash
grep portal /etc/hosts
kubectl get gateways -n platform-mesh-system
kubectl get httproutes -n platform-mesh-system
```

The portal should be accessible at `https://portal.dev.local:8443`.

### KCP workspace commands not working

**Terminal 2** — Ensure the kubeconfig is set:

```bash
export KUBECONFIG=$(pwd)/.secret/kcp/admin.kubeconfig
kubectl ws tree
```