param location string
param clusterName string
param aksSubnetId string
param nodeCount int = 3
param vmSize string = 'Standard_B4ms'
param agentpoolName string = 'nodepool1'
param aksClusterNetworkPlugin string = 'azure'
param aksNetworkPluginMode string = 'overlay'
param aksPodCidr string = '192.168.0.0/16'
param aksServiceCidr string = '10.0.0.0/16'
param aksDnsServiceIP string = '10.0.0.10'
param aksClusterOutboundType string = 'loadBalancer'

resource aks 'Microsoft.ContainerService/managedClusters@2025-03-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: agentpoolName
        count: nodeCount
        vmSize: vmSize
        mode: 'System'
        vnetSubnetID: aksSubnetId
      }
    ]
    networkProfile: {
      networkPlugin: aksClusterNetworkPlugin
      networkPluginMode: aksNetworkPluginMode
      podCidr: aksPodCidr
      serviceCidr: aksServiceCidr
      dnsServiceIP: aksDnsServiceIP
      outboundType: aksClusterOutboundType
    }
  }
}

var config = aks.listClusterAdminCredential().kubeconfigs[0].value

output aks_principal_id string = aks.identity.principalId
output controlPlaneFQDN string = aks.properties.fqdn
output kubeConfig string = config
