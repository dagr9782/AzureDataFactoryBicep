@description('Location for all Resources.')
param location string = 'brazilsouth'

param param_buildNumber string
param param_env_id string
param param_secret_pwd_example string
param param_vnet_address string
param param_adf_ir bool

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'rg-${param_env_id}-br-project-datafactory'
  location: location
}

module network 'network/main.bicep' = {
  scope: resourceGroup
  name: 'network-${param_buildNumber}'
  params: {
    env_id: param_env_id
    location: location
    param_vnet_address: param_vnet_address
  }
}

module security 'security/main.bicep' = {
  scope: resourceGroup
  name: 'security-${param_buildNumber}'
  params: {
    env_id: param_env_id
    location: location
    param_secret_pwd_example: param_secret_pwd_example
  }
}

module dataFactory 'datafactory/main.bicep' = {
  scope: resourceGroup
  name: 'datafactory-${param_buildNumber}'
  params: {
    env_id: param_env_id
    location: location
    adf_ir: param_adf_ir
  }
}
