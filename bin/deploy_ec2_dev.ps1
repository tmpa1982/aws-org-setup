# Deployment script for the EC2 instance in Dev account
$stackName = "dev-ec2-stack"
$templatePath = "iac/ec2_dev.yaml"
$profile = "dev"
$region = "ap-southeast-1"

Write-Host "Deploying stack $stackName to Dev account (317440775610) using profile $profile..."

aws cloudformation deploy `
    --template-file $templatePath `
    --stack-name $stackName `
    --profile $profile `
    --region $region `
    --capabilities CAPABILITY_IAM

if ($LASTEXITCODE -eq 0) {
    Write-Host "EC2 Stack deployment successful!"
    aws cloudformation describe-stacks --stack-name $stackName --profile $profile --region $region --query "Stacks[0].Outputs" --output table --no-cli-pager
} else {
    Write-Host "EC2 Stack deployment failed."
}
