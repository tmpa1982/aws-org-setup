# PowerShell script to grant ECR access to appdev-admin user
param (
    [string]$ProfileName = "admin",
    [string]$UserName = "appdev-admin",
    [string]$PermissionSetName = "ECRPushPullAccess",
    [string]$TargetAccountName = "shared-services"
)

Write-Host "Fetching Identity Center details..." -ForegroundColor Cyan
$instance = aws sso-admin list-instances --query "Instances[0].{InstanceArn:InstanceArn,IdentityStoreId:IdentityStoreId}" --output json --profile $ProfileName --no-cli-pager | ConvertFrom-Json

if (-not $instance.InstanceArn) {
    Write-Error "No IAM Identity Center instances found."
    exit 1
}

$INSTANCE_ARN = $instance.InstanceArn
$IDSTORE_ID = $instance.IdentityStoreId

Write-Host "Instance ARN: $INSTANCE_ARN"
Write-Host "Identity Store ID: $IDSTORE_ID"

# 1. Get User ID
Write-Host "`nFetching User ID for '$UserName'..." -ForegroundColor Cyan
$userId = aws identitystore list-users --identity-store-id $IDSTORE_ID --filters "AttributePath=UserName,AttributeValue=$UserName" --query "Users[0].UserId" --output text --profile $ProfileName --no-cli-pager

if ($userId -eq "None" -or -not $userId) {
    Write-Error "User '$UserName' not found."
    exit 1
}
Write-Host "User ID: $userId"

# 2. Create Permission Set if it doesn't exist
Write-Host "`nChecking for Permission Set '$PermissionSetName'..." -ForegroundColor Cyan
$permissionSetArn = aws sso-admin list-permission-sets --instance-arn $INSTANCE_ARN --profile $ProfileName --no-cli-pager --output json | ConvertFrom-Json | Select-Object -ExpandProperty PermissionSets | ForEach-Object {
    $details = aws sso-admin describe-permission-set --instance-arn $INSTANCE_ARN --permission-set-arn $_ --profile $ProfileName --no-cli-pager --output json | ConvertFrom-Json
    if ($details.PermissionSet.Name -eq $PermissionSetName) { $_ }
} | Select-Object -First 1

if (-not $permissionSetArn) {
    Write-Host "Creating Permission Set '$PermissionSetName'..." -ForegroundColor Cyan
    $permissionSetArn = aws sso-admin create-permission-set `
        --instance-arn $INSTANCE_ARN `
        --name $PermissionSetName `
        --description "Grants ECR push and pull permissions" `
        --profile $ProfileName `
        --query "PermissionSet.PermissionSetArn" `
        --output text `
        --no-cli-pager
    
    # Attach Managed Policy
    Write-Host "Attaching AmazonEC2ContainerRegistryPowerUser policy..." -ForegroundColor Cyan
    aws sso-admin attach-managed-policy-to-permission-set `
        --instance-arn $INSTANCE_ARN `
        --permission-set-arn $permissionSetArn `
        --managed-policy-arn "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser" `
        --profile $ProfileName `
        --no-cli-pager
} else {
    Write-Host "Permission Set already exists: $permissionSetArn" -ForegroundColor Gray
}

# 3. Get Target Account ID
Write-Host "`nFetching Account ID for '$TargetAccountName'..." -ForegroundColor Cyan
$accountId = aws organizations list-accounts --query "Accounts[?Name=='$TargetAccountName'].Id" --output text --profile $ProfileName --no-cli-pager

if ($accountId -eq "None" -or -not $accountId) {
    Write-Error "Account '$TargetAccountName' not found."
    exit 1
}
Write-Host "Target Account ID: $accountId"

# 4. Create Account Assignment
Write-Host "`nAssigning '$UserName' to account '$TargetAccountName'..." -ForegroundColor Cyan
aws sso-admin create-account-assignment `
    --instance-arn $INSTANCE_ARN `
    --target-id $accountId `
    --target-type AWS_ACCOUNT `
    --permission-set-arn $permissionSetArn `
    --principal-type USER `
    --principal-id $userId `
    --profile $ProfileName `
    --no-cli-pager | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Assignment successfully initiated!" -ForegroundColor Green
} else {
    Write-Error "Failed to create assignment."
}
