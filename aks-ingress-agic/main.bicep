targetScope = 'subscription'

param location string = 'canadacentral'
param userName string = 'agic'
param resourceName string = 'ingress'

var aksResourceGroupName = 'aks-${resourceName}-${userName}-rg'
var vnetName = 'vnet-${resourceName}-${userName}'
var subnetName = 'aks-subnet-${resourceName}-${userName}'
var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var netContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')

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
    appgwSubnetCIDR: '10.100.1.0/24'
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

module appGwRoleAuthorization './modules/agic-auth.bicep' = {
  name: 'appGwRoleAuthorization'
  scope: clusterrg
  params: {
      principalId: akscluster.outputs.agic_object_id
      roleDefinition: netContributorRoleId
      vnetResourceId: aksvnet.outputs.aksVnetId
  }
}

module kubernetes1 './modules/namespace.bicep' = {
  name: 'buildbicep-deploy1'
  scope: clusterrg
  params: {
    kubeConfig: akscluster.outputs.kubeConfig
  }
}

module kubernetes2 './modules/workloads.bicep' = {
  name: 'buildbicep-deploy'
  scope: clusterrg
  params: {
    kubeConfig: akscluster.outputs.kubeConfig
  }
}
