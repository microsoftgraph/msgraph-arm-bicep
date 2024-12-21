# Create Workload Identity Federation that can create other workload identity federations

## The Idea

Create federated identity credentials (FIC) at appropriate scopes and controls to deploy company and project specific resource. The process is rooted in a Git pull request review process in order to introduce checkpoints, audit trail and repeatability to process. This should restrict the need for manual work requiring high privileges.

## Example scenario

A high-privilege user creates an initial, bootstrap workload identity federation token between Azure and a certain GitHub repository. The workload in this repository is then allowed to access Microsoft Entra to create further workload identity federation tokens and assign them to other repositories.

The goal is to create a GitHub repository that is privileged enough to create further, more specific federated identifier according to needs of specific projects. This way creating resources can be support by pull request reviews. Together with application roles and restricting the federated identity credential (FIC) access to a certain repository, one can reduce the "blast radius" for any given project and repository and human operators.

## Benefits

- **Enhanced Security:** Restricting high-privilege usage reduces the attack surface and potential for unauthorized access.
- **Scalability:** Facilitates the growth of projects by enabling the creation of new identity federations as needed.
- **Efficient Management:** Streamlines the process of managing resource access across multiple projects and teams.

## Usage could look something like this

### az cli

```sh
# Sign in to Azure.
az login

# Sign in to GitHub.
gh auth login

# Deploy the Bicep template and capture the output as JSON.
deploymentOutput=$(az deployment tenant create --name bootstrap --location WestEurope --template-file ./main.bicep --parameters ./main.bicepparam --output json)

# Extract appId from the deployment output using jq.
appId=$(echo $deploymentOutput | jq -r '.properties.outputs.appId.value')

# The GitHub repository information.
gitHubOwner="myRoot"
gitHubRepo="myRepo"

# Set GitHub secrets using the GitHub CLI
gh secret set AZURE_CLIENT_ID --repo "${gitHubOwner}/${gitHubRepo}" --body "$appId"
gh secret set AZURE_TENANT_ID --repo "${gitHubOwner}/${gitHubRepo}" --body "$(az account show --query tenantId --output tsv)"
```

### PowerShell

```powershell

# Sign in to Azure.
Connect-AzAccount

# Sign in to GitHub.
gh auth login

# Deploy the Bicep template and capture the output as a JSON string.
$deploymentOutput = New-AzTenantDeployment -Name bootstrap -Location "WestEurope" TemplateFile ./main.bicep -TemplateParametersFile ./main.bicepparam -Verbose

# Extract appId from the deployment output.
$appId = $deploymentOutput.Properties.Outputs.appId.Value

# The GitHub repository information.
$gitHubOwner = "myRoot"
$gitHubRepo = "myRepo"

# Set GitHub secrets using the GitHub CLI.
gh secret set AZURE_CLIENT_ID --repo "$gitHubOwner/$gitHubRepo" --body $appId

$tenantId = (Get-AzTenant).Id
gh secret set AZURE_TENANT_ID --repo "$gitHubOwner/$gitHubRepo" --body $tenantId
```
