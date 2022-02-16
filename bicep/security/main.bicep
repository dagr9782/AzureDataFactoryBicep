@description('TenantID')
param tenantId string = '6e93a626-8aca-4dc1-9191-ce291b4b75a1'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment')
param env_id string

@description('Connection Password')
param param_secret_pwd_example string

@description('Name of the SKU desired')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

var accessPolicies = [
  {
    tenantId: tenantId
    objectId: dataFactory.id // Data Factory Managed Identity Object ID
    permissions: {
      secrets: [
        'get'
        'list'
      ]
    } 
  }
]

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: 'adf-${env_id}-br-project-datafactory'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: 'vn-${env_id}-br-project-datafactory'
}

// Vault

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: 'akv-${env_id}-br-project-datafactory'
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    accessPolicies: accessPolicies
  }
  dependsOn: [
    virtualNetwork
  ]
}

// Secrets

resource secret_pwd_project 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: 'akv-${env_id}-br-project-datafactory/pwd-example'
  properties: {
    value: param_secret_pwd_example
  }
  dependsOn: [
    keyVault
  ]
}

// Certificates

// Subscription Role assignments
