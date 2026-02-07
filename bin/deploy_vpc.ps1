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

    # 1. Get Subnet IDs from VPC stack outputs
    Write-Host "Retrieving Subnet IDs from $stackName..."
    $outputs = aws cloudformation describe-stacks --stack-name $stackName --profile $profile --region $region --query "Stacks[0].Outputs" --output json | ConvertFrom-Json
    $privateSubnetId = ($outputs | Where-Object { $_.OutputKey -eq "PrivateSubnetId" }).OutputValue
    $publicSubnetId = ($outputs | Where-Object { $_.OutputKey -eq "PublicSubnetId" }).OutputValue

    if (-not $privateSubnetId -or -not $publicSubnetId) {
        Write-Error "Could not find required Subnet IDs in stack outputs."
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
        --parameter-overrides ApplicationAccountId=$appAccountId PrivateSubnetId=$privateSubnetId PublicSubnetId=$publicSubnetId `
        --profile $profile `
        --region $region

    if ($LASTEXITCODE -eq 0) {
        Write-Host "RAM share deployment successful!"
    } else {
        Write-Host "RAM share deployment failed."
    }

    Write-Host "`n--- Verification ---"
    aws ec2 describe-vpcs --profile $profile --region $region --filters "Name=tag:Name,Values=MainVPC" --query "Vpcs[*].{VpcId:VpcId,CidrBlock:CidrBlock,State:State}" --output table --no-cli-pager
    aws ec2 describe-subnets --profile $profile --region $region --filters "Name=vpc-id,Values=$((aws ec2 describe-vpcs --profile $profile --region $region --filters "Name=tag:Name,Values=MainVPC" --query "Vpcs[0].VpcId" --output text --no-cli-pager))" --query "Subnets[*].{SubnetId:SubnetId,CidrBlock:CidrBlock,Name:Tags[?Key=='Name'].Value | [0]}" --output table --no-cli-pager
    aws ec2 describe-internet-gateways --profile $profile --region $region --filters "Name=attachment.vpc-id,Values=$((aws ec2 describe-vpcs --profile $profile --region $region --filters "Name=tag:Name,Values=MainVPC" --query "Vpcs[0].VpcId" --output text --no-cli-pager))" --query "InternetGateways[*].{IgwId:InternetGatewayId,State:Attachments[0].State}" --output table --no-cli-pager
} else {
    Write-Host "VPC Stack deployment failed."
}
