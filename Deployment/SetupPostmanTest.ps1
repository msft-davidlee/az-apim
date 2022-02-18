param(
    [string]$RESOURCE_GROUP,
    [string]$JWT_CONFIG_APP_ID,
    [string]$JWT_CONFIG_APP_SECRET,
    [string]$JWT_CONFIG_TENANT_ID,
    [string]$StackName)

# ClientId= =${{ secrets.JWT_CONFIG_APP_SECRET }} TenantId=${{ secrets.JWT_CONFIG_TENANT_ID }} SubscriptionKey=${{ steps.getsubscriptionkey.outputs.subscriptionKey }} StackName=${{ steps.buildenvironment.outputs.stackName }}
$apimContext = New-AzApiManagementContext -ResourceGroupName $RESOURCE_GROUP -ServiceName $StackName
$keys = Get-AzApiManagementSubscriptionKey -Context $apimContext -SubscriptionId master
$subscriptionKey = $keys.PrimaryKey

$obj = @{ "name" = "vars"; values = @( 
        @{ name = "ClientId"; value = $JWT_CONFIG_APP_ID; }; 
        @{ name = "ClientSecret"; value = $JWT_CONFIG_APP_SECRET; }; 
        @{ name = "TenantId"; value = $JWT_CONFIG_TENANT_ID; }; 
        @{ name = "SubscriptionKey"; value = $subscriptionKey; }; 
        @{ name = "StackName"; value = $StackName; }; ) 
}
$obj | ConvertTo-Json | Out-File environment.json -Encoding ASCII