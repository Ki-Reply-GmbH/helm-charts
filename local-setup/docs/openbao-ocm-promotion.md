# Promoting OpenBao to the Published platform-mesh OCM Component

This document describes what to change when `openbao-instance` and `openbao-operator` are added to the
officially published `github.com/platform-mesh/platform-mesh` OCM component (currently expected ~2 months
after May 2026).

## Background

Right now the two charts are built locally and pushed to the in-cluster OCI registry via the prerelease
flow. When they are published, OCM will resolve them from `ghcr.io` like all other providers, and the
local build step becomes unnecessary.

## Changes required

### 1. `local-setup/kustomize/components/openbao-provider/resources.yaml`

Update the `referencePath` in both `Resource` objects to match the path the OCM component team uses when
they publish. Ask them what the path looks like, or inspect the published component:

```bash
ocm get resources ghcr.io/platform-mesh//github.com/platform-mesh/platform-mesh --latest -o yaml | grep -A5 openbao
```

The current prerelease paths are flat:

```yaml
referencePath:
- name: openbao-instance   # top-level component reference
- name: chart
```

The published structure will likely be nested (matching the existing pattern for other providers), e.g.:

```yaml
referencePath:
- name: openbao-operator          # sub-component grouping both charts
- name: openbao-instance-chart    # chart sub-reference
resource:
  name: chart
```

Update both `Resource` objects (`openbao-instance-chart` and `openbao-operator-chart`) accordingly.

If the published component also ships the operator image via OCM (i.e. it is no longer a locally-built
image), add two `Resource` objects for the images as well, following the same pattern as
`example-httpbin-provider/resources.yaml`.

### 2. `local-setup/scripts/ocm-build-local-charts.sh`

Remove `openbao-instance` and `openbao-operator` from `CUSTOM_LOCAL_COMPONENTS_CHART_PATHS`:

```bash
# Remove these two lines:
"openbao-instance:charts/openbao-instance"
"openbao-operator:charts/openbao-operator"
```

### 3. `local-setup/scripts/ocm-build-component.sh`

- Remove `openbao-instance` and `openbao-operator` from `CUSTOM_LOCAL_COMPONENTS`.
- Remove the two `get_component_version` calls for them from `resolve_component_versions`.

### 4. Switch deployment command

Once the above is done, users can replace:

```bash
task local-setup:prerelease:example-data
```

with:

```bash
task local-setup:example-data
```

The `kind load docker-image openbao-operator:local` step in the setup docs also becomes unnecessary if the
operator image is published to `ghcr.io`.

### 5. Update `charts/openbao-operator/values.yaml`

If the operator image is now published, restore the image reference to the public registry:

```yaml
image:
  registry: ghcr.io
  repository: platform-mesh/openbao-operator
  tag: "<published-version>"
  pullPolicy: IfNotPresent
```

## Checklist

- [ ] Confirm exact OCM reference paths with the platform-mesh team
- [ ] Update `resources.yaml` reference paths
- [ ] Remove `openbao-instance` and `openbao-operator` from `ocm-build-local-charts.sh`
- [ ] Remove them from `ocm-build-component.sh`
- [ ] Update `charts/openbao-operator/values.yaml` if image is now published
- [ ] Verify with `task local-setup:example-data` (fresh cluster)
- [ ] Update `local-setup/docs/openbao-provider.md` to remove the local image build step
