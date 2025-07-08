@description('The name of the Azure Kubernetes Service')
param aksName string

@description('Azure Kubernetes Service Virtual Network Resource Id')
param aksVnetId string

@description('Azure Kubernetes Service Virtual Network Resource Id')
param nodeResourceGroupName string

@description('The location to deploy the resources to')
param location string

@description('An array of Azure RoleIds that are required for the DeploymentScript resource')
param rbacRolesNeeded array = [
  'acdd72a7-3385-48ef-bd42-f606fba81ae7' //Reader
  'fbc52c3f-28ad-4303-a892-8a056630b8f1' //AGC Configuration Manager
]

@description('An array of Azure RoleIds that are required for the DeploymentScript resource')
param albRolesNeeded array = [
  '4d97b98b-1d4f-4787-a291-c67834d212e7' //Network Contributor
]

@description('Name of the Managed Identity resource')
param managedIdentityName string = 'azure-alb-identity'

@description('Set to true when deploying template across tenants') 
param isCrossTenant bool = false

resource aks 'Microsoft.ContainerService/managedClusters@2025-03-01' existing = {
  name: aksName
}

var oidcIssuerUrl = aks.properties.oidcIssuerProfile.issuerURL

resource albIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: managedIdentityName
  location: location
}

var delegatedManagedIdentityResourceId = albIdentity.id

module nodeRgRoleAssignments 'alb-auth.bicep' = {
  name: 'nodeRgRoleAssignments'
  scope: resourceGroup(nodeResourceGroupName)
  params: {
    rbacRolesNeeded: rbacRolesNeeded
    albIdentityPrincipalId: albIdentity.properties.principalId
    aksId: aks.id
    albIdentityId: albIdentity.id
    isCrossTenant: isCrossTenant
    delegatedManagedIdentityResourceId: delegatedManagedIdentityResourceId
  }
}

resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {
  name: managedIdentityName
  parent: albIdentity
  properties: {
    issuer: oidcIssuerUrl
    subject: 'system:serviceaccount:azure-alb-system:alb-controller-sa'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: last(split(aksVnetId, '/'))
}

resource albRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefId in albRolesNeeded: {
  name: guid(roleDefId, albIdentity.id)
  scope: vnet
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefId)
    description: 'Assign agc managed identity network contributor role on the cluster vnet'
    principalId: albIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}]

output albIdentityId string = albIdentity.id
output albIdentityClientId string = albIdentity.properties.clientId
output albIdentityPrincipalId string = albIdentity.properties.principalId
