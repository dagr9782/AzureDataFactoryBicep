@description('Location for all resources')
param location string = resourceGroup().location

param tagValues object

@description('Environment')
param env_id string

@description('VNET Address')
param param_vnet_address string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'vn-${env_id}-br-project'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        param_vnet_address
      ]
    }
    subnets: [
      {
        name: 'sn-${env_id}-br-project'
        properties: {
          addressPrefix: param_vnet_address
          networkSecurityGroup: {
              id: networkSecurityGroup.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
          ]
        }
      }
    ]
  }
  tags: tagValues
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${env_id}-br-project'
  location: location
  tags: tagValues
}
