# Everything looks good. Here's a summary of all the changes made:

## Files changed:
- values.yaml	devMode: false, file storage config, size: 1Gi, security context fixed to non-root (uid 100), removed devRootToken/devListenAddress
- configmap.yaml	Non-dev branch now uses storage "file" driven by values instead of storage "inmem"
- deployment.yaml	Health probes accept 204 for sealed/uninit state; PVC volume + mount added at /vault/data
- secret.yaml	Token starts empty; init job patches it after operator init
- init-job.yaml	Full init/unseal/secret-patch flow added before k8s auth setup; uses curl against the k8s API (no kubectl needed); idempotent on re-runs
- pvc.yaml	New — 1Gi PVC for vault data storage
- rbac.yaml	New — Role + RoleBinding giving the service account get/patch/create/update on Secrets

## Key behavioral changes:

- After every pod restart, OpenBao comes back sealed. Run helm upgrade to trigger the init job, which will re-unseal using the key stored in the openbao-unseal-key secret.
- The root token is now a real generated token stored in openbao-root-token, not "root".
- Data persists across pod restarts via the PVC.