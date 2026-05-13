# OpenBao OCM Promotion — What to Change

When `openbao-instance` and `openbao-operator` are added to the published `github.com/platform-mesh/platform-mesh` OCM component, make these changes:

## Files to change

**`local-setup/kustomize/components/openbao-provider/resources.yaml`**
Update the `referencePath` in both `Resource` objects to match the paths in the published component.
Verify the actual paths by running:
```bash
ocm get resources ghcr.io/platform-mesh//github.com/platform-mesh/platform-mesh --latest -o yaml | grep -A5 openbao
```

**`local-setup/scripts/ocm-build-local-charts.sh`**
Remove the two lines:
```
"openbao-instance:charts/openbao-instance"
"openbao-operator:charts/openbao-operator"
```

**`local-setup/scripts/ocm-build-component.sh`**
Remove `openbao-instance` and `openbao-operator` from `CUSTOM_LOCAL_COMPONENTS` and remove their two `get_component_version` calls.

**`charts/openbao-operator/values.yaml`** *(if the operator image is also published)*
Restore registry/repository/tag/pullPolicy to the public `ghcr.io` image.

## After the changes

- Use `task local-setup:example-data` instead of `task local-setup:prerelease:example-data`.
- The `kind load docker-image openbao-operator:local` step is no longer needed.
