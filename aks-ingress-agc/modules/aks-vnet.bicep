param location string
param vnetName string
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

output subnetIds array = [
  for subnet in subnets: {
    name: subnet.name
    id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet.name)
  }
]
output aksVnetId string = vnet.id
