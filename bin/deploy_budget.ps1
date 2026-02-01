# PowerShell script to deploy the Budget CloudFormation stack
param (
    [Parameter(Mandatory=$true)]
    [string]$NotificationEmail
)

$stackName = "MonthlyBudgetStack"
$templatePath = "iac/budget.yaml"

Write-Host "Checking AWS identity for profile 'admin'..." -ForegroundColor Cyan
$identityJson = aws sts get-caller-identity --profile admin --output json
if ($LASTEXITCODE -ne 0) {
    Write-Error "Could not retrieve AWS identity for profile 'admin'. Please ensure you are logged in."
    exit 1
}

$identity = $identityJson | ConvertFrom-Json

Write-Host "Deploying stack '$stackName' to account $($identity.Account) with profile 'admin'..." -ForegroundColor Cyan

aws cloudformation deploy `
    --stack-name $stackName `
    --template-file $templatePath `
    --parameter-overrides NotificationEmail=$NotificationEmail `
    --profile admin `
    --no-fail-on-empty-changeset

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment successful!" -ForegroundColor Green
} else {
    Write-Error "Deployment failed."
}
