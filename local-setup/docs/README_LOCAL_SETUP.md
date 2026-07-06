
# Current workflow for local setup

## Prerequisites

Before starting, ensure you have the following installed:

- **Docker** or **Podman** (for container image builds)
- **Kind** (Kubernetes in Docker — used by the local platform mesh)
- **kubectl** with the [KCP plugin](https://github.com/kcp-dev/kcp) (`kubectl kcp`, `kubectl ws`, `kubectl create-workspace`)
- **Helm** v3
- **Task** (taskfile runner — [taskfile.dev](https://taskfile.dev))
- **Make** (for building the operator)
- **Go** (for compiling the operator)
- **jq** (for JSON parsing)
- **krew** - [install instructions](https://krew.sigs.k8s.io/)

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

## Build operator image

```bash
git clone -b  local-platform-mesh-operator --single-branch https://github.tools.sap/ApeiroRA/openbao-kcp-operator.git
cd openbao-kcp-operator
docker build --no-cache -t openbao-operator:local . 
```
-> this image will be loaded into kind cluster during start script
-> use --no-cache flag to make sure that recent changes are used

## Clone repo
```bash
# only needed branch
git clone -b  feat/openbao-multicluster-local-setup-pl-ocm-version-0-3-0 --single-branch https://github.com/Ki-Reply-GmbH/helm-charts.git 
cd openbao-kcp-operator

# or full repo (slower)
git clone https://github.com/Ki-Reply-GmbH/helm-charts.git
cd helm-charts
git checkout feat/openbao-multicluster-local-setup-pl-ocm-version-0-3-0
```

## Start standard flow
```bash
task local-setup:example-data
```
Note: This will take around 10 to 15 minutes to finish! 

Right at start you need to confirm the deletion of "platform-mesh" kind cluster if it already exists. Besides that there is no interaction needed.

## to continue without recreating everything (after initial setup)
```bash
task local-setup:example-data:iterate
```

## access platform mesh
when finished go to https://portal.localhost:8443/

## workflow in local platform mesh
1. Run task local-setup:example-data (fresh cluster) or task local-setup:example-data:iterate (update cluster)
2. When finished go to https://portal.localhost:8443/
3. There, register a new user (follow the instructions in UI)
4. Create a new organization
5. Important: Wait around 5 to 10 minutes now (if you proceed fast, you may encounter the unability to view the required "accounts" tab in local platform mesh, caused by a race condition around the initial invite email in the background)
6. Switch to your new organization in the UI (this changes the browser URL)
7. Login with your user, default password is "password" (follow the instructions in UI)
8. Create new account, click on the account when its ready
9. Currently not needed: Enable/install OpenBao in the Marketplace, refresh browser tab afterwards
10. Got to "OpenBao Tenants" tab and create new OpenBao instance - use for example:

name: openbaotest
secret: openbaotest-approle
secret-namespace: default

11. Click on the Tenant when its ready, you are now in the Dashboard of it (you can see here the namespace that you need later)
12. Click on the link in the tenant -> you are now in the standard OpenBao UI
13. (Only when cluster / kind container was stopped and re-started:) Unseal OpenBao

Retrieve key from cluster:
```bash
kubectl get secret openbao-unseal-key -n openbao-provider -o jsonpath='{.data.key}' | base64 -d
```
In this local setup, OpenBao is initialized with 1 key share and threshold 1, so that value is your full unseal key / unseal key portion.

14. Login to namespace
Copy namespace from OpenBao tenants's dashboard
Retrieve root token from cluster:
```bash
kubectl get secret openbao-root-token -n openbao-provider -o jsonpath='{.data.token}' | base64 -d
```

15. You should now be logged in in your cluster and can use OpenBao. 
Hint: Since OpenBao is running in regular mode, your changes will be saved as long as the kind cluster isn't deleted or recreated. If the kind container stops or get paused, OpenBao will seal automatically.










# Misc
## Platform mesh operator doesn't get ready whhen cluster is updated or continued after stopping it
Check OpenBao if it's sealed. If yes, that behaviour is expected and completely normal.
The operator need the OpenBao instance to be unsealed to get ready. 
OpenBao instance will automatically get unsealed when running "task local-setup:example-data". 
If your cluster doesn't get unsealed automatically, retrieve the key and seal it manually. The OpenBao operator pod should get ready soom afterwards.

## Check OpenBao status
```bash
kubectl exec -n openbao-provider deployment/openbao-instance -- bao status
```

## Unsealing
retrieve unseal keal
```bash
kubectl get secret openbao-unseal-key -n openbao-provider -o jsonpath='{.data.key}' | base64 -d
```
In this local setup, OpenBao is initialized with 1 key share and threshold 1, so that value is your full unseal key / unseal key portion.


## OCM pin precheck (automatic)
For non-prerelease local setup tasks, an OCM precheck now runs automatically before `start.sh`.
It validates that the pinned version in `local-setup/kustomize/components/ocm/component.yaml` still exists in GHCR.

If the version was removed, setup stops early and prints the latest available version plus a hint to run:

```bash
task bump-local-setup-component-version
task local-setup:example-data
```

For `--prerelease` tasks, this precheck is skipped.

# bug fixing

## Openbao-operator IP hard coded
You might need to set your local cluster IP of KCP correctly here:

local-setup/kustomize/components/openbao-provider/helmreleases.yaml (line 63)

# Outdated - needs review and experimentation

# Use OpenBao
To use OpenBao in the local kind setup, open the local Gateway route in your browser:

https://openbao.services.portal.localhost:8443/ui

There you need to authenticate.

Your namespace is orgs/<organisation>/<user-account>, e.g something like orgs/test/user1.

If the Gateway route is not available, use port-forwarding as a fallback:

```bash
kubectl port-forward svc/openbao -n openbao-provider 8200:8200
```

After that, go to http://localhost:8200/ui in your browser.

You must also retrieve your token:

```bash
kubectl get secret openbao-root-token -n openbao-provider -o jsonpath='{.data.token}' | base64 -d
```



# Short workflow (summary)
The operator image must be already existing!
1. run: task local-setup:example-data
2. Go to [localhost](https://portal.localhost:8443/), register
3. Create new org, click Switch when ready
4. In a terminal, run the invite poll below (takes ~5–15 seconds typically)
5. Once the invite is confirmed → create account
6. When account is ready → create OpenBao Tenant

## invite poll
```bash
# Replace <orgname> with your org name (the subdomain you see in the URL)
until kubectl get invites.core.platform-mesh.io \
  --server https://localhost:8443/clusters/root:orgs:<orgname> \
  -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q "Completed\|Ready\|Accepted"; do
  echo "Waiting for invite to be processed..."; sleep 3
done
echo "Done — safe to create account"
```

If you don't know the exact status value, first just wait for the invite to exist and have any status:

```bash
until kubectl get invites.core.platform-mesh.io \
  --server https://localhost:8443/clusters/root:orgs:<orgname> 2>/dev/null | grep -q "."; do
  echo "Waiting for invite..."; sleep 3
done
```

### code for organisation "liquid"
```bash

until kubectl get invites.core.platform-mesh.io \
  --server https://localhost:8443/clusters/root:orgs:liquid \
  -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q "Completed\|Ready\|Accepted"; do
  echo "Waiting for invite to be processed..."; sleep 3
done
echo "Done — safe to create account"

# If you don't know the exact status value, first just wait for the invite to exist and have any status:

until kubectl get invites.core.platform-mesh.io \
  --server https://localhost:8443/clusters/root:orgs:liquid 2>/dev/null | grep -q "."; do
  echo "Waiting for invite..."; sleep 3
done
```
