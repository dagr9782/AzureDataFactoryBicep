@description('Location for all resources')
param location string = resourceGroup().location

param tagValues object

@description('Environment')
param env_id string

resource databricks 'Microsoft.Databricks/workspaces@2021-04-01-preview' = {
  name: 'adb-${env_id}-br-project'
  location: location
  properties: {
    managedResourceGroupId: resourceGroup().id
  }
  tags: tagValues
}
