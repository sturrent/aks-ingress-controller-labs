param location string
param vnetName string
param subnetName string
param vvnetPreffix array
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vvnetPreffix
    }
    subnets: subnets
  }
}

var aksSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

output aksVnetId string = vnet.id
output akssubnet string = aksSubnetId
output vnetName string = vnet.name
