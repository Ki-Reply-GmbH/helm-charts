# Next Week: Local Setup Follow-Up

## Background

`task local-setup:example-data` started failing after updating the local OCM pin from `0.3.0-build.1095` to `0.4.0-build.518`.

The old `0.3.0-build.1095` OCM component was removed from GHCR, so it can no longer be resolved. The new `0.4.0-build.518` component exists, but our feature branch still has older local-setup manifests.

The current timeout is caused by the newer Platform Mesh operator expecting a `platform-mesh-profile` ConfigMap that our branch does not create.

## What To Do

1. Update the forked `main` branch from `platform-mesh/helm-charts` upstream `main`.
2. Rebase the feature branch onto the updated forked `main`.
3. Resolve conflicts carefully in local-setup files, especially:
   - `Taskfile.yaml`
   - `local-setup/scripts/start.sh`
   - `local-setup/kustomize/components/ocm/*`
   - `local-setup/kustomize/components/platform-mesh-operator-resource/*`
4. Keep the new OCM pin precheck task unless upstream has replaced this workflow.
5. Re-run from a fresh cluster:

```bash
task local-setup:example-data
```

## Team/PO Summary

This is not an OpenBao provider code issue. Platform Mesh is still under active development, and the OCM build artifact used by local setup was removed upstream. Updating to the latest OCM build requires matching newer local-setup manifests from upstream, so the next step is to rebase onto current upstream `main` instead of patching individual missing resources.
