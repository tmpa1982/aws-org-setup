# Deployment script for the EC2 instance in Dev account
$stackName = "dev-ec2-stack"
$templatePath = "iac/ec2_dev.yaml"
$profile = "dev"
$region = "ap-southeast-1"

Write-Host "Detecting VPC and Subnets in Dev account..."
$vpcId = aws ec2 describe-vpcs --profile $profile --region $region --filters "Name=cidr,Values=10.0.0.0/16" --query "Vpcs[0].VpcId" --output text --no-cli-pager
Write-Host "VPC: $vpcId"
$privateSubnetId = aws ec2 describe-subnets --profile $profile --region $region --filters "Name=vpc-id,Values=$vpcId" "Name=cidr,Values=10.0.1.0/24" --query "Subnets[0].SubnetId" --output text --no-cli-pager
Write-Host "Private Subnet: $privateSubnetId"
$publicSubnetId = aws ec2 describe-subnets --profile $profile --region $region --filters "Name=vpc-id,Values=$vpcId" "Name=cidr,Values=10.0.0.0/24" --query "Subnets[0].SubnetId" --output text --no-cli-pager
Write-Host "Public Subnet: $publicSubnetId"

if ($vpcId -eq "None" -or $privateSubnetId -eq "None" -or $publicSubnetId -eq "None") {
    Write-Error "Failed to detect required VPC or Subnets. Ensure the VPC stack is deployed and shared."
    exit 1
}

Write-Host "Updating stack $stackName in Dev account (317440775610) using profile $profile..."

aws cloudformation deploy `
    --template-file $templatePath `
    --stack-name $stackName `
    --profile $profile `
    --region $region `
    --capabilities CAPABILITY_IAM `
    --parameter-overrides VpcId=$vpcId PrivateSubnetId=$privateSubnetId PublicSubnetId=$publicSubnetId

if ($LASTEXITCODE -eq 0) {
    Write-Host "EC2 Stack deployment successful!"
    aws cloudformation describe-stacks --stack-name $stackName --profile $profile --region $region --query "Stacks[0].Outputs" --output table --no-cli-pager
} else {
    Write-Host "EC2 Stack deployment failed."
}
