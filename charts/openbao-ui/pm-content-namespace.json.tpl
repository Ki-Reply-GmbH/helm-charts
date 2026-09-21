{
  "name": "openbao-ui-namespace",
  "luigiConfigFragment": {
    "data": {
      "nodes": [
        {
          "pathSegment": "openbao",
          "navigationContext": "openbao-namespace",
          "label": "OpenBao",
          "entityType": "main.core_platform-mesh_io_account.namespace",
          "category": {
            "icon": "key",
            "label": "OpenBao",
            "collapsible": true,
            "order": __NAMESPACE_CATEGORY_ORDER__
          },
          "keepSelectedForChildren": true,
          "loadingIndicator": { "enabled": false },
          "context": {
            "openbaoLevel": "namespace",
            "accountNamespace": "__ACCOUNT_NAMESPACE__"
          },
          "url": "__HOST__/index.html"
        }
      ]
    }
  }
}
