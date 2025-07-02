param principalId string
param roleDefinition string
param vnetResourceId string

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: last(split(vnetResourceId, '/'))
}

resource netContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(roleDefinition, principalId)
  scope: vnet
  properties: {
    roleDefinitionId: roleDefinition
    description: 'Assign the agic managed identity contributor role on the cluster vnet'
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
