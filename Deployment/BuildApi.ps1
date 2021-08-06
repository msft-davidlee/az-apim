param([string]$rgName, [string]$serviceName)

if (!$rgName) {
    throw "RG cannot be empty!"
}

if (!$serviceName) {
    throw "Service name cannot be empty!"
}

$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $rgName -ServiceName $serviceName

$customerService = "CustomerServiceRewardsAPI"
$apiList = Get-AzApiManagementApi -Context $ApiMgmtContext -Name $customerService

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
    
    New-AzApiManagementOperation -Context $ApiMgmtContext -ApiId "LookupRewardPoints" -OperationId "61234567890" -Name 'Lookup reward points' -Method 'GET' -UrlTemplate '/rewards/{memberId}/points' -Description "Use this operation to lookup rewards points." -TemplateParameters @($MemberId) -Responses @($Response)
}