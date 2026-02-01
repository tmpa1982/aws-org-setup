# PowerShell script to deploy the Organization Structure CloudFormation stack
param (
    [string]$ParentId
)

$stackName = "OrgStructureStack"
$templatePath = "iac/org_structure.yaml"

Write-Host "Checking AWS identity for profile 'admin'..." -ForegroundColor Cyan
$identityJson = aws sts get-caller-identity --profile admin --output json
if ($LASTEXITCODE -ne 0) {
    Write-Error "Could not retrieve AWS identity for profile 'admin'. Please ensure you are logged in."
    exit 1
}

$identity = $identityJson | ConvertFrom-Json

# Dynamically find Root ID if ParentId is not provided
if ([string]::IsNullOrWhiteSpace($ParentId)) {
    Write-Host "No ParentId provided. Fetching Organization Root ID..." -ForegroundColor Cyan
    $rootsJson = aws organizations list-roots --profile admin --output json
    $roots = $rootsJson | ConvertFrom-Json
    $ParentId = $roots.Roots[0].Id
    Write-Host "Found Root ID: $ParentId" -ForegroundColor Gray
}

Write-Host "Deploying stack '$stackName' to account $($identity.Account) with profile 'admin'..." -ForegroundColor Cyan

aws cloudformation deploy `
    --stack-name $stackName `
    --template-file $templatePath `
    --parameter-overrides ParentId=$ParentId `
    --profile admin `
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment successful!" -ForegroundColor Green
} else {
    Write-Error "Deployment failed. Note: Account creation via CloudFormation may fail if the email is already in use or if the organization is not fully established."
}
