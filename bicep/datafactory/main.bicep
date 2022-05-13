@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment')
param env_id string

@description('Deploy IR')
param adf_ir bool

@description('Optional. Repository type - can be \'FactoryVSTSConfiguration\' or \'FactoryGitHubConfiguration\'. Default is \'FactoryVSTSConfiguration\'.')
param gitRepoType string = 'FactoryVSTSConfiguration'

@description('Optional. The account name.')
param gitAccountName string = 'raboweb-brazil'

@description('Optional. The project name. Only relevant for \'FactoryVSTSConfiguration\'.')
param gitProjectName string = 'CHANGE: Azure DevOps Project / Squad'

@description('Optional. The repository name.')
param gitRepositoryName string = 'CHANGE: Git Repo'

@description('Optional. The collaboration branch name. Default is \'main\'.')
param gitCollaborationBranch string = 'master'

@description('Optional. The root folder path name. Default is \'/\'.')
param gitRootFolder string = '/'

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: 'adf-${env_id}-br-project'
  location: location
  identity: {
    type: 'SystemAssigned'
    userAssignedIdentities: null
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    repoConfiguration: (env_id == 'dev') ? json('{"type": "${gitRepoType}","accountName": "${gitAccountName}","repositoryName": "${gitRepositoryName}","projectName": "${gitProjectName}","collaborationBranch": "${gitCollaborationBranch}","rootFolder": "${gitRootFolder}"}') : null
  }
  tags: {
      Environment: (toUpper(env_id))
  }
}

@description('Required. The type of Integration Runtime')
@allowed([
  'Managed'
  'SelfHosted'
])
param typeIR string = 'SelfHosted'

var sub = (env_id=='dev' || env_id=='sit') ? '8af6aa43-048b-4792-aa87-a8aa7c7b7b72' : 'cadd3f73-8792-4bae-9cd7-b4a1f3ca0119'
var linkedIR = '/subscriptions/${sub}/resourcegroups/rg-${env_id}-br-dataintegration/providers/Microsoft.DataFactory/factories/adf-${env_id}-br-dataintegration/integrationruntimes/ir-${env_id}-br-dataintegration'

resource integrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = if (adf_ir) {
  name: 'ir-${env_id}-br-project'
  parent: dataFactory
  properties: {
    type: typeIR
    typeProperties: {
      linkedInfo: {
        authorizationType: 'RBAC'
        resourceId: linkedIR
      }
    }
  }
}
