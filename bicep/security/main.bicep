@description('TenantID')
param tenantId string = '6e93a626-8aca-4dc1-9191-ce291b4b75a1'

@description('Location for all resources')
param location string = resourceGroup().location

param tagValues object

@description('Environment')
param env_id string

@description('Connection Password')
@secure()
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
    objectId: dataFactory.identity.principalId // Data Factory Managed Identity Object ID
    permissions: {
      secrets: [
        'get'
        'list'
      ]
    } 
  }
]

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: 'adf-${env_id}-br-project'
}

// Vault

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'akv-${env_id}-br-project'
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    accessPolicies: accessPolicies
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
          {
            id: resourceId('Microsoft.Network/VirtualNetworks/subnets', 'vn-${env_id}-br-project', 'sn-${env_id}-br-project')
          }
      ]
      ipRules: []
    }
    publicNetworkAccess: 'Disabled'
  }
  tags: tagValues
}

// Secrets

resource secret_pwd_project 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'pwd-example'
  parent: keyVault
  properties: {
    value: param_secret_pwd_example
  }
}

// Certificates

// Subscription Role assignments
