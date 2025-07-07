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

resource coreNamespace_albTestInfra 'core/Namespace@v1' = {
  metadata: {
    name: 'alb-test-infra'
  }
}
