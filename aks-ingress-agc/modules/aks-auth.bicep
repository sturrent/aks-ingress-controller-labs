param principalId string
param roleDefinition string

resource aksContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(roleDefinition, principalId)
  properties: {
    roleDefinitionId: roleDefinition
    description: 'Assign the cluster user-defined managed identity contributor role on the resource group.'
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
