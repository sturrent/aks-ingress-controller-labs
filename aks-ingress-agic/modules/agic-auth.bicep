param principalId string
param roleDefinition string

resource netContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(roleDefinition, principalId)
  properties: {
    roleDefinitionId: roleDefinition
    description: 'Assign the agic managed identity contributor role on the cluster vnet'
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
