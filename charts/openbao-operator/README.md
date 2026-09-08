# openbao-operator

OpenBao operator with multicluster runtime for managing OpenBaoTenant resources

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
## Values
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| controllerManager.serviceAccount.annotations | object | `{}` |  |
| controllerManager.serviceAccountName | string | `"openbao-operator-controller-manager"` |  |
| enabled | bool | `true` |  |
| fullnameOverride | string | `""` |  |
| healthProbe.bindAddress | string | `":8081"` |  |
| hostAliases | list | `[]` |  |
| image.pullPolicy | string | `"Never"` |  |
| image.registry | string | `""` |  |
| image.repository | string | `"openbao-operator"` |  |
| image.tag | string | `"local"` |  |
| imagePullSecrets | list | `[]` |  |
| leaderElection.enabled | bool | `true` |  |
| metrics.enable | bool | `true` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| operator.adminPolicyPrivileges | string | `"create,read,update,delete,list"` |  |
| operator.apiexportEndpointsliceName | string | `"openbao.apeiro.dev"` |  |
| operator.kcpKubeconfigSecretName | string | `"openbao-kubeconfig"` |  |
| operator.openbaoAddress | string | `"http://openbao.openbao-provider.svc:8200"` |  |
| operator.openbaoAuthMethod | string | `"kubernetes"` |  |
| operator.openbaoDisplayUrl | string | `""` |  |
| operator.openbaoK8sMountPath | string | `"kubernetes"` |  |
| operator.openbaoK8sRole | string | `"openbao-operator"` |  |
| operator.openbaoK8sTokenPath | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| operator.resources.limits.cpu | string | `"500m"` |  |
| operator.resources.limits.memory | string | `"128Mi"` |  |
| operator.resources.requests.cpu | string | `"100m"` |  |
| operator.resources.requests.memory | string | `"64Mi"` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| prometheus.enable | bool | `false` |  |
| rbac.enable | bool | `true` |  |
| replicaCount | int | `1` |  |
| tolerations | list | `[]` |  |

## Overriding Values

The values in the `defaults:` section can be reused from other charts by using the lookup function "common.getKeyValue". It implements lookup on three levels:

1. Looks for `keyOverride` in the chart's values.yaml
2. Looks for `global.key` in the chart's or parent chart's values.yaml
3. Uses the `key` in the chart's values.yaml
4. Uses the `common.defaults.key` value from the table below.

1 has precedence over 2 over 3 over 4 respectively. This approach allows for individual charts to have minimal configuration, while still being able to override parameters locally.

Example
```
1) .Values.deployment.resources.limits.memoryOverride = 4096MB
2) .Values.global.deployment.resources.limits.memory = 2048MB
3) .Values.deployment.resources.limits.memory = 1024MB
4) .Values.common.defaults.deployment.resources.limits.memory = default 512MB
```
# openbao-operator

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.1.0](https://img.shields.io/badge/AppVersion-v0.1.0-informational?style=flat-square)

OpenBao operator with multicluster runtime for managing OpenBaoTenant resources

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Platform Mesh Team |  |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| controllerManager.serviceAccount.annotations | object | `{}` |  |
| controllerManager.serviceAccountName | string | `"openbao-operator-controller-manager"` |  |
| enabled | bool | `true` |  |
| fullnameOverride | string | `""` |  |
| healthProbe.bindAddress | string | `":8081"` |  |
| hostAliases | list | `[]` |  |
| image.pullPolicy | string | `"Never"` |  |
| image.registry | string | `""` |  |
| image.repository | string | `"openbao-operator"` |  |
| image.tag | string | `"local"` |  |
| imagePullSecrets | list | `[]` |  |
| leaderElection.enabled | bool | `true` |  |
| metrics.enable | bool | `true` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| operator.adminPolicyPrivileges | string | `"create,read,update,delete,list"` |  |
| operator.apiexportEndpointsliceName | string | `"openbao.apeiro.dev"` |  |
| operator.kcpKubeconfigSecretName | string | `"openbao-kubeconfig"` |  |
| operator.openbaoAddress | string | `"http://openbao.openbao-provider.svc:8200"` |  |
| operator.openbaoAuthMethod | string | `"kubernetes"` |  |
| operator.openbaoDisplayUrl | string | `""` |  |
| operator.openbaoK8sMountPath | string | `"kubernetes"` |  |
| operator.openbaoK8sRole | string | `"openbao-operator"` |  |
| operator.openbaoK8sTokenPath | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| operator.resources.limits.cpu | string | `"500m"` |  |
| operator.resources.limits.memory | string | `"128Mi"` |  |
| operator.resources.requests.cpu | string | `"100m"` |  |
| operator.resources.requests.memory | string | `"64Mi"` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| prometheus.enable | bool | `false` |  |
| rbac.enable | bool | `true` |  |
| replicaCount | int | `1` |  |
| tolerations | list | `[]` |  |

