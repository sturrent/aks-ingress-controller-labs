targetScope = 'subscription'

param location string = 'canadacentral'
param userName string = 'agc'
param resourceName string = 'ingress'
param albHelmNamespace string = 'ingress-agc'
param albControllerNamespace string = 'azure-alb-system'

var aksResourceGroupName = 'aks-${resourceName}-${userName}-rg'
var vnetName = 'vnet-${resourceName}-${userName}'
var subnetName = 'aks-subnet-${resourceName}-${userName}'
var agcSubnetName = 'agc-ingress-subnet'
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
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.100.0.0/24'
        }
      }
      {
        name: agcSubnetName
        properties: {
          addressPrefix: '10.101.0.0/24'
          delegations: [
            {
              name: 'serviceNetworkingDelegation'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ]
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
    aksSubnetId: aksvnet.outputs.subnetIds[0].id
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

module albsetup './modules/alb-setup/main.bicep' = {
  name: 'alb-setup'
  scope: clusterrg
  params: {
    aksName: 'aks-${resourceName}-${userName}'
    location: location
    managedIdentityName: 'azure-alb-identity'
    aksVnetId: aksvnet.outputs.aksVnetId
    isCrossTenant: false
  }
}

module InstallNginxIngress './modules/aks-helm-install/main.bicep' = {
  name: 'install-alb-controller'
  scope: clusterrg
  params: {
    aksName: 'aks-${resourceName}-${userName}'
    location: location
    newOrExistingManagedIdentity: 'new'
    helmOciURL: 'oci://mcr.microsoft.com/application-lb/charts/alb-controller'
    helmApp: 'alb-controller'
    helmAppParams: '--namespace ${albHelmNamespace} --create-namespace --version 1.6.7 --set albController.namespace=${albControllerNamespace} --set albController.podIdentity.clientID=${albsetup.outputs.albIdentityClientId}'
  }
  dependsOn: [
    akscluster
  ]
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
    AGC_SUBNET_ID: aksvnet.outputs.subnetIds[1].id // AGC subnet ID
  }
}
