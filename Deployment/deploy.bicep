param prefix string
param environment string
param branch string
param location string = resourceGroup().location
param publisherEmail string
param publisherName string

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

resource rewardsset 'Microsoft.ApiManagement/service/apiVersionSets@2021-01-01-preview' = {
  name: '${apim.name}/customerapi'
  properties: {
    displayName: 'Rewards API'
    description: 'Rewards lookup for customers'
    versioningScheme: 'Segment'
  }
}

resource rewardsapicustomer 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: 'rewards'
  parent: apim
  properties: {
    displayName: 'Rewards'
    apiVersion: 'v1'
    description: 'This is a rewards api to award points and lookup points'
    apiVersionSetId: rewardsset.id
    path: '/'
    protocols: [
      'https'
    ]
  }
}

var schemaId = '1628259663928'

resource rewardsapicustomerschema 'Microsoft.ApiManagement/service/apis/schemas@2021-01-01-preview' = {
  name: schemaId
  parent: rewardsapicustomer
  properties: {
    contentType: 'application/vnd.oai.openapi.components+json'
    document: {}
  }
}

resource rewardsapicustomerops 'Microsoft.ApiManagement/service/apis/operations@2021-01-01-preview' = {
  name: 'customer'
  parent: rewardsapicustomer
  properties: {
    displayName: 'Customer'
    method: 'GET'
    urlTemplate: '/customer/{cardnumber}'
    templateParameters: [
      {
        name: 'cardnumber'
        required: true
        type: 'string'
        schemaId: schemaId
      }
    ]
    responses: [
      {
        statusCode: 200
        description: 'Customer points details based on card number'
        representations: [
          {
            contentType: 'application/json'
            typeName: 'Points'
            sample: loadTextContent('Sample.json')
          }
        ]
      }
    ]
  }
}

resource rewardsapicustomerpolicy 'Microsoft.ApiManagement/service/policies@2021-01-01-preview' = {
  name: 'policy'
  parent: apim
  properties: {
    value: replace(loadTextContent('Policy.xml'), '%name%', apim.name)
    format: 'xml'
  }
}
