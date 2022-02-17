param prefix string
param stackEnvironment string
param branch string
param location string = 'centralus'
param publisherEmail string
param publisherName string
param jwtConfigAppId string
param jwtConfigTenantId string
param apifunctionName string
param apifunctionVersion string
param appInsightsInstrumentationKey string
param appInsightsResourceId string
param version string

var stackName = '${prefix}${stackEnvironment}'
var tags = {
  'stack-name': stackName
  'stack-version': version
  'stack-environment': stackEnvironment
  'stack-branch': branch
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
    path: 'rewards'
    protocols: [
      'http'
      'https'
    ]
  }
}

var rawValueapi = replace(replace(loadTextContent('rewardsapi.xml'), '%jwtconfigappid%', jwtConfigAppId), '%jwtconfigtenantid%', jwtConfigTenantId)
resource rewardsapipolicy 'Microsoft.ApiManagement/service/apis/policies@2021-04-01-preview' = {
  parent: rewardsapi
  name: 'policy'
  properties: {
    value: rawValueapi
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

var rawValue = replace(replace(loadTextContent('rewardpointslookupbyyear.xml'), '%apifuncName%', apifunctionName), '%apifunctionkey%', listKeys(resourceId('Microsoft.Web/sites/functions', apifunctionName, 'GetMemberAnnualPoints'), apifunctionVersion).default)
resource rewardpointslookupbyyearpolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-04-01-preview' = {
  parent: rewardpointslookupbyyear
  name: 'policy'
  properties: {
    value: rawValue
    format: 'rawxml'
  }
}

output apimName string = apim.name

resource apimlogger 'Microsoft.ApiManagement/service/loggers@2021-04-01-preview' = {
  parent: apim
  name: stackName
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
    resourceId: appInsightsResourceId
  }
}

resource apimselfhostedgateway 'Microsoft.ApiManagement/service/gateways@2021-04-01-preview' = {
  parent: apim
  name: 'corp'
  properties: {
    locationData: {
      name: 'Dallas TX'
    }
  }
}
