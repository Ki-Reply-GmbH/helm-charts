{
  "name": "openbao-ui",
  "luigiConfigFragment": {
    "data": {
      "nodes": [
        {
          "pathSegment": "openbao",
          "navigationContext": "openbao-account",
          "label": "OpenBao",
          "entityType": "main.core_platform-mesh_io_account",
          "icon": "key",
          "order": __ACCOUNT_NAV_ORDER__,
          "category": {
            "id": "openbao",
            "isGroup": true,
            "icon": "key",
            "label": "OpenBao",
            "collapsible": true,
            "order": __ACCOUNT_NAV_ORDER__
          },
          "keepSelectedForChildren": true,
          "loadingIndicator": { "enabled": false },
          "context": {
            "openbaoLevel": "account",
            "accountNamespace": "__ACCOUNT_NAMESPACE__"
          },
          "url": "__HOST__/index.html"
        }
      ]
    }
  }
}
