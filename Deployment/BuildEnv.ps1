param(
    [string]$BUILD_ENV, 
    [string]$RESOURCE_GROUP, 
    [string]$PREFIX,
    [string]$GITHUB_REF,
    [string]$PUBLISHER_EMAIL,
    [string]$PUBLISHER_NAME)

$ErrorActionPreference = "Stop"

$deploymentName = "apimdeploy" + (Get-Date).ToString("yyyyMMddHHmmss")

$rgName = "$RESOURCE_GROUP-$BUILD_ENV"
$deployText = (az deployment group create --name $deploymentName --resource-group $rgName --template-file Deployment/deploy.bicep --parameters `
        prefix=$PREFIX `
        environment=$BUILD_ENV `
        branch=$GITHUB_REF `
        publisherEmail=$PUBLISHER_EMAIL `
        publisherName="$PUBLISHER_NAME")

$deployOutput = ($deployText | ConvertFrom-Json)
$serviceName = $deployOutput.properties.outputs.apimName.value

$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $rgName -ServiceName $serviceName
$apiList = Get-AzApiManagementApi -Context $ApiMgmtContext

$customerService = "Customer Service Rewards API"
$customerServiceApiFound = $apiList | Where-Object { $_.Name -eq $customerService }

if (!$customerServiceApiFound) {
    New-AzApiManagementApi -Context $ApiMgmtContext -Name $customerService -Protocols @("https") -Path "rewards"
    
    $MemberId = New-Object -TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
    $MemberId.Name = "MemberId"
    $MemberId.Description = "Member Id"
    $MemberId.Type = "string"

    $ResponseRepresentation = New-Object -TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementRepresentation
    $ResponseRepresentation.ContentType = 'application/json'
    $ResponseRepresentation.Sample = '{ "points": [ { "value":100, "effective":"2021-08-01",  "expires":"2021-08-31" } ] }'

    $Response = New-Object -TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementResponse
    $Response.StatusCode = 204
    $Response.Representations = @($ResponseRepresentation)
    
    New-AzApiManagementOperation -Context $ApiMgmtContext -ApiId "" -OperationId "61234567890" -Name 'Lookup reward points' -Method 'GET' -UrlTemplate '/rewards/{memberId}/points' -Description "Use this operation to lookup rewards points." -TemplateParameters @($MemberId) -Responses @($Response)
}
