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
az deployment group create --name $deploymentName --resource-group $rgName --template-file Deployment/deploy.bicep --parameters `
        prefix=$PREFIX `
        environment=$BUILD_ENV `
        branch=$GITHUB_REF `
        publisherEmail=$PUBLISHER_EMAIL `
        publisherName="$PUBLISHER_NAME"
