using './main.bicep'

@description('The display name for the application.')
param applicationIdentityRegistrationDisplayName = 'GitHub Actions Example Application Deployer'

@description('The name for the application.')
param applicationIdentityRegistrationName = 'root-appident-deployer'

@description('The owner of the organization that it assigned to a workload identity that is used by GitHub Actions to deploy further resources.')
param gitHubOwner = 'github-owner'

@description('The GitHub repository that is assigned to a workload identity that is used by GitHub Actions to deploy further resources.')
param gitHubRepo =  'github-repo'
