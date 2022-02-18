param prefix string
param stackEnvironment string
param branch string
param version string
param location string = 'centralus'

var stackName = '${prefix}${stackEnvironment}'
var tags = {
  'stack-name': stackName
  'stack-version': version
  'stack-environment': stackEnvironment
  'stack-branch': branch
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
          'value': '~4'
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

output apifunctionName string = apifuncapp.name
output apifunctionVersion string = apifuncapp.apiVersion
output appInsightsInstrumentationKey string = appinsights.properties.InstrumentationKey
output appInsightsResourceId string = appinsights.id
