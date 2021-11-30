param prefix string
param environment string
param branch string
param location string = resourceGroup().location
param publisherEmail string
param publisherName string
param managedUserId string = 'apim${environment}user'
param scriptVersion string = utcNow()

var stackName = '${prefix}${environment}'
var tags = {
  'stack-name': stackName
  'environment': environment
  'branch': branch
}

resource apim 'Microsoft.ApiManagement/service@2021-01-01-preview' = {
  name: stackName
  location: location
  tags: tags
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

resource rewardsapi 'Microsoft.ApiManagement/service/apis@2021-04-01-preview' = {
  parent: apim
  name: 'rewards-api'
  properties: {
    subscriptionRequired: true
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    apiRevision: '1'
    isCurrent: true
    displayName: 'Rewards API'
    serviceUrl: 'https://contoso'
    path: 'rewards'
    protocols: [
      'http'
      'https'
    ]
  }
}

resource rewardpointslookupbyyear 'Microsoft.ApiManagement/service/apis/operations@2021-04-01-preview' = {
  parent: rewardsapi
  name: 'rewards-points-lookup-by-year'
  properties: {
    templateParameters: [
      {
        name: 'memberId'
        description: 'Member Id'
        type: 'string'
        required: true
        values: []
      }
      {
        name: 'year'
        description: 'Year'
        type: 'integer'
        required: true
        values: []
      }
    ]
    description: 'Use this operation to lookup rewards points.'
    responses: [
      {
        statusCode: 200
        headers: []
        representations: [
          {
            contentType: 'application/json'
            sample: loadTextContent('sample.json')
          }
        ]
      }
    ]
    displayName: 'Lookup reward points'
    method: 'GET'
    urlTemplate: '/{memberId}/points/year/{year}'
  }
}

// resource staticSetup 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: stackName
//   kind: 'AzurePowerShell'
//   location: location
//   tags: tags
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${managedUserId}': {}
//     }
//   }
//   properties: {
//     forceUpdateTag: scriptVersion
//     azPowerShellVersion: '5.0'
//     retentionInterval: 'P1D'
//     arguments: '-rgName ${resourceGroup().name} -serviceName ${apim.name}'
//     scriptContent: loadTextContent('BuildApi.ps1')
//   }
// }

output apimName string = apim.name
