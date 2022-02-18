param(
    [string]$RESOURCE_GROUP,
    [string]$JWT_CONFIG_APP_ID,
    [string]$JWT_CONFIG_APP_SECRET,
    [string]$JWT_CONFIG_TENANT_ID,
    [string]$StackName,
    [string]$FilePath)

# ClientId= =${{ secrets.JWT_CONFIG_APP_SECRET }} TenantId=${{ secrets.JWT_CONFIG_TENANT_ID }} SubscriptionKey=${{ steps.getsubscriptionkey.outputs.subscriptionKey }} StackName=${{ steps.buildenvironment.outputs.stackName }}
$apimContext = New-AzApiManagementContext -ResourceGroupName $RESOURCE_GROUP -ServiceName $StackName
$keys = Get-AzApiManagementSubscriptionKey -Context $apimContext -SubscriptionId master
$subscriptionKey = $keys.PrimaryKey

$obj = @{ id = "9839bdec-3169-476d-bac2-be860f222568"; "name" = "vars"; values = @( 
        @{ key = "ClientId"; value = $JWT_CONFIG_APP_ID; enabled = $true; }; 
        @{ key = "ClientSecret"; value = $JWT_CONFIG_APP_SECRET; enabled = $true; }; 
        @{ key = "TenantId"; value = $JWT_CONFIG_TENANT_ID; enabled = $true; }; 
        @{ key = "SubscriptionKey"; value = $subscriptionKey; enabled = $true; }; 
        @{ key = "StackName"; value = $StackName; enabled = $true; }; ) 
}
$obj | ConvertTo-Json | Out-File $FilePath -Encoding ASCII