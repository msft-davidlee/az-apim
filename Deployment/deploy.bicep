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
            sample: '{\\r\\n  \\"points\\": [\\r\\n    {\\r\\n      \\"value\\": 100,\r\n      \\"expires\\": \\"2021-12-31\\",\\r\\n      \\"earned\\": \\"2021-01-12\\"\\r\\n    }\\r\\n  ]\\r\\n}'
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
    value: '<!--\\r\\n    IMPORTANT:\\r\\n    - Policy elements can appear only within the <inbound>, <outbound>, <backend> section elements.\\r\\n    - Only the <forward-request> policy element can appear within the <backend> section element.\\r\\n    - To apply a policy to the incoming request (before it is forwarded to the backend service), place a corresponding policy element within the <inbound> section element.\\r\\n    - To apply a policy to the outgoing response (before it is sent back to the caller), place a corresponding policy element within the <outbound> section element.\\r\\n    - To add a policy position the cursor at the desired insertion point and click on the round button associated with the policy.\\r\\n    - To remove a policy, delete the corresponding policy statement from the policy document.\\r\\n    - Policies are applied in the order of their appearance, from the top down.\\r\\n-->\\r\\n<policies>\\r\\n  <inbound>\\r\\n    <cors allow-credentials=\\"true\\">\\r\\n      <allowed-origins>\\r\\n        <origin>https://dleems00dev.developer.azure-api.net</origin>\\r\\n      </allowed-origins>\\r\\n      <allowed-methods preflight-result-max-age=\\"300\\">\\r\\n        <method>*</method>\\r\\n      </allowed-methods>\\r\\n      <allowed-headers>\\r\\n        <header>*</header>\\r\\n      </allowed-headers>\\r\\n      <expose-headers>\\r\\n        <header>*</header>\\r\\n      </expose-headers>\\r\\n    </cors>\\r\\n  </inbound>\\r\\n  <backend>\\r\\n    <forward-request />\\r\\n  </backend>\\r\\n  <outbound />\\r\\n</policies>'
    format: 'xml'
  }
}
