# OpenBao Instance Helm Chart

Deploys OpenBao secrets management server in development mode.

## Purpose

This chart deploys OpenBao for local development and testing. It includes an init job that automatically configures Kubernetes authentication for the operator.

## Features

- **Kubernetes Auth Bootstrap**: Init job configures K8s authentication automatically
- **Operator Ready**: Pre-configured for OpenBao operator integration
- **Health Probes**: Liveness and readiness probes configured

## Installation

```bash
helm install openbao-instance charts/openbao-instance \
  -n openbao-provider --create-namespace
```

## Configuration

### Key Values

```yaml
# OpenBao server configuration
config:
  devMode: true                    # Use dev mode (NOT for production)
  devRootToken: "root"             # Root token (change in production)
  devListenAddress: "0.0.0.0:8200"

# Init job configuration
initJob:
  enabled: true                                          # Enable K8s auth bootstrap
  operatorServiceAccount: "openbao-operator-controller-manager"
  operatorNamespace: "openbao-provider"
  operatorRole: "openbao-operator"

# Resources
resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

## Dev Mode vs Production

### Dev Mode (This Chart)

✅ **Advantages:**
- Auto-unsealed (no manual unsealing)
- In-memory storage (no persistent volume needed)
- Fast startup
- Simple configuration

❌ **Limitations:**
- Data lost on pod restart
- Single replica only
- Not suitable for production

### Production Mode (Future)

For production, you would need:
- Raft storage backend with PersistentVolumeClaims
- Manual unsealing or auto-unseal with KMS
- 3+ replicas for high availability
- TLS enabled
- Audit logging configured

## Verification

```bash
# Check pod is running
kubectl get pods -n openbao-provider -l app=openbao

# Check OpenBao status
kubectl exec -n openbao-provider deployment/openbao-instance -- bao status

# Expected: Sealed: false, Initialized: true

# Verify init job completed
kubectl get jobs -n openbao-provider

# Check K8s auth is enabled
kubectl exec -n openbao-provider deployment/openbao-instance -- bao auth list
```

## Troubleshooting

### Pod CrashLoopBackOff

Check logs:
```bash
kubectl logs -n openbao-provider -l app=openbao
```

Common causes:
- Image pull failure
- Resource limits too low
- Port 8200 already in use

### Init Job Failed

Check job logs:
```bash
kubectl logs -n openbao-provider job/openbao-instance-init-k8s-auth
```

Re-run init job:
```bash
kubectl delete job -n openbao-provider openbao-instance-init-k8s-auth
helm upgrade openbao-instance charts/openbao-instance -n openbao-provider
```

## Chart Values Reference

See [values.yaml](values.yaml) for complete list of configurable values.

## Related Charts

- [openbao-operator](../openbao-operator/README.md) - Operator that manages OpenBaoTenant resources

## Resources

- OpenBao Documentation: https://openbao.org/docs/
- OpenBao GitHub: https://github.com/openbao/openbao
