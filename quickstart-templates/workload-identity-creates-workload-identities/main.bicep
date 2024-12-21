targetScope = 'tenant'
extension microsoftGraph


@description('The display name for the application.')
param applicationIdentityRegistrationDisplayName string

@description('The name for the application.')
param applicationIdentityRegistrationName string

@description('The owner of the organization that it assigned to a workload identity that is used by GitHub Actions to deploy further resources.')
param gitHubOwner string

@description('The GitHub repository that is assigned to a workload identity that is used by GitHub Actions to deploy further resources.')
param gitHubRepo string

@description('Subject of the GitHub Actions workflow\'s federated identity credentials (FIC) that is checked before issuing an Entra ID access token to access Azure resources. GitHub Actions subject examples can be found in https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims.')
var gitHubActionsFederatedIdentitySubject = 'repo:${gitHubOwner}/${gitHubRepo}:ref:refs/heads/main'


// The githubOIDCProvider and microsoftEntraAudience are well-known values that are used to
// create the federated identity credentials for the GitHub Actions application so the two systems
// can properly authenticate and authorize between each other. For other OIDC enabled systems you need to check
// their documentation to find out the correct values so the federated identity credentials can be created
// to connect to Azure.
var githubOIDCProvider = 'https://token.actions.githubusercontent.com'
var microsoftEntraAudience = 'api://AzureADTokenExchange'

// In order for the Azure and GitHub Actions to communicate with each other, an
// application for GitHub Actions is created to Azure Entra. This application is then
// assigned an application role that allows it to access the Microsoft Graph API.
resource githubActionsApplication 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: applicationIdentityRegistrationName
  displayName: applicationIdentityRegistrationDisplayName

  // This creates the federated identity credentials for the GitHub Actions application.
  resource githubFederatedIdentityCredential 'federatedIdentityCredentials@v1.0' = {
    name: '${githubActionsApplication.uniqueName}/githubFederatedIdentityCredential'
    audiences: [microsoftEntraAudience]
    description: 'Identity for application to deploy the root identity infrastructure.'
    issuer: githubOIDCProvider
    subject: gitHubActionsFederatedIdentitySubject
    }
}


// This is the Azure service principal the GitHub Actions application is assigned to.
resource gitHubIdentityActionsServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  displayName: applicationIdentityRegistrationDisplayName
  appId: githubActionsApplication.appId
}


// The identifier '00000003-0000-0000-c000-000000000000' is a well-known identifier
// for Microsoft first part application 'Microsoft Graph', see more at
// https://learn.microsoft.com/en-us/troubleshoot/azure/entra/entra-id/governance/verify-first-party-apps-sign-in.
resource microsoftGraphServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' existing = {
  appId: '00000003-0000-0000-c000-000000000000'
}


// This searches the used application role permission by its friendly name. There should be only one,
// so the fist one is taken to be used in the symbolic name.
// See at https://learn.microsoft.com/en-us/graph/permissions-reference#applicationreadwriteownedby
// for the actual description. Look also at https://www.azadvertizer.net/azEntraIdAPIpermissionsAdvertizer.html?targetPermissionId=18a4783c-866b-4cc7-a460-3d5e5662c884
// how one can search for permissions GUIDs. Using clear names is clearer.
//
// TODO: At the moment 'Application.ReadWrite.All' is used because there's a bug in
// Azure. See at https://github.com/microsoftgraph/msgraph-bicep-types/issues/142 and at
// https://learn.microsoft.com/en-us/graph/permissions-reference#approleassignmentreadwriteall.
param appRoleName string = 'Application.ReadWrite.All'
var graphAppRoles = microsoftGraphServicePrincipal.appRoles
var appRoleDetail = filter(graphAppRoles, graphAppRoles => graphAppRoles.value == appRoleName)[0]


// Assign the GitHub Actions service principal the Application.ReadWrite.OwnedBy permission, 
// which allows the service principal to be able to create and manage the applications and service principals is creates/owns.
resource symbolicname 'Microsoft.Graph/appRoleAssignedTo@v1.0' = {
  appRoleId: appRoleDetail.id
  principalId: gitHubIdentityActionsServicePrincipal.id
  resourceId: microsoftGraphServicePrincipal.id
}

// This outputs the application ID of the GitHub Actions application. So, for instance, this can be
// used in a PowerShell or a Bash Script to set the AZURE_CLIENT_ID environment variable in GitHub.
output appId string = githubActionsApplication.appId
