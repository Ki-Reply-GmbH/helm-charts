# OpenBao Local Setup Review Findings

Date: 2026-06-18  
Scope: `git/helm-charts` on branch `feat/openbao-multicluster-local-setup`  
Commits reviewed: `7077963ab8c13d492fccd2f2c74525afddc12655..HEAD`  
Notes: Included current working state (`CLAUDE.md` untracked). Ignored `local-setup/docs/*` except `local-setup/docs/README_LOCAL_SETUP.md`.

## Findings (High to Low)

1. **Critical**: UI/schema allow missing secret namespace, but controller requires it at runtime.
- Refs:
  - `local-setup/example-data/root/providers/openbao-provider/contentconfiguration.yaml:111`
  - `local-setup/example-data/root/providers/openbao-provider/apiresourceschema.yaml:96`
  - `local-setup/example-data/root/providers/openbao-provider/apiresourceschema.yaml:131`
  - `../openbao-operator/internal/controller/openbaotenant_controller.go:700`
  - `../openbao-operator/internal/controller/openbaotenant_controller.go:705`
  - `../openbao-operator/internal/controller/openbaotenant_controller.go:572`
- Impact: Tenant creation from portal can succeed but reconciliation fails for AppRole/OIDC when namespace is omitted.
- Introduced in: `60d6d2c0`
- Fix direction: Either require namespace fields in schema/UI, or implement safe namespace defaulting in controller.

2. **High**: Hardcoded KCP/portal IP in operator `hostAliases`.
- Refs:
  - `local-setup/kustomize/components/openbao-provider/helmreleases.yaml:63`
  - `local-setup/docs/README_LOCAL_SETUP.md:145`
- Impact: Breaks after cluster recreation/service IP changes unless manually updated.
- Introduced in: `60d6d2c0`
- Fix direction: Replace with stable DNS/service resolution or patch dynamically in startup flow.

3. **High**: Local registry reuse check does not handle stopped container.
- Ref:
  - `local-setup/scripts/start.sh:75`
- Impact: If `kind-registry` exists but is stopped, script says "Reuse existing local registry" and chart push can fail.
- Introduced in: `6668af19`
- Fix direction: Detect running state and start container when needed.

4. **Medium**: Helm push uses wildcard tarballs from `/tmp`.
- Refs:
  - `local-setup/scripts/start.sh:84`
  - `local-setup/scripts/start.sh:86`
- Impact: Multiple matching tgz files can make push nondeterministic or fail.
- Introduced in: `6668af19`
- Fix direction: Clean matching files first, or push explicit tarball path returned by `helm package`.

5. **Medium**: API contract drift across chart CRD, KCP APIResourceSchema, and examples.
- Refs:
  - `charts/openbao-operator/crds/openbao.apeiro.dev_openbaotenants.yaml:174`
  - `local-setup/example-data/root/providers/openbao-provider/apiresourceschema.yaml:19`
  - `../openbao-operator/api/v1/openbaotenant_types.go:37`
  - `local-setup/example-data/samples/openbao-tenant-example.yaml:7`
  - `local-setup/example-data/samples/openbao-tenant-example.yaml:52`
- Impact: Conflicting expectations for consumers and higher chance of reconciliation/UI mismatch.
- Introduced across: `c86ac707`, changed further in `60d6d2c0`
- Fix direction: Regenerate/align CRD + APIResourceSchema + samples from one canonical operator API state.

6. **Low**: Untracked `CLAUDE.md` no longer reflects current implementation.
- Refs:
  - `CLAUDE.md:46`
  - `CLAUDE.md:52`
  - `charts/openbao-instance/values.yaml:17`
  - `charts/openbao-instance/Chart.yaml:6`
- Impact: Team confusion (doc still says dev mode/token root/2.1.0 while code uses persistent mode/2.5.4).
- Status: Current working-state issue (not committed).

## Unused Prerelease Additions

1. `local-setup/kustomize/components/openbao-provider/resources.yaml` is currently dead in active flow because it is disabled in `local-setup/kustomize/components/openbao-provider/kustomization.yaml:7`.
2. OCM prerelease scripts still include OpenBao local components:
- `local-setup/scripts/ocm-build-local-charts.sh:24`
- `local-setup/scripts/ocm-build-component.sh:27`
3. Prerelease task paths remain available in `Taskfile.yaml` (for example `local-setup:prerelease` at line 379), but current active flow is non-prerelease.

## Validation Performed

- `helm lint` passed:
  - `charts/openbao-instance`
  - `charts/openbao-operator`
- `helm template` rendered:
  - `openbao-instance`
  - `openbao-operator`
- `kubectl kustomize` rendered:
  - `local-setup/kustomize/overlays/example-data`
  - `local-setup/example-data/root/providers/openbao-provider`

## Residual Risks / Gaps

- No full end-to-end cluster execution was run in this review pass.
- Could not re-verify `--kubeconfig` runtime behavior in operator binary locally due to blocked external Go toolchain download in this environment.

