param(
    [string]$BUILD_ENV,
    [string]$RUN_NUMBER,
    [string]$RESOURCE_GROUP, 
    [string]$PREFIX,
    [string]$GITHUB_REF,
    [string]$PUBLISHER_EMAIL,
    [string]$PUBLISHER_NAME,
    [string]$JWT_CONFIG_APP_ID,
    [string]$JWT_CONFIG_TENANT_ID)

$ErrorActionPreference = "Stop"

$deploymentName = "apimfirstdeploy" + (Get-Date).ToString("yyyyMMddHHmmss")

$firstDeployText = (az deployment group create --name $deploymentName --resource-group $RESOURCE_GROUP --template-file Deployment/first.bicep --parameters `
        prefix=$PREFIX `
        version=$RUN_NUMBER `
        stackEnvironment=$BUILD_ENV `
        branch=$GITHUB_REF)

$firstDeployOutput = ($firstDeployText | ConvertFrom-Json)

$apifunctionName = $firstDeployOutput.properties.outputs.apifunctionName.value
$apifunctionVersion = $firstDeployOutput.properties.outputs.apifunctionVersion.value
$appInsightsInstrumentationKey = $firstDeployOutput.properties.outputs.appInsightsInstrumentationKey.value
$appInsightsResourceId = $firstDeployOutput.properties.outputs.appInsightsResourceId.value

Push-Location .\src\Demo\DemoApi\
dotnet publish -c Release -o out
Compress-Archive out\* -DestinationPath out.zip -Force
az functionapp deployment source config-zip -g $RESOURCE_GROUP -n $apifunctionName --src out.zip
Pop-Location

$deploymentName = "apimdeploy" + (Get-Date).ToString("yyyyMMddHHmmss")

az deployment group create --name $deploymentName --resource-group $RESOURCE_GROUP --template-file Deployment/deploy.bicep --parameters `
    prefix=$PREFIX `
    stackEnvironment=$BUILD_ENV `
    branch=$GITHUB_REF `
    version=$RUN_NUMBER `
    jwtConfigAppId=$JWT_CONFIG_APP_ID `
    jwtConfigTenantId=$JWT_CONFIG_TENANT_ID `
    apifunctionName=$apifunctionName `
    apifunctionVersion=$apifunctionVersion `
    appInsightsInstrumentationKey=$appInsightsInstrumentationKey `
    appInsightsResourceId=$appInsightsResourceId `
    publisherEmail=$PUBLISHER_EMAIL `
    publisherName="$PUBLISHER_NAME"
