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
| JWT_CONFIG_APP_ID | App Id which is the Client Id of the application registration you have created. |
| JWT_CONFIG_TENANT_ID | Tenant Id of the AAD instance the application is created in. |

# Interactive Demo(s)
Once you have your APIM created, you can go through the following steps to configure your APIM instance.

## Self-Hosted Gateway Demo
Shows how we can use APIM as the frontend for an internal application hosted "on premise".

1. cd into the src/Demo folder
2. Run the following command to create the docker image ``` docker build -f /DemoHosted/AppDockerfile -t "demo/hostedapp:1.0" . ```.
3. Run the following command to run the docker container ``` docker run -d -p 8090:80 --name hostedapp "demo/hostedapp:1.0" ```.
4. Run the following command to ensure the app is running ``` curl "http://localhost:8090/rewards?memberId=1234A&year=2021" ```
5. You should see something similar:

```
StatusCode        : 200
StatusDescription : OK
Content           : {"memberId":"1234A","points":[{"effective":"2021-03-01T00:00:00","expires":"2021-05-01T00:00:00","value":12}]}
RawContent        : HTTP/1.1 200 OK
                    Transfer-Encoding: chunked
                    Content-Type: application/json; charset=utf-8
                    Date: Wed, 01 Dec 2021 14:54:01 GMT
                    Server: Kestrel

                    {"memberId":"1234A","points":[{"effective":"2021-03-...
Forms             : {}
Headers           : {[Transfer-Encoding, chunked], [Content-Type, application/json; charset=utf-8], [Date, Wed, 01 Dec 2021 14:54:01 GMT], [Server, Kestrel]}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : mshtml.HTMLDocumentClass
RawContentLength  : 110
```
6. Next, you can follow the instructions here to setup your self-hosted APIM gateway https://docs.microsoft.com/en-us/azure/api-management/how-to-deploy-self-hosted-gateway-docker
7. After you have complete this step, we should inspect the internal IP addresses of both the APIM gateway container and Hosted App container. Do a ``` docker ps ``` to see the container id and use that for the following command: ``` docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' CONTAINER_ID ```. If you want to do a quick test locally, you can also login to the container itself using the following command ``` docker exec -it corp /bin/bash ```. This allows you to now do ``` curl "http://IP_ADDRESS/rewards?memberId=1234A&year=2021" ``` inside of the container itself.
8. Now we are ready to build the API. We can clone the Rewards API, maybe give the API URL suffix rewards2 as the value. Next, we should change the gateway from Managed to corp. Lastly, we should add a re-write policy with the following ``` /rewards?memberId={memberId}&year={year} ``` to transform the incoming request to the expected request going to the local service.
9. Note that your APIM self-hosted gateway is running locally on port 80 by default if you did not change any setthings. You can now craft the following type of HTTP GET request ``` http://localhost/rewards2/5454/points/year/2012 ```. Obviously, you need to add the necessary Subscription Key as it is enabled. 

## DevOps - Migration Tool Demo
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
6. Now you can run the update to your new instance with commands such as ``` az deployment group create ```.