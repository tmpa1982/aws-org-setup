# PowerShell script to create an IAM Identity Center (SSO) user and assign AdministratorAccess to an account
param (
    [Parameter(Mandatory=$true)]
    [string]$UserName,
    [Parameter(Mandatory=$true)]
    [string]$Email,
    [Parameter(Mandatory=$true)]
    [string]$FirstName,
    [Parameter(Mandatory=$true)]
    [string]$LastName,
    [Parameter(Mandatory=$true)]
    [string]$TargetAccountId
)

Write-Host "Fetching Identity Center details..." -ForegroundColor Cyan

# 1. Get Identity Center Instance and Identity Store ID
$instancesJson = aws sso-admin list-instances --profile admin --output json
$instances = $instancesJson | ConvertFrom-Json
if ($instances.Instances.Count -eq 0) {
    Write-Error "No IAM Identity Center instance found."
    exit 1
}

$instanceArn = $instances.Instances[0].InstanceArn
$identityStoreId = $instances.Instances[0].IdentityStoreId

Write-Host "InstanceArn: $instanceArn" -ForegroundColor Gray
Write-Host "IdentityStoreId: $identityStoreId" -ForegroundColor Gray

# 2. Create the User in Identity Store
Write-Host "Creating user '$UserName' ($Email)..." -ForegroundColor Cyan
$createUserOutput = aws identitystore create-user `
    --identity-store-id $identityStoreId `
    --user-name $UserName `
    --display-name "$FirstName $LastName" `
    --name "GivenName=$FirstName,FamilyName=$LastName" `
    --emails "Value=$Email,Type=work,Primary=true" `
    --profile admin `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create user. It might already exist."
    exit 1
}

$user = $createUserOutput | ConvertFrom-Json
$userId = $user.UserId
Write-Host "User created with ID: $userId" -ForegroundColor Green

# 3. Find the AdministratorAccess Permission Set
Write-Host "Finding AdministratorAccess permission set..." -ForegroundColor Cyan
$permSetsJson = aws sso-admin list-permission-sets --instance-arn $instanceArn --profile admin --output json
$permSets = $permSetsJson | ConvertFrom-Json

$adminPermSetArn = $null
foreach ($psArn in $permSets.PermissionSets) {
    $psDetailJson = aws sso-admin describe-permission-set --instance-arn $instanceArn --permission-set-arn $psArn --profile admin --output json
    $psDetail = $psDetailJson | ConvertFrom-Json
    if ($psDetail.PermissionSet.Name -eq "AdministratorAccess") {
        $adminPermSetArn = $psArn
        break
    }
}

if (-not $adminPermSetArn) {
    Write-Error "Could not find 'AdministratorAccess' permission set."
    exit 1
}
Write-Host "Found Permission Set: $adminPermSetArn" -ForegroundColor Gray

# 4. Assign User to Account
Write-Host "Assigning user to account $TargetAccountId with AdministratorAccess..." -ForegroundColor Cyan
aws sso-admin create-account-assignment `
    --instance-arn $instanceArn `
    --target-id $TargetAccountId `
    --target-type AWS_ACCOUNT `
    --permission-set-arn $adminPermSetArn `
    --principal-type USER `
    --principal-id $userId `
    --profile admin

if ($LASTEXITCODE -eq 0) {
    Write-Host "Assignment successfully initiated!" -ForegroundColor Green
    Write-Host "The user should receive an invitation email at $Email." -ForegroundColor Yellow
} else {
    Write-Error "Failed to assign user to account."
}
