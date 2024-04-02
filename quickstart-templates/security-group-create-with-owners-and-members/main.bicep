provider microsoftGraph

@description('location of the resource group')
param location string = resourceGroup().location

resource resourceApp 'Microsoft.Graph/applications@v1.0' existing = {
  uniqueName: 'ExampleResourceApp'
}

resource resourceSp 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: resourceApp.appId
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'ExampleManagedIdentity'
  location: location
}

resource group 'Microsoft.Graph/groups@v1.0' = {
  uniqueName: 'ExampleGroup'
  displayName: 'Example Group'
  mailEnabled: false
  mailNickname: 'exampleGroup'
  securityEnabled: true
  owners: [
    resourceSp.id
  ]
  members: [
    managedIdentity.properties.principalId
  ]
}
