# Disclaimer
The information contained in this README.md file and any accompanying materials (including, but not limited to, scripts, sample codes, etc.) are provided "AS-IS" and "WITH ALL FAULTS." Any estimated pricing information is provided solely for demonstration purposes and does not represent final pricing and Microsoft assumes no liability arising from your use of the information. Microsoft makes NO GUARANTEES OR WARRANTIES OF ANY KIND, WHETHER EXPRESSED OR IMPLIED, in providing this information, including any pricing information.

# Introduction
This project helps you get started with the Developer SKU version of API Management. Note that deployment can take up to 1.5 hours.

# Get Started
To create this APIM environment in your Azure subscription, please follow the steps below. 

1. Fork this git repo. See: https://docs.github.com/en/get-started/quickstart/fork-a-repo
2. Create two resource groups to represent two environments. Suffix each resource group name with either a -dev or -prod. An example could be apim-dev and apim-prod.
3. Next, you must create a service principal with Contributor roles assigned to the two resource groups.
4. In your github organization for your project, create two environments, and named them dev and prod respectively.
5. Create the following secrets in your github per environment. Be sure to populate with your desired values. The values below are all suggestions.
6. Note that the environment suffix of dev or prod will be appened to your resource group but you will have the option to define your own resource prefix.
7. Create a Managed user with this convention apim\environment\user and assign with Contributor role. This is needed to run the deployment script.

## Secrets
| Name | Comments |
| --- | --- |
| AZURE_CREDENTIALS | <pre>{<br/>&nbsp;&nbsp;&nbsp;&nbsp;"clientId": "",<br/>&nbsp;&nbsp;&nbsp;&nbsp;"clientSecret": "", <br/>&nbsp;&nbsp;&nbsp;&nbsp;"subscriptionId": "",<br/>&nbsp;&nbsp;&nbsp;&nbsp;"tenantId": "" <br/>}</pre> |
| PREFIX | myapim - or whatever name you would like for all your resources |
| RESOURCE_GROUP | apim - or whatever name you give to the resource group |
| PUBLISHER_EMAIL | your email address |
| PUBLISHER_NAME | your name |

# Interactive Demo
Once you have your APIM created, you can go through the following steps to configure your APIM instance.

## Setup security.

## DevOps - Migration Tool
Shows how we can migrate API changes from an existing APIM instance to a another (could be new or existing) i.e. from Dev to Prod APIM instance.

1. Clone the following repo: https://github.com/Azure/azure-api-management-devops-resource-kit.git
2. Create the following file and give it the name export.json:

```
{
    "sourceApimName": "",
    "destinationApimName": "",
    "resourceGroup": "",
    "fileFolder": "",
    "apiName": "rewards-api",
    "linkedTemplatesBaseUrl": "",
    "paramNamedValue": "false",
    "paramLogResourceId": "false"
} 
```
3. Fill in the sourceApimName, destinationApimName, resourceGroup that represents your migration of API from source APIM to destination APIM instance.
4. Fill in the fileFolder which represents the folder of where to deploy the changes to. Be sure the folder path exist.
5. Now you are ready to run the command. You can cd into the folder of the repo and run the following command which will create the ARM Template used for deployment.

```
 dotnet run extract --extractorConfig <path to export file>\export.json
```