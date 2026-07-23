#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KCP_URL="${KCP_URL:-https://localhost:8443}"
KCP_KUBECONFIG="${KCP_KUBECONFIG:-$ROOT_DIR/.secret/kcp/admin.kubeconfig}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-900s}"

ROOT_SERVER="${KCP_URL%/}/clusters/root"
ORGS_SERVER="${KCP_URL%/}/clusters/root:orgs"
SYSTEM_SERVER="${KCP_URL%/}/clusters/root:platform-mesh-system"
OPENBAO_PROVIDER_SERVER="${KCP_URL%/}/clusters/root:providers:openbao-provider"
OPENBAO_PROVIDER_PATH="root:providers:openbao-provider"
ONBOARDING_TYPE_PATH="root:platform-mesh-system"
ONBOARDING_DIR="$ROOT_DIR/local-setup/example-data/root/platform-mesh-system"

if [[ ! -f "$KCP_KUBECONFIG" ]]; then
  echo "Admin kubeconfig not found at $KCP_KUBECONFIG" >&2
  exit 1
fi

kcp_kubectl=(kubectl --kubeconfig "$KCP_KUBECONFIG")

wait_for_openbao_prerequisites() {
  echo "Waiting for the OpenBao APIExport and APIExportPolicy"

  "${kcp_kubectl[@]}" --server "$OPENBAO_PROVIDER_SERVER" wait \
    --for=jsonpath='{.status.conditions[?(@.type=="IdentityValid")].status}'=True \
    --timeout="$WAIT_TIMEOUT" \
    apiexports.apis.kcp.io/openbao.apeiro.dev

  "${kcp_kubectl[@]}" --server "$ORGS_SERVER" wait \
    --for=jsonpath='{.status.conditions[?(@.type=="Ready")].status}'=True \
    --timeout="$WAIT_TIMEOUT" \
    apiexportpolicies.core.platform-mesh.io/openbao.apeiro.dev
}

apply_onboarding_resources() {
  echo "Installing the shared OpenBao workspace initializer"

  "${kcp_kubectl[@]}" --server "$SYSTEM_SERVER" apply \
    -f "$ONBOARDING_DIR/openbao-onboarding-workspacetype.yaml"
  "${kcp_kubectl[@]}" --server "$SYSTEM_SERVER" apply \
    -f "$ONBOARDING_DIR/openbao-onboarding-template.yaml"
  "${kcp_kubectl[@]}" --server "$SYSTEM_SERVER" apply \
    -f "$ONBOARDING_DIR/openbao-onboarding-target.yaml"
}

wait_for_openbao_default_binding() {
  local workspace_type="$1"

  echo "Waiting for WorkspaceType/$workspace_type to default-bind OpenBao"
  "${kcp_kubectl[@]}" --server "$ROOT_SERVER" wait \
    --for=jsonpath='{.spec.defaultAPIBindings[?(@.export=="openbao.apeiro.dev")].path}'="$OPENBAO_PROVIDER_PATH" \
    --timeout="$WAIT_TIMEOUT" \
    "workspacetype.tenancy.kcp.io/$workspace_type"
}

attach_onboarding_initializer() {
  local workspace_type="$1"
  local existing_path

  existing_path="$(
    "${kcp_kubectl[@]}" --server "$ROOT_SERVER" \
      get workspacetype.tenancy.kcp.io "$workspace_type" \
      -o jsonpath='{.spec.extend.with[?(@.name=="openbao-onboarding")].path}'
  )"

  if [[ "$existing_path" == "$ONBOARDING_TYPE_PATH" ]]; then
    echo "WorkspaceType/$workspace_type already extends openbao-onboarding"
    return
  fi

  if [[ -n "$existing_path" ]]; then
    echo "WorkspaceType/$workspace_type already references openbao-onboarding at unexpected path: $existing_path" >&2
    exit 1
  fi

  "${kcp_kubectl[@]}" --server "$ROOT_SERVER" \
    patch workspacetype.tenancy.kcp.io "$workspace_type" \
    --type=json \
    -p='[{"op":"add","path":"/spec/extend/with/-","value":{"name":"openbao-onboarding","path":"root:platform-mesh-system"}}]'
}

wait_for_openbao_prerequisites
apply_onboarding_resources

for workspace_type in org account; do
  wait_for_openbao_default_binding "$workspace_type"
  attach_onboarding_initializer "$workspace_type"
done

echo "Automatic OpenBao onboarding is configured for new organization and account workspaces"
