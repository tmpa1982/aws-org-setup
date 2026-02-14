# PowerShell script to deploy GitHub Actions OIDC stack
param (
    [string]$ProfileName = "shared",
    [string]$GitHubOrg = "tmpa1982",
    [string]$GitHubRepo = "aws-python-sample",
    [string]$StackName = "github-oidc"
)

$TemplatePath = Join-Path $PSScriptRoot "..\iac\github_oidc.yaml"

Write-Host "Deploying GitHub OIDC stack..." -ForegroundColor Cyan

aws cloudformation deploy `
    --stack-name $StackName `
    --template-file $TemplatePath `
    --parameter-overrides GitHubOrg=$GitHubOrg GitHubRepo=$GitHubRepo `
    --capabilities CAPABILITY_NAMED_IAM `
    --profile $ProfileName `
    --no-cli-pager

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nStack deployed successfully!" -ForegroundColor Green
    $roleArn = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --query "Stacks[0].Outputs[?OutputKey=='RoleArn'].OutputValue" `
        --output text `
        --profile $ProfileName `
        --no-cli-pager
    
    Write-Host "`nIMPORTANT: Set 'AWS_ROLE_TO_ASSUME' in GitHub Secrets to:" -ForegroundColor Yellow
    Write-Host $roleArn -ForegroundColor Cyan
} else {
    Write-Error "Stack deployment failed."
}
