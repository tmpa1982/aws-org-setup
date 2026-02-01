# Deployment script for the VPC
$stackName = "vpc-verification-stack"
$templatePath = "iac/vpc.yaml"
$profile = "shared"
$region = "ap-southeast-1"
$accountId = "558460665868"

Write-Host "Deploying stack $stackName to account $accountId using profile $profile..."

aws cloudformation deploy `
    --template-file $templatePath `
    --stack-name $stackName `
    --profile $profile `
    --region $region

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment successful!"
    aws ec2 describe-vpcs --profile $profile --region $region --filters "Name=tag:Name,Values=MainVPC"
    aws ec2 describe-subnets --profile $profile --region $region --filters "Name=tag:Name,Values=PrivateSubnet"
} else {
    Write-Host "Deployment failed."
}
