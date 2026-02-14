# Deployment script for the ECR Repository
$repoName = "app-repo"
$stackName = "ecr-$repoName-stack"
$templatePath = "iac/ecr.yaml"
$profile = "shared"
$region = "ap-southeast-1"

Write-Host "Deploying stack $stackName with repository name $repoName using profile $profile..."

aws cloudformation deploy `
    --template-file $templatePath `
    --stack-name $stackName `
    --parameter-overrides RepositoryName=$repoName `
    --profile $profile `
    --region $region --no-cli-pager

if ($LASTEXITCODE -eq 0) {
    Write-Host "ECR Stack deployment successful!"
    
    Write-Host "`n--- ECR Repository Details ---"
    aws ecr describe-repositories --repository-names $repoName --profile $profile --region $region --query "repositories[0].{RepositoryName:repositoryName,RepositoryUri:repositoryUri}" --output table --no-cli-pager
} else {
    Write-Host "ECR Stack deployment failed."
}
