param prefix string
param appEnvironment string
param branch string
param location string = resourceGroup().location
param publisherEmail string
param publisherName string

var stackName = '${prefix}${appEnvironment}'
var tags = {
  'stack-name': stackName
  'environment': appEnvironment
  'branch': branch
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: stackName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    ImmediatePurgeDataOn30Days: true
    IngestionMode: 'ApplicationInsights'
  }
}

var apiapp = '${stackName}api'
resource apiappStr 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: apiapp
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
  tags: tags
}

resource apiappplan 'Microsoft.Web/serverfarms@2020-10-01' = {
  name: apiapp
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

var apiappConnection = 'DefaultEndpointsProtocol=https;AccountName=${apiappStr.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(apiappStr.id, apiappStr.apiVersion).keys[0].value}'
resource apifuncapp 'Microsoft.Web/sites@2020-12-01' = {
  name: apiapp
  location: location
  tags: tags
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: apiappplan.id
    clientAffinityEnabled: true
    siteConfig: {
      webSocketsEnabled: true
      appSettings: [
        {
          'name': 'APPINSIGHTS_INSTRUMENTATIONKEY'
          'value': appinsights.properties.InstrumentationKey
        }
        {
          'name': 'AzureWebJobsDashboard'
          'value': apiappConnection
        }
        {
          'name': 'AzureWebJobsStorage'
          'value': apiappConnection
        }
        {
          'name': 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          'value': apiappConnection
        }
        {
          'name': 'WEBSITE_CONTENTSHARE'
          'value': 'functions2021'
        }
        {
          'name': 'FUNCTIONS_WORKER_RUNTIME'
          'value': 'dotnet'
        }
        {
          'name': 'FUNCTIONS_EXTENSION_VERSION'
          'value': '~3'
        }
        {
          'name': 'ApplicationInsightsAgent_EXTENSION_VERSION'
          'value': '~2'
        }
        {
          'name': 'XDT_MicrosoftApplicationInsights_Mode'
          'value': 'default'
        }
      ]
    }
  }
}

output apifuncName string = apifuncapp.name

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

resource rewardsapipolicy 'Microsoft.ApiManagement/service/apis/policies@2021-04-01-preview' = {
  parent: rewardsapi
  name: 'policy'
  properties: {
    value: loadTextContent('rewardsapi.xml')
    format: 'rawxml'
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
        representations: []
      }
    ]
    displayName: 'Lookup reward points'
    method: 'GET'
    urlTemplate: '/{memberId}/points/year/{year}'
  }
}

var rawValue = replace(replace(loadTextContent('rewardpointslookupbyyear.xml'), '%apifuncName%', apifuncapp.name), '%apifunctionkey%', listKeys(resourceId('Microsoft.Web/sites/functions', apifuncapp.name, 'GetMemberAnnualPoints'), apifuncapp.apiVersion).default)
resource rewardpointslookupbyyearpolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-04-01-preview' = {
  parent: rewardpointslookupbyyear
  name: 'policy'
  properties: {
    value: rawValue
    format: 'rawxml'
  }
}

output apimName string = apim.name
