param([string]$rgName, [string]$serviceName)

if (!$rgName) {
    throw "RG cannot be empty!"
}

if (!$serviceName) {
    throw "Service name cannot be empty!"
}

$ApiMgmtContext = New-AzApiManagementContext -ResourceGroupName $rgName -ServiceName $serviceName

$apiList = Get-AzApiManagementApi -Context $ApiMgmtContext

$RewardsName = "Rewards API"
$RewardId = "rewards-api"
$ApiFound = $apiList | Where-Object { $_.Name -eq $RewardsName }

if (!$ApiFound) {
    New-AzApiManagementApi -Context $ApiMgmtContext -ApiId $RewardId -Name $RewardsName -Protocols @("https") -Path "rewards" -ServiceUrl "https://contoso"
    
    $MemberIdParam = New-Object -TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
    $MemberIdParam.Name = "memberId"
    $MemberIdParam.Description = "Member Id"
    $MemberIdParam.Type = "string"

    $YearParam = New-Object -TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementParameter
    $YearParam.Name = "year"
    $YearParam.Description = "Year"
    $YearParam.Type = "integer"

    $ResponseRepresentation = New-Object -TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementRepresentation
    $ResponseRepresentation.ContentType = 'application/json'
    $ResponseRepresentation.Sample = '{ "points": [ { "value":100, "effective":"2021-08-01",  "expires":"2021-08-31" } ] }'

    $Response = New-Object -TypeName Microsoft.Azure.Commands.ApiManagement.ServiceManagement.Models.PsApiManagementResponse
    $Response.StatusCode = 200
    $Response.Representations = @($ResponseRepresentation)
    
    New-AzApiManagementOperation -Context $ApiMgmtContext -ApiId $RewardId -OperationId "61234567890" `
        -Name 'Lookup reward points' `
        -Method 'GET' `
        -UrlTemplate '/rewards/{memberId}/points/year/{year}' `
        -Description "Use this operation to lookup rewards points." `
        -TemplateParameters @($MemberIdParam, $YearParam) `
        -Responses @($Response)
}

$Policy = @"
<policies>
    <inbound>
        <mock-response status-code="200" content-type="application/json" />
        <base />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
"@

Set-AzApiManagementPolicy -Context $ApiMgmtContext -ApiId $RewardId -Policy $Policy