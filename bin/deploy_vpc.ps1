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
    Write-Host "VPC Stack deployment successful!"

    # 1. Get PrivateSubnetId from VPC stack outputs
    Write-Host "Retrieving PrivateSubnetId from $stackName..."
    $outputs = aws cloudformation describe-stacks --stack-name $stackName --profile $profile --region $region --query "Stacks[0].Outputs" --output json | ConvertFrom-Json
    $privateSubnetId = ($outputs | Where-Object { $_.OutputKey -eq "PrivateSubnetId" }).OutputValue

    if (-not $privateSubnetId) {
        Write-Error "Could not find PrivateSubnetId in stack outputs."
        exit 1
    }

    # 2. Deploy RAM share stack
    $ramStackName = "vpc-ram-share-stack"
    $ramTemplatePath = "iac/ram_share.yaml"
    $appAccountId = "317440775610" # application-dev account

    Write-Host "Deploying RAM share stack $ramStackName..."
    aws cloudformation deploy `
        --template-file $ramTemplatePath `
        --stack-name $ramStackName `
        --parameter-overrides ApplicationAccountId=$appAccountId PrivateSubnetId=$privateSubnetId `
        --profile $profile `
        --region $region

    if ($LASTEXITCODE -eq 0) {
        Write-Host "RAM share deployment successful!"
    } else {
        Write-Host "RAM share deployment failed."
    }

    aws ec2 describe-vpcs --profile $profile --region $region --filters "Name=tag:Name,Values=MainVPC" --no-cli-pager
    aws ec2 describe-subnets --profile $profile --region $region --filters "Name=tag:Name,Values=PrivateSubnet" --no-cli-pager
} else {
    Write-Host "VPC Stack deployment failed."
}
