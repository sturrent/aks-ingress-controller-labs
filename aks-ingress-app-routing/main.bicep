targetScope = 'subscription'

param location string = 'canadacentral'
param userName string = 'app-routing'
param resourceName string = 'ingress'

var aksResourceGroupName = 'aks-${resourceName}-${userName}-rg'
var vnetName = 'vnet-${resourceName}-${userName}'
var subnetName = 'aks-subnet-${resourceName}-${userName}'
var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource clusterrg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: aksResourceGroupName
  location: location
}

module aksvnet './modules/aks-vnet.bicep' = {
  name: vnetName
  scope: clusterrg
  params: {
    location: location
    subnetName: subnetName
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.100.0.0/24'
        }
      } 
    ]
    vnetName: vnetName
    vvnetPreffix:  [
      '10.100.0.0/16'
    ]
  }
}

module akscluster './modules/aks-cluster.bicep' = {
  name: resourceName
  scope: clusterrg
  params: {
    location: location
    clusterName: 'aks-${resourceName}-${userName}'
    aksSubnetId: aksvnet.outputs.akssubnet
  }
}

module roleAuthorization './modules/aks-auth.bicep' = {
  name: 'roleAuthorization'
  scope: clusterrg
  params: {
      principalId: akscluster.outputs.aks_principal_id
      roleDefinition: contributorRoleId
  }
}

module kubernetes './modules/workloads.bicep' = {
  name: 'buildbicep-deploy'
  scope: clusterrg
  params: {
    kubeConfig: akscluster.outputs.kubeConfig
  }
}
