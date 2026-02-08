# Cleanup script for the EC2 resources in Dev account
$stackName = "dev-ec2-stack"
$profile = "dev"
$region = "ap-southeast-1"

Write-Host "Deleting stack $stackName in Dev account (317440775610) using profile $profile..."

aws cloudformation delete-stack `
    --stack-name $stackName `
    --profile $profile `
    --region $region

Write-Host "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete `
    --stack-name $stackName `
    --profile $profile `
    --region $region

if ($LASTEXITCODE -eq 0) {
    Write-Host "EC2 Stack deletion successful!"
} else {
    Write-Host "EC2 Stack deletion failed or timed out."
}

Write-Host "`n--- Verification ---"
Write-Host "Checking for any remaining EC2 instances in the Dev account..."
$remainingInstances = aws ec2 describe-instances `
    --profile $profile `
    --region $region `
    --filters "Name=instance-state-name,Values=running,pending,stopping,stopped" `
    --query "Reservations[*].Instances[*].{InstanceId:InstanceId,Name:Tags[?Key=='Name'].Value | [0],State:State.Name}" `
    --output json | ConvertFrom-Json

if ($remainingInstances.Count -gt 0) {
    Write-Host "The following instances still exist in the account:"
    $remainingInstances | Format-Table -AutoSize
} else {
    Write-Host "No instances found in the account."
}
