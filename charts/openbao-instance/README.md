# openbao-instance

OpenBao secrets management server for local development (dev mode)

![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
## Values
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| config.devMode | bool | `false` |  |
| config.storage.path | string | `"/vault/data"` |  |
| config.storage.size | string | `"1Gi"` |  |
| config.storage.type | string | `"file"` |  |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `"docker.io"` |  |
| image.repository | string | `"openbao/openbao"` |  |
| image.tag | string | `"2.5.4"` |  |
| imagePullSecrets | list | `[]` |  |
| initJob.backoffLimit | int | `5` |  |
| initJob.enabled | bool | `true` |  |
| initJob.image.registry | string | `"docker.io"` |  |
| initJob.image.repository | string | `"openbao/openbao"` |  |
| initJob.image.tag | string | `"2.5.4"` |  |
| initJob.openbaoAddress | string | `"http://openbao:8200"` |  |
| initJob.operatorNamespace | string | `"openbao-provider"` |  |
| initJob.operatorPolicyName | string | `"openbao-operator"` |  |
| initJob.operatorRole | string | `"openbao-operator"` |  |
| initJob.operatorServiceAccount | string | `"openbao-operator-controller-manager"` |  |
| initJob.resources.limits.cpu | string | `"200m"` |  |
| initJob.resources.limits.memory | string | `"128Mi"` |  |
| initJob.resources.requests.cpu | string | `"50m"` |  |
| initJob.resources.requests.memory | string | `"64Mi"` |  |
| initJob.restartPolicy | string | `"Never"` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podSecurityContext.fsGroup | int | `1000` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| replicaCount | int | `1` |  |
| resources.limits.cpu | string | `"500m"` |  |
| resources.limits.memory | string | `"256Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"128Mi"` |  |
| securityContext.capabilities.add[0] | string | `"IPC_LOCK"` |  |
| securityContext.runAsNonRoot | bool | `true` |  |
| securityContext.runAsUser | int | `100` |  |
| service.annotations | object | `{}` |  |
| service.port | int | `8200` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
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
# openbao-instance

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.5.4](https://img.shields.io/badge/AppVersion-2.5.4-informational?style=flat-square)

OpenBao secrets management server for local development (dev mode)

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Platform Mesh Team |  |  |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| config.devMode | bool | `false` |  |
| config.storage.path | string | `"/vault/data"` |  |
| config.storage.size | string | `"1Gi"` |  |
| config.storage.type | string | `"file"` |  |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `"docker.io"` |  |
| image.repository | string | `"openbao/openbao"` |  |
| image.tag | string | `"2.5.4"` |  |
| imagePullSecrets | list | `[]` |  |
| initJob.backoffLimit | int | `5` |  |
| initJob.enabled | bool | `true` |  |
| initJob.image.registry | string | `"docker.io"` |  |
| initJob.image.repository | string | `"openbao/openbao"` |  |
| initJob.image.tag | string | `"2.5.4"` |  |
| initJob.openbaoAddress | string | `"http://openbao:8200"` |  |
| initJob.operatorNamespace | string | `"openbao-provider"` |  |
| initJob.operatorPolicyName | string | `"openbao-operator"` |  |
| initJob.operatorRole | string | `"openbao-operator"` |  |
| initJob.operatorServiceAccount | string | `"openbao-operator-controller-manager"` |  |
| initJob.resources.limits.cpu | string | `"200m"` |  |
| initJob.resources.limits.memory | string | `"128Mi"` |  |
| initJob.resources.requests.cpu | string | `"50m"` |  |
| initJob.resources.requests.memory | string | `"64Mi"` |  |
| initJob.restartPolicy | string | `"Never"` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podSecurityContext.fsGroup | int | `1000` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| replicaCount | int | `1` |  |
| resources.limits.cpu | string | `"500m"` |  |
| resources.limits.memory | string | `"256Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"128Mi"` |  |
| securityContext.capabilities.add[0] | string | `"IPC_LOCK"` |  |
| securityContext.runAsNonRoot | bool | `true` |  |
| securityContext.runAsUser | int | `100` |  |
| service.annotations | object | `{}` |  |
| service.port | int | `8200` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |

