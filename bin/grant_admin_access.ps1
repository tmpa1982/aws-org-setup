# Grant admin access to admin-user for all accounts in the organization
# This script uses the --profile admin to perform administrative actions.

$PROFILE_NAME = "admin"
$USER_NAME = "admin-user"
$PERMISSION_SET_NAME = "AdministratorAccess"

Write-Host "Fetching Identity Center Instance details..." -ForegroundColor Cyan
$instance = aws sso-admin list-instances --query "Instances[0].{InstanceArn:InstanceArn,IdentityStoreId:IdentityStoreId}" --output json --profile $PROFILE_NAME --no-cli-pager | ConvertFrom-Json

if (-not $instance.InstanceArn) {
    Write-Error "No IAM Identity Center instances found."
    exit 1
}

$INSTANCE_ARN = $instance.InstanceArn
$IDSTORE_ID = $instance.IdentityStoreId

Write-Host "Instance ARN: $INSTANCE_ARN"
Write-Host "Identity Store ID: $IDSTORE_ID"

Write-Host "`nFetching User ID for '$USER_NAME'..." -ForegroundColor Cyan
$userId = aws identitystore list-users --identity-store-id $IDSTORE_ID --filters "AttributePath=UserName,AttributeValue=$USER_NAME" --query "Users[0].UserId" --output text --profile $PROFILE_NAME --no-cli-pager

if ($userId -eq "None" -or -not $userId) {
    Write-Error "User '$USER_NAME' not found in Identity Store."
    exit 1
}
Write-Host "User ID: $userId"

Write-Host "`nFetching Permission Set ARN for '$PERMISSION_SET_NAME'..." -ForegroundColor Cyan
$permissionSetArn = aws sso-admin list-permission-sets --instance-arn $INSTANCE_ARN --query "PermissionSets[?contains(@, '$PERMISSION_SET_NAME')] | [0]" --output text --profile $PROFILE_NAME --no-cli-pager
# Note: If there are many permission sets, a more robust filter might be needed, but for now we follow setup logic.
# Re-verifying search if simple filter fails or returns list
if ($permissionSetArn -eq "None" -or -not $permissionSetArn) {
    # Fallback to list and find by name if query was too broad
    $psList = aws sso-admin list-permission-sets --instance-arn $INSTANCE_ARN --output json --profile $PROFILE_NAME --no-cli-pager | ConvertFrom-Json
    foreach ($psArn in $psList.PermissionSets) {
        $psDetails = aws sso-admin describe-permission-set --instance-arn $INSTANCE_ARN --permission-set-arn $psArn --output json --profile $PROFILE_NAME --no-cli-pager | ConvertFrom-Json
        if ($psDetails.PermissionSet.Name -eq $PERMISSION_SET_NAME) {
            $permissionSetArn = $psArn
            break
        }
    }
}

if (-not $permissionSetArn) {
    Write-Error "Permission Set '$PERMISSION_SET_NAME' not found."
    exit 1
}
Write-Host "Permission Set ARN: $permissionSetArn"

Write-Host "`nFetching active AWS accounts..." -ForegroundColor Cyan
$accounts = aws organizations list-accounts --query "Accounts[?State=='ACTIVE'].{Id:Id,Name:Name}" --output json --profile $PROFILE_NAME --no-cli-pager | ConvertFrom-Json

Write-Host "Found $($accounts.Count) active accounts."

foreach ($account in $accounts) {
    Write-Host "`nGranting access to account: $($account.Name) ($($account.Id))..." -ForegroundColor Cyan
    
    # Check if assignment already exists (optional optimization, but create-account-assignment is idempotent or errors gracefully)
    aws sso-admin create-account-assignment `
        --instance-arn $INSTANCE_ARN `
        --target-id $($account.Id) `
        --target-type "AWS_ACCOUNT" `
        --permission-set-arn $permissionSetArn `
        --principal-type "USER" `
        --principal-id $userId `
        --profile $PROFILE_NAME `
        --no-cli-pager | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Assignment request submitted for $($account.Name)." -ForegroundColor Green
    } else {
        Write-Host "Error assigning access to $($account.Name)." -ForegroundColor Red
    }
}

Write-Host "`nChecking status of assignments..." -ForegroundColor Cyan
aws sso-admin list-account-assignment-creation-status --instance-arn $INSTANCE_ARN --max-items 5 --profile $PROFILE_NAME --no-cli-pager
