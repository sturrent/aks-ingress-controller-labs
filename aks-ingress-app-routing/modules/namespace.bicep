@secure()
param kubeConfig string

extension kubernetes with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource coreNamespace_aksStore 'core/Namespace@v1' = {
  metadata: {
    name: 'aks-store'
  }
}
