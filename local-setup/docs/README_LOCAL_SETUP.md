
# Current workflow

## Build operator image
```bash
cd /home/ldeppewsl/docs/openbao/platform-mesh/git/openbao-operator
make docker-build IMG=openbao-operator:local
```
-> this image will be loaded into kind cluster during start script


## Start standard flow
```bash
cd /home/ldeppewsl/docs/openbao/platform-mesh/git/helm-charts

task local-setup:example-data
```

## to continue without recreating everything (after initial setup)
```bash
task local-setup:example-data:iterate
```

## access platform mesh
go to https://portal.localhost:8443/


## Unsealing
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