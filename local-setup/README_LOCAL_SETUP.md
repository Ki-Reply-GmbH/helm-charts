
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

## Unsealing
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