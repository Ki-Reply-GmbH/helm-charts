
# Current workflow

## Build operator image
```bash
cd /home/ldeppewsl/docs/openbao/platform-mesh/git/openbao-operator
docker build --no-cache -t openbao-operator:local . 
```
-> this image will be loaded into kind cluster during start script
-> use --no-cache flag to make sure that recent changes are used


## Start standard flow
```bash
cd /home/ldeppewsl/docs/openbao/platform-mesh/git/helm-charts

task local-setup:example-data
```
Note: This will take around 10 to 15 minutes to finish! 

Right at start you need to confirm the deletion of "platform-mesh" kind cluster if it already exists. Besides that there is no interaction needed.

## to continue without recreating everything (after initial setup)
```bash
task local-setup:example-data:iterate
```

## OCM pin precheck (automatic)
For non-prerelease local setup tasks, an OCM precheck now runs automatically before `start.sh`.
It validates that the pinned version in `local-setup/kustomize/components/ocm/component.yaml` still exists in GHCR.

If the version was removed, setup stops early and prints the latest available version plus a hint to run:

```bash
task bump-local-setup-component-version
task local-setup:example-data
```

For `--prerelease` tasks, this precheck is skipped.

## access platform mesh
go to https://portal.localhost:8443/

# Short workflow
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


# Create Tenant in Platform mesh

name: everything accepted here
secret: <name>-approle
secret-namespace: default

# Use OpenBao
if OpenBao Tenant is ready in Platform Mesh click on it, you should see an URL like http://openbao.openbao-provider.svc:8200 and also your namespace.

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

## if you get a login error like can't find namespace
First make sure that you use the decoded root token!

Next use an incognito tab to go to http://localhost:8200/ui in your browser.

If that doesn't work, use command:
```bash
task local-setup:example-data:iterate
```
to update cluster. 
When finished use an incognito tab to go to http://localhost:8200/ui and use your root token.
Your root-token will have changed, you need to retrieve it again! The user account and namespace stays the same.

# Misc


## Unsealing
### retrieve unseal keal
```bash
kubectl get secret openbao-unseal-key -n openbao-provider -o jsonpath='{.data.key}' | base64 -d
```
In this local setup, OpenBao is initialized with 1 key share and threshold 1, so that value is your full unseal key / unseal key portion.

###
Check status
```bash
kubectl exec -n openbao-provider deployment/openbao-instance -- bao status
```

```bash
flux reconcile helmrelease openbao-instance -n default
```
-> Force Flux to re-reconcile the HelmRelease (triggers the init job)

Or if you want to force a full upgrade cycle:
```bash
flux reconcile helmrelease openbao-instance -n default --with-source
```

### FYI: if running outside of Flux
```bash
helm upgrade openbao-instance ./charts/openbao-instance -n openbao-provider
```

# bug fixing

## Openbao-operator IP hard coded
You might need to set your local cluster IP of KCP correctly here:

local-setup/kustomize/components/openbao-provider/helmreleases.yaml (line 63)
