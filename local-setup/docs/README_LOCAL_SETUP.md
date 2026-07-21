
# Current workflow for local setup

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

## Pinned OCM release archive (automatic)

Non-prerelease local setup tasks download and checksum-verify the immutable
`platform-mesh-0.3.0.ctf.tgz` asset from the
[`Ki-Reply-GmbH/helm-charts` 0.3.0 release](https://github.com/Ki-Reply-GmbH/helm-charts/releases/tag/0.3.0)
before `start.sh` can remove an existing
cluster. It is an OCM Common Transport Format archive, not source code; it is an OCM repository snapshot. The archive is cached under `local-setup/assets/` and imported into a
local OCI registry during setup; the Platform Mesh component itself is not
resolved from GHCR. The archive contains the recursive descriptor closure;
referenced charts and images continue to use their declared registries.

For an environment without direct GitHub access, download the asset in advance
and run:

```bash
PLATFORM_MESH_RELEASE_FILE=/path/to/platform-mesh-0.3.0.ctf.tgz task local-setup:example-data
```

The GitHub source archives are not OCM transport archives. This workflow is
deliberately fixed to 0.3.0; supporting 0.4.0 requires compatibility changes.
The artifact preparation step is skipped for `--prerelease` tasks.

### (Future option) Manual full OCM backup

For an offline or long-term backup, create the full archive once, store the
archive and its `.sha256` file in controlled storage such as SharePoint, and
keep both files together:

```bash
bin/ocm --config .ocm/config transfer componentversion --recursive --copy-resources --type tgz --repo ghcr.io/platform-mesh github.com/platform-mesh/platform-mesh:0.3.0 platform-mesh-0.3.0-full.ctf.tgz
sha256sum platform-mesh-0.3.0-full.ctf.tgz > platform-mesh-0.3.0-full.ctf.tgz.sha256
```

To restore it, manually download both files, verify the checksum with
`sha256sum -c platform-mesh-0.3.0-full.ctf.tgz.sha256`, then use the archive
path:

```bash
PLATFORM_MESH_RELEASE_FILE=/path/to/platform-mesh-0.3.0-full.ctf.tgz task local-setup:example-data
```

The default setup pins the checksum of the smaller descriptor archive, so
`PLATFORM_MESH_RELEASE_SHA256` in `local-setup/scripts/setup-release.sh` must
be deliberately changed to the stored full-archive checksum before restoring.

# bug fixing

## Openbao-operator IP hard coded
You might need to set your local cluster IP of KCP correctly here:

local-setup/kustomize/components/openbao-provider/helmreleases.yaml (line 63)
