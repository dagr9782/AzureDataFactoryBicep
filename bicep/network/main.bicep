@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment')
param env_id string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'vn-${env_id}-br-project-datafactory'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        'CHANGE: 10.10.37.0/24'
      ]
    }
    subnets: [
      {
        name: 'sn-${env_id}-br-project-datafactory'
        properties: {
          addressPrefix: 'CHANGE: 10.10.37.0/24'
          networkSecurityGroup: {
              id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${env_id}-br-project-datafactory'
  location: location
}
