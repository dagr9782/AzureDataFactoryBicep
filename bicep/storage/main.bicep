@description('Location for all resources.')
param location string = resourceGroup().location

param tagValues object

@description('Environment')
param env_id string

@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
@description('Type of Storage Account to create.')
param storageAccountKind string = 'StorageV2'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Storage Account Sku Name.')
param storageAccountSku string = 'Standard_LRS'

@allowed([
  'Hot'
  'Cool'
])
@description('Storage Account Access Tier.')
param storageAccountAccessTier string = 'Hot'

@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
@description('Optional. Set the minimum TLS version on request to storage.')
param minimumTlsVersion string = 'TLS1_2'

@description('If true, enables Hierarchical Namespace for the storage account.')
param enableHierarchicalNamespace bool = true

@description('Optional. Allows HTTPS traffic only to storage service if sets to true.')
param supportsHttpsTrafficOnly bool = true

var supportsBlobService = storageAccountKind == 'BlockBlobStorage' || storageAccountKind == 'BlobStorage' || storageAccountKind == 'StorageV2' || storageAccountKind == 'Storage'
var supportsFileService = storageAccountKind == 'FileStorage' || storageAccountKind == 'StorageV2' || storageAccountKind == 'Storage'

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: 'adf-${env_id}-br-project'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name : 'sa${env_id}brproject' // Max 24 characters
  location: location
  kind: storageAccountKind
  sku: {
    name: storageAccountSku
  }
  properties: {
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: supportsBlobService ? {
          enabled: true
        } : null
        file: supportsFileService ? {
          enabled: true
        } : null
      }
    }
    accessTier: storageAccountKind != 'Storage' ? storageAccountAccessTier : null
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    isHnsEnabled: enableHierarchicalNamespace ? enableHierarchicalNamespace : null
    minimumTlsVersion: minimumTlsVersion
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: resourceId('Microsoft.Network/VirtualNetworks/subnets', 'vn-${env_id}-br-project', 'sn-${env_id}-br-project')
        }
      ]
      ipRules: [
        {
          action: 'Allow'
          value: '147.161.129.0/24' // Scaler Proxy
        }
        {
          action: 'Allow'
          value: '20.38.84.104/30' // Power BI Ireland
        }
        {
          action: 'Allow'
          value: '20.38.84.128/25' // Power BI Ireland
        }
        {
          action: 'Allow'
          value: '20.38.85.0/25' // Power BI Ireland
        }
        {
          action: 'Allow'
          value: '20.38.86.0/24' // Power BI Ireland
        }
        {
          action: 'Allow'
          value: '52.146.140.128/25' // Power BI Ireland
        }
        {
          action: 'Allow'
          value: '37.74.18.112/29' // RFTM Fuse
        }
      ]
    }
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    publicNetworkAccess: 'Enabled'
  }
  tags: tagValues
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: 'default'
  parent: storageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: 'project-datamart'
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}

resource atpSettings 'Microsoft.Security/advancedThreatProtectionSettings@2019-01-01' = {
  name: 'current'
  scope: storageAccount
  properties: {
    isEnabled: true
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'pe-dfs-${env_id}-br-project'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pe-dfs-${env_id}-br-project'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
    subnet: {
      id: resourceId('Microsoft.Network/VirtualNetworks/subnets', 'vn-${env_id}-br-project', 'sn-${env_id}-br-project')
    }
  }
  tags: tagValues
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount.id, dataFactory.id, 'Storage Blob Data Owner')
  properties: {
    description: 'ADF as Storage Blob Data Owner'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
  scope: storageAccount
}
