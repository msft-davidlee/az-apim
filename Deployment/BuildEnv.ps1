param(
    [string]$BUILD_ENV, 
    [string]$RESOURCE_GROUP, 
    [string]$PREFIX,
    [string]$GITHUB_REF,
    [string]$PUBLISHER_EMAIL,
    [string]$PUBLISHER_NAME,
    [string]$JWT_CONFIG_APP_ID,
    [string]$JWT_CONFIG_TENANT_ID)

$ErrorActionPreference = "Stop"

$deploymentName = "apimdeploy" + (Get-Date).ToString("yyyyMMddHHmmss")

$rgName = "$RESOURCE_GROUP-$BUILD_ENV"

$firstDeployText = (az deployment group create --name $deploymentName --resource-group $rgName --template-file Deployment/first.bicep --parameters `
        prefix=$PREFIX `
        appEnvironment=$BUILD_ENV `
        branch=$GITHUB_REF)

$firstDeployOutput = ($firstDeployText | ConvertFrom-Json)

$apifunctionName = $firstDeployOutput.properties.outputs.apifunctionName.value

Push-Location .\src\Demo\DemoApi\
dotnet publish -c Release -o out
Compress-Archive out\* -DestinationPath out.zip -Force
az functionapp deployment source config-zip -g $rgName -n $apifunctionName --src out.zip
Pop-Location

az deployment group create --name $deploymentName --resource-group $rgName --template-file Deployment/deploy.bicep --parameters `
    prefix=$PREFIX `
    appEnvironment=$BUILD_ENV `
    branch=$GITHUB_REF `
    jwtConfigAppId=$JWT_CONFIG_APP_ID `
    jwtConfigTenantId=$JWT_CONFIG_TENANT_ID `
    apifunctionName=$apifunctionName `
    apifunctionVersion=$firstDeployOutput.properties.outputs.apifunctionVersion.value `
    appInsightsInstrumentationKey=$firstDeployOutput.properties.outputs.appInsightsInstrumentationKey.value `
    appInsightsResourceId=$firstDeployOutput.properties.outputs.appInsightsResourceId.value `
    publisherEmail=$PUBLISHER_EMAIL `
    publisherName="$PUBLISHER_NAME"
