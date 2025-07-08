@description('An array of Azure RoleIds that are required for the DeploymentScript resource')
param rbacRolesNeeded array

@description('The principal ID of the ALB managed identity')
param albIdentityPrincipalId string

@description('The resource ID of the AKS cluster')
param aksId string

@description('The resource ID of the ALB managed identity')
param albIdentityId string

@description('Set to true when deploying template across tenants')
param isCrossTenant bool

@description('The delegated managed identity resource ID')
param delegatedManagedIdentityResourceId string

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefId in rbacRolesNeeded: {
  name: guid(aksId, roleDefId, albIdentityId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefId)
    principalId: albIdentityPrincipalId
    principalType: 'ServicePrincipal'
    delegatedManagedIdentityResourceId: isCrossTenant ? delegatedManagedIdentityResourceId : null
  }
}]
